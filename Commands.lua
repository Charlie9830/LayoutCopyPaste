local Commands = {}

function Commands.sendExportCommand(layoutNumber, fileName, dirPath)
    gma.cmd("Export Layout " .. layoutNumber .. " " .. Quote .. fileName .. Quote .. " /o /nc /p = " .. Quote .. dirPath ..
                Quote)
end

function Commands.sendImportCommand(layoutNumber, fileName)
    gma.cmd("Import " .. Quote .. fileName .. Quote .. " At Layout " .. layoutNumber.." /o /nc")
end

function Commands.setDriveToInternal()
    local result = gma.cmd("SelectDrive 1")
    gma.feedback(result)
end
return Commands