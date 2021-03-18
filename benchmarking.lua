local handler = require("xmlhandler.tree")
local xml2lua = require("xml2lua")
local Utils = require("Utils")
local inspect = require("Inspect")

local function writeOutResult(time)
    local benchmarkingOutputFile = io.open("benchmarkoutput.txt", "a+")
    io.output(benchmarkingOutputFile)
    io.write("\n" .. time)
    io.close()
end

local function bench(path)
    -- TODO: Process Hangs when writing to a File that doesnt exist. No Exceptions, just Stalls
    local file = io.open(path, "r")
    io.input(file)

    local xml = ""
    for line in io.lines() do
        xml = xml .. "\n" .. Utils.trimBOM(line)
    end

    io.close(file)

    -- local doopHandler = handler:new()
    --     local doopParser = xml2lua.parser(doopHandler)

    --     print(inspect(doopParser.options))


    local startTime = os.clock()
    for i = 1, 300 do
        local sourceHandler = handler:new()
        local sourceParser = xml2lua.parser(sourceHandler)

        sourceParser:parse(Utils.trim(xml))
    end

    writeOutResult(os.clock() - startTime)
    return
end

bench("lcp_sourcelayout.xml")

