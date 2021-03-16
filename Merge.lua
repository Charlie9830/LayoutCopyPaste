local XmlUtils = require("XmlUtils")
local inspect = require("inspect")

local Merge = {}

-- Converts in place an existing singular node into a List, the existing data of the node becomes the element at index[1]
local function listifySingularNode(node)
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

local function mergeContent(sourceContent, targetData, pasteTargetRec, contentPath)
    -- Validate the provided Xml Path. Coerce it into existence if required.
    if XmlUtils.isValidXmlPath(targetData, contentPath) == false then
        XmlUtils.coercePath(targetData, contentPath)
    end

    -- Obtain a reference to the Parent Node of the Elements, we are going to Mutate this Node in place.
    local targetNodeRef = XmlUtils.traversePath(targetData, contentPath)

    -- If the node is Singular, it will be of type:table with string properties, if it is not singular it will be of type:array. Therefore, if it's singular, 
    -- .. we need to "Listify" it first.
    if XmlUtils.isNodeSingular(targetNodeRef) then
        listifySingularNode(targetNodeRef)
    end
    for i = 1, #sourceContent do
        -- Insert sourceContent nodes into our node reference.
        table.insert(targetNodeRef, sourceContent[i])
    end

end

function Merge.execute(sourceContent, targetData, pasteTargetRec, xmlPaths)
    local output = targetData;

    -- Texts
    mergeContent(sourceContent.texts, targetData, pasteTargetRec, xmlPaths.texts)
    
    -- Rectangles
    mergeContent(sourceContent.rectangles, targetData, pasteTargetRec, xmlPaths.rectangles)

    -- CObjects
    mergeContent(sourceContent.cObjects, targetData, pasteTargetRec, xmlPaths.cObjects)

    return output
end

return Merge
