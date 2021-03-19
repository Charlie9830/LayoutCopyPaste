local Utils = require "Utils"
local xml2lua = require("xml2lua")

local LayoutIO = {}

local xmlDecl = "<?xml version=\"1.0\" encoding=\"utf-8\"?> \n"

local function fileExists(path)
    local file = io.open(path)

    if file == nil then
        return false
    else
        return true
    end
end

function LayoutIO.read(path, parser, handler, progressHandle)
    if fileExists(path) == false then
        gma.feedback("Doesn't Exist")
        gma.gui.progress.stop(progressHandle)
        return nil
    end
    local file = io.open(path, "r")
    io.input(file)

    local xml = ""
    local lineCount = 0
    for line in io.lines() do
        xml = xml .. "\n" .. Utils.trimBOM(line)
        lineCount = lineCount + 1
    end
    io.close(file)

    gma.gui.progress.setrange(progressHandle, 0, lineCount)

    local parseCount = 0
    local progressCallback = function()
        if (math.fmod(parseCount, 10) == 0) then
            gma.gui.progress.set(progressHandle, parseCount)
        end

        parseCount = parseCount + 1
    end

    parser:parse(Utils.trim(xml), nil, progressCallback)

    gma.gui.progress.stop(progressHandle)

    return handler.root
end

function LayoutIO.write(path, data)
    gma.feedback(path)
    local file = io.open(path, "w+")
    io.output(file)

    io.write(xmlDecl)
    io.write(xml2lua.toXml(data))

    io.close()
end

return LayoutIO
