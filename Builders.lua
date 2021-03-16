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
        cObjects = cObjects
    }

end

function Builders.XmlPaths(fixturesPath, rectanglesPath, textsPath, cObjectsPath)
    return {
        fixtures = fixturesPath,
        rectangles = rectanglesPath,
        texts = textsPath,
        cObjects = cObjectsPath
    }
end

return Builders
