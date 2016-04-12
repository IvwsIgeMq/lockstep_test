------------------------------------------------------------------
-- BulletBase.lua
-- Author     : liyongguang
-- Date       : 2015-08-13
-- Description: 子弹基类
------------------------------------------------------------------

-- local MonsterBase = import(".MonsterBase")

local BulletBase = class("BulletBase",cc.Node)

local MATERIAL_DEFAULT = cc.PhysicsMaterial(0.01, 1, 0)

function BulletBase:create(texPath)
    local self = BulletBase.new()
    return self
end

function BulletBase:ctor()
	self.width 	= 50
	self.height = 30
	self:createPhysicsBody(self.width,self.height,MATERIAL_DEFAULT)
end

function BulletBase:createPhysicsBody(w,h,m)
	local m = m or MATERIAL_DEFAULT
	local w = w or self.width
	local h = h or self.height
	local body = cc.PhysicsBody:createBox(cc.size(w, h),m)
	-- body:setRotationEnable(false)
	self:setPhysicsBody(body)
	self.body = body
end

function BulletBase:removeSelf()
	self:removeFromParent(true)
end


return BulletBase
