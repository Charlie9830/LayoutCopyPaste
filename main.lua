-- ===================== --
-- Layout Copy and Paste
-- ===================== --
-- Version 1.0
-- Created by Charlie Hall and Ellie Garnett
-- https://www.github.com/charlie9830
-- Last Updated March 2021

-- Source Code available at:
-- https://github.com/Charlie9830/LayoutCopyPaste

-- DESCRIPTION --
-- =========== --
-- This plugin allows users to Copy and Paste regions from one layout to another, this includes all Text, Rectangle, Pool
-- and Fixture elements. Bitmap copy is not currently implemented.

-- INSTRUCTIONS --
-- ============ --
-- [1] Draw a rectangle on your layout around the objects you wish to Copy, set the text property on this rectangle to 'copy'
-- [2] In the layout you wish to copy the elements into, draw a rectangle and set the text property to 'paste', This size of this 
-- rectangle does not matter, the plugin will only use its position to place this incoming elements.
-- [3] Run the plugin by typing "Plugin X" into your command line, where x is the number of the plugin, or by touching the plugin
-- pool element in the Plugins window.
-- [4] Enter the number of your source layout (The layout with the 'copy' rectangle)
-- [5] Enter the number of your target layout (That layout with the 'paste' rectangle)
-- Your elements will be copied from the 'copy' rectangle to the 'paste' rectangle.
-- The plugin is very robust, validating all inputs before performing any possibly 'destructive' actions, however if you find that
-- your layout has been borked, you can 'oops' out of it. 'oops' back to the command "Import Layout at x /path="lcp_outputlayout.xml"...."

-- LICENSES --
-- ======== --
-- Layout Copy and Paste
-- MIT License

-- Copyright (c) 2021 Charlie Hall & Ellie Garnett

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

-- xml2lua
--  This code is freely distributable under the terms of the MIT license
--
-- @author Paul Chakravarti (paulc@passtheaardvark.com)
-- @author Manoel Campos da Silva Filho

-- luabundler
-- Copyright (c) 2020 Benjamin Dobell
-- This code is freely distributable under the terms of the MIT license

local Utils = require("Utils")
local LayoutIO = require("LayoutIO")
local Query = require("Query")
local Builders = require("Builders")
local Merge = require("Merge")
local handler = require("xmlhandler.tree")
local xml2lua = require("xml2lua")
local Mocks = require("Mocks")
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
local outputLayoutFilePath = maRootPath .. separator .. 'importexport' .. separator ..
                                 outputLayoutFileName -- MA recoils at the idea of importing a layout from any other folder except it's default importexport folder.
    
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
    gma.feedback("Starting Layout Copy and Paste Plugin")
    gma.echo("Starting Layout Copy and Paste Plugin")
    local isValid, sourceLayoutNumber = Utils.validateIntegerInput(
                                            Dialogs.askForSourceLayoutNumber(
                                                gma.show.getvar(previousSourceLayoutVarName)))
    if isValid == false then
        Dialogs.invalidNumericEntry()
        gma.echo("Invalid numeric entry, exiting plugin")
        return
    end

    if gma.show.getobj.handle("Layout " .. sourceLayoutNumber) == nil then
        Dialogs.layoutDoesNotExist(sourceLayoutNumber)
        gma.echo("Layout does not exist, exiting plugin ")
        return
    end

    local isValid, targetLayoutNumber = Utils.validateIntegerInput(
                                            Dialogs.askForTargetLayoutNumber(
                                                gma.show.getvar(previousTargetLayoutVarName)))
    if isValid == false then
        Dialogs.invalidNumericEntry()
        gma.echo("Invalid numeric entry, exiting plugin")
        return
    end

    if gma.show.getobj.handle("Layout " .. targetLayoutNumber) == nil then
        Dialogs.layoutDoesNotExist(targetLayoutNumber)
        gma.echo("Layout does not exist, exiting plugin ")
        return
    end

    gma.echo("Commanding MA to export source layout to " .. maTempPath)
    Commands.sendExportCommand(sourceLayoutNumber, sourceLayoutFileName, maTempPath)

    gma.echo("Commanding MA to export target layout to " .. maTempPath)
    Commands.sendExportCommand(targetLayoutNumber, targetLayoutFileName, maTempPath)

    local xmlPaths = Builders.XmlPaths(fixturesPath, fixturesIndexPath, rectanglesPath, textsPath, cObjectsPath)

    -- Init Source Layout XML Parser and Handler (1 Parser and Handler Combo per XML File)
    gma.echo("Instantiating source layout XML handler")
    local sourceHandler = handler:new()
    local sourceParser = xml2lua.parser(sourceHandler)

    -- Read in Source Layout XML
    gma.echo("Reading source layout from disk")
    sourceLayoutReadProgressHandle = gma.gui.progress.start("Processing Source Layout")

    local sourceLayout
    local pcallResult, err = pcall(function()
        sourceLayout = LayoutIO.read(sourceLayoutFilePath, sourceParser, sourceHandler, sourceLayoutReadProgressHandle)
    end)
    if pcallResult then
        -- No Errors
    else
        -- An Error Occured.
        gma.gui.progress.stop(sourceLayoutReadProgressHandle)
        gma.echo(err)
        gma.echo("Exception thrown while reading source layout, exiting plugin.")

        -- Set sourceLayout to nil so error handling below will catch and inform user.
        sourceLayout = nil
    end

    if sourceLayout == nil then
        gma.gui.progress.stop(sourceLayoutReadProgressHandle)
        Dialogs.fatalError(
            "An error occured whilst reading the source layout xml. Exiting plugin, No show data has been changed." ..
                " There may be more information about this error in the System Monitor window.")
        return
    end

    gma.echo("Source layout read and parsing complete")

    -- Find the Copy Selection Rectangle
    gma.echo("Querying for copy rectangle")
    local copySourceRec = Query.findRec(sourceLayout, rectanglesPath, copyRectangleText)

    if copySourceRec == nil then
        Dialogs.noCopyRectangle(copyRectangleText)
        gma.echo("No copy rectangle found, exiting plugin")
        return
    end

    gma.echo("Copy rectangle located")

    -- Query for elements inside the Copy Selection Rectangle. Build into sourceContent Container.
    gma.echo("Hit testing source elements")
    local sourceContent =
        Builders.SourceContent(Query.getElements(sourceLayout, xmlPaths.fixtures, copySourceRec, ""), -- Fixtures
        Query.getElements(sourceLayout, xmlPaths.rectangles, copySourceRec, copyRectangleText), -- Rectangles
        Query.getElements(sourceLayout, xmlPaths.texts, copySourceRec, ""), -- Texts
        Query.getElements(sourceLayout, xmlPaths.cObjects, copySourceRec, "") -- cObjects (Pool Objects)
        )

    if sourceContent.isEmpty == true then
        Dialogs.nothingToCopy()
        gma.echo("Hit testing copy rectangle returned 0 results, exiting plugin")
        return
    end

    gma.echo("Instantiating target layout XML handler")
    -- Init Target Layout XML Parser and Handler (1 Parser and Handler Combo per XML File)
    local targetHandler = handler:new()
    local targetParser = xml2lua.parser(targetHandler)

    -- Read in Source Layout XMl
    gma.echo("Reading Target layout from disk")
    targetLayoutReadProgressHandle = gma.gui.progress.start("Processing Target Layout")

    local targetLayout
    local pcallresult, err = pcall(function()
        targetLayout = LayoutIO.read(targetLayoutFilePath, targetParser, targetHandler, targetLayoutReadProgressHandle)
    end)
    if pcallresult then
        -- No Errors
    else
        -- An Error has occured
        gma.gui.progress.stop(targetLayoutReadProgressHandle)
        gma.echo(err)
        gma.echo("An exception was thrown whilst reading the target layout")
        targetLayout = nil
    end

    if targetLayout == nil then
        gma.gui.progress.stop(targetLayoutReadProgressHandle)
        Dialogs.fatalError("An error occured whilst reading the target layout xml. Exiting plugin. " ..
                               " There may be more information about this error in the System Monitor window. ")
        return
    end

    -- Find the Target Pasteing Rectangle
    gma.feedback("Querying for Paste rectangle")
    local pasteTargetRec = Query.findRec(targetLayout, xmlPaths.rectangles, pasteRectangleText)

    if pasteTargetRec == nil then
        Dialogs.noPasteRectangle(pasteRectangleText)
        gma.echo("Could not locate Paste rectangle, exiting plugin")
        return
    end

    gma.echo("Paste rectangle located")

    gma.echo("Peeking at target layout's Fixture index")
    -- Validate that we arent going to cause Fixture Collisions in the Target Layout.
    local targetLayoutFixtureIds = Query.peekFixtureIndex(targetLayout, xmlPaths.fixturesIndex)

    local collisionCount, collidingFixtureIds = Query.getCollidingFixtures(sourceContent.fixtures,
                                                    targetLayoutFixtureIds)

    if collisionCount > 0 and Dialogs.throwFixtureCollisionConfirm() == false then
        gma.echo("User has canceled process, exiting plugin")
        return
    end

    gma.echo("Pruning colliding fixtures (if any)")
    -- Prune Colliding Fixtures (if any)
    sourceContent.fixtures = Utils.pruneFixtures(collisionCount, sourceContent.fixtures, collidingFixtureIds)

    gma.echo("Fixture prune complete")

    gma.echo("Preparing final execution confirmation dialog")
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
        gma.echo("User has not granted pre execution permission, exiting plugin")
        return
    end

    -- Merge the XML files into an Output file.
    gma.echo("Executing layout merge")

    -- Merge Non Fixture Items.
    gma.echo("Merging non fixture items")
    local xOffset, yOffset = Merge.calculatePosOffset(copySourceRec, pasteTargetRec)
    local output = Merge.executeNonFixtures(sourceContent, targetLayout, xmlPaths, xOffset, yOffset)

    -- Merge Fixtures
    gma.echo("Merging fixtures")
    output = Merge.executeFixtures(sourceContent.fixtures, output, xmlPaths, xOffset, yOffset)

    -- Write to Output storage
    gma.echo("Writing merged layout to disk")

    if DEV == true then
        LayoutIO.write(outputLayoutFileName, output)
    else
        local pcallResult, err = pcall(LayoutIO.write, outputLayoutFilePath, output)
        if pcallResult then
            -- No Errors Caught
        else
            -- Error whilst writing to output File. Bail out to save us from attempting to import a corrupted or incomplete Layout.
            gma.echo(err)
            gma.echo("An exception has been thrown whilst writing the output layout to disk")
            Dialogs.fatalError(
                "An error occured whilst writing the output.xml. Your Layouts were unaffected. Exiting plugin." ..
                    " There may be more information about this error in the System Monitor window.")
            return
        end
    end

    -- Command MA to import the file we just output.
    gma.feedback("Politely asking MA to import our marged layout")
    Commands.sendImportCommand(targetLayoutNumber, outputLayoutFileName)

    gma.echo("Saving variables for next run.")
    gma.show.setvar(previousSourceLayoutVarName, tostring(sourceLayoutNumber))
    gma.show.setvar(previousTargetLayoutVarName, tostring(targetLayoutNumber))

    gma.echo("Layout Copy and Paste completed sucessfully")
    gma.feedback("Layout Copy and Paste completed sucessfully")

    return
end

if DEV == true then
    Main()
else
    return Main
end
