-- Grab environment.
local tonumber = tonumber
local beautiful = beautiful
local awful = awful
local math = math

module("vain.layout.centerwork")

name = "centerwork"

top_left = 0
top_right = 1
bottom_left = 2
bottom_right = 3

function arrange(p)

    -- A useless gap (like the dwm patch) can be defined with
    -- beautiful.useless_gap_width .
    local useless_gap = tonumber(beautiful.useless_gap_width)
    if useless_gap == nil
    then
        useless_gap = 0
    end

    -- Screen.
    local wa = p.workarea
    local cls = p.clients

    -- Width of main column?
    local t = awful.tag.selected(p.screen)
    local mwfact = awful.tag.getmwfact(t)

    if #cls > 0
    then
        -- Main column, fixed width and height.
        local c = cls[#cls]
        local g = {}
        local mainwid = math.floor(wa.width * mwfact)
        local slavewid = wa.width - mainwid
        local slaveLwid = math.floor(slavewid / 2)
        local slaveRwid = slavewid - slaveLwid
        local slaveThei = math.floor(wa.height / 2)
        local slaveBhei = wa.height - slaveThei

        g.height = wa.height - 2 * useless_gap
        g.width = mainwid
        g.x = wa.x + slaveLwid
        g.y = wa.y + useless_gap

        c:geometry(g)

        -- Auxiliary windows.
        if #cls > 1
        then
            local at = 0
            for i = (#cls - 1),1,-1
            do
                -- It's all fixed. If there are more than 5 clients,
                -- those additional clients will float. This is
                -- intentional.
                if at == 4
                then
                    break
                end

                c = cls[i]
                g = {}

                if at == top_left
                then
                    -- top left
                    g.x = wa.x + useless_gap
                    g.y = wa.y + useless_gap
                    g.width = slaveLwid - 2 * useless_gap
                    g.height = slaveThei - useless_gap
                elseif at == top_right
                then
                    -- top right
                    g.x = wa.x + slaveLwid + mainwid + useless_gap
                    g.y = wa.y + useless_gap
                    g.width = slaveRwid - 2 * useless_gap
                    g.height = slaveThei - useless_gap
                elseif at == bottom_left
                then
                    -- bottom left
                    g.x = wa.x + useless_gap
                    g.y = wa.y + slaveThei + useless_gap
                    g.width = slaveLwid - 2 * useless_gap
                    g.height = slaveBhei - 2 * useless_gap
                elseif at == bottom_right
                then
                    -- bottom right
                    g.x = wa.x + slaveLwid + mainwid + useless_gap
                    g.y = wa.y + slaveThei + useless_gap
                    g.width = slaveRwid - 2 * useless_gap
                    g.height = slaveBhei - 2 * useless_gap
                end

                c:geometry(g)

                at = at + 1
            end

            -- Set remaining clients to floating.
            for i = (#cls - 1 - 4),1,-1
            do
                c = cls[i]
                awful.client.floating.set(c, true)
            end
        end
    end
end

-- vim: set et :
