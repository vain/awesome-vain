-- Grab environment.
local awful = awful
local mouse = mouse
local pairs = pairs
local capi =
{
    screen = screen,
    mouse = mouse,
    client = client,
    keygrabber = keygrabber
}

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
                                      if not c:isvisible()
                                      then
                                          awful.tags.viewmore(c:tags(),
                                                              c.screen)
                                      end
                                      capi.client.focus = c
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

-- vim: set et :
