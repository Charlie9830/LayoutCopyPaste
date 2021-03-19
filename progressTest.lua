local progressHandle;

local function Start()
    progressHandle = gma.gui.progress.start("Parsing XML Document This an take a while...")
    gma.gui.progress.setrange(progressHandle, 1, 10)

    gma.sleep(1)
    gma.gui.progress.set(progressHandle, 4)
    gma.sleep(1)
    gma.gui.progress.set(progressHandle, 8)


    local crash = "crash"..nil
    print("Shouldn't See this")
end

local function Cleanup()
    gma.feedback("Cleanup Function Activated")
    gma.gui.progress.stop(progressHandle)
end


return Start, Cleanup