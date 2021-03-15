local Utils = require("Utils")
local LayoutIO = require("LayoutIO")
local Mutation = require("Mutation")

local data = LayoutIO.read("helloworld.xml")

print(data.MA.Info._attr.datetime)

Mutation.findSelectionRec(data)
