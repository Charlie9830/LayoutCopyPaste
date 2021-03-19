local xml2lua = {_VERSION = "1.4-5"}
local XmlParser = require("XmlParser")

local function printableInternal(tb, level)
  if tb == nil then
     return
  end
  
  level = level or 1
  local spaces = string.rep(' ', level*2)
  for k,v in pairs(tb) do
      if type(v) == "table" then
         print(spaces .. k)
         printableInternal(v, level+1)
      else
         print(spaces .. k..'='..v)
      end
  end  
end

function xml2lua.parser(handler)    
    if handler == xml2lua then
        error("You must call xml2lua.parse(handler) instead of xml2lua:parse(handler)")
    end

    local options = { 
            --Indicates if whitespaces should be striped or not
            stripWS = 1, 
            expandEntities = 1,
            errorHandler = function(errMsg, pos) 
                error(string.format("%s [char=%d]\n", errMsg or "Parse Error", pos))
            end
          }

    return XmlParser.new(handler, options)
end


function xml2lua.printable(tb)
    printableInternal(tb)
end

function xml2lua.toString(t)
    local sep = ''
    local res = ''
    if type(t) ~= 'table' then
        return t
    end

    for k,v in pairs(t) do
        if type(v) == 'table' then 
            v = xml2lua.toString(v)
        end
        res = res .. sep .. string.format("%s=%s", k, v)    
        sep = ','
    end
    res = '{'..res..'}'

    return res
end


function xml2lua.loadFile(xmlFilePath)
    local f, e = io.open(xmlFilePath, "r")
    if f then
        --Gets the entire file content and stores into a string
        local content = f:read("*a")
        f:close()
        return content
    end
    
    error(e)
end


local function attrToXml(attrTable)
  local s = ""
  attrTable = attrTable or {}
  
  for k, v in pairs(attrTable) do
      s = s .. " " .. k .. "=" .. '"' .. v .. '"'
  end
  return s
end

---Gets the first key of a given table
local function getFirstKey(tb)
   if type(tb) == "table" then
      for k, _ in pairs(tb) do
          return k
      end
      return nil
   end

   return tb
end


function xml2lua.toXml(tb, tableName, level)
  level = level or 1
  local firstLevel = level
  local spaces = string.rep(' ', level*2)
  tableName = tableName or ''
  local xmltb = (tableName ~= '' and level == 1) and {'<'..tableName..'>'} or {}

  for k, v in pairs(tb) do
      if type(v) == 'table' then
         if type(k) == 'number' then
            local attrs = attrToXml(v._attr)
            v._attr = nil
            table.insert(xmltb, 
                spaces..'<'..tableName..attrs..'>\n'..xml2lua.toXml(v, tableName, level+1)..
                '\n'..spaces..'</'..tableName..'>') 
         else 
            level = level + 1
            if type(getFirstKey(v)) == 'number' then 
               table.insert(xmltb, xml2lua.toXml(v, k, level))
            else
               -- Otherwise, the "HashMap" values are objects 
               local attrs = attrToXml(v._attr)
               v._attr = nil
               table.insert(xmltb, 
                   spaces..'<'..k..attrs..'>\n'.. xml2lua.toXml(v, k, level+1)..
                   '\n'..spaces..'</'..k..'>')
            end
         end
      else
         if type(k) == 'number' then
            k = tableName
         end
         table.insert(xmltb, spaces..'<'..k..'>'..tostring(v)..'</'..k..'>')
      end
  end

  if tableName ~= '' and firstLevel == 1 then
      table.insert(xmltb, '</'..tableName..'>\n')
  end

  return table.concat(xmltb, '\n')
end

return xml2lua
