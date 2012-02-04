This repository contains stuff I wrote for the [Awesome Window
Manager](http://awesome.naquadah.org/). Essentially, it contains
everything I use in my `rc.lua` that is not trivial: Widgets, layouts,
utility functions. This means, the stuff in here is exceedingly
customized to fit *my* needs. Thus, you shouldn't blindly use it. It's
likely for things to get changed or removed or whatever. Rather than
actually using it, read the code. :)

All of this is [GPL3+](http://www.gnu.org/licenses/gpl-3.0.txt).

Note: I'm using the 3.4 branch of Awesome. Thus, this module is likely
to not work with the current git branch.


Using it
========

Basically, all you have to do is including the module:

	require("vain")
	vain.widgets.terminal = "xterm"

Some widgets require a terminal, so you need to set that as well.

For this to work, the directory `vain` must be located in the same
directory as your `rc.lua`.

	$ pwd
	/home/void/.config/awesome
	$ tree -l
	.
	|-- rc.lua
	|-- themes -> ../.awesome-themes/
	|   |-- ...
	|   `-- ...
	`-- vain -> ../.awesome-vain/vain
	    |-- init.lua
	    |-- layout
	    |   |-- browse.lua
	    |   |-- gimp.lua
	    |   |-- init.lua
	    |   |-- termfair.lua
	    |   `-- uselessfair.lua
	    |-- util.lua
	    `-- widgets.lua


Layouts
=======

How do layouts work in general?
-------------------------------

A "layout" is simply a lua table or module that has an attribute `name`
and a function called `arrange`. So the most simple layout could look
like this:

	mylayout = {}
	mylayout.name = "hurz"
	mylayout.arrange = function(p) end

To use this layout on a tag, you have to write:

	awful.layout.set(mylayout, tags[1][7])

(Of course, you could just add it to the default table called
`layouts`.)

Now, the `arrange` function gets a parameter `p` which is another table.
The most important elements of this table are `workarea` and `clients`.
Thus, the table `p` looks similar to this:

	p = {
	    workarea = { x, y, width, height },
	    clients = { ... },
	    ...
	}

The job of the `arrange` function is to iterate over all clients and set
their geometry. That is, for each client you have to call `geometry` on
it:

	mylayout.arrange = arrange(p)

	    local wa = p.workarea
	    local cls = p.clients

	    for k, c in ipairs(cls)
	    do
	        local g = {}

	        g.width = ...
	        g.height = ...
	        g.x = wa.x + ...
	        g.y = wa.y + ...

	        c:geometry(g)
	    end
	end

That's it. Awesome handles all the nasty stuff like minimized clients,
floating clients, order of clients, focus, drawing window borders etc.

What about icons?
-----------------

Thanks to Nicolas Estibals (https://github.com/nestibal) for creating
icons for awesome's default theme!

You have to extend your theme like this (let's say this file is called
`~/.config/awesome/extended_default_theme.lua`):

	dofile("/usr/share/awesome/themes/default/theme.lua")
	...
	theme.layout_termfair      = os.getenv("HOME") .. "/.config/awesome/vain/themes/default/layouts/termfairw.png"
	theme.layout_browse        = os.getenv("HOME") .. "/.config/awesome/vain/themes/default/layouts/browsew.png"
	theme.layout_gimp          = os.getenv("HOME") .. "/.config/awesome/vain/themes/default/layouts/gimpw.png"
	theme.layout_cascade       = os.getenv("HOME") .. "/.config/awesome/vain/themes/default/layouts/cascadew.png"
	theme.layout_cascadebrowse = os.getenv("HOME") .. "/.config/awesome/vain/themes/default/layouts/cascadebrowsew.png"
	...
	return theme

Then, you can tell `beautiful` to use this extended theme:

	beautiful.init(os.getenv("HOME") .. "/.config/awesome/extended_default_theme.lua")

Icons for the default theme are available in black and white. There's
also a set of icons for the "zenburn" theme (this is what I use).

What do my layouts do?
----------------------

### termfair
I do a lot of work on terminals. The common tiling algorithms usually
maximize windows, so you'll end up with a terminal that has about 200
columns or more. That's way too much. Have you ever read a manpage in a
terminal of this size?

This layout restricts the size of each window. Each window will have the
same width but is variable in height. Furthermore, windows are
left-aligned. The basic workflow is as follows (the number above the
screen is the number of open windows, the number in a cell is the fixed
number of a client):

	     (1)                (2)                (3)
	+---+---+---+      +---+---+---+      +---+---+---+
	|   |   |   |      |   |   |   |      |   |   |   |
	| 1 |   |   |  ->  | 2 | 1 |   |  ->  | 3 | 2 | 1 |  ->
	|   |   |   |      |   |   |   |      |   |   |   |
	+---+---+---+      +---+---+---+      +---+---+---+

	     (4)                (5)                (6)
	+---+---+---+      +---+---+---+      +---+---+---+
	| 4 |   |   |      | 5 | 4 |   |      | 6 | 5 | 4 |
	+---+---+---+  ->  +---+---+---+  ->  +---+---+---+
	| 3 | 2 | 1 |      | 3 | 2 | 1 |      | 3 | 2 | 1 |
	+---+---+---+      +---+---+---+      +---+---+---+

The first client will be located in the left column. When opening
another window, this new window will be placed in the left column while
moving the first window into the middle column. Once a row is full,
another row above it will be created.

The number of columns is fixed and controlled by the value of `nmaster`
of the tag. The number of rows is usually variable but you can set a
minimum by setting `ncol` of the tag.

This sets the `termfair` layout on tag 7 of screen 1 and sets it to 3
columns and at least 2 rows:

	awful.layout.set(vain.layout.termfair, tags[1][7])
	awful.tag.setnmaster(3, tags[1][7])
	awful.tag.setncol(2, tags[1][7])

### browse
A very wide browser window is a pain. Some pages do restrict their width
but others don't. The latter will be unreadable because your eye has to
keep track of very long lines.

The `browse` layout has a fixed column on the left which is meant for
the browser. Its size is controlled by `mwfact` of the tag. Additional
windows will be opened in another column right to your browser. New
windows are placed above old windows.

	    (1)              (2)              (3)              (4)
	+-----+---+      +-----+---+      +-----+---+      +-----+---+
	|     |   |      |     |   |      |     | 3 |      |     | 4 |
	|     |   |      |     |   |      |     |   |      |     +---+
	|  1  |   |  ->  |  1  | 2 |  ->  |  1  +---+  ->  |  1  | 3 |
	|     |   |      |     |   |      |     | 2 |      |     +---+
	|     |   |      |     |   |      |     |   |      |     | 2 |
	+-----+---+      +-----+---+      +-----+---+      +-----+---+

For my laptop, I place the right column *on top of* the browser column:
Additional windows will overlap the browser window. This is unusual for
a tiling layout but I need it: When browsing the web, I often want to
open a terminal window (just for a few minutes, then I'll close it).
Typically, the browser window would get resized and for most browsers
this means that the current position in the web page is lost. Hence, I'd
need to scroll the page to reach that point where I was before I opened
the terminal. That's a mess.

Whether the slave column is place on top of the browser window or not is
controlled by the value of `ncol` of the tag. A value of 1 means
"overlapping slave column" and anything else means "don't overlap
windows".

Thus, the following sets the `browse` layout on tag 7 of screen 1. The
main column will have half of the screen width and there will be a
separate column for slave windows.

	awful.layout.set(vain.layout.browse, tags[1][7])
	awful.tag.setmwfact(0.5, tags[1][2])
	awful.tag.setncol(2, tags[1][7])

### gimp
Gimp is something very special. A lot of people don't use Gimp because
it has "so many windows". Using an own layout for Awesome, you can solve
this "problem". (I don't consider it a problem, actually.)

The `gimp` layout uses one big slot for Gimp's image window. To the
right, there's one slot for each toolbox or dock. Windows that are *not*
Gimp windows are set to floating mode.

	+-------+---+---+
	|       |   |   |
	| Image | T | D |
	|       |   |   |
	+-------+---+---+

By default (i.e., if `ncol` is 1), when opening another image window, it
will be placed over the first window overlapping it. So usually, you
only see one image window because that's the image you're working on.
You can use an application switcher or hotkeys to switch to other image
windows (see `menu_clients_current_tags` in the section "Utility
functions").

Sometimes, you may need to get a better overview. By setting the value
of `ncol` to 2, you can switch to "cascade mode":

	+-------------+---+---+
	|     +-----+ |   |   |
	|     |     | |   |   |
	|   +-| Img | |   |   |
	|   | |     | |   |   |
	| +-| +-----+ | T | D |
	| | |     |   |   |   |
	| | +-----+   |   |   |
	| |     |     |   |   |
	| +-----+     |   |   |
	+-------------+---+---|

You can control the offset for each window by setting the global
variable `vain.layout.gimp.cascade_offset`. The default value is 16
pixels.

When setting `ncol` to 2, all images will be stacked in the main slot:

	+-------+---+---+
	| Image |   |   |
	+-------+   |   |
	| Image | T | D |
	+-------+   |   |
	| Image |   |   |
	+-------+---+---+

Again, `mwfact` controls the width of the main slot. So, the following
will use the `gimp` layout on tag 7 of screen 1, defaulting to "stacking
mode" and the main slot will have a width of 75% of your screen:

	awful.layout.set(vain.layout.gimp, tags[1][7])
	awful.tag.setmwfact(0.75, tags[1][2])
	awful.tag.setncol(3, tags[1][7])

However, this is not enough. Default Awesome rules will set the
toolboxes and docks to floating mode because they are *utility windows*.
But: A layout doesn't manage floating windows. So we'll need a set of
rules that set Gimp toolboxes back to normal mode. You have to merge
this set of rules with your existing rules:

	awful.rules.rules = awful.util.table.join(
	    awful.rules.rules,
	    vain.layout.gimp.rules
	)

You can still use your own rules, for example, to move Gimp windows to a
specific tag.

### cascade
Cascade all windows (see gimp layout) of a tag.

Similarly, you can control the offsets by setting those two variables:

	vain.layout.cascade.cascade_offset_x = 64
	vain.layout.cascade.cascade_offset_y = 16

The following reserves space for 5 windows:

	awful.tag.setnmaster(5, tags[s][1])

That is, no window will get resized upon the creation of a new window,
unless there's more than 5 windows.

### cascadebrowse
Similar to the regular `browse` layout, however, clients in the slave
column are cascaded instead of tiled. Thus, there's a similar set of
settings:

	vain.layout.cascadebrowse.cascade_offset_x = 2
	vain.layout.cascadebrowse.cascade_offset_y = 32
	awful.tag.setnmaster(5, tags[s][1])

I recommend setting `cascade_offset_x` to a very small value or even 0
to avoid wasting space.

### uselessfair
This is a duplicate of the stock `fair` layouts. However, I added
"useless gaps" (see below) to this layout. Use it like this:

	awful.layout.set(vain.layout.uselessfair, tags[1][7])

Useless gaps
------------

Useless gaps are gaps between windows. They are "useless" because they
serve no special purpose despite increasing overview. I find it easier
to recognize window boundaries if windows are set apart a little bit.

The `uselessfair` layout, for example, looks like this:

	+================+
	#                #
	#  +---+  +---+  #
	#  | 1 |  |   |  #
	#  +---+  |   |  #
	#         | 3 |  #
	#  +---+  |   |  #
	#  | 2 |  |   |  #
	#  +---+  +---+  #
	#                #
	+================+

All of my layouts provide useless gaps. To set the width of the gap,
you'll have to extend your `beautiful` theme. There must be an item
called `useless_gap_width` in the `theme` table. If it doesn't exist,
the width will default to 0.

	...
	theme.useless_gap_width = "5"
	...


Widgets
=======

Each function returns a widget that can be used in wiboxes. Most widgets
are updated periodically; see the code for the default timer values.

## systemload
Show the current system load in a textbox. Read it directly from
`/proc/loadavg`.

	mysysload = vain.widgets.systemload()

A click on the widget will call `htop` in your `terminal`.

The function takes a table as an optional argument. That table may
contain:

	.refresh_timeout: Defaults to 10 seconds.
	.show_all: Show all three values or by default only the first one?

## memusage
Show used memory and total memory in MiB. Read from `/proc/meminfo`.

	mymemusage = vain.widgets.memusage()

A click on the widget will call `htop` in your `terminal`.

The function takes a table as an optional argument. That table may
contain:

	.refresh_timeout: Defaults to 10 seconds.

## mailcheck
Check Maildirs and show the result in a textbox. For example, I have a
set of Maildirs below `~/Mail`:

	$ pwd
	/home/void/Mail
	$ tree -ad
	.
	|-- bugs
	|   |-- cur
	|   |-- new
	|   `-- tmp
	|-- lists
	|   |-- cur
	|   |-- new
	|   `-- tmp
	|-- system
	|   |-- cur
	|   |-- new
	|   `-- tmp
	.
	.
	.

The `mailcheck` widget checks whether there are files in the `new`
directories. To do so, it calls `find`. If there's new mail, the textbox
will say something like "mail: bugs(3), system(1)", otherwise it says
"no mail".

	mymailcheck = vain.widgets.mailcheck()

The function takes a table as an optional argument. That table may
contain:

	.refresh_timeout: Defaults to 30 seconds.
	.mailpath: Path to your maildirs, defaults to `~/Mail`.
	.ignore_boxes: Another table which lists boxes (just the last part,
		like `lists`) to ignore. Defaults to an empty table.
	.initial_update: Check for mail when starting Awesome or wait for
		the first refresh timeout? Defaults to the former.

When clicking on the widget, the bash alias `smail` is called. That's a
wrapper script for [mutt](http://www.mutt.org/) which I use: It
automatically commits to a [git](http://git-scm.com/) repository after
I've read mail.

`beautiful.mailcheck_new` may contain a color. The new-mail-message is
shown in this color. Uses red if undefined.

## battery
Show the remaining time and capacity of your laptop battery, as well as
the current wattage. Uses the `/sys` filesystem.

	mybattery = vain.widgets.battery()

The function takes a table as an optional argument. That table may
contain:

	.refresh_timeout: Defaults to 30 seconds.
	.battery: Identifier of the battery to watch, defaults to `BAT0`.

## volume
Show and control the current volume in a textbox. Periodically calls
the `control_volume.sh` script to get the current volume. That same
script is used to set the volume. See below.

* Left click: Mute/unmute.
* Right click: Mute/unmute.
* Middle click: Launch `alsamixer` in your `terminal`.
* Scroll wheel: Increase/decrase volume.

	myvolume = vain.widgets.volume()

The function takes a table as an optional argument. That table may
contain:

	.refresh_timeout: Defaults to 2 seconds.
	.mixer_channel: Defaults to `Master`.

I currently use a script similar to the following as
`control_volume.sh`:

	#!/bin/bash
	channel=${2:-Master}
	case $1 in
		up)
			mpc volume +2
			;;
		down)
			mpc volume -2
			;;
		toggle)
			amixer set $channel toggle
			;;
		get)
			mpc volume | sed -r 's/^volume: ?([^%]+)%.*/\1/'

			echo -n ' '

			amixer get $channel |
			sed -rn 's/.*\[([a-z]+)\]/\1/p' |
			head -1
			;;
	esac

That is, I get and set volume via
[mpd](http://en.wikipedia.org/wiki/Music_Player_Daemon). I used to do
all of that via `amixer` but this tool gets more and more broken. For
example, once the volume reached 0%, `amixer` can't get it back.

This is a very ugly solution. I decided to use a wrapper script so I
don't need to touch my Awesome configuration once I find a better
solution.

## mpd
Provides a set of imageboxes to control a running instance of mpd on
your local host. Also provides controls similiar to the volume widget.
To control mpd, `mpc` is used.

* Right click on any icon: Mute/unmute via `control_volume.sh`. See
  above.
* Middle click on any icon: Call `ncmpcpp` in your `terminal`.

This function does not return one widget but a table of widgets. For
now, you'll have to add them one for one to your wibox:

	mpdtable = vain.widgets.mpd()
	...
	mywibox[s].widgets = {
	    ...
	    mpdtable[1],
	    mpdtable[2],
	    mpdtable[3],
	    mpdtable[4],
	    mpdtable[5],
	    mpdtable[6],
	    ...
	}

The function takes a table as an optional argument. That table may
contain:

	.mixer_channel: Defaults to `Master`.

## net
Monitors network interfaces and shows current traffic in a textbox. If
the interface is not present or if there's not enough data yet, you'll
see `wlan0: -` or similar.  Otherwise, the current traffic is shown in
kilobytes per second as `eth0: ↑(00,010.2), ↓(01,037.8)` or similar.

	neteth0 = vain.widgets.net()

The function takes a table as an optional argument. That table may
contain:

	.refresh_timeout: Defaults to 2 seconds.
	.iface: Defaults to `eth0`.

## gitodo
This is an integration of [gitodo](https://github.com/vain/gitodo) into
Awesome.

	todolist = vain.widgets.gitodo()

The function takes a table as an optional argument. That table may
contain:

	.refresh_timeout: Defaults to 120 seconds.
	.initial_update: Check for todo items when starting Awesome or wait
		for the first refresh timeout? Defaults to the former.

`beautiful.gitodo_normal` is used as the color for non-outdated items,
`beautiful.gitodo_warning` for those items close to their deadline and
`beautiful.gitodo_outdated` is the color of outdated items.


Utility functions
=================

I'll only explain the more complex functions. See the source code for
the others.

## menu\_clients\_current\_tags
Similar to `awful.menu.clients()`, but this menu only shows the clients
of currently visible tags. Use it like this:

	globalkeys = awful.util.table.join(
	    ...
	    awful.key({ "Mod1" }, "Tab", function()
	        awful.menu.menu_keys.down = { "Down", "Alt_L", "Tab", "j" }
	        awful.menu.menu_keys.up = { "Up", "k" }
	        vain.util.menu_clients_current_tags({ width = 350 }, { keygrabber = true })
	    end),
	    ...
	)

## magnify\_client
Set a client to floating and resize it in the same way the "magnifier"
layout does it. Place it on the "current" screen (derived from the mouse
position). This allows you to magnify any client you wish, regardless of
the currently used layout. Use it with a client keybinding like this:

	clientkeys = awful.util.table.join(
		...
		awful.key({ modkey, "Control" }, "m", vain.util.magnify_client),
		...
	)

If you want to "de-magnify" it, just reset the clients floating state to
`false` (hit `Mod`+`CTRL`+`Space`, for example).
