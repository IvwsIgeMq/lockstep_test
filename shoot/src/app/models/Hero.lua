------------------------------------------------------------------
-- Hero.lua
-- Author     : liyongguang
-- Date       : 2015-08-12
-- Description: 主角
------------------------------------------------------------------

local MonsterBase = import(".MonsterBase")
local BulletLine = import(".BulletLine")
local BulletFactory = import(".BulletFactory")

local Hero = class("Hero",MonsterBase)


local MATERIAL_DEFAULT = cc.PhysicsMaterial(0.01, 0, 0)

function Hero:create(...)
    local self = Hero.new(...)
    return self
end

function Hero:ctor(pos)

   self.name = "hero"
	self:initAttr()
	self:setAllState()
	self:setAllAnimations()
   self:setPosition(pos)
	self:createPhysicsBody(80,160,MATERIAL_DEFAULT)
	self:setPhysicsBitType(ConstBitTypeHero)
   self.velocity = self:getPhysicsBody():getVelocity()
	-- self.body:applyImpulse(cc.p(0,1000000))

	self:createSkeleton("spineboy.json", "spineboy.atlas", 0.3)

	self:setAttackDeg(0)
	self:schedulerUpdate()
	self:setState(1)
	self:setCascadeOpacityEnabled(true)

	-- self:setDirection(1)
	-- 	self:setMoving(true)
	self.flag = 0
	self.pos_list = {}
	self.isActionOver = true
	self.logicPos = pos
	self.nextLogicPos = pos
	self.command_list ={}
   self.update_num = 0


--   self.shadow:setScale(0.5)
--   self:setScale(0.5)
end

function Hero:addCommand(info,logic_frame)
	 if info.type  then
        if not self.command_list[logic_frame] then
          self.command_list[logic_frame] = {}
        end
       self.command_list[logic_frame][info.type] = info

   end
end

function Hero:doCommand(world,forwardTime,logic_frame)

     self:startPhysics()
    if not self.command_list[logic_frame] then
      return
    end
    for key, var in pairs(self.command_list[logic_frame]) do
         -- if not self.isPlayer then
         --    self:setPosition(var.pos)
         -- end
        if var.type == 2 then
            self:answerInput(unpack(var.data))
        elseif var.type==3 then
            self:jump()
        elseif var.type == 4 then
            self:answerInput(unpack(var.data))
        elseif var.type == 5 then
         --   print("setAttacking")
            self:setAttacking(true)
        elseif var.type == 6 then
         --   print("setAttacking")
            self:setAttacking(true,2)
        elseif var.type == 7 then
         --   print("setAttacking")
            self:setAttacking(true,3)
        elseif var.type == 8 then
         --   print("setAttacking")
            self:setAttacking(true,4)
        elseif var.type == 9 then
         --   print("setAttacking",false)
            self:setAttacking(false)
        end
    end
   --  print("HERO docommand")
    self.command_list[logic_frame]= {}
end

function Hero:logicUpdate (forwardTime)

   local logicPos =  cc.p(self:getPosition())
   local viewPos = cc.p(self.shadow:getPosition())
   -- if cc.pDistanceSQ(logicPos,viewPos)> 1 then
      self.update_num = math.ceil(forwardTime/(1/60))
   -- end
   -- print("logicUpdate",logicPos.x ,logicPos.y)
   if self.attacking then
      if self.shootTime <= 0 then
         self:attack()
         self.shootTime = self.shootDelay
      else
         self.shootTime = self.shootTime - forwardTime
      end
   end
   if self:isStopState() then
      --self:setXSpeed(0)
   end

   if self.state == self.states.Run then
      if self.moving then
         if self.dir == 1 then
   --			self:setXSpeed(self.maxSpeed)
         else
            -- self:setXSpeed(-self.maxSpeed)
         end
      end
   end

end


function Hero:stopPhysics()
   self.velocity = self:getPhysicsBody():getVelocity()
   self:getPhysicsBody():setVelocity(cc.p(0,0))

end

function Hero:startPhysics ()
   -- print("self.velocity",self.velocity.x ,self.velocity.y)
   self:getPhysicsBody():setVelocity(cc.p(0,self.velocity.y))
end

function Hero:mergePosition()
     local len = 10000000
     local index = 0
       local _x,_y = self.shadow:getPosition()
    for key, var in ipairs(self.pos_list) do
    	local _len = cc.pDistanceSQ(cc.p(_x,_y),var)
    	if _len < len then
    	   len = _len
    	   index = key
    	end
    end
    for var=1, index-1 do
    	table.remove(self.pos_list,var)
    end
end

function Hero:update()
   if self.update_num >0  then
      local viewPos= cc.p(self.shadow:getPosition())
      local logicPos = cc.p(self:getPosition())
      local pos = cc.pLerp(viewPos,logicPos,1/self.update_num)
      self.shadow:setPosition(pos)
      self.update_num =self.update_num -1
      self.gameView:followHero()
   end

--    self.shadow:setPosition(cc.p(self:getPosition()))

end

-------------------------------------------------
-- 设置人物方向，角度
-------------------------------------------------
function Hero:answerInput( angle, length )
	if length == 0 then
		self:setMoving(false)
		-- self:setAttackDeg(self.dir == 1 and 0 or 180)
		return
	end
	-- print(length.."   "..angle)
	-- print(self.flag)
	if angle > 90 and angle < 270 then
		if self.flag ~= -1 then
			self:setDirection(-1)
			self:setMoving(true)
			self.flag = 0

			if self.bloodSpriteBg then
				self.bloodSpriteBg:setScaleX(-self.bloodSpriteBg:getScaleX())
			end
		end
	else
		if self.flag ~= 1 then
			self:setDirection(1)
			self:setMoving(true)
			self.flag = 0

			if self.bloodSpriteBg then
				self.bloodSpriteBg:setScaleX(-self.bloodSpriteBg:getScaleX())
			end
		end
	end
	self:setAttackDeg(angle)
end


-------------------------------------------------
--implement: y轴起跳
-------------------------------------------------
function Hero:jump( )
	if self.jumping then return end
	self.flag = 0
	self.jumping = true
	self:setState(self.states.Jump)
	self.body:applyImpulse(cc.p(0,self.jumpImpulse))
end

-------------------------------------------------
-- implement: 设置动作混合
-------------------------------------------------
function Hero:setAnimationMix()
	local skeletonNode = self.skeletonNode
	skeletonNode:setMix("run", "idle", 0.1)
    skeletonNode:setMix("jump", "idle", 0.1)
    skeletonNode:setMix("shoot", "idle", 0.1)
    skeletonNode:setMix("shoot", "run", 0.1)
end

-------------------------------------------------
-- implement: 攻击
-------------------------------------------------
function Hero:attack()
	self.skeletonNode:setAnimation(1, "shoot", false)

	-- local pos 		= self.gameView:convertToWorldSpace(cc.p(self:getPosition()))
	local attackDeg 	= self.attackDeg
	local bulletPos 	= self:getGunHeadPos()
   -- print("logging",bulletPos.x,bulletPos.y)
	local shootMonster	= self:lockMonster(bulletPos)

	if self.attackType == 1 then
		BulletFactory:createBullet( bulletPos, attackDeg, 1 , shootMonster, self.gameView )
	elseif self.attackType == 2 then
		BulletFactory:createBullet( bulletPos, attackDeg, 2 , shootMonster, self.gameView )
	elseif self.attackType == 3 then
		BulletFactory:createBullets( bulletPos, attackDeg, self.gameView )
	elseif self.attackType == 4 then
		BulletFactory:createBullet( bulletPos, attackDeg, 1 , shootMonster, self.gameView, true)
	end
	-- BulletFactory:createBullet( bulletPos, attackDeg, 2 , shootMonster, self.gameView )


end

-------------------------------------------------
-- 锁定攻击目标
-------------------------------------------------
function Hero:lockMonster( pos )
	local monster = nil
	local minDis = 1000000
	local flag = false
	for k,v in pairs(self.gameView.monsters) do
		--if not flag then
			if v and v.getPosition then
				local x,y = v:getPosition()
				local dis = math.sqrt(math.pow(pos.x-x,2)+math.pow(pos.y-y,2))
				if dis < minDis then
					-- print(dis)
					minDis = dis
					monster = v
				end
			end
		-- 	if (x - pos.x > 0 and self.dir == 1) or (x - pos.x < 0 and self.dir == -1) then
		-- 		flag = true
		-- 	end
		-- end
	end
	return monster
end

-------------------------------------------------
-- 获取枪头位置
-------------------------------------------------
function Hero:getGunHeadPos()
	local degree = self.attackDeg
	local x,y = self:getPosition()
	local length = 100
	x = x + length * math.cos( math.rad(degree) )
	y = y + length * math.sin( math.rad(degree) )
	return cc.p(x,y)
end

-------------------------------------------------
-- 获取枪头位置
-------------------------------------------------
function Hero:skill1()
	self:setOpacity(60)
	local node = cc.Node:create()
	self:addChild(node)
	local function func()
		self:setOpacity(255)
		node:removeFromParent()
	end
	node:runAction( cc.Sequence:create( cc.DelayTime:create(5),cc.CallFunc:create(func) ) )
end

-------------------------------------------------
-- implement: 更新骨骼角度
-------------------------------------------------
function Hero:updateBonesRotation()
	local degree = self.attackDeg
	if self.dir == -1 then
		degree = degree - (degree - 90)*2
	end
	self.skeletonNode:setBoneRotation("rear_upper_arm",225+degree)
	self.skeletonNode:setBoneRotation("torso",108)
	self.skeletonNode:setBoneRotation("rear_bracer",352)
	self.skeletonNode:setBoneRotation("gun",25)
end



return Hero
