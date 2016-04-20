
local tcp              = class("tcp", cc.Node)
local Net = require("Net")
local json = require("json")
function tcp:ctor()
    StartNodeTimer(self, function () self:update() end, 0.0)
    self.sock = Net.Net("kcp")
    self.onMessage = function () end
    self.rtt  = 0
end


function tcp:connect (args)
   print("create tcp","218.107.220.124", 8010)
   --self.sock:connect("192.168.62.180", 8014)
    self.sock:connect("127.0.0.1",8010)
end

function tcp:update(dt)
   local data =self.sock:recv()
   while data  do
       print("data",data)
      if data == 'connected' then
         local str = json.encode({type=0})
         self.sock:send(str)
      else
         self.onMessage(data)
      end
      data = self.sock:recv()
   end
end

function tcp:sendMessage(cmd,data)
   info = {}
	info.ID = self.ID
   info.data = data
   info.type = cmdq
	local json_str = json.encode(info)
    self.sock:send(json_str)
end



return tcp
