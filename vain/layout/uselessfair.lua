---------------------------------------------------------------------------
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2008 Julien Danjou
-- @copyright 2010 Vain
-- @release v3.4.6
---------------------------------------------------------------------------

-- Grab environment we need
local ipairs = ipairs
local math = math
local beautiful = beautiful
local tonumber = tonumber

--- Fair layouts module for awful / vain
module("vain.layout.uselessfair")

local function fair(p, orientation)
    -- A useless gap (like the dwm patch) can be defined with
    -- beautiful.useless_gap_width .
    local useless_gap = tonumber(beautiful.useless_gap_width)
    if useless_gap == nil
    then
        useless_gap = 0
    end

    -- Mostly copied.
    local wa = p.workarea
    local cls = p.clients

    if #cls > 0 then
        local cells = math.ceil(math.sqrt(#cls))
        local strips = math.ceil(#cls / cells)

        local cell = 0
        local strip = 0
        for k, c in ipairs(cls) do
            local g = {}
            if ( orientation == "east" and #cls > 2 )
            or ( orientation == "south" and #cls <= 2 ) then
                if #cls < (strips * cells) and strip == strips - 1 then
                    g.width = wa.width / (cells - ((strips * cells) - #cls))
                else
                    g.width = wa.width / cells
                end
                g.height = wa.height / strips

                g.x = wa.x + cell * g.width
                g.y = wa.y + strip * g.height

            else
                if #cls < (strips * cells) and strip == strips - 1 then
                    g.height = wa.height / (cells - ((strips * cells) - #cls))
                else
                    g.height = wa.height / cells
                end
                g.width = wa.width / strips

                g.x = wa.x + strip * g.width
                g.y = wa.y + cell * g.height
            end

            -- Useless gap.
            if useless_gap > 0
            then
                g.width = g.width - 2 * useless_gap
                g.height = g.height - 2 * useless_gap
                g.x = g.x + useless_gap
                g.y = g.y + useless_gap
            end
            -- End of useless gap.

            c:geometry(g)

            cell = cell + 1
            if cell == cells then
                cell = 0
                strip = strip + 1
            end
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
