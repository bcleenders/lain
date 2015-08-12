
--[[

     Licensed under GNU General Public License v2 
      * (c) 2015, Dario Gjorgjevski

--]]

local newtimer     = require("lain.helpers").newtimer
local read_pipe    = require("lain.helpers").read_pipe

local wibox        = require("wibox")

local string       = { match = string.match }

local setmetatable = setmetatable

local function worker (args)
   local kbdlayout    = {}
   kbdlayout.widget   = wibox.widget.textbox('')

   local layouts          = args.layouts
   local settings         = args.settings or function () end
   local add_us_secondary = args.add_us_secondary or true
   local idx              = 1
   
   local function run_settings (layout, variant)
      widget = kbdlayout.widget
      kbdlayout_now = { layout=string.match(layout, "[^,]+"), -- Make sure to match the primary layout only.
			variant=variant }
      settings()
   end
   
   function kbdlayout.update ()
      local status = read_pipe('setxkbmap -query')

      run_settings(string.match(status, "layout:%s*([^\n]*)"),
		   string.match(status, "variant:%s*([^\n]*)"))
   end

   function kbdlayout.set (i)
      idx = ((i - 1) % #layouts) + 1 -- Make sure to wrap around as needed.
      local to_execute = 'setxkbmap ' .. layouts[idx].layout

      if add_us_secondary then
	 to_execute = to_execute .. ",us"
      end

      if layouts[idx].variant then
	 to_execute = to_execute .. ' ' .. layouts[idx].variant
      end

      if os.execute(to_execute) then
	 run_settings(layouts[idx].layout, layouts[idx].variant)
      end
   end

   function kbdlayout.next ()
      kbdlayout.set(idx + 1)
   end

   function kbdlayout.prev ()
      kbdlayout.set(idx - 1)
   end

   newtimer("kbdlayout", args.timeout or 10, kbdlayout.update)
   return setmetatable(kbdlayout, { __index = kbdlayout.widget })
end

return setmetatable({}, { __call = function (_, ...) return worker(...) end })
