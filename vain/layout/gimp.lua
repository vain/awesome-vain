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
        }
    },
}

-- Append these rules to your global rules table.
rules =
{
    named_rules.toolbox,
    named_rules.dock,
    named_rules.image
}

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

    -- If ncol is 1, all image windows are placed at the same
    -- coordinates. Otherwise, they are stacked vertically.
    local stack_main = awful.tag.getncol(t)

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

        -- Common values.
        mainwid = wa.width * mwfact
        slavearea = wa.width - mainwid

        -- Layout main windows. New windows on top.
        if #main > 0
        then
            mainhei = wa.height / #main

            for i = #main,1,-1
            do
                c = main[i]

                g = {}
                if stack_main == 1
                then
                    -- Do not stack, all image windows at the same
                    -- coordinates.
                    g.x = wa.x
                    g.y = wa.y
                    g.width = mainwid
                    g.height = wa.height
                else
                    g.x = wa.x
                    g.y = wa.y + (i - 1) * mainhei
                    g.width = mainwid
                    g.height = mainhei
                end

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

        -- Layout slave windows in columns right to the main windows.
        -- Order is ... tricky.
        -- (It looks like Gimp registers the toolbox first. But that's
        -- not guaranteed. Anyway, sorting it this way, the toolbox
        -- should be the leftmost item.)
        if #slave > 0
        then
            slavewid = slavearea / #slave
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
