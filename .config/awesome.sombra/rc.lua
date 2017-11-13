--[[

     Credits and thanks to:
     github.com/copycat-killer

--]]

-- {{{ Required libraries
local gears         = require("gears")
local awful         = require("awful")
                      require("awful.autofocus")
local wibox         = require("wibox")
local beautiful     = require("beautiful")
local naughty       = require("naughty")
local lain          = require("lain")
--local menubar       = require("menubar")
local freedesktop   = require("freedesktop")
local hotkeys_popup = require("awful.hotkeys_popup").widget
-- }}}

-- {{{ Error handling
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Autostart applications
local function run_once(cmd)
  findme = cmd
  firstspace = cmd:find(" ")
  if firstspace then
     findme = cmd:sub(0, firstspace-1)
  end
  awful.spawn.with_shell(string.format("pgrep -u $USER -x %s > /dev/null || (%s)", findme, cmd))
end

run_once("xset -b")
run_once("unclutter -root")
run_once("urxvtd -q -f -o &")
run_once("synapse")
run_once("pa-applet")
run_once("cbatticon")
run_once("compton &")
-- run_once("xflux -l 21 120")
run_once("conky &")
-- run_once("ss-qt5")
run_once("redshift-gtk")
run_once("xscreensaver -no-splash")
run_once("fcitx-autostart")
run_once("nm-applet")
-- run_once("gnome-power-manager")
-- }}}

-- {{{ Variable definitions
-- beautiful init
beautiful.init(os.getenv("HOME") .. "/.config/awesome/theme.lua")

-- common
local modkey     = "Mod4"
local altkey     = "Mod1"
local terminal   = "urxvt"
local editor     = "vim"

-- user defined
local browser    = os.getenv("BROWSER")
local tagnames   = { " term ", " file ", " net ", " doc ", " dev ", " media ", " float " }

-- table of layouts to cover with awful.layout.inc, order matters.
local initialLayouts = {
  awful.layout.suit.tile,
  awful.layout.suit.tile,
  awful.layout.suit.tile,
  awful.layout.suit.tile,
  awful.layout.suit.tile,
  awful.layout.suit.tile,
  awful.layout.suit.floating,
}

awful.layout.layouts = {
  awful.layout.suit.tile,
  awful.layout.suit.fair,
  awful.layout.suit.tile.bottom,
  -- awful.layout.suit.fair.horizontal,
  awful.layout.suit.floating,
  -- awful.layout.suit.floating,
  -- awful.layout.suit.tile,
  -- awful.layout.suit.tile.left,
  -- awful.layout.suit.tile.bottom,
  -- awful.layout.suit.tile.top,
  -- awful.layout.suit.fair,
  -- awful.layout.suit.fair.horizontal,
  -- awful.layout.suit.spiral,
  -- awful.layout.suit.spiral.dwindle,
  -- awful.layout.suit.max,
  -- awful.layout.suit.max.fullscreen,
  -- awful.layout.suit.magnifier,
  -- awful.layout.suit.corner.nw,
  -- awful.layout.suit.corner.ne,
  -- awful.layout.suit.corner.sw,
  -- awful.layout.suit.corner.se,
}

-- lain
lain.layout.termfair.nmaster        = 3
lain.layout.termfair.ncol           = 1
lain.layout.termfair.center.nmaster = 3
lain.layout.termfair.center.ncol    = 1
-- }}}



-- {{{ Helper functions
local function client_menu_toggle_fn()
    local instance = nil

    return function ()
        if instance and instance.wibox.visible then
            instance:hide()
            instance = nil
        else
            instance = awful.menu.clients({ theme = { width = 250 } })
        end
    end
end

function get_memory_usage()
    local ret = {}
    for l in io.lines('/proc/meminfo') do
        local k, v = l:match("([^:]+):%s+(%d+)")
        ret[k] = tonumber(v)
    end
    return ret
end

function string_split(string, pat, plain)
    local ret = {}
    local pos = 0
    local start, stop
    local t_insert = table.insert
    while true do
        start, stop = string:find(pat, pos, plain)
        if not start then
            t_insert(ret, string:sub(pos))
            break
        end
        t_insert(ret, string:sub(pos, start-1))
        pos = stop + 1
    end
    return ret
end

function parse_key(string)
    local t_insert = table.insert
    local parts = string_split(string, '[+-]')
    local last = table.remove(parts)
    local ret = {}
    for _, p in ipairs(parts) do
        p_ = p:lower()
        local m
        if p_ == 'ctrl' then
            m = 'Control'
        elseif p_ == 'alt' then
            m = 'Mod1'
        else
            m = p
        end
        t_insert(ret, m)
    end
    return ret, last
end

_key_map_cache = {}
function map_client_key(client, key_map)
    local t_insert = table.insert
    local keys
    if _key_map_cache[key_map] then
        keys = awful.util.table.join(client:keys(), _key_map_cache[key_map])
    else
        keys = {}
        for from, to in pairs(key_map) do
            local mod, key = parse_key(from)
            local key = awful.key(mod, key, function(c)
                awful.util.spawn(
                'xdotool key --clearmodifiers --window '
                .. c.window .. ' ' .. to)
            end)
            for _, k in ipairs(key) do
                t_insert(keys, k)
            end
        end
        _key_map_cache[key_map] = keys
        keys = awful.util.table.join(client:keys(), keys)
    end
    client:keys(keys)
end
-- }}}


-- {{{ Menu
myawesomemenu = {
    { "hotkeys", function() return false, hotkeys_popup.show_help end },
    { "manual", terminal .. " -e man awesome" },
    { "edit config", string.format("%s -e %s %s", terminal, editor, awesome.conffile) },
    { "restart", awesome.restart },
    { "quit", function() awesome.quit() end }
}
mymainmenu = freedesktop.menu.build({
    icon_size = beautiful.menu_height or 16,
    before = {
        { "Awesome", myawesomemenu, beautiful.awesome_icon },
        -- other triads can be put here
    },
    after = {
        { "Open terminal", terminal },
        -- other triads can be put here
    }
})



-- {{{ Menu
--myawesomemenu = {
--  { "hotkeys", function() return false, hotkeys_popup.show_help end},
--  { "restart", awesome.restart },
--  { "quit", function() awesome.quit() end}
--}

--mymainmenu = awful.menu({
--  items = {
--    { "awesome", myawesomemenu, beautiful.awesome_icon }
--  }
--})

--menubar.utils.terminal = terminal -- Set the Menubar terminal for applications that require it
-- }}}

-- {{{ Wibox
local markup = lain.util.markup
local separators = lain.util.separators

local function infoText(widget, value, unit, label)
  widget:set_markup(
    " "
    .. label
    .. " "
    .. markup("#BF616Aaa", "" .. value .. "")
    -- .. markup("#BF616Aaa", "<b>" .. value .. "</b>")
    .. markup("#BF616A99", unit)
    .. " "
  )
end

local mytextclock = lain.widgets.abase({
    timeout  = 60,
    cmd      = " date +'%a %d %b %R'",
    trim     = true,
    settings = function()
        words = {}
        for word in output:gmatch("%w+") do table.insert(words, word) end
        widget:set_markup(markup("#65737e",
          " "
          .. words[1]
          .. " "
          .. words[2]
          .. " "
          .. words[3]
          .. " "
          .. markup("#ddd", words[4] .. ":" .. words[5])
          .. ""
        ))
    end
})

-- calendar
lain.widgets.calendar.attach(mytextclock, {
    notification_preset = {
        font = beautiful.font,
        fg   = beautiful.fg_widget,
        bg   = beautiful.bg_widget
    }
})

-- MEM
local memicon = wibox.widget.imagebox(beautiful.widget_mem)
local memwidget = lain.widgets.mem({
    settings = function()
      infoText(widget, mem_now.used, "MB", "mem")
    end
})

-- CPU
local cpuicon = wibox.widget.imagebox(beautiful.widget_cpu)
local cpuwidget = lain.widgets.cpu({
    settings = function()
        infoText(widget, cpu_now.usage, "%", "cpu")
    end
})

-- Coretemp
local tempicon = wibox.widget.imagebox(beautiful.widget_temp)
local tempwidget = lain.widgets.temp({
    settings = function()
        infoText(widget, coretemp_now, "°C", "temp")
    end
})

-- Systray
local systray = wibox.widget.systray()
systray.set_base_size(20)

-- ALSA volume
local volicon = wibox.widget.imagebox(beautiful.widget_vol)
local volume = lain.widgets.alsa({
    settings = function()
        if volume_now.status == "off" then
            volicon:set_image(beautiful.widget_vol_mute)
        elseif tonumber(volume_now.level) == 0 then
            volicon:set_image(beautiful.widget_vol_no)
        elseif tonumber(volume_now.level) <= 50 then
            volicon:set_image(beautiful.widget_vol_low)
        else
            volicon:set_image(beautiful.widget_vol)
        end

        infoText(widget, volume_now.level, "%", "vol")
    end
})

-- Net
local neticon = wibox.widget.imagebox(beautiful.widget_net)
neticon:buttons(awful.util.table.join(awful.button({ }, 1, function () awful.util.spawn_with_shell(iptraf) end)))
local netwidget = lain.widgets.net({
    settings = function()
        widget:set_markup(markup("#7AC82E", " " .. net_now.received)
                          .. "" ..
                          markup("#46A8C3", " " .. net_now.sent .. " "))
    end
})

-- Separators
local spr     = wibox.widget.textbox(' ')
local arrl_dl = separators.arrow_left(beautiful.bg_focus, "alpha")
local arrl_ld = separators.arrow_left("alpha", beautiful.bg_focus)

-- Create a wibox for each screen and add it
local taglist_buttons = awful.util.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

local tasklist_buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() and c.first_tag then
                                                      c.first_tag:view_only()
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, client_menu_toggle_fn()),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Quake application
    s.quake = lain.util.quake({ app = terminal })

    -- Wallpaper
    set_wallpaper(s)

    -- Tags
    awful.tag(tagnames, s, initialLayouts)

    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s, height = 30 })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            s.mytaglist,
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            wibox.layout.margin(systray, 5, 0, 5, 0),
            volume,
            memwidget,
            cpuwidget,
            tempwidget,
            netwidget,
            mytextclock,
            --                                 L  R  T  B
            wibox.layout.margin(s.mylayoutbox, 5, 2, 1, 2),
        },
    }
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(

    -- Sound
    awful.key({ }, "XF86AudioRaiseVolume",
      function () awful.util.spawn("amixer set Master 5%+", false) end),
    awful.key({ }, "XF86AudioLowerVolume",
      function () awful.util.spawn("amixer set Master 5%-", false) end),

    -- Tag browsing
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Tab", awful.tag.history.restore,
              {description = "go back", group = "tag"}),

    -- By direction client focus
    awful.key({ modkey }, "t",
        function()
            awful.client.focus.bydirection("down")
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey }, "n",
        function()
            awful.client.focus.bydirection("up")
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey }, "h",
        function()
            awful.client.focus.bydirection("left")
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey }, "s",
        function()
            awful.client.focus.bydirection("right")
            if client.focus then client.focus:raise() end
        end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "t", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "n", function () awful.client.swap.byidx( -1)    end),

    -- Resizing & Moving (for floating client)
   awful.key({ modkey, "Shift" }, "Left",  function () awful.client.moveresize( 0, 0, -1, 0) end),
   awful.key({ modkey, "Shift" }, "Right", function () awful.client.moveresize( 0, 0,  1, 0) end),
   awful.key({ modkey, "Shift" }, "Up",    function () awful.client.moveresize( 0, 0, 0, -1) end),
   awful.key({ modkey, "Shift" }, "Down",  function () awful.client.moveresize( 0, 0, 0,  1) end),
   awful.key({ modkey, "Control" }, "Down",  function () awful.client.moveresize(  0,  1,   0,   0) end),
   awful.key({ modkey, "Control" }, "Up",    function () awful.client.moveresize(  0, -1,   0,   0) end),
   awful.key({ modkey, "Control" }, "Left",  function () awful.client.moveresize(-1,   0,   0,   0) end),
   awful.key({ modkey, "Control" }, "Right", function () awful.client.moveresize( 1,   0,   0,   0) end),

    awful.key({ altkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),

    -- Show/Hide Wibox
    awful.key({ modkey }, "b", function ()
        for s in screen do
            s.mywibox.visible = not s.mywibox.visible
        end
    end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),

    awful.key({ modkey, "Control"    }, "s",     function () awful.tag.incmwfact( 0.005)    end),
    awful.key({ modkey, "Control"    }, "h",     function () awful.tag.incmwfact(-0.005)    end),
    awful.key({ modkey, "Control"    }, "t",     function () awful.client.incwfact( 0.02)    end),
    awful.key({ modkey, "Control"    }, "n",     function () awful.client.incwfact(-0.02)    end),

    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
              {description = "select previous", group = "layout"}),

    -- Dropdown application
    awful.key({ modkey, }, "z", function () awful.screen.focused().quake:toggle() end),

    -- Widgets popups
    awful.key({ altkey, }, "c", function () lain.widgets.calendar.show(1) end),

    -- ALSA volume control
    awful.key({ altkey }, "Up",
        function ()
            os.execute(string.format("amixer set %s 1%%+", volume.channel))
            volume.update()
        end),
    awful.key({ altkey }, "Down",
        function ()
            os.execute(string.format("amixer set %s 1%%-", volume.channel))
            volume.update()
        end),

    -- User programs
    awful.key({ modkey }, "c", function () awful.spawn(browser) end),

    -- Lock screen
    awful.key({ modkey }, "l", function () awful.util.spawn("slock", false) end,
              {description = "lock the screen", group = "launcher"}),

    -- Prompt
    awful.key({ modkey }, "r", function () awful.util.spawn("rofi -show run", false) end,
              {description = "run rofi prompt box", group = "launcher"})

)

clientkeys = awful.util.table.join(

  awful.key({ modkey }, "f",
    function (c)
      c.fullscreen = not c.fullscreen
      c:raise()
    end,
    { description = "toggle fullscreen", group = "client" }
  ),

  awful.key({ modkey }, "w",
    function (c)
      c.focusable = false
    end,
    { description = "make client unfocusable", group = "client" }
  ),

  awful.key({ modkey, "Shift" }, "c",
    function (c)
      c:kill()
    end,
    { description = "close", group = "client" }
  ),

  awful.key({ modkey, "Control" }, "space",
    awful.client.floating.toggle,
    { description = "toggle floating", group = "client" }
  ),

  awful.key({ modkey, "Control" }, "Return",
    function (c)
      c:swap(awful.client.getmaster())
    end,
    { description = "move to master", group = "client" }
  ),

  awful.key({ modkey }, "p",
    function (c)
      c.ontop = not c.ontop
    end,
    { description = "toggle keep on top", group = "client" }
  )

)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}


-- {{{ Rules
local old_filter = awful.client.focus.filter
function myfocus_filter(c)
  if old_filter(c) then
    -- TM.exe completion pop-up windows
    if (c.instance == 'TM.exe' or c.instance == 'QQ.exe' or c.instance == 'TIM.exe')
        and c.above and c.skip_taskbar
        and (c.type == 'normal' or c.type == 'dialog') -- dialog type is for tooltip windows
        and (c.class == 'TM.exe' or c.class == 'QQ.exe' or c.class == 'TIM.exe') then
        return nil
    -- This works with tooltips and some popup-menus
    elseif c.class == 'Wine' and c.above == true then
      return nil
    elseif (c.class == 'Wine' or c.class == 'QQ.exe')
      and c.type == 'dialog'
      and c.skip_taskbar == true
      and c.size_hints.max_width and c.size_hints.max_width < 160
      then
      -- for popup item menus of Photoshop CS5
      return nil
    -- popups for Settings page in Firefox
    elseif c.skip_taskbar and c.instance == 'Popup' and c.class == 'Firefox' then
      return nil
    elseif c.class == 'Key-mon' then
      return nil
    else
      return c
    end
  end
end
awful.client.focus.filter = myfocus_filter
awful.rules.rules = {
  -- All clients will match this rule.
  {
    rule = { },
    properties = { border_width = beautiful.border_width,
                   border_color = beautiful.border_normal,
                   focus = awful.client.focus.filter,
                   raise = true,
                   focus = myfocus_filter,
                   keys = clientkeys,
                   buttons = clientbuttons,
                   screen = awful.screen.preferred,
                   placement = awful.placement.no_overlap+awful.placement.no_offscreen,
                   size_hints_honor = false
    }
  }, {
    rule = { class = "Screenruler" },
    properties = {
      floating = true,
      focus = false,
      border_width = 0,
    }
  }, {
    rule = { role = "FullScreenHtop" },
    properties = {
      maximized_horizontal = true,
      maximized_vertical = true,
    }
  }, {
    rule = { class = "Firefox", instance = "firefox" },
    properties = { floating = true }
  }, {
    -- popup from FireGestures with mouse wheel
    rule = {
      class = "Firefox",
      skip_taskbar = true,
      instance = 'Popup',
    },
    properties = {
      floating = true,
      border_width = 0,
    }
  }, {
    rule = { class = "Wireshark", name = "Wireshark" }, -- wireshark startup window
    properties = { floating = true }
  }, {
    rule_any = {
      instance = {
          'TM.exe', 'QQ.exe', 'TIM.exe',
          'QQExternal.exe', -- QQ 截图
          'deepin-music-player',
      },
    },
    properties = {
      -- This, together with myfocus_filter, make the popup menus flicker taskbars less
      -- Non-focusable menus may cause TM2013preview1 to not highlight menu
      -- items on hover and crash.
      -- Also for deepin-music, removing borders and floating pop-ups
      focusable = true,
      floating = true,
      border_width = 0,
    }
  }, {
    rule = {
      -- mainly for picpick
      class = "Wine",
      above = true,
    },
    properties = {
      floating = true,
      border_width = 0,
    }
  }, {
    rule = {
      -- for WinHex
      class = "Wine",
      instance = "WinHex.exe",
      name = "数据解释器",
    },
    properties = {
      floating = true,
      border_width = 0,
    }
  }, {
    rule = {
      class = "Wine",
      skip_taskbar = true,
      type = "dialog",
    },
    callback = function (c)
      if c.size_hints.max_width and c.size_hints.max_width < 160 then
        -- for popup item menus of Photoshop CS5
        c.border_width = 0
      end
    end,
  }, {
    rule = {
      -- 白板的工具栏
      name = 'frmPresentationTool',
      instance = 'picpick.exe',
    },
    properties = {
      ontop = true,
    }
  }, {
    rule_any = {
      class = {
        'Flashplayer', 'Gnome-mplayer', 'Totem',
        'Eog', 'feh', 'Display', 'Gimp', 'Gimp-2.6',
        'Screenkey', 'TempTerm', 'AliWangWang',
        'Dia', 'Pavucontrol', 'Stardict', 'XEyes', 'Skype',
        'Xfce4-appfinder',
        "/usr/lib/firefox/plugin-container",
      },
      name = {
        '文件传输', 'Firefox 首选项', '暂存器', 'Keyboard',
      },
      instance = {
        'Browser', -- 火狐的关于对话框
        'MATLAB', -- splash
      },
      role = {
        'TempTerm',
      },
    },
    properties = {
      floating = true,
    }
  }, {
    rule = {
      instance = "xfce4-notifyd",
    },
    properties = {
      border_width = 0,
      focus = false,
    }
  }, {
    rule = {
      class = "Key-mon",
    },
    properties = {
      border_width = 0,
      focus = false,
      focusable = false,
      opacity = 0.65,
      sticky = true,
    }
  },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
qqad_blocked = 0
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::leave", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and myfocus_filter(c) then
            client_unfocused = c.window
        end
    end)

    c:connect_signal("mouse::enter", function(c)
    -- 如果离开后又进入同一窗口则忽略，这解决了由于输入条而造成的焦点移动
        if client_unfocused ~= c.window
            and awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and myfocus_filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    if c.name and c.name:match('^FlashGot') then
        c.minimized = true
        -- naughty.notify({title="FlashGot", text="OK"})
    elseif c.instance == 'empathy-chat' or (c.role == 'conversation' and c.class == 'Pidgin') then
        local t
        t = c:tags()
        if #t == 1 and t[1] == tags[mouse.screen][6] then
            awful.util.spawn_with_shell('sleep 0.1 && fcitx-remote -T', false)
        else
            awful.client.movetotag(tags[mouse.screen][6], c)
        end
    --elseif c.class == 'qTox' then
    --    map_client_key(c, emacs_keys)
    --elseif c.class == 'Evince' then
    --    map_client_key(c, evince_keys)
    elseif c.class and c.class:match('^Minecraft ') then
        local keys = c:keys()
        local mykey = awful.key({'Control'}, 't', function(c)
            awful.util.spawn('zhinput')
        end)
        keys = awful.util.table.join(keys, mykey)
        c:keys(keys)
    elseif c.name == '中文输入' then
        awful.util.spawn_with_shell('sleep 0.05 && fcitx-remote -T', false)
    elseif c.instance == 'QQ.exe' then
        -- naughty.notify({title="新窗口", text="名称为 ".. c.name .."，class 为 " .. c.class:gsub('&', '&amp;') .. " 的窗口已接受管理。", preset=naughty.config.presets.critical})

        if c.name and (c.name == '腾讯网迷你版' or c.name == '京东' or c.name:match('^腾讯.+新闻$')) then
            qqad_blocked = qqad_blocked + 1
            naughty.notify({title="QQ广告屏蔽 " .. qqad_blocked, text="检测到一个符合条件的窗口，标题为".. c.name .."。"})
            c:kill()
        --else
        --    map_client_key(c, tm_keys)
        --    map_client_key(c, emacs_keys)
        end
    elseif c.class == 'MPlayer' or c.class == 'mpv' then
        awful.client.floating.set(c, true)
        awful.placement.centered(c)
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
