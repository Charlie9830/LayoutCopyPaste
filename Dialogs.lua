local Dialogs = {}

function Dialogs.throwFixtureCollisionConfirm()
    return gma.gui.confirm("Fixture Collision", [[
            You have selected fixtures that already exist in the destination Layout. MA2 does not allow multiple instances of the same fixture
            within the same layout. If you continue, those clashing fixtures will be excluded from the copying process.
            Are you sure you want to continue?
        ]])
end

return Dialogs
