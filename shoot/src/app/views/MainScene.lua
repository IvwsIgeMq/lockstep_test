
local MainScene = class("MainScene", cc.load("mvc").ViewBase)
local GameView            = import(".GameView")
local JoystickWithAngle   = import(".JoystickWithAngle")
local ControllView        = import(".ControllView")
local MiniMapView         = import(".MiniMapView")
local tcp         = import("..net.tcp")
require("socket")

function MainScene:onCreate()
    print("MainScene:onCreate")
    self.OrderScene = {max=100}
end

function MainScene:onUpdate (dt)
        self.world:step(0)
        self.gameView:viewUpdate(dt,self.world,self.forwardTime)

end



function MainScene:showWithScene(transition, time, more)
    self:setVisible(true)
    local scene = cc.Scene:createWithPhysics()
    scene:addChild(self)
    self.time = 0
    self.syncOK = false
    self.scene = scene
    local t = tcp.new()
    self.tcp = t
    local gameView = GameView:create(t)
    self.gameView = gameView
    local ndBg = cc.Sprite:create("bg.jpg")
    ndBg:setAnchorPoint( cc.p(0,0) )
    ndBg:setPosition( cc.p(0,0) )
    self.scene:addChild(ndBg)
    gameView:setBg(ndBg)
    self.scene:addChild(gameView)
    self.forwardTime  = 0
    display.runScene(scene, transition, time, more)
    self.world = scene:getPhysicsWorld()
    -- 设重力
    self.world:setGravity( cc.p(0, -1500) )

    self.world:setSubsteps(20)
    self.world:setAutoStep(false)
    -- 显示刚体边缘
    if true then
      -- self.world:setDebugDrawMask(cc.PhysicsWorld.DEBUGDRAW_ALL)
    else
        self.world:setDebugDrawMask(cc.PhysicsWorld.DEBUGDRAW_NONE)
    end


    local JoystickWithAngle = JoystickWithAngle.new()
    JoystickWithAngle:setCallbackFunc( function()
            local type = 2
            if JoystickWithAngle.m_length == 0 and JoystickWithAngle.m_angle == 0 then
                type = 4
            end
            local time = socket.gettime() --毫秒
            gameView.sendCommand[type] = {JoystickWithAngle.m_angle,JoystickWithAngle.m_length}
    end)

    self.forwardTime = 0.06
    self.logic_frame = 1
    self.view_frame = 1
    self.command_list ={}
    self.last_time = socket.gettime()
    t.onMessage = function(data)
        local json = require("json")
        local info = json.decode(data)
      --   print("data",data)
        if info.type == 1  then
           if not self.syncOK then
             return
           end
            local tt =  socket.gettime()
            -- print("self.tcp.rttvalue= ",self.tcp.rttvalue,"self.tcp.rttvalue*3",self.tcp.rttvalue*3,"tt- self.last_time =" ,tt- self.last_time ,"(tt- self.last_time -0.06))",(tt- self.last_time -0.06))
            -- self.tcp.rttvalue  = (self.tcp.rttvalue*3+(tt- self.last_time -0.06))/4
            -- if self.tcp.rttvalue < tt- self.last_time -0.06 then
            --    self.tcp.rttvalue = tt- self.last_time -0.06
            -- end
            print("tick",(tt- self.last_time)*1000)
               self.last_time = tt
            local time = 0
            local len = #gameView.serverFrameKeyLIst
            if len <= 1 then
                  time = tt+0.1
            elseif len <10 then
               time = gameView.serverFrameKeyLIst[#gameView.serverFrameKeyLIst].time +self.forwardTime
            else
               time = gameView.serverFrameKeyLIst[#gameView.serverFrameKeyLIst].time
            end
            table.insert(gameView.serverFrameKeyLIst,{time =time ,frame = self.logic_frame})
            -- gameView:updateLogic(self.world,self.forwardTime,self.logic_frame)
            self.logic_frame = self.logic_frame +1
            -- self.tcp:sendMessage(-100,{time = socket.gettime()})
        elseif info.type == 0 then -- 创建自身
            self.logic_frame = info.logic_frame
            self.ID = info.ID
            t.ID = info.ID
            print("创建人物",info.ID)
            gameView:addHero({ID= info.ID})
            local snapshot = gameView:makeSnapshot(self.logic_frame) -- 统计当前状态 用来同步给其他新进的玩家
            self.tcp:sendMessage(-4,snapshot)
        elseif info.type == -2 then  --同步已经在线的玩家和怪物
              gameView:setSnapshot(info.object)
               for i=self.logic_frame,info.object.logic_frame do -- lua for 会执行到
                   gameView:updateLogic(self.world,self.forwardTime,self.logic_frame)
                   self.logic_frame = i
               end
              print("同步已经在线的玩家",self.logic_frame,info.object.logic_frame)
            self.syncOK  = true
        elseif info.type == -3 then -- 移除玩家
            gameView:removeHero(info.ID)
         elseif info.type == -4 then  --新玩家进入
            print("新玩家进入")
            local snapshot = gameView:makeSnapshot(self.logic_frame) -- 统计当前状态 用来同步给其他新进的玩家
            self.tcp:sendMessage(-2,snapshot)
            gameView:setSnapshot(info.object) --生成新玩家
        elseif info.type == -100 then --测延时

           local now = socket.gettime()
           local rtt =  now - info.data.time
           if sef.tcp.rttvalue <  (rtt -self.tcp.rtt ) then
             sef.tcp.rttvalue =  (rtt -self.tcp.rtt )
          end
           self.tcp.rtt = (self.tcp.rtt +rtt)/2


        else
         --   print(data)
            local hero = gameView:getHero(info.ID)
            hero:addCommand(info,self.logic_frame )
        end
    end


    self.tcp:connect()
    self.scene:addChild(JoystickWithAngle,self.OrderScene['max'])
    local controllView = ControllView:create(gameView,t)
    self.scene:addChild(controllView,100)

    --小地图
    local mimiMap = MiniMapView:create(gameView)
    self.scene:addChild(mimiMap,3)


    self.scene:addChild(t)

    self.scene:onUpdate(function (...)
        self:onUpdate(...)
    end)
    return self
end







return MainScene
