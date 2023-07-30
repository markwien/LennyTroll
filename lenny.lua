--[[
It's Lenny in Lua
--]]

local path = '/usr/local/freeswitch/sounds/lenny/';
local counter_mainloop = 1;
local counter_noinput  = 1;
local counter_consec_noinput = 0;

function get_filename (aType, aNumber)
   local file = path .. aType .. '/' .. aNumber .. '.raw';
   local fd = io.open(file, "r");
   if fd == nil then
      file = path .. aType .. '/' .. aNumber .. '.gsm'; 
   end
   io.close(fd);
   return file;
end

function wait_for_silence(aTimeoutIncrement) 
   if aTimeoutIncrement == nil then
      aTimeoutIncrement = 2000;
   end
   freeswitch.consoleLog( 'DEBUG', "ENTER wait_for_silence " .. aTimeoutIncrement .. "\n" );
   if session:ready() ~= true then
      return false;
   end
   session:setVariable("wait_for_silence_timeout" , "");
   session:setVariable("wait_for_silence_listenhits", "0");
   session:setVariable("wait_for_silence_silence_hits", "0" );
   session:execute( "wait_for_silence", "300 30 5 " .. aTimeoutIncrement);

   local timeout = tonumber(session:getVariable("wait_for_silence_timeout"));
   local speech  = tonumber(session:getVariable("wait_for_silence_listenhits"));
   local silence = tonumber(session:getVariable("wait_for_silence_silence_hits"));

   freeswitch.consoleLog( 'DEBUG', "Speech : " .. speech .. " Silence : " .. silence .. "\n" );
   if speech > 20 then
      wait_for_silence( aTimeoutIncrement );
      return true;
   else
      return false;
   end
end

function play_next_mainloop ()
   session:execute( "playback", get_filename( 'mainloop', counter_mainloop ) );
   counter_mainloop = counter_mainloop + 1;
   local fd = io.open( get_filename( 'mainloop', counter_mainloop ) , "r");
   if fd == nil then 
      counter_mainloop = 1;
   end
   counter_consec_noinput = 0;
   io.close(fd);
   return 2000;
end

function play_next_noinput ()
   session:execute("playback", get_filename( 'mainloop', counter_mainloop ) );
   counter_noinput = counter_noinput + 1; 
   counter_consec_noinput = counter_consec_noinput + 1;
   local fd = io.open( get_filename( 'noinputloop', counter_noinput ) , "r");
   if fd ~= nil then
      counter_noinput = 1;
   end
   if counter_consec_noinput > 3 then
      counter_mainloop = 1;
   end
   io.close(fd);
   return 3200;
end

session:answer();
session:execute( "playback", get_filename( 'greeting', 1 ) );
local SilenceTimeout = 4000;
while session:ready() == true do
   if wait_for_silence( SilenceTimeout ) ~= true then
      SilenceTimeout = play_next_noinput();
   else
      SilenceTimeout = play_next_mainloop();
   end
end
