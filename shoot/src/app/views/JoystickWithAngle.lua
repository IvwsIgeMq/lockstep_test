--
-- Created by hdj.
-- User: xm4399
-- Date: 15/8/14
-- Time: 上午8:32
-- To change this template use File | Settings | File Templates.
--

local JoystickWithAngle = class("JoystickWithAngle",function(...)
    return cc.LayerColor:create(cc.c4b(255,0,0,0),display.width*0.5,display.height)
end)
JoystickWithAngle.DIRECT = {
    ["LEFTUP"] = 1,
    ["RIGHTUP"] = 2,
    ["LEFTBOTTON"] = 3,
    ["RIGHTBOTTON"] = 4,
}

function JoystickWithAngle:ctor()
    self.m_diff = {["x"] = 40,["y"] = 40}
    self.R = 0 -- 大圆半径
    self.m_RPos = nil -- 大圆中心位置
    self.r = 0 -- 小圆半径
    self.d = 0 -- 九个相同正方形的边长
    self.O = cc.p(0,0) -- 中心点
    self.joystick = nil -- 摇杆控制
    self.m_ifTouch = false -- 是否触摸到摇杆
    self.m_ifOutTouch = false -- 是否超出触摸范围
    self.m_ifHaveHandTouch = false
    self.m_angle = 0
    self.m_length = 0
    self.m_callBackFunc = nil
    self.scheduler = cc.Director:getInstance():getScheduler()
    self.schedulerEntry = nil
    self:registerScriptHandler(handler(self,self.onNodeEvent))
    --    加入触摸层
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(handler(self,self.handleTouchBegan),cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(handler(self,self.handleTouchMoved),cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(handler(self,self.handleTouchEnded),cc.Handler.EVENT_TOUCH_ENDED)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
    --    加入遥感
    self.joystickBg = display.newSprite("joystick1.png")
    -- :align(cc.p(0.5,0.5),self.m_diff.x+self.R,self.m_diff.y+self.R)
    :addTo(self)
    self.joystickBg:setOpacity(191)
    self.R = self.joystickBg:getContentSize().width*0.5

    self.m_RPos = cc.p(self.R,self.R)
    self.m_RPos = cc.pAdd(self.m_RPos,self.m_diff)
    self.joystickBg:setPosition(self.m_RPos)
    self.r = self.R/3
    self.d = self.R*2/3
    -- self.O = cc.p(self.m_diff.x+self.R,self.m_diff.y+self.R)
    self.O = self.m_RPos
    --    加入摇杆上面圆圈部分
    self.joystick = display.newSprite("joystick2.png")
    :move(self.O.x,self.O.y)
    :addTo(self)
    --      更新
    self:scheduleUpdate(handler(self,self.update))
end

function JoystickWithAngle:update(dt)
    if self.m_ifTouch then
        if self.m_callBackFunc then
            self.m_callBackFunc()
        end
    end
end

--  退出的时候要把自动更新关闭
function JoystickWithAngle:onNodeEvent(event)
    if "enter" == event then
        self:onEnter()
    elseif "exit" == event then
        self:onExit()
    end
end
function JoystickWithAngle:onEnter()

end
function JoystickWithAngle:onExit()
    self:unscheduleUpdate()
end

function JoystickWithAngle:handleTouchBegan(touch,event)
    if self.m_ifHaveHandTouch then
        return false
    end
    local location = self:convertToNodeSpace(touch:getLocation())
    local rect = cc.rect(0, 0, self:getContentSize().width, self:getContentSize().height)
    if not cc.rectContainsPoint(rect, location) then
        return false
    end
    -- local joystickRect = self.joystick:getBoundingBox()
    -- if cc.rectContainsPoint(joystickRect,location) then
        -- self.m_ifTouch = true
    -- end
    -- location = (math.pow(self.O.x-location.x,2)+math.pow(self.O.y-location.y,2) <=  math.pow(self.R,2)) and location or self:getOutOfRangePos(location)
    -- self.joystick:setPosition(location)
    self.m_ifTouch = true
    self.m_ifHaveHandTouch = true
    self.m_ifOutTouch = false
    self.m_length = 1
    local ifIn = math.pow(self.O.x-location.x,2)+math.pow(self.O.y-location.y,2) <=  math.pow(self.R,2)
    if ifIn then
        self.joystick:setPosition(location)
    else
        -- 分成四个触摸部分
        --      左下
        self.joystick:setPosition(location)
        if cc.rectContainsPoint(cc.rect(0,0,self.m_diff.x+self.R,self.m_diff.y+self.R),location) then
            local x = math.sin(math.rad(45))*self.R
            local y = math.cos(math.rad(45))*self.R
            self.O = cc.pAdd(location,cc.p(x,y))
            self.joystickBg:setPosition(self.O)
        --      右下
        elseif cc.rectContainsPoint(cc.rect(self.m_diff.x+self.R,0,self:getContentSize().width-self.m_diff.x-self.R,self.m_diff.y+self.R),location) then
            local x = math.sin(math.rad(45))*self.R
            local y = math.cos(math.rad(45))*self.R
            self.O = cc.p(location.x-x,location.y+y)
            self.joystickBg:setPosition(self.O)
        --      左上
        elseif cc.rectContainsPoint(cc.rect(0,self.m_diff.y+self.R,self.m_diff.x+self.R,self:getContentSize().width-self.R-self.m_diff.y),location) then
            local x = math.cos(math.rad(45))*self.R
            local y = math.sin(math.rad(45))*self.R
            self.O = cc.p(location.x+x,location.y-y)
            self.joystickBg:setPosition(self.O)
        --      右上
        else
            local x = math.cos(math.rad(45))*self.R
            local y = math.sin(math.rad(45))*self.R
            self.O = cc.p(location.x-x,location.y-y)
            self.joystickBg:setPosition(self.O)
        end
    end



    return true
end

function JoystickWithAngle:handleTouchMoved(touch,event)
    --        判断触摸滑动点是否在摇杆范围内
    -- local location = touch:getLocation()
    -- location = (math.pow(self.O.x-location.x,2)+math.pow(self.O.y-location.y,2) <=  math.pow(self.R,2)) and location or self:getOutOfRangePos(location)
    -- self.joystick:setPosition(location)
    -- self.m_angle = cc.pToAngleSelf(cc.p(location.x-self.O.x,location.y-self.O.y))
    -- self.m_angle = math.deg(self.m_angle)
    local location = self:convertToNodeSpace(touch:getLocation())
    local rect = cc.rect(0, 0, self:getContentSize().width, self:getContentSize().height)
    if not cc.rectContainsPoint(rect, location) or self.m_ifOutTouch then
        self.m_ifTouch = false
        self.m_angle = 0
        self.m_length = 0
        self.m_callBackFunc()
        self.joystickBg:setPosition(self.m_RPos)
        self.joystick:setPosition(self.m_RPos)
        self.m_ifOutTouch = true
        return
    end
    -- local location = self:convertToNodeSpace(touch:getLocation())
    self.joystick:setPosition(location)
    local ifIn = math.pow(self.O.x-location.x,2)+math.pow(self.O.y-location.y,2) <=  math.pow(self.R,2)
    if ifIn then
        local rotateAngle = cc.pToAngleSelf(cc.p(location.x-self.O.x,location.y-self.O.y))
        self.m_angle = math.deg(rotateAngle)
    else
        -- 1 计算旋转的角度
        local rotateAngle = cc.pToAngleSelf(cc.p(location.x-self.O.x,location.y-self.O.y))
        self.m_angle = math.deg(rotateAngle)
        local x = math.cos(rotateAngle)*self.R
        local y = math.sin(rotateAngle)*self.R
        self.O = cc.p(location.x-x,location.y-y)
        self.joystickBg:setPosition(self.O)
    end

    if self.m_angle < 0 then
        self.m_angle = 360+self.m_angle
    end
end

function JoystickWithAngle:handleTouchEnded(touch,event)
    self.m_ifTouch = false
    self.m_ifHaveHandTouch = false
    self.m_angle = 0
    self.m_length = 0
    self.m_callBackFunc()
    self.O = self.m_RPos
    self.joystickBg:setPosition(self.m_RPos)
    self.joystick:setPosition(self.m_RPos)
end

function JoystickWithAngle:setCallbackFunc(func)
    self.m_callBackFunc = func
end

function JoystickWithAngle:getOutOfRangePos(location)
    local angle = cc.pToAngleSelf(cc.p(location.x-self.O.x,location.y-self.O.y))
    local x = self.R*math.cos(angle)
    local y = self.R*math.sin(angle)
    return cc.p(x+self.m_RPos.x,y+self.m_RPos.y)
end

return JoystickWithAngle
