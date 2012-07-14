-- Grab environment.
local ipairs = ipairs
local tonumber = tonumber
local beautiful = beautiful
local awful = awful
local math = math

module("vain.layout.browse")

extra_padding = 0

name = "browse"
function arrange(p)

    -- Layout with one fixed column meant for the browser window. Its
    -- width is calculated according to mwfact. Other clients are
    -- stacked vertically in a slave column on the right.

    --       (1)              (2)              (3)              (4)
    --   +-----+---+      +-----+---+      +-----+---+      +-----+---+
    --   |     |   |      |     |   |      |     | 3 |      |     | 4 |
    --   |     |   |      |     |   |      |     |   |      |     +---+
    --   |  1  |   |  ->  |  1  | 2 |  ->  |  1  +---+  ->  |  1  | 3 |
    --   |     |   |      |     |   |      |     | 2 |      |     +---+
    --   |     |   |      |     |   |      |     |   |      |     | 2 |
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

    if #cls > 0
    then
        -- Main column, fixed width and height.
        local c = cls[#cls]
        local g = {}
        local mainwid = math.floor(wa.width * mwfact)
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
            local slavehei = math.floor(wa.height / (#cls - 1))
            for i = (#cls - 1),1,-1
            do
                c = cls[i]
                g = {}
                g.width = slavewid
                if i == (#cls - 1)
                then
                    g.height = wa.height - (#cls - 2) * slavehei
                else
                    g.height = slavehei
                end
                g.x = wa.x + mainwid
                g.y = wa.y + (i - 1) * slavehei
                if useless_gap > 0
                then
                    g.width = g.width - 2 * useless_gap
                    if i == 1
                    then
                        -- This is the topmost client. Push it away from
                        -- the screen border (add to g.y and subtract
                        -- useless_gap once) and additionally shrink its
                        -- height.
                        g.height = g.height - 2 * useless_gap
                        g.y = g.y + useless_gap
                    else
                        -- All other clients.
                        g.height = g.height - useless_gap
                    end
                    g.x = g.x + useless_gap
                end
                c:geometry(g)
            end
        end
    end
end

-- vim: set et :
