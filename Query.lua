local inspect = require("inspect")
local Builders = require("Builders")
local Query = {}

-- Validates a particular path down the XML Tree. If returns true if all Path Segments return non nil objects.
local function isValidXmlPath(data, path)
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

local function traversePath(data, path)
    local currentNode = data

    for i = 1, #path do
        currentNode = currentNode[path[i]]
    end

    return currentNode
end

local function hitTest(pointX, pointY, selectionRec)
    local pointX = tonumber(pointX)
    local pointY = tonumber(pointY)
    return pointX >= selectionRec.left and pointX <= selectionRec.right and pointY >= selectionRec.top and pointY <=
               selectionRec.bottom
end

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

-- Xml2Lua will provide a table instance of a node if no other instances of that Tag exist within the parent Node, But if mulitple instances exist, Xml2Lua will instead
-- provide an array instance. This function sanitizes a node into an Array, even if that array is only 1 element long.
local function enumerateNode(node)
    local function isNodeSingular(node)
        return #node == 0
    end

    if isNodeSingular(node) then
        return {node}
    else
        return node
    end
end

function Query.findSelectionRec(data, xmlRectanglesPath)
    -- Validate the Path to Rectangles
    if isValidXmlPath(data, xmlRectanglesPath) == false then
        print("Path Invalid")
        return nil
    end

    -- Traverse the Path
    local nodes = enumerateNode(traversePath(data, xmlRectanglesPath))

    -- Find a matching node else return nil
    for i = 1, #nodes do
        if matchesCopyRec(nodes[i]) then
            return Builders.Rec(nodes[i])
        end
    end

    return nil
end

function Query.getElements(data, xmlPath, selectionRec)
    if isValidXmlPath(data, xmlPath) == false then
        return {}
    end

    --- HERE. Need to call EnumerateNode based on XML Path.
    local nodes = enumerateNode(traversePath(data, xmlPath))
    local elements = {}
    local elementIndex = 1

    for i = 1, #nodes do
        if hitTest(nodes[i]._attr.center_x, nodes[i]._attr.center_y, selectionRec) == true then
            elements[elementIndex] = nodes[i]
            elementIndex = elementIndex + 1
        end
    end

    return elements
end

return Query
