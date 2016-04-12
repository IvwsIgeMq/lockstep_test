local ControllView = class("ControllView", cc.Layer)


function ControllView:create(gameView,tcp)
    self = ControllView.new(gameView,tcp)
	return self
end

function ControllView:ctor(gameView,tcp )

   	self.gameView = gameView
   	self.tcp = tcp
    print("tcp",tcp)

    local function onTouchBegan(touch, event)

		 local pos = touch:getLocation()
		if pos.y >= 400 then
			gameView.hero:jump()
			return true
		end

		-- if pos.y <= 200 then
			-- gameView.hero:setAttacking(true,pos)
			-- return true
		-- end

		if pos.x <= 480 then
			gameView.hero:setDirection(-1)
			gameView.hero:setMoving(true)

		else
			gameView.hero:setDirection(1)
			gameView.hero:setMoving(true)

		 end

        return true
    end

    local function onTouchMove(touch, event)
    	-- local pos = touch:getLocation()
    	-- gameView.hero:setAttackPos(pos)
    end


    local function onTouchEnd(touch, event)
        	local pos = touch:getLocation()
  	     	if pos.y >= 400 then
		 	return true
		end

		-- if pos.y <= 200 then
			-- gameView.hero:setAttacking(false)
			-- return true
		-- end

		if pos.x <= 480 then
			gameView.hero:setDirection(-1)
			gameView.hero:setMoving(false)

		else
			gameView.hero:setDirection(1)
			gameView.hero:setMoving(false)

		 end
		return true
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchMove,cc.Handler.EVENT_TOUCH_MOVED )
    listener:registerScriptHandler(onTouchEnd,cc.Handler.EVENT_TOUCH_ENDED )
    local eventDispatcher = self:getEventDispatcher()
  --  eventDispatcher:addEventListenerWithFixedPriority(listener, -129)

    local function onNodeEvent(event)
        if event == "exit" then
           self:getEventDispatcher():removeEventListener(listener)
        end
    end

    self:registerScriptHandler(onNodeEvent)

    self:registerBtnEvent()
end

function ControllView:registerBtnEvent()
	local jumpSpr = cc.Sprite:create("jump.png")
    jumpSpr:setPosition(cc.p(880, 90))
    jumpSpr:setScale(1.5)
    self:addChild(jumpSpr, 10)
    local rectJump = cc.rect(826, 36, 108, 108)

    local shootSpr = cc.Sprite:create("shoot.png")
    shootSpr:setPosition(cc.p(730, 90))
    shootSpr:setScale(1.5)
    self:addChild(shootSpr, 10)
    local rectshoot = cc.rect(676, 36, 108, 108)

    local trackSpr = cc.Sprite:create("shoot.png")
    trackSpr:setPosition(cc.p(730, 220))
    trackSpr:setScale(1.5)
    self:addChild(trackSpr, 10)
    local rectTrack = cc.rect(676, 166, 108, 108)

    local moreSpr = cc.Sprite:create("shoot.png")
    moreSpr:setPosition(cc.p(880, 220))
    moreSpr:setScale(1.5)
    self:addChild(moreSpr, 10)
    local rectMore = cc.rect(826, 166, 108, 108)

    local bounceSpr = cc.Sprite:create("shoot.png")
    bounceSpr:setPosition(cc.p(880, 350))
    bounceSpr:setScale(1.5)
    self:addChild(bounceSpr, 10)
    local rectBounce = cc.rect(826, 296, 108, 108)

    local flag = 0

    local function onTouchBegan(touch, event)
        local locationInNode = touch:getLocation()

        if cc.rectContainsPoint(rectJump, locationInNode) then
--        	self.gameView.hero:jump()
            self.tcp:sendMessage(3,{pos = cc.p(self.gameView.hero:getPosition()), data="jump"})
            -- print("logging")

            jumpSpr:setColor(cc.c3b(255, 0, 0))
            flag = 1
            return true
        elseif cc.rectContainsPoint(rectshoot, locationInNode) then
--        	self.gameView.hero:setAttacking(true)
            self.tcp:sendMessage(5,{pos = cc.p(self.gameView.hero:getPosition()),data="attack"})
            shootSpr:setColor(cc.c3b(255, 0, 0))
            flag = 2
            return true
        elseif cc.rectContainsPoint(rectTrack, locationInNode) then
--            self.gameView.hero:setAttacking(true,2)
            self.tcp:sendMessage(6,{pos = cc.p(self.gameView.hero:getPosition()),data="attack2"})
            trackSpr:setColor(cc.c3b(255, 0, 0))
            flag = 3
            return true
        elseif cc.rectContainsPoint(rectMore, locationInNode) then
--            self.gameView.hero:setAttacking(true,3)
            self.tcp:sendMessage(7,{pos = cc.p(self.gameView.hero:getPosition()),data="attack3"})
            moreSpr:setColor(cc.c3b(255, 0, 0))
            flag = 4
            return true
        elseif cc.rectContainsPoint(rectBounce, locationInNode) then
--            self.gameView.hero:setAttacking(true,4)
            self.tcp:sendMessage(8,{pos = cc.p(self.gameView.hero:getPosition()),data="attack4"})
            bounceSpr:setColor(cc.c3b(255, 0, 0))
            flag = 5
            return true
        end

        return true
    end


    local function onTouchEnded(touch, event)
    	local location = touch:getLocation()
    	if location.x > ConstScreenWidth/2 then
	    	if flag == 1 then
	        	jumpSpr:setColor(cc.c3b(255, 255, 255))
	        elseif flag == 2 then
--	        	self.gameView.hero:setAttacking(false)
	            shootSpr:setColor(cc.c3b(255, 255, 255))
            elseif flag == 3 then
--                self.gameView.hero:setAttacking(false)
                trackSpr:setColor(cc.c3b(255, 255, 255))
            elseif flag == 4 then
--                self.gameView.hero:setAttacking(false)
                moreSpr:setColor(cc.c3b(255, 255, 255))
            elseif flag == 5 then
--                self.gameView.hero:setAttacking(false)
                bounceSpr:setColor(cc.c3b(255, 255, 255))
	        end
            self.tcp:sendMessage(9,{pos = cc.p(self.gameView.hero:getPosition()),data="attack4"})
	    end
        return false
    end

    local listener1 = cc.EventListenerTouchOneByOne:create()
    -- listener1:setSwallowTouches(true)

    listener1:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    -- listener1:registerScriptHandler(onTouchMove,cc.Handler.EVENT_TOUCH_MOVED )
    listener1:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )

    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener1, jumpSpr)
end





return ControllView
