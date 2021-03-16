local Utils = require("Utils")
local XmlUtils = {}

local function hasAttrs(node)
    if node._attr == nil then
        return false
    end

    if Utils.hasProperties(node._attr) == false then
        return false
    end

    return true
end

local function hasChildren(node)
    local doesHaveChildren = false

    for k, v in pairs(node) do
        if k ~= "_attr" then
            doesHaveChildren = true
            break
        end
    end

    return doesHaveChildren
end

function XmlUtils.listChildrenTags(node)
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

-- Check if a given node is Singular. If there is only once instance of a node within a given Parent node. Xml2Lua will return a Table instance, otherwise if there are
-- .. multiple instances of a node an Array will be returned.
function XmlUtils.isNodeSingular(node)
    return #node == 0
end

function XmlUtils.isBlankAndChildless(node)
    return hasAttrs(node) == false and hasChildren(node) == false
end

-- Xml2Lua will provide a table instance of a node if no other instances of that Tag exist within the parent Node, But if mulitple instances exist, Xml2Lua will instead
-- provide an array instance. This function sanitizes a node into an Array, even if that array is only 1 element long.
function XmlUtils.enumerateNode(node)

    if XmlUtils.isNodeSingular(node) then
        return {node}
    else
        return node
    end
end

-- Validates a particular path down the XML Tree. If returns true if all Path Segments return non nil objects.
function XmlUtils.isValidXmlPath(data, path)
    -- TODO: Error handling for nil path argument

    local currentNode = data
    if currentNode == nil then
        return false
    end

    for i = 1, #path do
        currentNode = currentNode[path[i]]
        if currentNode == nil then
            return false
        end
    end

    return true
end

function XmlUtils.traversePath(data, path)
    local currentNode = data

    for i = 1, #path do
        currentNode = currentNode[path[i]]
    end

    return currentNode
end

-- Coerces a Path into existence. Walks down the desired path creating Nodes where needed.
function XmlUtils.coercePath(rootNode, path)
    local currentNode = rootNode

    for i = 1, #path do
        if currentNode[path[i]] == nil then
            currentNode[path[i]] = {
                _attr = {}
            }
        end

        currentNode = currentNode[path[i]]
    end
end

return XmlUtils
