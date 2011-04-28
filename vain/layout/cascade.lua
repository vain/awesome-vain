-- Grab environment.
local awful = awful

module("vain.layout.cascade")

cascade_offset_x = 32
cascade_offset_y = 8

name = "cascade"
function arrange(p)

    -- Cascade windows, just like the cascade layout for gimp.

    -- Screen.
    local wa = p.workarea
    local cls = p.clients

    local current_cascade_offset_x = cascade_offset_x * (#cls - 1)
    local current_cascade_offset_y = cascade_offset_y * (#cls - 1)

    -- Iterate.
    for i = 1,#cls,1
    do
        local c = cls[i]
        local g = {}

        g.x = wa.x + (#cls - i) * cascade_offset_x
        g.y = wa.y + (i - 1) * cascade_offset_y
        g.width = wa.width - current_cascade_offset_x
        g.height = wa.height - current_cascade_offset_y

        c:geometry(g)
    end
end

-- vim: set et :
