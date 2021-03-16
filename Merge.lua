local XmlUtils = require("XmlUtils")
local inspect = require("inspect")
local Builders = require "Builders"

local Merge = {}



function Merge.calculatePosOffset(sourceCopyRec, targetPasteRec)
    local xOffset = sourceCopyRec.centerX - targetPasteRec.centerX
    local yOffset = sourceCopyRec.centerY - targetPasteRec.centerY

    return xOffset, yOffset
end

-- Performs a Translate (Move) of an node in place.
local function translateNode(node, xOffset, yOffset)
    if node == nil or node._attr == nil then
        return
    end

    node._attr['center_x'] = tonumber(node._attr['center_x']) - xOffset
    node._attr['center_y'] = tonumber(node._attr['center_y']) - yOffset

    return
end

local function alreadyInFixturesIndex(subfixNodeAttrs, fixturesIndexLookup)
    if subfixNodeAttrs == nil then
        return false
    end

    print(Builders.SubFixKey(subfixNodeAttrs.fix_id, subfixNodeAttrs.sub_index, subfixNodeAttrs.cha_id))

    return fixturesIndexLookup[Builders.SubFixKey(subfixNodeAttrs.fix_id, subfixNodeAttrs.sub_index,
               subfixNodeAttrs.cha_id)] ~= nil
end

function Merge.buildFixtureLookup(fixturesIndexNode)
    local fixturesIndexLookup = {}

    for i = 1, #fixturesIndexNode do
        local attr = fixturesIndexNode[i]._attr
        fixturesIndexLookup[Builders.SubFixKey(attr.fix_id, attr.sub_index, attr.cha_id)] = fixturesIndexNode[i]
    end

    return fixturesIndexLookup
end

local function getPendingDuplicateFixtures(fixtures, targetFixtureLookup)
    if fixtures == nil or #fixtures == 0 then
        return {}
    end

    local duplicateFixtures = {}
    local duplicateIndex = 1

    for i = 1, #fixtures do
        local subFixNode = fixtures[i]["Subfixture"]
        if alreadyInFixturesIndex(subFixNode._attr, targetFixtureLookup) == true then
            duplicateFixtures[duplicateIndex] = subFixNode
            duplicateIndex = duplicateIndex + 1
        end
    end

    return duplicateFixtures

end

-- Updates the Subfixtures XML index in place. Without a correct Subfixtures index, commands such as "SelFix Layout X" will not work correctly.
local function updateFixturesIndex(fixtures, targetData, fixturesIndexNode, targetFixtureLookup, fixturesIndexPath)
    if fixtures == nil or #fixtures == 0 then
        -- Wrap it up boys, we are done here, nice work.
        return
    end

    -- If the node is Singular, it will be of type:table with string properties, if it is not singular it will be of type:array. Therefore, if it's singular, 
    -- .. we need to "Listify" it first.
    if XmlUtils.isNodeSingular(fixturesIndexNode) then
        XmlUtils.listifySingularNode(fixturesIndexNode)
    end

    for i = 1, #fixtures do
        local incomingSubFixNode = fixtures[i]["Subfixture"]
        table.insert(fixturesIndexNode, XmlUtils.cloneNode(incomingSubFixNode))
    end
end

local function mergeContent(sourceContent, targetData, contentPath, xOffset, yOffset)
    if #sourceContent == 0 then
        -- Nothing to Merge in so just walk away, don't touch anything on your way out.
        return
    end
    -- Validate the provided Xml Path. Coerce it into existence if required.
    if XmlUtils.isValidXmlPath(targetData, contentPath) == false then
        XmlUtils.coercePath(targetData, contentPath)
    end

    -- Obtain a reference to the Parent Node of the Elements, we are going to Mutate this Node in place.
    local targetNode = XmlUtils.traversePath(targetData, contentPath)

    -- If the node is Singular, it will be of type:table with string properties, if it is not singular it will be of type:array. Therefore, if it's singular, 
    -- .. we need to "Listify" it first.
    if XmlUtils.isNodeSingular(targetNode) then
        XmlUtils.listifySingularNode(targetNode)
    end
    for i = 1, #sourceContent do
        -- Apply X,Y Translation to source Node.
        translateNode(sourceContent[i], xOffset, yOffset)
        -- Insert sourceContent nodes into our node reference.
        table.insert(targetNode, sourceContent[i])
    end
end

function Merge.preValidateFixtureMerge(fixtures, targetFixturesLookup)
    -- MA does not allow multiple instances of a single Fixture to appear on the same Layout. We must also follow this Rule.
    -- Therefore we need to Prune out the fixtures that would double up.
    -- Build a Lookup of existing instances of Subfixture in the index node. This will avoid Big O problems.

    local duplicateFixtures = getPendingDuplicateFixtures(fixtures, targetFixturesLookup)

    return duplicateFixtures
end

function Merge.executeNonFixtures(sourceContent, targetData, xmlPaths, xOffset, yOffset)
    -- Texts
    mergeContent(sourceContent.texts, targetData, xmlPaths.texts, xOffset, yOffset)

    -- Rectangles
    mergeContent(sourceContent.rectangles, targetData, xmlPaths.rectangles, xOffset, yOffset)

    -- CObjects
    mergeContent(sourceContent.cObjects, targetData, xmlPaths.cObjects, xOffset, yOffset)

    return targetData
end

function Merge.executeFixtures(fixtures, targetData, xmlPaths, xOffset, yOffset, fixtureLookup)
    local prunedFixtures = {}
    local pruneIndex = 1
    for i = 1, #fixtures do
        if alreadyInFixturesIndex(fixtures[i]["Subfixture"]._attr, fixtureLookup) == false then
            prunedFixtures[pruneIndex] = fixtures[i]
            pruneIndex = pruneIndex + 1
        end
    end

    -- Fixtures
    mergeContent(prunedFixtures, targetData, xmlPaths.fixtures, xOffset, yOffset)

    -- Update the Subfixtures index.
    updateFixturesIndex(prunedFixtures, targetData, XmlUtils.getFixturesIndexNode(targetData, xmlPaths.fixturesIndex),
        fixtureLookup, xmlPaths.fixturesIndex)

    return targetData

end

return Merge
