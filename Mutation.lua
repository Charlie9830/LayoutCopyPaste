local inspect = require("inspect")
local Mutation = {}

local function findRectangleTable(data)
    -- Traverse down to the Rectangles Node.

    local recTable = data.MA.Group.LayoutData.Rectangles


    -- Notice here that we are then calling LayoutELement on recTable. Thats because the parser is grouping the Tag types into their own Arrays.
    for k, v in pairs(recTable.LayoutElement) do
        print(v._attr.text)
    end
end

function Mutation.findSelectionRec(data)
    findRectangleTable(data)
end

return Mutation
