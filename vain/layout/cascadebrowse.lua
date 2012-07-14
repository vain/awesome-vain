-- Grab environment.
local ipairs = ipairs
local tonumber = tonumber
local beautiful = beautiful
local awful = awful
local print = print

module("vain.layout.cascadebrowse")

cascade_offset_x = 5
cascade_offset_y = 32
extra_padding = 0

name = "cascadebrowse"
function arrange(p)

    -- Layout with one fixed column meant for the browser window. Its
    -- width is calculated according to mwfact. Other clients are
    -- cascaded or "tabbed" in a slave column on the right.

    -- It's a bit hard to demonstrate the behaviour with ASCII-images...
    --
    --       (1)              (2)              (3)              (4)
    --   +-----+---+      +-----+---+      +-----+---+      +-----+---+
    --   |     |   |      |     |   |      |     |   |      |     | 4 |
    --   |     |   |      |     | 2 |      |     | 3 |      |     |   |
    --   |  1  |   |  ->  |  1  |   |  ->  |  1  |   |  ->  |  1  +---+
    --   |     |   |      |     +---+      |     +---+      |     | 3 |
    --   |     |   |      |     |   |      |     | 2 |      |     |---|
    --   |     |   |      |     |   |      |     |---|      |     | 2 |
    --   |     |   |      |     |   |      |     |   |      |     |---|
    --   +-----+---+      +-----+---+      +-----+---+      +-----+---+

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

    -- Make slave windows overlap main window? Do this if ncol is 1.
    local overlap_main = awful.tag.getncol(t)

    -- Minimum space for slave windows? See cascade.lua.
    local num_c = awful.tag.getnmaster(t)
    local how_many = #cls - 1
    if how_many < num_c
    then
        how_many = num_c
    end
    local current_cascade_offset_x = cascade_offset_x * (how_many - 1)
    local current_cascade_offset_y = cascade_offset_y * (how_many - 1)

    if #cls > 0
    then
        -- Main column, fixed width and height.
        local c = cls[#cls]
        local g = {}
        local mainwid = wa.width * mwfact
        local slavewid = wa.width - mainwid

        if overlap_main == 1
        then
            g.width = wa.width

            -- The size of the main window may be reduced a little bit.
            -- This allows you to see if there are any windows below the
            -- main window.
            -- This only makes sense, though, if the main window is
            -- overlapping everything else.
            g.width = g.width - extra_padding
        else
            g.width = mainwid
        end

        g.height = wa.height
        g.x = wa.x
        g.y = wa.y
        if useless_gap > 0
        then
            -- Reduce width once and move window to the right. Reduce
            -- height twice, however.
            g.width = g.width - useless_gap
            g.height = g.height - 2 * useless_gap
            g.x = g.x + useless_gap
            g.y = g.y + useless_gap

            -- When there's no window to the right, add an additional
            -- gap.
            if overlap_main == 1
            then
                g.width = g.width - useless_gap
            end
        end
        c:geometry(g)

        -- Remaining clients stacked in slave column, new ones on top.
        if #cls > 1
        then
            for i = (#cls - 1),1,-1
            do
                c = cls[i]
                g = {}
                g.width = slavewid - current_cascade_offset_x
                g.height = wa.height - current_cascade_offset_y
                g.x = wa.x + mainwid + (how_many - i) * cascade_offset_x
                g.y = wa.y + (i - 1) * cascade_offset_y
                if useless_gap > 0
                then
                    g.width = g.width - 2 * useless_gap
                    g.height = g.height - 2 * useless_gap
                    g.x = g.x + useless_gap
                    g.y = g.y + useless_gap
                end
                c:geometry(g)
            end
        end
    end
end

-- vim: set et :
