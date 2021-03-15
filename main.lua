local Utils = require("Utils")
local LayoutIO = require("LayoutIO")
local Mutation = require("Mutation")
local inspect = require("inspect")

local data = LayoutIO.read("helloworld.xml")

--print(data.MA.Info._attr.datetime)
local selectionRec = Mutation.findSelectionRec(data)

print(inspect(selectionRec))
