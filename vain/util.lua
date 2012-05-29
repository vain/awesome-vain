-- Grab environment.
local awful = awful
local naughty = naughty
local beautiful = beautiful
local mouse = mouse
local pairs = pairs
local ipairs = ipairs
local table = table
local string = string
local client = client
local io = io
local screen = screen
local math = math
local tonumber = tonumber

module("vain.util")

-- Like awful.menu.clients, but only show clients of currently selected
-- tags.
function menu_clients_current_tags(menu, args)

    -- List of currently selected tags.
    local cls_tags = awful.tag.selectedlist(mouse.screen)

    -- Final list of menu items.
    local cls_t = {}

    if cls_tags == nil
    then
        return nil
    end

    -- For each selected tag get all clients of that tag and add them to
    -- the menu. A click on a menu item will raise that client.
    for i = 1,#cls_tags
    do
        local t = cls_tags[i]
        local cls = t:clients()

        for k, c in pairs(cls)
        do
            cls_t[#cls_t + 1] = { awful.util.escape(c.name) or "",
                                  function ()
                                      c.minimized = false
                                      client.focus = c
                                      c:raise()
                                  end,
                                  c.icon }
        end
    end

    -- No clients? Then quit.
    if #cls_t <= 0
    then
        return nil
    end

    -- menu may contain some predefined values, otherwise start with a
    -- fresh menu.
    if not menu
    then
        menu = {}
    end

    -- Set the list of items and show the menu.
    menu.items = cls_t
    local m = awful.menu.new(menu)
    m:show(args)
    return m
end

-- Destroys all current/visible naughty notifications.
function clear_naughty()
    -- First, store current items. Necessary because naughty.destroy()
    -- interferes with the iteration.
    local notis = {}
    for _, scr in ipairs(naughty.notifications)
    do
        for _, ori in pairs(scr)
        do
            for _, noti in pairs(ori)
            do
                table.insert(notis, noti)
            end
        end
    end

    -- Got 'em, destroy 'em.
    for _, noti in pairs(notis)
    do
        naughty.destroy(noti)
    end
end

-- Checks whether this element exists in the table.
function element_in_table(element, table)
    for k, v in pairs(table)
    do
        if v == element
        then
            return true
        end
    end
    return false
end

-- Read the first line of a file or return nil.
function first_line(f)
    local fp = io.open(f)
    if not fp
    then
        return nil
    end

    local content = fp:read("*l")
    fp:close()
    return content
end

-- Pad a number (float) with leading zeros and add thousand separators.
-- For example,
--
--     print(vain.util.paddivnum(1234567.123, 8, 2))
--
-- shows
--
--     01,234,567.12
--
-- That's handy if you need strings of fixed lengths. However, this only
-- works for positive numbers.
function paddivnum(num, padlen, declen)
    local rounded = string.format('%.' .. declen .. 'f', num)
    local intpart, decpart = string.match(rounded, '([^.]+)\.(.*)')
    intpart = string.rep('0', padlen - #intpart) .. intpart
    intpart = string.reverse(intpart)
    intpart = string.gsub(intpart, '(%d%d%d)', '%1,')
    intpart = string.reverse(intpart)
    intpart = string.gsub(intpart, '^,', '')
    return intpart .. '.' .. decpart
end

-- Move the mouse away: To the (bottom|top) (left|right) minus a little
-- offset.
-- 0 = bottom left, 1 = top left, 2 = top right, 3 = bottom right.
function move_mouse_away(target)
    local g = {}
    local mg = screen[mouse.screen].geometry

    if target == nil then target = 0 end

    if target < 2
    then
        g.x = mg.x + 1
    else
        g.x = mg.x + mg.width - 2
    end

    if target == 1 or target == 2
    then
        g.y = mg.y + 1
    else
        g.y = mg.y + mg.height - 2
    end

    mouse.coords(g)
end

-- Center the mouse on the current screen.
function center_mouse()
    local mg = screen[mouse.screen].geometry
    local g = {}
    g.x = mg.x + mg.width * 0.5
    g.y = mg.y + mg.height * 0.5
    mouse.coords(g)
end

-- Magnify a client: Set it to "float" and resize it.
function magnify_client(c)
    awful.client.floating.set(c, true)

    local mg = screen[mouse.screen].geometry
    local tag = awful.tag.selected(mouse.screen)
    local mwfact = awful.tag.getmwfact(tag)
    local g = {}
    g.width = math.sqrt(mwfact) * mg.width
    g.height = math.sqrt(mwfact) * mg.height
    g.x = mg.x + (mg.width - g.width) / 2
    g.y = mg.y + (mg.height - g.height) / 2
    c:geometry(g)
end

-- Trim a string.
-- See also: http://lua-users.org/wiki/StringTrim
function trim(s)
    return s:match "^%s*(.-)%s*$"
end

-- Split a string.
-- See also: http://lua-users.org/wiki/SplitJoin
function split(s, sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    string.gsub(s, pattern, function(c) fields[#fields+1] = c end)
    return fields
end

-- Read the nice value of pid from /proc.
function get_nice_value(pid)
    local n = first_line('/proc/' .. pid .. '/stat')
    if n == nil
    then
        -- This should not happen. But I don't want to crash, either.
        return 0
    end

    -- Remove pid and tcomm. This is necessary because tcomm may contain
    -- nasty stuff such as whitespace or additional parentheses...
    n = string.gsub(n, '.*%) ', '')

    -- Field number 17 now is the nice value.
    fields = split(n, ' ')
    return tonumber(fields[17])
end

-- To be used as a signal handler for "focus":
--    client.add_signal("focus", vain.util.niceborder_focus)
-- This requires beautiful.border_focus{,_highprio,_lowprio}.
function niceborder_focus(c)
    local n = get_nice_value(c.pid)
    if n == 0
    then
        c.border_color = beautiful.border_focus
    elseif n < 0
    then
        c.border_color = beautiful.border_focus_highprio
    else
        c.border_color = beautiful.border_focus_lowprio
    end
end

-- To be used as a signal handler for "unfocus":
--    client.add_signal("unfocus", vain.util.niceborder_unfocus)
-- This requires beautiful.border_normal{,_highprio,_lowprio}.
function niceborder_unfocus(c)
    local n = get_nice_value(c.pid)
    if n == 0
    then
        c.border_color = beautiful.border_normal
    elseif n < 0
    then
        c.border_color = beautiful.border_normal_highprio
    else
        c.border_color = beautiful.border_normal_lowprio
    end
end

-- An internal function: Show the next non-empty tag in the given
-- direction (may be 1 = seek right or -1 = seek left). Don't use this
-- function in your code, use tag_viewnext_nonempty() or
-- tag_viewprev_nonempty().
local function tag_viewdirection_nonempty(direction, screenuserdata)
    -- Get screen index, the current tag, its index and all existing
    -- tags on the current screen.
    local screeni = screenuserdata and screenuserdata.index or mouse.screen
    local t = awful.tag.selected(screeni)
    local start = awful.tag.getidx(t)
    local tags = screen[screeni]:tags()

    -- Maybe no tag is shown at all. Bail out.
    if start == nil
    then
        return
    end

    local i = start + direction

    -- Wrap indices. That's a little annoying since lua uses 1-based
    -- indexing.
    i = ((i - 1) % #tags) + 1

    -- If all tags are empty, we will at some point return to i = start.
    while i ~= start
    do
        -- Got a tag with clients! Now calculate offset and show it.
        if #(tags[i]:clients()) ~= 0
        then
            awful.tag.viewidx(i - start, screenuserdata)
            return
        end

        i = i + direction
        i = ((i - 1) % #tags) + 1
    end
end

-- Show the next non-empty tag.
function tag_viewnext_nonempty(screenuserdata)
    tag_viewdirection_nonempty( 1, screenuserdata)
end

-- Show the previous non-empty tag.
function tag_viewprev_nonempty(screenuserdata)
    tag_viewdirection_nonempty(-1, screenuserdata)
end

-- vim: set et :
