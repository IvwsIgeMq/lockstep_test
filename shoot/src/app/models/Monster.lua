------------------------------------------------------------------
-- Monster.lua
-- Author     : liyongguang
-- Date       : 2015-08-13
-- Description: 怪物
------------------------------------------------------------------

local MonsterBase = import(".MonsterBase")

local Monster = class("Monster",MonsterBase)

local MATERIAL_DEFAULT = cc.PhysicsMaterial(0.01, 0, 0)

function Monster:create()
    local self = Monster.new()
    return self
end

function Monster:ctor()

	-- 默认动作s
	local animations = {
		[1] 	= "run",
		[2] 	= "run",
		[3] 	= "test",
		[4] 	= "death",
		[5] 	= "jump",
		[6] 	= "jump",
	}

	self:initAttr()
	self:setAllAnimations(animations)

	self.maxSpeed  = 100
	self.shootTime = 1
	self.jumpImpulse = 40000

	self:createPhysicsBody(80,100,MATERIAL_DEFAULT)
	self:createSkeleton("alien.json", "alien.atlas", 0.3)

	self.skeletonNode:setAnimation(0, "run", true)

	-- self:setMoving(true)

	   -- StartNodeTimer(self, function () self:update() end, 1)
      StartNodeTimer(self, function () self:viewUpdate() end, 1/60)

   self.command_list = {}
   self.pos_list = {}
   self.update_num = 0
end


function Monster:viewUpdate (args)
   if self.update_num >0  then
      local viewPos= cc.p(self.shadow:getPosition())
      local logicPos = cc.p(self:getPosition())
      local pos = cc.pLerp(viewPos,logicPos,1/self.update_num)
      self.shadow:setPosition(pos)
      self.update_num =self.update_num -1
   end


end

function Monster:logicUpdate ()

   local logicPos =  cc.p(self:getPosition())
   local viewPos = cc.p(self.shadow:getPosition())
   if cc.pDistanceSQ(logicPos,viewPos)> 1 then
      self.update_num = 3
   end
   self:updateAI()
  --  self:addPos()
end


function Monster:addCommand (info)
   if info.subType then
      self.command_list[info.subType] = info
     end
--   dump(self.command_list)
end
function Monster:doCommand ()
   for key, var in pairs(self.command_list) do
      if var.subType == 4 then
          self:moveLeft()
      elseif var.subType==5 then
           self:moveRight()
      elseif var.subType == 6 then
         self:jump()
      end
   end
end








function Monster:moveRight (args)
   self:setDirection(1)
   self:setXSpeed(self.maxSpeed)
   if self.bloodSpriteBg then
      self.bloodSpriteBg:setScaleX(1)
   end
end

function Monster:moveLeft (args)
    self:setDirection(-1)
   self:setXSpeed(-self.maxSpeed)
   if self.bloodSpriteBg then
      self.bloodSpriteBg:setScaleX(-1)
   end
end



function Monster:lockHero(  )
   local pos = cc.p(self:getPosition())
	local monster = nil
	local minDis = 1000000
	local flag = false
	for k,v in pairs(self.gameView.heroList) do
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
function Monster:updateAI()

    local target = self:lockHero()
   	local x =  target:getPositionX()
   	local my = self:getPositionX()
   	if x < my then
         self:moveLeft()
   	else
   		self:moveRight()
   	end
   	if math.abs(x - my) <= 180 then
   		self:jump()
   	end


end


-------------------------------------------------
-- implement: 攻击
-------------------------------------------------
function Monster:attack()
	self.skeletonNode:setAnimation(1, "jump", false)
end


return Monster
