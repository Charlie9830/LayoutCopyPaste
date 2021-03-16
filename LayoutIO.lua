local Utils = require "Utils"
local xml2lua = require("xml2lua")
local inspect = require("inspect")

local LayoutIO = {}

local xmlDecl = "<?xml version=\"1.0\" encoding=\"utf-8\"?> \n"

function LayoutIO.read(path, parser, handler)
    -- TODO: Process Hangs when writing to a File that doesnt exist. No Exceptions, just Stalls
    local file = io.open(path, "r")
    io.input(file)

    local xml = ""
    for line in io.lines() do
        xml = xml .. "\n" .. Utils.trimBOM(line)
    end

    io.close(file)

    parser:parse(Utils.trim(xml))

    return handler.root
end

function LayoutIO.write(path, data)
    local file = io.open(path, "w+")
    io.output(file)

    io.write(xmlDecl)
    io.write(xml2lua.toXml(data))

    io.close()
end

return LayoutIO
