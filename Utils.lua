local Utils = {}

-- String Trim
function Utils.trim(value)
    return (value:gsub("^%s*(.-)%s*$", "%1"))
end

-- Trims BOM (Byte Order Marks) from XML.
function Utils.trimBOM(xml)
    local trimmed = string.gsub(xml, "\239\187\191", "")

    return trimmed
end

return Utils
