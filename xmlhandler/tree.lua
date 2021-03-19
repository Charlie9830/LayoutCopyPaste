local function init()
    local obj = {
        root = {},
        options = {noreduce = {}}
    }
    
    obj._stack = {obj.root}  
    return obj  
end

local tree = init()

function tree:new()
    local obj = init()

    obj.__index = self
    setmetatable(obj, self)

    return obj
end

function tree:reduce(node, key, parent)
    for k,v in pairs(node) do
        if type(v) == 'table' then
            self:reduce(v,k,node)
        end
    end
    if #node == 1 and not self.options.noreduce[key] and 
        node._attr == nil then
        parent[key] = node[1]
    end
end

function tree:starttag(tag)
    local node = {}
    if self.parseAttributes == true then
        node._attr=tag.attrs
    end

    --Table in the stack representing the tag being processed
    local current = self._stack[#self._stack]
    
    if current[tag.name] then
        table.insert(current[tag.name], node)
    else
        current[tag.name] = {node}
    end

    table.insert(self._stack, node)
end


function tree:endtag(tag, s)
    --Table in the stack representing the tag being processed
    --Table in the stack representing the containing tag of the current tag
    local prev = self._stack[#self._stack-1]
    if not prev[tag.name] then
        error("XML Error - Unmatched Tag ["..s..":"..tag.name.."]\n")
    end
    if prev == self.root then
        -- Once parsing complete, recursively reduce tree
        self:reduce(prev, nil, nil)
    end

    table.remove(self._stack)
end


function tree:text(text)
    local current = self._stack[#self._stack]
    table.insert(current, text)
end

---Parses CDATA tag content.
tree.cdata = tree.text
tree.__index = tree
return tree
