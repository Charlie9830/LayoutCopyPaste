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

function XmlUtils.cloneNode(node)
    local orig_type = type(node)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, node, nil do
            copy[XmlUtils.cloneNode(orig_key)] = XmlUtils.cloneNode(orig_value)
        end
        setmetatable(copy, XmlUtils.cloneNode(getmetatable(node)))
    else -- number, string, boolean, etc
        copy = node
    end
    return copy
end

function XmlUtils.getFixturesIndexNode(data, fixturesIndexPath)
    -- Validate the provided path to the fixtures index. Coerce it into existence if required.
    if XmlUtils.isValidXmlPath(data, fixturesIndexPath) == false then
        XmlUtils.coercePath(data, fixturesIndexPath)
    end

    -- Get the Fixtures Index Node
    return XmlUtils.traversePath(data, fixturesIndexPath)
end

-- Converts in place an existing singular node into a List, the existing data of the node becomes the element at index[1]
function XmlUtils.listifySingularNode(node)
    -- First determine if the provided node is Blank (No Attributes) and Childless, this is usually the result of the xmlPath being coerced into existence.
    -- .. when this is the case we just want to remove the empty _attr property from the node. Otherwise we will end up adding a blank node to the XML output.
    if XmlUtils.isBlankAndChildless(node) == true then
        node._attr = nil
        return
    end

    local packagedNode = {}
    local keysToDelete = {}
    packagedNode._attr = node._attr
    node._attr = nil

    for k, v in pairs(node) do
        packagedNode[k] = v
        table.insert(keysToDelete, k)
    end

    for i = 1, #keysToDelete do
        node[keysToDelete[i]] = nil
    end

    node[1] = packagedNode
end

return XmlUtils
