-- Grab environment.
local awful = awful
local widget = widget
local timer = timer
local string = string
local beautiful = beautiful
local image = image
local io = io
local math = math
local os = os
local pairs = pairs
local tonumber = tonumber
local vain = vain

module("vain.widgets")

terminal = ''

-- System load
function systemload(args)
    local args = args or {}
    local refresh_timeout = args.timeout or 10

    local mysysload = widget({ type = "textbox" })
    local mysysloadupdate = function()
        local f = io.open("/proc/loadavg")
        local ret = f:read("*all")
        f:close()

        local a, b, c = string.match(ret, "([^%s]+) ([^%s]+) ([^%s]+)")
        mysysload.text = string.format("%s %s %s", a, b, c)
        mysysload.text = ' <span color="' .. beautiful.fg_urgent .. '">'
                         .. mysysload.text .. '</span> '
    end
    mysysloadupdate()
    local mysysloadtimer = timer({ timeout = refresh_timeout })
    mysysloadtimer:add_signal("timeout", mysysloadupdate)
    mysysloadtimer:start()
    mysysload:buttons(awful.util.table.join(
        awful.button({}, 0,
            function()
                awful.util.spawn(terminal .. ' -e htop')
            end)
    ))
    return mysysload
end

-- Maildir check
function mailcheck(args)
    local args = args or {}
    local mailpath = args.mailpath or os.getenv("HOME") .. "/Mail"
    local ignore_boxes = args.ignore_boxes or {}
    local refresh_timeout = args.refresh_timeout or 30

    local mymailcheck = widget({ type = "textbox" })
    local mymailcheckupdate = function()
        -- Search for files in "new" directories. Print only their base
        -- path.
        local p = io.popen("find " .. mailpath ..
                           " -path '*/new/[^.]*' -type f -printf '%h\n'")
        local boxes = {}
        local line = ""
        repeat
            line = p:read("*l")
            if line ~= nil
            then
                -- Strip off leading mailpath and anything after and
                -- including "/new...". Save number of new mails.
                local box = string.match(line, mailpath ..
                                               "/*\.?([^/]+)/new.*")
                if boxes[box] == nil
                then
                    boxes[box] = 1
                else
                    boxes[box] = boxes[box] + 1
                end
            end
        until line == nil

        local newmail = ""
        for box, number in pairs(boxes)
        do
            -- Add this box only if it's not to be ignored.
            if not vain.util.element_in_table(box, ignore_boxes)
            then
                if newmail == ""
                then
                    newmail = box .. "(" .. number .. ")"
                else
                    newmail = newmail .. ", " ..
                              box .. "(" .. number .. ")"
                end
            end
        end

        if newmail == ""
        then
            mymailcheck.text = " no mail "
        else
            mymailcheck.text = ' <span color="'
                               .. beautiful.border_focus
                               .. '">mail: ' .. newmail .. '</span> '
        end
    end
    if args.initial_update == nil or args.initial_update
    then
        mymailcheckupdate()
    else
        mymailcheck.text = " no mail "
    end
    local mymailchecktimer = timer({ timeout = refresh_timeout })
    mymailchecktimer:add_signal("timeout", mymailcheckupdate)
    mymailchecktimer:start()
    mymailcheck:buttons(awful.util.table.join(
        awful.button({}, 0,
            function()
                awful.util.spawn(terminal .. ' -e muttgit.sh')
            end)
    ))
    return mymailcheck
end

-- Battery
function battery(args)
    local args = args or {}
    local bat = args.battery or "BAT0"
    local refresh_timeout = args.refresh_timeout or 30

    local mybattery = widget({ type = "textbox" })
    local mybatteryupdate = function()

        local first_line = vain.util.first_line
        local present = first_line("/sys/class/power_supply/" .. bat ..
                                   "/present")
        if present == "1"
        then
            local rate = first_line("/sys/class/power_supply/" .. bat ..
                                    "/current_now")
            local ratev = first_line("/sys/class/power_supply/" .. bat ..
                                     "/voltage_now")
            local rem = first_line("/sys/class/power_supply/" .. bat ..
                                   "/charge_now")
            local tot = first_line("/sys/class/power_supply/" .. bat ..
                                   "/charge_full")
            local status = first_line("/sys/class/power_supply/" .. bat ..
                                      "/status")

            local time_rat = 0
            if status == "Charging"
            then
                status = "(+)"
                time_rat = (tot - rem) / rate
            elseif status == "Discharging"
            then
                status = "(-)"
                time_rat = rem / rate
            else
                status = "(.)"
            end

            local hrs = math.floor(time_rat)
            local min = (time_rat - hrs) * 60
            local time = string.format("%02d:%02d", hrs, min)

            local perc = string.format("%d%%", (rem / tot) * 100)

            local watt = string.format("%.2fW", (rate * ratev) / 1e12)

            text = watt .. " " .. perc .. " " .. time .. " " .. status
        else
            text = "no battery"
        end

        mybattery.text = ' <span color="' .. beautiful.fg_urgent .. '">'
                         .. text .. '</span> '
    end
    mybatteryupdate()
    local mybatterytimer = timer({ timeout = refresh_timeout })
    mybatterytimer:add_signal("timeout", mybatteryupdate)
    mybatterytimer:start()
    return mybattery
end

-- Volume
function volume(args)
    local args = args or {}
    local mixer_channel = args.mixer_channel or "Master"
    local refresh_timeout = args.refresh_timeout or 2

    local myvolume = widget({ type = "textbox" })
    local myvolumeupdate = function()
        -- Mostly copied from vicious.
        local f = io.popen("amixer get " .. mixer_channel)
        local mixer = f:read("*all")
        f:close()

        local volu, mute = string.match(mixer, "([%d]+)%%.*%[([%l]*)")

        if volu == nil
        then
            volu = 0
        end

        if mute == nil
        then
            mute = "---"
        elseif mute == 'on'
        then
            mute = 'O'
        else
            mute = 'M'
        end

        local ret = string.format("%03d%% %s", volu, mute)
        myvolume.text = ' <span color="' .. beautiful.fg_urgent .. '">'
            .. ret .. '</span> '
    end
    myvolumeupdate()
    local myvolumetimer = timer({ timeout = refresh_timeout })
    myvolumetimer:add_signal("timeout", myvolumeupdate)
    myvolumetimer:start()
    myvolume:buttons(awful.util.table.join(
        awful.button({}, 1,
            function()
                awful.util.spawn('amixer set ' .. mixer_channel ..
                                 ' toggle')
             end),

        awful.button({}, 2,
            function()
                awful.util.spawn(terminal .. ' -e alsamixer')
            end),

        awful.button({}, 3,
            function()
                awful.util.spawn('amixer set ' .. mixer_channel ..
                                 ' toggle')
            end),

        awful.button({}, 4,
            function()
                awful.util.spawn('amixer set ' .. mixer_channel ..
                                 ' 2dB+ unmute')
            end),

        awful.button({}, 5,
            function()
                awful.util.spawn('amixer set ' .. mixer_channel ..
                                 ' 2dB- unmute')
            end)
    ))
    return myvolume
end

-- MPD
function mpd(args)
    local args = args or {}
    local mixer_channel = args.mixer_channel or "Master"

    local mpdtable = {
        widget({ type = "textbox" }),
        widget({ type = "imagebox" }),
        widget({ type = "imagebox" }),
        widget({ type = "imagebox" }),
        widget({ type = "imagebox" }),
        widget({ type = "textbox" })
    }

    mpdtable[1].text = " mpd: "

    mpdtable[2].image = image("/usr/share/icons/Tango/32x32/actions/" ..
                              "player_rew.png")
    mpdtable[3].image = image("/usr/share/icons/Tango/32x32/actions/" ..
                              "player_stop.png")
    mpdtable[4].image = image("/usr/share/icons/Tango/32x32/actions/" ..
                              "player_play.png")
    mpdtable[5].image = image("/usr/share/icons/Tango/32x32/actions/" ..
                              "player_fwd.png")

    mpdtable[6].text = " "

    local function buttons_for_mpdwidget(widg, cmd)
        widg:buttons(awful.util.table.join(
            awful.button({}, 1, function() awful.util.spawn(cmd) end),

            awful.button({}, 2,
                function()
                    awful.util.spawn(terminal .. ' -e ncmpcpp')
                end),

            awful.button({}, 3,
                function()
                    awful.util.spawn('amixer set ' .. mixer_channel ..
                                     ' toggle')
                end),

            awful.button({}, 4,
                function()
                    awful.util.spawn('amixer set ' .. mixer_channel ..
                                     ' 2dB+ unmute')
                end),

            awful.button({}, 5,
                function()
                    awful.util.spawn('amixer set ' .. mixer_channel ..
                                     ' 2dB- unmute')
                end)
        ))
    end
    buttons_for_mpdwidget(mpdtable[2], 'mpc prev')
    buttons_for_mpdwidget(mpdtable[3], 'mpc stop')
    buttons_for_mpdwidget(mpdtable[4], 'mpc toggle')
    buttons_for_mpdwidget(mpdtable[5], 'mpc next')
    return mpdtable
end

-- Net
net_last_t = {}
net_last_r = {}

function net(args)
    local args = args or {}
    local iface = args.iface or "eth0"
    local delta = args.refresh_timeout or 2

    local mynet = widget({ type = "textbox" })
    local mynetupdate = function()
        local state = vain.util.first_line('/sys/class/net/' .. iface ..
                                           '/operstate')
        local now_t = vain.util.first_line('/sys/class/net/' .. iface ..
                                           '/statistics/tx_bytes')
        local now_r = vain.util.first_line('/sys/class/net/' .. iface ..
                                           '/statistics/rx_bytes')
        local text = iface .. ': '

        if state == 'down' or not now_t or not now_r
        then
            mynet.text = ' ' .. text .. '-' .. ' '
            return
        end

        if net_last_t[iface] and net_last_t[iface]
        then
            local val = ((now_t - net_last_t[iface]) / delta / 1e3)
            text = text
                   .. '<span color="' .. beautiful.fg_focus .. '">'
                   .. '↑('
                   .. vain.util.paddivnum(val, 5, 1)
                   .. ')'
                   .. '</span>'

            text = text .. ', '

            val = ((now_r - net_last_r[iface]) / delta / 1e3)
            text = text
                   .. '<span color="' .. beautiful.fg_urgent .. '">'
                   .. '↓('
                   .. vain.util.paddivnum(val, 5, 1)
                   .. ')'
                   .. '</span>'

            mynet.text = ' ' .. text .. ' '
        else
            mynet.text = ' ' .. text .. '-' .. ' '
        end

        net_last_t[iface] = now_t
        net_last_r[iface] = now_r
    end
    mynetupdate()
    local mynettimer = timer({ timeout = delta })
    mynettimer:add_signal("timeout", mynetupdate)
    mynettimer:start()
    return mynet
end

-- Integration of "gitodo".
-- See: https://github.com/vain/gitodo
-- Shows the number of open tasks. On click, a terminal is spawned which
-- first shows all those tasks and then launches a shell for you to work
-- with gitodo.
function gitodo(args)
    local args = args or {}
    local widg = widget({ type = "textbox" })

    local mytodoupdate = function()
        local f = io.popen("gitodo --count")
        local ret = f:read("*all")
        f:close()

        local outdated, warning, all = string.match(ret,
                                                    "(%d+) (%d+) (%d+)")

        local msg = ' todo: '

        if tonumber(outdated) > 0
        then
            msg = msg .. '<span color="' .. beautiful.border_focus
                      .. '">'
                      .. outdated
                      .. '</span>, '
        end

        if tonumber(warning) > 0
        then
            msg = msg .. '<span color="' .. beautiful.fg_urgent
                      .. '">'
                      .. warning
                      .. '</span>, '
        end

        msg = msg .. '<span color="' .. beautiful.fg_urgent
                  .. '">'
                  .. all
                  .. '</span> '

        widg.text = msg
    end
    if args.initial_update == nil or args.initial_update
    then
        mytodoupdate()
    else
        widg.text = ' todo: - '
    end
    local todotimer = timer({ timeout = 120 })
    todotimer:add_signal("timeout", mytodoupdate)
    todotimer:start()

    widg:buttons(awful.util.table.join(
        awful.button({}, 0,
            function()
                awful.util.spawn(terminal
                                 .. ' -e bash -c "gitodo; echo; bash"')
            end)
    ))

    return widg
end

-- vim: set et :
