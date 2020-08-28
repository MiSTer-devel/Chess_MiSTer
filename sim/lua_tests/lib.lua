package.path = package.path .. ";./../lualib/?.lua"
package.path = package.path .. ";./../luatools/?.lua"
require("vsim_comm")

function reset()
   reg_set_connection(0x81, DUMMYREG)
   wait_ns(10000)
   reg_set_connection(0x80, DUMMYREG)
   wait_ns(100000)
end

function press_button(button)
   local value = 0x80
   if (button == "up")     then value = value + 0x02 end
   if (button == "down")   then value = value + 0x04 end
   if (button == "left")   then value = value + 0x08 end
   if (button == "right")  then value = value + 0x10 end
   if (button == "action") then value = value + 0x20 end
   if (button == "cancel") then value = value + 0x40 end
   reg_set_connection(value, DUMMYREG)
   wait_ns(1000)
   reg_set_connection(0x80, DUMMYREG)
   if (button == "action") then
      wait_ns(1000)
   else
      wait_ns(10000)
   end
end

function goto_field(x, y)
   for i = 0, 6 do
      press_button("up")
      press_button("left")
   end
   for i = 0, (x - 1) do
      press_button("right")
   end
   for i = 0, (y - 1) do
      press_button("down")
   end
end

function select_field(x, y)
   goto_field(x, y)
   press_button("action")
end

function move(fromX, fromY, toX, toY)
   goto_field(fromX, fromY)
   press_button("action")
   goto_field(toX, toY)
   press_button("action")
end
