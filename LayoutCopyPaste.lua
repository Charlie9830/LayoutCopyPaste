function Start()
    -- local tempPath = gma.show.getvar("TEMPPATH")

    local tempPath = gma.show.getvar("PATH") .. "/temp"
    gma.feedback(tempPath)
    gma.cmd("Export Layout 11 \"helloworld\" /path=\" " .. tempPath)
    local data = gma.import(tempPath .. "helloworld")

    gma.feedback(data)

end

return Start
