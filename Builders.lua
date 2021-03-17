local Builders = {}

function Builders.Rec(recXmlNode)
    -- XML Values
    local rec = {
        centerX = tonumber(recXmlNode._attr.center_x),
        centerY = tonumber(recXmlNode._attr.center_y),
        sizeW = tonumber(recXmlNode._attr.size_w),
        sizeH = tonumber(recXmlNode._attr.size_h)
    }

    -- Computed Values
    rec.left = rec.centerX - (rec.sizeW / 2)
    rec.right = rec.centerX + (rec.sizeW / 2)
    rec.top = rec.centerY - (rec.sizeH / 2)
    rec.bottom = rec.centerY + (rec.sizeH / 2)

    return rec
end

function Builders.SourceContent(fixtures, rectangles, texts, cObjects)
    return {
        fixtures = fixtures,
        rectangles = rectangles,
        texts = texts,
        cObjects = cObjects,
        isEmpty = #fixtures == 0 and #rectangles == 0 and #texts == 0 and #cObjects == 0
    }

end

function Builders.XmlPaths(fixturesPath, fixturesIndexPath, rectanglesPath, textsPath, cObjectsPath)
    return {
        fixtures = fixturesPath,
        fixturesIndex = fixturesIndexPath,
        rectangles = rectanglesPath,
        texts = textsPath,
        cObjects = cObjectsPath
    }
end

function Builders.SubFixKey(fix_id, sub_index, cha_id)
    local key = ""
    if fix_id ~= nil then
        key = key .. fix_id .. "."
    else
        key = key .. '0.'
    end

    if sub_index ~= nil then
        key = key .. sub_index .. "."
    else
        key = key .. '0.'
    end

    if cha_id ~= nil then
        key = key .. cha_id
    else
        key = key .. '0'
    end

    return key

end

return Builders
