local inspect = require("inspect")
local Builders = require("Builders")
local Mutation = {}

local function matchesCopyRec(node)
    return node._attr ~= nil and node._attr.text == 'copy'
end

local function listChildrenTags(node)
    local tags = {}
    local i = 1

    for k, v in pairs(node) do
        if k ~= "_attr" then
            tags[i] = tostring(k)
            i = i + 1
        end
    end

    return tags
end

local function isNodeSingular(node)
    return #node == 0
end

function Mutation.findSelectionRec(data)
    -- Validate the Path to Rectangles
    if data == nil or data.MA == nil or data.MA.Group == nil or data.MA.Group.LayoutData == nil or
        data.MA.Group.LayoutData.Rectangles == nil or data.MA.Group.LayoutData.Rectangles.LayoutElement == nil then
        return nil
    end

    local node = data.MA.Group.LayoutData.Rectangles.LayoutElement

    if isNodeSingular(node) then
        if matchesCopyRec(node) then
            return Builders.Rec(node)
        end
    else
        for i = 1, #node do
            if matchesCopyRec(node[i]) then
                return Builders.Rec(node[i])
            end
        end
    end

    -- Traverse down to the Rectangles Node.

    -- local recTable = data.MA.Group.LayoutData.Rectangles

    -- -- Notice here that we are then calling LayoutELement on recTable. Thats because the parser is grouping the Tag types into their own Arrays.
    -- for k, v in pairs(recTable.LayoutElement) do
    --     print(v._attr.text)
    -- end
end

return Mutation
