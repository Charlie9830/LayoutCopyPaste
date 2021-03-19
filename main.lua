local Utils = require("Utils")
local LayoutIO = require("LayoutIO")
local Query = require("Query")
local Builders = require("Builders")
local Merge = require("Merge")
local handler = require("xmlhandler.tree")
local xml2lua = require("xml2lua")
local Mocks = require("Mocks")
local XmlUtils = require("XmlUtils")
local Dialogs = require("Dialogs")
local Commands = require("Commands")

Mocks.initGmaMock()


-- USER CONFIG
local copyRectangleText = "copy" -- The text that the plugin will use to identify the "Copy Rectangle". It's Case Insensitive.
local pasteRectangleText = "paste" -- The text that the plugin will use to identiy the "Paste Rectangle". It's Case Insensitive.
-- END USER CONFIG

-- NOTE TO USERS --

-- Set DEV Mode
DEV = false
if gma.show.getvar("HOSTTYPE") == "Development" then
    DEV = true
end

-- CONFIG
-- XML Paths
local fixturesPath = {"MA", "Group", "LayoutData", "SubFixtures", "LayoutSubFix"}
local fixturesIndexPath = {"MA", "Group", "Subfixtures", "Subfixture"}
local rectanglesPath = {"MA", "Group", "LayoutData", "Rectangles", "LayoutElement"}
local textsPath = {"MA", "Group", "LayoutData", "Texts", "LayoutElement"}
local cObjectsPath = {"MA", "Group", "LayoutData", "CObjects", "LayoutCObject"}


local separator = '/' 

local maTempPath = gma.show.getvar('TEMPPATH')
local maRootPath = gma.show.getvar('PATH')
local sourceLayoutFileName = "lcp_sourcelayout.xml"
local targetLayoutFileName = "lcp_targetlayout.xml"
local outputLayoutFileName = "lcp_outputlayout.xml"
local previousSourceLayoutVarName = "lcp_previousSourceLayoutNumber"
local previousTargetLayoutVarName = "lcp_previousTargetLayoutNumber"

local sourceLayoutFilePath = maTempPath .. separator .. sourceLayoutFileName
if DEV == true then
    sourceLayoutFilePath = sourceLayoutFileName
end
local targetLayoutFilePath = maTempPath .. separator .. targetLayoutFileName
if DEV == true then
    targetLayoutFilePath = targetLayoutFileName
end
local outputLayoutFilePath = maRootPath .. separator .. 'importexport' -- MA recoils at the idea of importing a layout from any other folder except it's default importexport folder.
if DEV == true then
    outputLayoutFilePath = outputLayoutFileName
end

Quote = "\""

-- END CONFIG --

IsEmpty = function(array)
    return array == nil or #array == 0
end

-- LUA Standard Library Extensions
table.has = function(set, propertyName)
    return set[propertyName] ~= nil
end

string.compareCaseInsensitive = function(a, b)
    if a == nil and b == nil then
        return true
    end

    if a == nil or b == nil then
        return a == b
    end

    return string.lower(a) == string.lower(b)
end

-- END LUA Standard Library Extensions

-- GMA Progress Handles --
local sourceLayoutReadProgressHandle
local targetLayoutReadProgressHandle

local function Main()
    gma.feedback("Running Layout Copy and Paste")

    local isValid, sourceLayoutNumber = Utils.validateIntegerInput(
                                            Dialogs.askForSourceLayoutNumber(
                                                gma.show.getvar(previousSourceLayoutVarName)))
    if isValid == false then
        Dialogs.invalidNumericEntry()
        return
    end

    if gma.show.getobj.handle("Layout " .. sourceLayoutNumber) == nil then
        Dialogs.layoutDoesNotExist(sourceLayoutNumber)
        return
    end

    local isValid, targetLayoutNumber = Utils.validateIntegerInput(
                                            Dialogs.askForTargetLayoutNumber(
                                                gma.show.getvar(previousTargetLayoutVarName)))
    if isValid == false then
        Dialogs.invalidNumericEntry()
        return
    end

    if gma.show.getobj.handle("Layout " .. targetLayoutNumber) == nil then
        Dialogs.layoutDoesNotExist(targetLayoutNumber)
        return
    end

    gma.feedback("Exporting Source Layout")
    Commands.sendExportCommand(sourceLayoutNumber, sourceLayoutFileName, maTempPath)
    gma.feedback("Exporting Target Layout")
    Commands.sendExportCommand(targetLayoutNumber, targetLayoutFileName, maTempPath)

    gma.feedback("Starting XML Processing")
    local xmlPaths = Builders.XmlPaths(fixturesPath, fixturesIndexPath, rectanglesPath, textsPath, cObjectsPath)

    -- Init Source Layout XML Parser and Handler (1 Parser and Handler Combo per XML File)
    local sourceHandler = handler:new()
    local sourceParser = xml2lua.parser(sourceHandler)

    -- Read in Source Layout XML
    gma.feedback("Reading Source Layout")
    sourceLayoutReadProgressHandle = gma.gui.progress.start("Processing Source Layout")

    local sourceLayout
    if pcall(function()
        sourceLayout = LayoutIO.read(sourceLayoutFilePath, sourceParser, sourceHandler, sourceLayoutReadProgressHandle)
    end) then
        -- No Errors
    else
        -- An Error Occured.
        gma.gui.progress.stop(sourceLayoutReadProgressHandle)
        Dialogs.fatalError(
            "An error occured when reading the source layout xml. Exiting plugin, No show data has been changed")
        sourceLayout = nil
    end

    if sourceLayout == nil then
        gma.gui.progress.stop(sourceLayoutReadProgressHandle)
        Dialogs.fatalError(
            "An error occured when reading the source layout xml. Exiting plugin, NO show data has been changed.")
        return
    end

    gma.feedback("Source Layout Read Complete")

    -- Find the Copy Selection Rectangle
    gma.feedback("Finding Copy Rectangle")
    local copySourceRec = Query.findRec(sourceLayout, rectanglesPath, copyRectangleText)

    if copySourceRec == nil then
        Dialogs.noCopyRectangle(copyRectangleText)
        return
    end

    gma.feedback("Copy Rectangle Found")

    -- Query for elements inside the Copy Selection Rectangle. Build into sourceContent Container.
    gma.feedback("Finding Source Elements")
    local sourceContent =
        Builders.SourceContent(Query.getElements(sourceLayout, xmlPaths.fixtures, copySourceRec, ""), -- Fixtures
        Query.getElements(sourceLayout, xmlPaths.rectangles, copySourceRec, copyRectangleText), -- Rectangles
        Query.getElements(sourceLayout, xmlPaths.texts, copySourceRec, ""), -- Texts
        Query.getElements(sourceLayout, xmlPaths.cObjects, copySourceRec, "") -- cObjects (Pool Objects)
        )

    if sourceContent.isEmpty == true then
        Dialogs.nothingToCopy()
        return
    end

    gma.feedback("Source Elements Found")

    -- Init Target Layout XML Parser and Handler (1 Parser and Handler Combo per XML File)
    local targetHandler = handler:new()
    local targetParser = xml2lua.parser(targetHandler)

    -- Read in Source Layout XMl
    gma.feedback("Reading Target Layout")
    targetLayoutReadProgressHandle = gma.gui.progress.start("Processing Target Layout")

    local targetLayout
    if pcall(function()
        targetLayout = LayoutIO.read(targetLayoutFilePath, targetParser, targetHandler, targetLayoutReadProgressHandle)
    end) then
        -- No Errors
    else
        -- An Error has Occured
        gma.gui.progress.stop(targetLayoutReadProgressHandle)
        targetLayout = nil
    end

    if targetLayout == nil then
        gma.gui.progress.stop(targetLayoutReadProgressHandle)
        Dialogs.fatalError("An error occured when reading the target layout xml. Exiting plugin.")
        return
    end

    -- Find the Target Pasteing Rectangle
    gma.feedback("Finding Paste Rectangle")
    local pasteTargetRec = Query.findRec(targetLayout, xmlPaths.rectangles, pasteRectangleText)

    if pasteTargetRec == nil then
        Dialogs.noPasteRectangle(pasteRectangleText)
        return
    end

    gma.feedback("Paste Rectangle Found")

    gma.feedback("Peeking at Target Fixture index")
    -- Validate that we arent going to cause Fixture Collisions in the Target Layout.
    local targetLayoutFixtureIds = Query.peekFixtureIndex(targetLayout, xmlPaths.fixturesIndex)

    local collisionCount, collidingFixtureIds = Query.getCollidingFixtures(sourceContent.fixtures,
                                                    targetLayoutFixtureIds)

    if collisionCount > 0 and Dialogs.throwFixtureCollisionConfirm() == false then
        return
    end

    gma.feedback("Pruning Colliding Fixtures")
    -- Prune Colliding Fixtures (if any)
    sourceContent.fixtures = Utils.pruneFixtures(collisionCount, sourceContent.fixtures, collidingFixtureIds)

    gma.feedback("Fixture Prune Complete")

    local sourceLayoutHandle = gma.show.getobj.handle("Layout " .. sourceLayoutNumber)
    local sourceLayoutName = gma.show.getobj.label(sourceLayoutHandle)
    if sourceLayoutName == nil then
        sourceLayoutName = "Layout " .. sourceLayoutNumber
    end

    local targetLayoutHandle = gma.show.getobj.handle("Layout " .. targetLayoutNumber)
    local targetLayoutName = gma.show.getobj.label(targetLayoutHandle)
    if targetLayoutName == nil then
        targetLayoutName = "Layout " .. targetLayoutNumber
    end

    local copyItemCount = #sourceContent.fixtures + #sourceContent.cObjects + #sourceContent.rectangles +
                              #sourceContent.texts

    if Dialogs.PreExecutionPermission(sourceLayoutName, targetLayoutName, copyItemCount) == false then
        return
    end

    -- Merge the XML files into an Output file.
    gma.feedback("Executing XML Layout Merge")

    -- Merge Non Fixture Items.
    local xOffset, yOffset = Merge.calculatePosOffset(copySourceRec, pasteTargetRec)
    local output = Merge.executeNonFixtures(sourceContent, targetLayout, xmlPaths, xOffset, yOffset)

    -- Merge Fixtures
    output = Merge.executeFixtures(sourceContent.fixtures, output, xmlPaths, xOffset, yOffset)

    -- Write to Output storage
    gma.feedback("Writing Merged Layout to output File")

    if DEV == true then
        LayoutIO.write(outputLayoutFilePath, output)
    else
        if pcall(LayoutIO.write, outputLayoutFilePath .. separator .. outputLayoutFileName, output) then
            -- No Errors Caught
        else
            -- Error whilst writing to output File. Bail out to save us from attempting to import a corrupted or incomplete Layout.
            Dialogs.fatalError(
                "An error occured whilst writing the output.xml. Your Layouts were unaffected. Exiting plugin.")
            return
        end
    end

    -- Command MA to import the file we just output.
    gma.feedback("Asking MA to Import Output File")
    Commands.sendImportCommand(targetLayoutNumber, outputLayoutFileName)

    gma.show.setvar(previousSourceLayoutVarName, tostring(sourceLayoutNumber))
    gma.show.setvar(previousTargetLayoutVarName, tostring(targetLayoutNumber))
    gma.feedback("Complete")

    return
end

if DEV == true then
    Main()
else
    return Main
end

return Main
