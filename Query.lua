local inspect = require("inspect")
local Builders = require("Builders")
local XmlUtils = require("XmlUtils")
local Query = {}



local function hitTest(pointX, pointY, selectionRec)
    local pointX = tonumber(pointX)
    local pointY = tonumber(pointY)
    return pointX >= selectionRec.left and pointX <= selectionRec.right and pointY >= selectionRec.top and pointY <=
               selectionRec.bottom
end

local function matchRec(node, idText)
    return node._attr ~= nil and node._attr.text == idText
end



function Query.findRec(data, xmlRectanglesPath, idText)
    -- Validate the Path to Rectangles
    if XmlUtils.isValidXmlPath(data, xmlRectanglesPath) == false then
        print("Invalid Path to Rectangles")
        return nil
    end

    -- Traverse the Path
    local nodes = XmlUtils.enumerateNode(XmlUtils.traversePath(data, xmlRectanglesPath))

    -- Find a matching node else return nil
    for i = 1, #nodes do
        if matchRec(nodes[i], idText) then
            return Builders.Rec(nodes[i])
        end
    end

    return nil
end

function Query.getElements(data, xmlPath, selectionRec)
    if XmlUtils.isValidXmlPath(data, xmlPath) == false then
        return {}
    end

    --- HERE. Need to call EnumerateNode based on XML Path.
    local nodes = XmlUtils.enumerateNode(XmlUtils.traversePath(data, xmlPath))
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
