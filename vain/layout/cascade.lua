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

    -- Opening a new window will usually force all existing windows to
    -- get resized. This wastes a lot of CPU time. So let's set a lower
    -- bound to "how_many": This wastes a little screen space but you'll
    -- get a much better user experience.
    local t = awful.tag.selected(p.screen)
    local num_c = awful.tag.getnmaster(t)
    local how_many = #cls
    if how_many < num_c
    then
        how_many = num_c
    end

    local current_cascade_offset_x = cascade_offset_x * (how_many - 1)
    local current_cascade_offset_y = cascade_offset_y * (how_many - 1)

    -- Iterate.
    for i = 1,#cls,1
    do
        local c = cls[i]
        local g = {}

        g.x = wa.x + (how_many - i) * cascade_offset_x
        g.y = wa.y + (i - 1) * cascade_offset_y
        g.width = wa.width - current_cascade_offset_x
        g.height = wa.height - current_cascade_offset_y

        c:geometry(g)
    end
end

-- vim: set et :
