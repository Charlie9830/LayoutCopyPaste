function Start()
    local tempPath = gma.show.getvar("PATH") .. "/importexport/" -- Path to Folder
    gma.cmd("Export Layout 11 \"helloworld\" /path=\"" .. tempPath .. "\"") -- Use the Command Line to Export Layout 11

    local file = io.open(tempPath .. "/helloworld.xml") -- Read the File in as a Table

    if file == nil then
        gma.feedback("File is Nil")
    end

    gma.feedback(file)

end

return Start
