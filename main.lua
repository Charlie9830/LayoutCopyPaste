local Utils = require("Utils")
local LayoutIO = require("LayoutIO")
local Mutation = require("Mutation")
local inspect = require("inspect")

local data = LayoutIO.read("C:\\ProgramData\\MA Lighting Technologies\\grandma\\gma2_V_3.9.60\\temp\\helloworld.xml")

-- print(data.MA.Info._attr.datetime)
local selectionRec = Mutation.findSelectionRec(data)

