local Utils = require "Utils"
local xml2lua = require("xml2lua")
local handler = require("xmlhandler.tree")

local LayoutIO = {}

function LayoutIO.read(path)
    local file = io.open(path, "r")
    io.input(file)

    local xml = ""
    for line in io.lines() do
        xml = xml .. "\n" .. Utils.trimBOM(line)
    end

    io.close(file)

    local parser = xml2lua.parser(handler)
    parser:parse(Utils.trim(xml))

    return handler.root
end

function LayoutIO.write(path, data)
    local file = io.open(path, "w+")
    io.output(file)
    io.write(xml2lua.toXml(data))
    io.close()
end

return LayoutIO
