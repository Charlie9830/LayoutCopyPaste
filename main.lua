local Utils = require("Utils")
local LayoutIO = require("LayoutIO")
local Mutation = require("Mutation")
local inspect = require("inspect")

-- CONFIG
-- XML Paths
local fixturesPath = {"MA", "Group", "LayoutData", "SubFixtures", "LayoutSubFix"}
local rectanglesPath = {"MA", "Group", "LayoutData", "Rectangles", "LayoutElement"}
local textsPath = {"MA", "Group", "LayoutData", "Texts", "LayoutElement"}
local cObjectsPath = {"MA", "Group", "LayoutData", "CObjects", "LayoutCObject"}
--

-- MA2 Test File Path
-- C:\\ProgramData\\MA Lighting Technologies\\grandma\\gma2_V_3.9.60\\temp\\helloworld.xml

local data = LayoutIO.read("helloworld.xml")

-- print(data.MA.Info._attr.datetime)
local selectionRec = Mutation.findSelectionRec(data, rectanglesPath)

local fixtures = Mutation.getElements(data, fixturesPath, selectionRec)
local rectangles = Mutation.getElements(data, rectanglesPath, selectionRec)
local texts = Mutation.getElements(data, textsPath, selectionRec)
local cObjects = Mutation.getElements(data, cObjectsPath, selectionRec)

print(inspect(fixtures))
