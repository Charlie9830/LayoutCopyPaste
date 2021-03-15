local Builders = {}

function Builders.Rec(recXmlNode)
    
    return {
        centerX = recXmlNode._attr.center_x,
        centerY = recXmlNode._attr.center_y,
        sizeW = recXmlNode._attr.size_w,
        sizeH = recXmlNode._attr.size_h
    }
end

return Builders
