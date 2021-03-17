local Dialogs = {}

function Dialogs.throwFixtureCollisionConfirm()
    return gma.gui.confirm("Fixture Collision", [[
            You have selected fixtures that already exist in the destination Layout.
            MA does not allow multiple occurances of the same fixture to exist within a Layout.
            If you contiue, the copy process will ignore the offending fixtures.
        ]])
end

return Dialogs
