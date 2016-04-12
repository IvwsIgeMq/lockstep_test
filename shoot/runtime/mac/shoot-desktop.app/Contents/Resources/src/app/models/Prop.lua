------------------------------------------------------------------
-- Prop.lua
-- Author     : liyongguang
-- Date       : 2015-08-17
-- Description: 道具
------------------------------------------------------------------

local Prop = class("Prop",cc.Node)

-------------------------------------------------
-- 创建道具  ty:类型
-------------------------------------------------
function Prop:create(ty,pos)
    local self = Prop.new(ty,pos)
    return self
end

-------------------------------------------------
-- 初始化道具属性
-------------------------------------------------
function Prop:ctor(ty,pos)
	if pos then
		self:setPosition(pos)
	end
	self.type = ty
	local sprRes = "Star.png"
	if self.type == 1 then
		sprRes = "Star.png"
	end
	local spr = cc.Sprite:create(sprRes)
	spr:setAnchorPoint(cc.p(0,0))
	self:addChild(spr)
	self.spr = spr
	self:createPhysicsBody(40,40,MATERIAL_DEFAULT)
end

-------------------------------------------------
-- 创建道具刚体
-------------------------------------------------
function Prop:createPhysicsBody(w,h,m)
	local m = m or MATERIAL_DEFAULT
	local w = w or self.width
	local h = h or self.height
	local body = cc.PhysicsBody:createBox(cc.size(w, h),m)
	body:setCategoryBitmask(ConstBitTypeProp) 
	body:setContactTestBitmask(ConstBitTypeHero)  
	body:setCollisionBitmask(ConstBitTypeHero)   
	body:setGravityEnable(false) 
	local size = self.spr:getContentSize()
	body:setPositionOffset(cc.p(size.width/2,size.height/2))
	self:setPhysicsBody(body)
	self.body = body
end

-------------------------------------------------
-- 移除道具
-------------------------------------------------
function Prop:removeSelf()
	self:removeFromParent(true)
end




return Prop
