------------------------------------------------------------------
-- Monster.lua
-- Author     : liyongguang
-- Date       : 2015-08-13
-- Description: 怪物基类
------------------------------------------------------------------

local MonsterBase = class("MonsterBase",cc.Node)
local MonsterData = import(".MonsterData")

local MATERIAL_DEFAULT = cc.PhysicsMaterial(1, 0, 0)

-- 默认状态s
local DEFAULT_STATES = {
	Stand 	 	= 1,	--＊
	Run 	 	= 2,	--＊
	Squat	 	= 3,	--＊
	Dead	 	= 4,	--＊
	Jump 	 	= 5,	--＊
	RunJump 	= 6,	--＊
	Hurt 		= 7,	--＊
}

-- 默认动作s
local DEFAULT_ANIMATIONS = {
	[1] 	= "idle",
	[2] 	= "run",
	[3] 	= "test",
	[4] 	= "death",
	[5] 	= "jump",
	[6] 	= "jump",
	[7] 	= "hit",
}

function MonsterBase:create()
    local self = MonsterBase.new()
    return self
end

function MonsterBase:ctor()
	self:initAttr()

end

function MonsterBase:initAttr()
	self.state 			= 0 		--状态
	self.attacking 		= false		--是否攻击中
	self.moving 		= false	    --是否移动中
	self.jumping		= false		--是否在空中
	self.dir 			= 1 		--方向
	self.skeletonNode 	= nil 		--spine节点
	self.animation		= 1			--动作标记
	self.attackDeg		= 0			--攻击角度

	self.shootTime 		= 0  		--射击时间
	self.shootDelay		= 0.08 		--射击延迟

	self.jumpImpulse    = 100000	--弹跳力度
	self.alive			= true 		--活着的

	-- self.startSpeed 		= 100 	--初始速度
	self.maxSpeed			= 400	--最大速度
	-- self.speedUpA		= 20	--加速度
	-- self.speedDownA		= 20	--减速度

	self.gameView = nil
	self:setAllState()
	self:setAllAnimations()

	self.data = MonsterData:getMonsertData()
end

-------------------------------------------------
-- 设置gameview
-------------------------------------------------
function MonsterBase:setGameView(gameView)
	self.gameView = gameView
end

-------------------------------------------------
-- 设置怪物有的特性 状态 跑，跳，站，等
-------------------------------------------------
function MonsterBase:setAllState( states )
	self.states = states or DEFAULT_STATES
end

-------------------------------------------------
-- 设置状态所对应动动作
-------------------------------------------------
function MonsterBase:setAllAnimations( animations )
	self.animations = animations or DEFAULT_ANIMATIONS
end

-------------------------------------------------
-- 启用定时器
-------------------------------------------------
function MonsterBase:schedulerUpdate()
	StartNodeTimer(self, function (...) self:update(...) end, 1/60)
end
-------------------------------------------------
-- 停用定时器
-------------------------------------------------
function MonsterBase:stopUpdate()
	StopNodeTimer(self)
end

-------------------------------------------------
-- 创建物理刚体
-------------------------------------------------
function MonsterBase:createPhysicsBody(w,h,m)
	self.bodyH = h
	local w = w or 80
	local h = h or 160
	local m = m or MATERIAL_DEFAULT
	local body = cc.PhysicsBody:createBox(cc.size(w, h),m)
	body:setVelocity(cc.p(0,0))
	body:setRotationEnable(false)
	self.shadow = cc.Node:create()
   self.shadow:setPosition(cc.p(self:getPosition()))
	self.shadowTarget = cc.Node:create()
	self.shadowTarget:setPosition(cc.p(self:getPosition()))
	self.shadowFrom = cc.Node:create()
	self.shadowFrom:setPosition(cc.p(self:getPosition()))
	self:setPhysicsBody(body)
	self.body = body
	self:setPhysicsBitType()
end


function MonsterBase:addTo(node,level)
		node:addChild(self,level)
		node:addChild(self.shadow,level)
		node:addChild(self.shadowTarget,level)
		node:addChild(self.shadowFrom,level)
end
-------------------------------------------------
-- 设置刚体3个码
-------------------------------------------------
function MonsterBase:setPhysicsBitType( category, contact, collision )
	local category = category or ConstBitTypeMonster
	self.body:setCategoryBitmask(category)
	local contact = contact or ConstBitTypeAll
	self.body:setContactTestBitmask(contact)
	local collision = collision or ConstBitTypeAll
	self.body:setCollisionBitmask(collision)
end

-------------------------------------------------
-- 创建spine节点
-------------------------------------------------
function MonsterBase:createSkeleton(json,atlas,scale)
	local skeletonNode = sp.SkeletonAnimation:create(json, atlas, scale)
    skeletonNode:setPosition(cc.p(0, -self.bodyH/2 ))
    self.shadow:addChild(skeletonNode)
    self.skeletonNode = skeletonNode
    print("创建spine节点",json,skeletonNode)
    self:setAnimationMix()
end

-------------------------------------------------
-- 设置动作混合
-------------------------------------------------
function MonsterBase:setAnimationMix()
	local skeletonNode = self.skeletonNode
 --	   skeletonNode:setMix("run", "idle", 0.1)
 --    skeletonNode:setMix("jump", "idle", 0.1)
 --    skeletonNode:setMix("shoot", "idle", 0.1)
 --    skeletonNode:setMix("shoot", "run", 0.1)
end


-------------------------------------------------
-- 设置状态 跑，跳，站，等
-------------------------------------------------
function MonsterBase:setState(state)
	self.state = state
	self:changeAnimationState()
end

-------------------------------------------------
-- 准备切换动作状态
-------------------------------------------------
function MonsterBase:changeAnimationState()
	local r = true
	for k,v in pairs(self.states) do
		if self.state == v then
			local animation = self.animations[self.state]
			if animation == "jump" then r = false end
			self:setAnimation( self.animations[self.state] , r )
			return
		end
	end
end

-------------------------------------------------
-- 是否需要切换动作状态
-------------------------------------------------
function MonsterBase:setAnimation( ani , repeat_, id )
	if self.animation == ani then return end

	self.animation = self.animations[self.state]
	local id = id or 0
	self.skeletonNode:setAnimation(id, ani, repeat_)
end

-------------------------------------------------
-- 设置运动方向
-------------------------------------------------
function MonsterBase:setDirection(dir)
	if self.dir == dir then return end
	self.dir = dir
	local x = self.shadow:getScaleX()
	if self.dir == -1 then
		self.shadow:setScaleX(-x)
	else
		self.shadow:setScaleX(-x)
	end
end

-------------------------------------------------
-- x轴开始移动
-------------------------------------------------
function MonsterBase:startMoving()

end

-------------------------------------------------
-- x轴结束移动
-------------------------------------------------
function MonsterBase:endMoving()

end

-------------------------------------------------
-- 是否是静止的
-------------------------------------------------
function MonsterBase:isStopState()
	if self.moving or self.jumping then
		return false
	end
	return true
end

-------------------------------------------------
-- 攻击
-------------------------------------------------
function MonsterBase:attack( )

end

-------------------------------------------------
-- 起跳
-------------------------------------------------
function MonsterBase:jump( )
	if self.jumping then return end
	self.flag = 0
	self.jumping = true
	self:setState(self.states.Jump)
	self.body:applyImpulse(cc.p(0,self.jumpImpulse))
end

-------------------------------------------------
-- 落地
-------------------------------------------------
function MonsterBase:jumpGround( )
	self:resetYSpeed( )
	self.jumping = false
	self.flag = 0
	if self.moving then
		self:setState(self.states.Run)
	else
		self:setState(self.states.Stand)
	end
end

-------------------------------------------------
-- 设置移动状态  true 运动中  false 静止
-------------------------------------------------
function MonsterBase:setMoving( state )
	self.moving = state
	 -- if self.moving == state and setXSpeed ==  then return end
	if self.moving then
		if self.dir == 1 then
			self:setXSpeed(self.maxSpeed)
		else
			self:setXSpeed(-self.maxSpeed)
		end
		if self.jumping then return end
		self:setState(self.states.Run)
	else
		if not self.jumping then
			self.body:setVelocity(cc.p(0,0))
			self:setState(self.states.Stand)
		else
			self:setXSpeed(0)
		end
	end
end

function MonsterBase:makeSnapshot ()
	return {Velocity = self.body:getVelocity(),pos = cc.p(self:getPosition()),data = self.data,deg = self.attackDeg}
end

function MonsterBase:setSnapshot (Snapshot)
	if not Snapshot then
		return
	end
	self:setPosition(Snapshot.pos)
	self.shadow:setPosition(Snapshot.pos)
	self:getPhysicsBody():setVelocity(Snapshot.Velocity)
	self.data = Snapshot.data
	self:setAttackDeg(Snapshot.deg)
end
-------------------------------------------------
-- 设置攻击状态
-------------------------------------------------
function MonsterBase:setAttacking(b,t)
	self.attacking 	  = b
	self.attackType   = t or 1
	self.shootTime 	  = 0
end

-------------------------------------------------
-- 更新骨骼角度
-------------------------------------------------
function MonsterBase:updateBonesRotation()
	return
end

-------------------------------------------------
-- 设置攻击锁定位置
-------------------------------------------------
function MonsterBase:setAttackDeg(deg)
	self.attackDeg = deg
	self:updateBonesRotation()
end

-------------------------------------------------
-- 是否可以起跳
-------------------------------------------------
function MonsterBase:canJump( )
	return math.abs(self:getYSpeed()) < 1
end

-------------------------------------------------
-- 移除Y轴速度
-------------------------------------------------
function MonsterBase:resetYSpeed( )
	local speed = self.body:getVelocity()
	self.body:setVelocity(cc.p(speed.x,0))
end

-------------------------------------------------
-- 移除X轴速度
-------------------------------------------------
function MonsterBase:resetXSpeed( )
	local speed = self.body:getVelocity()
	self.body:setVelocity(cc.p(0,speed.y))
end

-------------------------------------------------
-- 设置X轴速度
-------------------------------------------------
function MonsterBase:setXSpeed( x )

	local speed = self.body:getVelocity()
	self.body:setVelocity(cc.p(x,speed.y))
end

-------------------------------------------------
-- 设置Y轴速度
-------------------------------------------------
function MonsterBase:setYSpeed( y )
	local speed = self.body:getVelocity()
	self.body:setVelocity(cc.p(speed.x,y))
end

-------------------------------------------------
-- 获取Y轴速度
-------------------------------------------------
function MonsterBase:getYSpeed( )
	return self.body:getVelocity().y
end

-------------------------------------------------
-- 受击
-------------------------------------------------
function MonsterBase:hurt()
	self.skeletonNode:setAnimation(1, self.animations[self.states.Hurt], false)
end
-------------------------------------------------
-- 死亡
-------------------------------------------------
function MonsterBase:dead(step)
	self.data.blood = math.max(self.data.blood - (step == 1 and 10 or 100),0)
	local to = cc.ProgressTo:create(0.2, self.data.blood/self.data.Live*100)
    self.bloodSprite:runAction(cc.RepeatForever:create(to))

	if self.data.blood > 0 then
		return
	end

	if step == 1 then
		print('英雄死了，游戏结束')
		return
	end

	self.alive = false
	self.gameView.monsters[self.mId] = nil--, self.mId)
	self.skeletonNode:setAnimation(0, "death", false)
	self.body:removeFromWorld()
	self:stopUpdate()
	self:runAction( cc.Sequence:create( cc.DelayTime:create(3),cc.CallFunc:create(function() self:removeSelf() end) ))
end

-------------------------------------------------
-- 移除
-------------------------------------------------
function MonsterBase:removeSelf()
	self:removeFromParent(true)
end


return MonsterBase
