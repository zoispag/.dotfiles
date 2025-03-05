-- Initialize a counter to track shift presses
local shiftPressCount = 0
local shiftPressTimer = nil

-- Function to reset the counter
local function resetShiftCount()
   shiftPressCount = 0
   if shiftPressTimer then
       shiftPressTimer:stop()
       shiftPressTimer = nil
   end
end

hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function(event)
   local flags = event:getFlags()
   local keyCode = event:getKeyCode()

   if flags['shift'] and keyCode == hs.keycodes.map["shift"] then
      shiftPressCount = shiftPressCount + 1
      print("Shift pressed: " .. shiftPressCount)  -- Debug: Print the count

      -- If shift is pressed 3 times
      if shiftPressCount == 3 then
         hs.eventtap.keyStrokes("```")  -- Type three backticks
         print("Three shifts detected! Typing backticks...")  -- Debug message
         resetShiftCount()  -- Reset the counter after typing
      else
         -- Set a timer to reset the counter after 0.5 seconds if no further shift presses
         if shiftPressTimer then
            shiftPressTimer:stop()
         end
         shiftPressTimer = hs.timer.delayed.new(0.5, resetShiftCount)
         shiftPressTimer:start()
      end
   end

   return false
end):start()

print("Hammerspoon script loaded!")  -- Debug message
