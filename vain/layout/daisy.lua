---------------------------------------------------------------------------
-- @author Temir Umurzakov temir@umurzakov.com
-- @copyright 2008 Julien Danjou
-- @copyright 2010 Vain
-- @copyright 2013 Temir Umurzakov
-- @release v3.4.6
---------------------------------------------------------------------------

-- Grab environment we need
local ipairs = ipairs
local math = math
local beautiful = beautiful
local tonumber = tonumber
local awful = awful

-- Central working area that overlap others small.
-- Small windows could replace main window by moving it
-- with <META> + mouse left button key. 
-- Very comfortable for working with many terminals.
--
-- +----+----+----+----+
-- |  +-+----+----+-+  |
-- +--|             |--+
-- |  |             |  |
-- +--|             |--+
-- |  |             |  |
-- +--|             |--+
-- |  +-+----+----+-+  |
-- +----+----+----+----+

--- Fair layouts module for awful / vain
module("vain.layout.daisy")

local function fair(p, orientation)
    local wa = p.workarea

    local main_width = math.ceil(wa.width * 0.8)
    local main_height = math.ceil(wa.height * 0.7)
    local main_wdiff = math.ceil(wa.width - main_width)
    local main_hdiff = math.ceil(wa.height - main_height)
    local main_x = math.ceil(main_wdiff / 2)
    local main_y = math.ceil(main_hdiff / 2)
    local slave_width = math.ceil(wa.width/4)
    local slave_height = math.ceil(wa.height/4)
    local top_offset = 25

    local index = 0;

    local cls = p.clients
    if #cls > 0 then
        for k, c in ipairs(cls) do
            local g = {}

            if index == 0 then
                g.width = main_width
                g.height = main_height
                g.x = main_x
                g.y = main_y
                first = false
            else
                g.width = slave_width
                g.height = slave_height

                if index >= 1 and index <=4 then
                    g.x = slave_width * (index - 1)
                    g.y = top_offset 
                elseif index >=5 and index <= 7 then
                    g.x = wa.width - slave_width
                    g.y = slave_height * (index - 4) + top_offset
                elseif index >=8 and index <= 10 then
                    g.x = slave_width * (3 - index + 7)
                    g.y = wa.height - slave_height + top_offset
                elseif index >=11 and index <= 12 then
                    g.x = 0
                    g.y = slave_height * (3 - index + 10) + top_offset
                else
                    -- i don't know what to do with this windows
                    -- lets place them in the center
                    g.x = math.ceil(wa.width / 2) - math.ceil(slave_width / 2)
                    g.y = math.ceil(wa.height / 2) - math.ceil(slave_height / 2)
                    awful.client.floating.set(c, true)
                end
            end

            c:geometry(g)

            index = index + 1
        end
    end
end

--- Horizontal fair layout.
-- @param screen The screen to arrange.
horizontal = {}
horizontal.name = "fairh"
function horizontal.arrange(p)
    return fair(p, "east")
end

-- Vertical fair layout.
-- @param screen The screen to arrange.
name = "fairv"
function arrange(p)
    return fair(p, "south")
end
