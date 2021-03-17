local Utils = {}

local Builders = require("Builders")

-- String Trim
function Utils.trim(value)
    return (value:gsub("^%s*(.-)%s*$", "%1"))
end

-- Trims BOM (Byte Order Marks) from XML.
function Utils.trimBOM(xml)
    local trimmed = string.gsub(xml, "\239\187\191", "")

    return trimmed
end

-- Determines if the provided object has any properties. Properties defined as non integer accsessors. Ignores existence of integer accsessors.
function Utils.hasProperties(object)
    if object == nil then
        return false
    end

    local hasSomething = false

    for k, v in pairs(object) do
        hasSomething = true
        break
    end

    return hasSomething
end

function Utils.pruneFixtures(collisionCount, sourceFixtures, collidingFixtureIds)
    if collisionCount == 0 then
        return sourceFixtures
    end

    local returnList = {}
    for i = 1, #sourceFixtures do
        local attr = sourceFixtures[i]["Subfixture"]._attr
        if table.has(collidingFixtureIds, Builders.SubFixKey(attr.fix_id, attr.sub_index, attr.cha_id)) == false then
            table.insert(returnList, sourceFixtures[i])
        end
    end

    return returnList
end

return Utils
