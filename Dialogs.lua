local Dialogs = {}

function Dialogs.throwFixtureCollisionConfirm()
    return gma.gui.confirm("Fixture Collision", [[
            You have selected fixtures that already exist in the destination Layout.
            MA does not allow multiple occurances of the same fixture to exist within a Layout.
            If you contiue, the copy process will ignore the offending fixtures.
        ]])
end

function Dialogs.invalidNumericEntry()
    gma.gui.msgbox("Invalid Input", "Invalid number entered. Exiting plugin.")
end

function Dialogs.askForSourceLayoutNumber(previousValue)
    if DEV == true then
        return "11"
    end

    if previousValue == nil then
        previousValue = ""
    end

    return gma.textinput("Enter SOURCE Layout number..", previousValue)
end

function Dialogs.askForTargetLayoutNumber(previousValue)
    if DEV == true then
        return "12"
    end

    if previousValue == nil then
        previousValue = ""
    end

    return gma.textinput("Enter DESTINATION Layout number..", previousValue)
end

function Dialogs.layoutDoesNotExist(layoutNumber)
    return gma.gui.msgbox("Layout not found", "Sorry, Layout " .. layoutNumber .. " doesn't exist. Exiting Plugin.")
end

function Dialogs.noCopyRectangle(copyRectangleText)
    gma.gui.msgbox("No Copy Rectangle",
        "Could not find a rectangle with text set to \"" .. copyRectangleText .. "\" on source layout.")
end

function Dialogs.noPasteRectangle(pasteRectangleText)
    gma.gui.msgbox("No Paste Rectangle", "Could not find a rectangle with text set to \"" .. pasteRectangleText ..
        "\" on destination layout.")
end

function Dialogs.nothingToCopy()
    gma.gui.msgbox("Nothing to Copy. Exiting plugin.")
end

function Dialogs.PreExecutionPermission(sourceLayoutName, targetLayoutName, itemCount)
    if gma.gui.confirm("Just Checkin'",
        "About to copy " .. itemCount .. " items from  " .. sourceLayoutName .. " to " .. targetLayoutName ..
            ".. Press Ok to continue") then
        return true
    else
        return false
    end
end

function Dialogs.fatalError(message)
    gma.gui.msgbox('Error', message)
end

return Dialogs
