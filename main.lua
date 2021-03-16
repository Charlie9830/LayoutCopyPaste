local Utils = require("Utils")
local LayoutIO = require("LayoutIO")
local Query = require("Query")
local Builders = require("Builders")
local Merge = require("Merge")
local handler = require("xmlhandler.tree")
local xml2lua = require("xml2lua")
local Mocks = require("Mocks")
local inspect = require("inspect")

Mocks.initGmaMock()

-- Set DEV Mode
DEV = false
if gma.show.getvar("HOSTTYPE") == "Development" then
    DEV = true
end

-- USER CONFIG
local copyRectangleText = "copy"
local pasteRectangleText = "paste"
-- END USER CONFIG

-- CONFIG
-- XML Paths
local fixturesPath = {"MA", "Group", "LayoutData", "SubFixtures", "LayoutSubFix"}
local rectanglesPath = {"MA", "Group", "LayoutData", "Rectangles", "LayoutElement"}
local textsPath = {"MA", "Group", "LayoutData", "Texts", "LayoutElement"}
local cObjectsPath = {"MA", "Group", "LayoutData", "CObjects", "LayoutCObject"}

-- CONFIG --
local separator = '\92'
local maTempPath = gma.show.getvar('TEMPPATH')
local maRootPath = gma.show.getvar('PATH')
local sourceLayoutFileName = "lcp_sourcelayout.xml"
local targetLayoutFileName = "lcp_targetlayout.xml"
local outputLayoutFileName = "lcp_outputlayout.xml"

local sourceLayoutFilePath = maTempPath .. separator .. sourceLayoutFileName
if DEV == true then
    sourceLayoutFilePath = sourceLayoutFileName
end
local targetLayoutFilePath = maTempPath .. separator .. targetLayoutFileName
if DEV == true then
    targetLayoutFilePath = targetLayoutFilePath
end
local outputLayoutFilePath = maRootPath .. separator .. 'importexport' -- MA recoils at the idea of importing a layout from any other folder except it's default importexport folder.
if DEV == true then
    outputLayoutFilePath = outputLayoutFileName
end

local quote = "\""
-- END CONFIG --

local function sendExportCommand(layoutNumber, fileName, dirPath)
    gma.cmd("Export Layout " .. layoutNumber .. " " .. quote .. fileName .. quote .. " /p = " .. quote .. dirPath ..
                quote)
end

local function sendImportCommand(layoutNumber, fileName)
    -- gma.cmd("Import \"lcp_sourcelayout.xml\" At Layout 12")
    gma.cmd("Import " .. quote .. fileName .. quote .. " At Layout " .. layoutNumber)
end

local function throwError(message)
    gma.feedback(message)
end

local function Main()
    gma.feedback("Running Layout Copy Paste")
    gma.feedback("Exporting Source Layout")
    sendExportCommand(11, sourceLayoutFileName, maTempPath)
    gma.feedback("Exporting Target Layout")
    sendExportCommand(12, targetLayoutFileName, maTempPath)

    gma.feedback("Starting XML Processing")
    local xmlPaths = Builders.XmlPaths(fixturesPath, rectanglesPath, textsPath, cObjectsPath)

    -- Init Source Layout XML Parser and Handler (1 Parser and Handler Combo per XML File)
    local sourceHandler = handler:new()
    local sourceParser = xml2lua.parser(sourceHandler)

    -- Read in Source Layout XML
    gma.feedback("Reading Source Layout")
    local sourceLayout = LayoutIO.read(sourceLayoutFilePath, sourceParser, sourceHandler)

    -- Find the Copy Selection Rectangle
    local copySourceRec = Query.findRec(sourceLayout, rectanglesPath, copyRectangleText)

    if copySourceRec == nil then
        throwError("Could not find Copy Rectangle on Source Layout.")
        return
    end

    -- Query for elements inside the Copy Selection Rectangle. Build into sourceContent Container.
    local sourceContent =
        Builders.SourceContent(Query.getElements(sourceLayout, xmlPaths.fixtures, copySourceRec), -- Fixtures
        Query.getElements(sourceLayout, xmlPaths.rectangles, copySourceRec), -- Rectangles
        Query.getElements(sourceLayout, xmlPaths.texts, copySourceRec), -- Texts
        Query.getElements(sourceLayout, xmlPaths.cObjects, copySourceRec) -- cObjects (Pool Objects)
        )

    -- Init Target Layout XML Parser and Handler (1 Parser and Handler Combo per XML File)
    local targetHandler = handler:new()
    local targetParser = xml2lua.parser(targetHandler)

    -- Read in Source Layout XMl
    gma.feedback("Reading Target Layout")
    local targetLayout = LayoutIO.read(targetLayoutFilePath, targetParser, targetHandler)

    -- Silenced until implemented properly.
    local pasteTargetRec = Query.findRec(targetLayout, xmlPaths.rectangles, pasteRectangleText)

    if pasteTargetRec == nil then
        throwError("Could not find Paste Target Rec on Target Layout")
        return
    end

    -- Merge the XML files into an Output file.
    gma.feedback("Executing XML Layout Merge")
    local output = Merge.execute(sourceContent, targetLayout, copySourceRec, pasteTargetRec, xmlPaths)

    -- Write to Output storage
    gma.feedback("Writing Merged Layout to output File")

    if DEV == true then
        LayoutIO.write(outputLayoutFilePath, output)
    else
        LayoutIO.write(outputLayoutFilePath .. separator .. outputLayoutFileName, output)
    end

    -- Command MA to import the file we just output.
    gma.feedback("Asking MA to Import Output File")
    sendImportCommand(12, outputLayoutFileName)

    gma.feedback("Complete")
end

if DEV == true then
    Main()
else
    return Main
end