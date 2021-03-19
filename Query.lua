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
    return node._attr ~= nil and string.compareCaseInsensitive(node._attr.text, idText)
end

function Query.findRec(data, xmlRectanglesPath, idText)
    -- Validate the Path to Rectangles
    if XmlUtils.isValidXmlPath(data, xmlRectanglesPath) == false then
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

function Query.getCollidingFixtures(sourceFixtures, targetFixtureSet)
    if sourceFixtures == nil or #sourceFixtures == 0 then
        return 0, {}
    end

    -- Add source Fixtures SubFixKey to returnSet if it appears in targetFixtureSet.
    local returnSet = {}
    local collisionCount = 0
    for i = 1, #sourceFixtures do
        local subFixNode = sourceFixtures[i]["Subfixture"]
        local attr = subFixNode._attr
        local subFixKey = Builders.SubFixKey(attr.fix_id, attr.sub_index, attr.cha_id)

        if table.has(targetFixtureSet, subFixKey) == true then
            returnSet[subFixKey] = true
            collisionCount = collisionCount + 1
        end
    end

    return collisionCount, returnSet
end

function Query.peekFixtureIndex(data, xmlPath)
    if XmlUtils.isValidXmlPath(data, xmlPath) == false then
        -- If the path is invalid, then there are no Fixtures in the Layout.
        return {}
    end

    local fixturesIndexNode = XmlUtils.traversePath(data, xmlPath)

    -- Extract the fixture data from the node, we can't use LisitfySingularNode as it would be an antipattern to mutate the underlying table in a Query Function.
    local returnSet = {}
    if XmlUtils.isNodeSingular(fixturesIndexNode) then
        local attr = fixturesIndexNode._attr
        returnSet[Builders.SubFixKey(attr["fix_id"], attr["sub_index"], attr["cha_id"])] = true
        return returnSet
    else
        for i = 1, #fixturesIndexNode do
            local attr = fixturesIndexNode[i]._attr
            returnSet[Builders.SubFixKey(attr["fix_id"], attr["sub_index"], attr["cha_id"])] = true
        end

        return returnSet
    end

    return {}
end

function Query.getElements(data, xmlPath, selectionRec, selectionRecIdText)
    if XmlUtils.isValidXmlPath(data, xmlPath) == false then
        return {}
    end

    --- HERE. Need to call EnumerateNode based on XML Path.
    local nodes = XmlUtils.enumerateNode(XmlUtils.traversePath(data, xmlPath))
    local elements = {}
    local elementIndex = 1

    for i = 1, #nodes do
        if hitTest(nodes[i]._attr.center_x, nodes[i]._attr.center_y, selectionRec) == true and
            matchRec(nodes[i], selectionRecIdText) == false then
            elements[elementIndex] = nodes[i]
            elementIndex = elementIndex + 1
        end
    end

    return elements
end

return Query
