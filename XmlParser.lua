local function decimalToHtmlChar(code)
    local num = tonumber(code)
    if num >= 0 and num < 256 then
        return string.char(num)
    end

    return "&#"..code..";"
end

local function hexadecimalToHtmlChar(code)
    local num = tonumber(code, 16)
    if num >= 0 and num < 256 then
        return string.char(num)
    end

    return "&#x"..code..";"
end

local XmlParser = {
    -- Private attribures/functions
    _XML        = '^([^<]*)<(%/?)([^>]-)(%/?)>',
    _ATTR1      = '([%w-:_]+)%s*=%s*"(.-)"',
    _ATTR2      = '([%w-:_]+)%s*=%s*\'(.-)\'',
    _CDATA      = '<%!%[CDATA%[(.-)%]%]>',
    _PI         = '<%?(.-)%?>',
    _COMMENT    = '<!%-%-(.-)%-%->',
    _TAG        = '^(.-)%s.*',
    _LEADINGWS  = '^%s+',
    _TRAILINGWS = '%s+$',
    _WS         = '^%s*$',
    _DTD1       = '<!DOCTYPE%s+(.-)%s+(SYSTEM)%s+["\'](.-)["\']%s*(%b[])%s*>',
    _DTD2       = '<!DOCTYPE%s+(.-)%s+(PUBLIC)%s+["\'](.-)["\']%s+["\'](.-)["\']%s*(%b[])%s*>',
    --_DTD3       = '<!DOCTYPE%s+(.-)%s*(%b[])%s*>',
    _DTD3       = '<!DOCTYPE%s.->',
    _DTD4       = '<!DOCTYPE%s+(.-)%s+(SYSTEM)%s+["\'](.-)["\']%s*>',
    _DTD5       = '<!DOCTYPE%s+(.-)%s+(PUBLIC)%s+["\'](.-)["\']%s+["\'](.-)["\']%s*>',

    --Matches an attribute with non-closing double quotes (The equal sign is matched non-greedly by using =+?)
    _ATTRERR1   = '=+?%s*"[^"]*$',
    --Matches an attribute with non-closing single quotes (The equal sign is matched non-greedly by using =+?)
    _ATTRERR2   = '=+?%s*\'[^\']*$',
    --Matches a closing tag such as </person> or the end of a openning tag such as <person>
    _TAGEXT     = '(%/?)>',

    _errstr = { 
        xmlErr = "Error Parsing XML",
        declErr = "Error Parsing XMLDecl",
        declStartErr = "XMLDecl not at start of document",
        declAttrErr = "Invalid XMLDecl attributes",
        piErr = "Error Parsing Processing Instruction",
        commentErr = "Error Parsing Comment",
        cdataErr = "Error Parsing CDATA",
        dtdErr = "Error Parsing DTD",
        endTagErr = "End Tag Attributes Invalid",
        unmatchedTagErr = "Unbalanced Tag",
        incompleteXmlErr = "Incomplete XML Document",
    },

    _ENTITIES = { 
        ["&lt;"] = "<",
        ["&gt;"] = ">",
        ["&amp;"] = "&",
        ["&quot;"] = '"',
        ["&apos;"] = "'",
        ["&#(%d+);"] = decimalToHtmlChar,
        ["&#x(%x+);"] = hexadecimalToHtmlChar,
    },
}

function XmlParser.new(_handler, _options)
    local obj = {
        handler = _handler,
        options = _options,
        _stack  = {}
    }

    setmetatable(obj, XmlParser)
    obj.__index = XmlParser
    return obj;
end


local function fexists(table, elementName)
    if table == nil then
        return false
    end

    if table[elementName] == nil then
        return fexists(getmetatable(table), elementName)
    else
        return true
    end
end

local function err(self, errMsg, pos)
    if self.options.errorHandler then
        self.options.errorHandler(errMsg,pos)
    end
end

--- Removes whitespaces
local function stripWS(self, s)
    if self.options.stripWS then
        s = string.gsub(s,'^%s+','')
        s = string.gsub(s,'%s+$','')
    end
    return s
end

local function parseEntities(self, s) 
    if self.options.expandEntities then
        for k,v in pairs(self._ENTITIES) do
            s = string.gsub(s,k,v)
        end
    end

    return s
end

local function parseTag(self, s)
    local tag = {
            name = string.gsub(s, self._TAG, '%1'),
            attrs = {}
          }            

    local parseFunction = function (k, v) 
            tag.attrs[k] = parseEntities(self, v)
            tag.attrs._ = 1 
          end
                          
    string.gsub(s, self._ATTR1, parseFunction) 
    string.gsub(s, self._ATTR2, parseFunction)

    if tag.attrs._ then
        tag.attrs._ = nil
    else 
        tag.attrs = nil
    end

    return tag
end

local function parseXmlDeclaration(self, xml, f)
    -- XML Declaration
    f.match, f.endMatch, f.text = string.find(xml, self._PI, f.pos)
    if not f.match then 
        err(self, self._errstr.declErr, f.pos)
    end 

    if f.match ~= 1 then
        -- Must be at start of doc if present
        err(self, self._errstr.declStartErr, f.pos)
    end

    local tag = parseTag(self, f.text) 
    -- TODO: Check if attributes are valid
    -- Check for version (mandatory)
    if tag.attrs and tag.attrs.version == nil then
        err(self, self._errstr.declAttrErr, f.pos)
    end

    if fexists(self.handler, 'decl') then 
        self.handler:decl(tag, f.match, f.endMatch)
    end    

    return tag
end

local function parseNormalTag(self, xml, f)
    -- Extract tag name and attrs
    local tag = parseTag(self, f.tagstr) 

    if (f.endt1=="/") then
        if fexists(self.handler, 'endtag') then
            if tag.attrs then
                -- Shouldn't have any attributes in endtag
                err(self, string.format("%s (/%s)", self._errstr.endTagErr, tag.name), f.pos)
            end
            if table.remove(self._stack) ~= tag.name then
                err(self, string.format("%s (/%s)", self._errstr.unmatchedTagErr, tag.name), f.pos)
            end
            self.handler:endtag(tag, f.match, f.endMatch)
        end
    else
        table.insert(self._stack, tag.name)
        if fexists(self.handler, 'starttag') then
            self.handler:starttag(tag, f.match, f.endMatch)
        end

        -- Self-Closing Tag
        if (f.endt2=="/") then
            table.remove(self._stack)
            if fexists(self.handler, 'endtag') then
                self.handler:endtag(tag, f.match, f.endMatch)
            end
        end
    end

    return tag
end

local function parseTagType(self, xml, f)
    -- Test for tag type
    if string.find(string.sub(f.tagstr, 1, 5), "?xml%s") then
        parseXmlDeclaration(self, xml, f)
    else
        parseNormalTag(self, xml, f)
    end
end

local function getNextTag(self, xml, f)
  f.match, f.endMatch, f.text, f.endt1, f.tagstr, f.endt2 = string.find(xml, self._XML, f.pos)
  if not f.match then 
      if string.find(xml, self._WS, f.pos) then
          -- No more text - check document complete
          if #self._stack ~= 0 then
              err(self, self._errstr.incompleteXmlErr, f.pos)
          else
              return false 
          end
      else
          -- Unparsable text
          err(self, self._errstr.xmlErr, f.pos)
      end
  end 

  f.text = f.text or ''
  f.tagstr = f.tagstr or ''
  f.match = f.match or 0
  
  return f.endMatch ~= nil
end

function XmlParser:parse(xml, parseAttributes, progressCallback)
    if type(self) ~= "table" or getmetatable(self) ~= XmlParser then
        error("You must call xmlparser:parse(parameters) instead of xmlparser.parse(parameters)")
    end

    if parseAttributes == nil then
       parseAttributes = true
    end

    self.handler.parseAttributes = parseAttributes

    --Stores string.find results and parameters
    --and other auxiliar variables
    local f = {
        --string.find return
        match = 0,
        endMatch = 0,
        -- text, end1, tagstr, end2,

        --string.find parameters and auxiliar variables
        pos = 1,
        -- startText, endText,
        -- errStart, errEnd, extStart, extEnd,
    }

    while f.match do
        progressCallback()
        if not getNextTag(self, xml, f) then
            break
        end
        
        -- Handle leading text
        f.startText = f.match
        f.endText = f.match + string.len(f.text) - 1
        f.match = f.match + string.len(f.text)
        f.text = parseEntities(self, stripWS(self, f.text))
        if f.text ~= "" and fexists(self.handler, 'text') then
            self.handler:text(f.text, nil, f.match, f.endText)
        end

        parseTagType(self, xml, f)
        f.pos = f.endMatch + 1
    end
end

XmlParser.__index = XmlParser
return XmlParser
