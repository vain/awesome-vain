-- Please note: Since Gimp 2.8, this layout is deprecated and no longer
-- maintained. It may still work but I don't use it anymore. Gimp 2.8
-- has a "single window mode" which does all I need.


-- Grab environment.
local ipairs = ipairs
local table = table
local tonumber = tonumber
local beautiful = beautiful
local awful = awful

module("vain.layout.gimp")

-- Only meant for internal use.
local named_rules =
{
    toolbox =
    {
        rule = { class = "Gimp", role = "gimp-toolbox" },
        properties =
        {
            floating = false
        },
    },

    dock =
    {
        rule = { class = "Gimp", role = "gimp-dock" },
        properties =
        {
            floating = false
        },
    },

    image =
    {
        rule = { class = "Gimp", role = "gimp-image-window" },
        properties =
        {
            floating = false
        },
        callback = awful.titlebar.add
    },
}

-- Append these rules to your global rules table.
rules =
{
    named_rules.toolbox,
    named_rules.dock,
    named_rules.image
}

-- Offset for each window when in cascade mode.
cascade_offset = 16

-- Layout algorithm.
name = "gimp"
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

    -- ncol determines the layout type for main/image windows.
    local main_type = awful.tag.getncol(t)

    if #cls > 0
    then
        local main = {}
        local slave = {}

        -- Filter clients. Unknown clients are ignored and set to
        -- floating.
        for k, c in ipairs(cls)
        do
            if awful.rules.match(c, named_rules.dock.rule) or
               awful.rules.match(c, named_rules.toolbox.rule)
            then
                table.insert(slave, c)
            elseif awful.rules.match(c, named_rules.image.rule)
            then
                table.insert(main, c)
            else
                awful.client.floating.set(c, true)
            end
        end

        -- Common values for main and slaves.
        mainwid = wa.width * mwfact

        -- Layout main windows. New windows on top.
        if #main > 0
        then

            -- Frequently used values.
            mainhei = wa.height / #main
            current_cascade_offset = cascade_offset * (#main - 1)

            for i = #main,1,-1
            do
                c = main[i]

                g = {}
                if main_type == 1
                then
                    -- Overlap windows, all at the same place.
                    g.x = wa.x
                    g.y = wa.y
                    g.width = mainwid
                    g.height = wa.height
                elseif main_type == 2
                then
                    -- Overlap windows, cascaded.
                    g.x = wa.x + (#main - i) * cascade_offset
                    g.y = wa.y + (i - 1) * cascade_offset
                    g.width = mainwid - current_cascade_offset
                    g.height = wa.height - current_cascade_offset
                else
                    -- Stack windows vertically.
                    g.x = wa.x
                    g.y = wa.y + (i - 1) * mainhei
                    g.width = mainwid
                    g.height = mainhei
                end

                if useless_gap > 0
                then
                    -- If we're stacking and this is not the topmost
                    -- client, then only reduce height once. Otherwise
                    -- it's either the topmost client or we're not
                    -- stacking, hence add the useless_gap on both
                    -- sides.
                    if main_type >= 3 and i ~= 1
                    then
                        g.height = g.height - useless_gap
                    else
                        g.height = g.height - 2 * useless_gap
                        g.y = g.y + useless_gap
                    end
                    g.width = g.width - 2 * useless_gap
                    g.x = g.x + useless_gap
                end

                c:geometry(g)
            end
        end

        -- Layout slave windows in columns right to the main windows.
        -- Order is ... tricky.
        -- (It looks like Gimp registers the toolbox first. But that's
        -- not guaranteed. Anyway, sorting it this way, the toolbox
        -- should be the leftmost item.)
        if #slave > 0
        then
            slavewid = (wa.width - mainwid) / #slave
            slavehei = wa.height

            for i = 1,#slave,1
            do
                c = slave[i]

                g = {}
                g.x = wa.x + mainwid + (i - 1) * slavewid
                g.y = wa.y
                g.width = slavewid
                g.height = slavehei

                if useless_gap > 0
                then
                    -- Never push slaves in x direction because the main
                    -- windows already added a useless_gap there.
                    g.width = g.width - useless_gap
                    g.height = g.height - 2 * useless_gap
                    g.y = g.y + useless_gap
                end

                c:geometry(g)
            end
        end
    end
end

-- vim: set et :
