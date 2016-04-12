------------------------------------------------------------------
-- BulletFactory.lua
-- Author     : liyongguang
-- Date       : 2015-08-17
-- Description: 子弹工厂
------------------------------------------------------------------
local BulletLine = import(".BulletLine")

local BulletFactory = class("BulletFactory")

-------------------------------------------------
-- 创建一颗子弹
-------------------------------------------------
function BulletFactory:createBullet( pos, degree, type ,shootMonster ,pNode ,bounce)

	local attr 	= {}
	attr.pos 	= pos
	attr.degree = degree
	attr.ty 	= type
	attr.goal	= shootMonster
	attr.pNode	= pNode
	attr.bounce = bounce

	local bullet = BulletLine:create("bullet.png",attr)
	pNode:addChild(bullet,3)

	return bullet
end

-------------------------------------------------
-- 创建多颗子弹
-------------------------------------------------
function BulletFactory:createBullets( pos, degree, pNode )

	local fDegree = degree + 40
	for var = 0,4 do
			local attr 	= {}
			attr.pos 	= pos
			attr.degree = fDegree - var*20
			attr.ty 	= 1
			attr.pNode	= pNode
		local bullet = BulletLine:create("bullet.png",attr)
		pNode:addChild(bullet,3)
	end

end

return BulletFactory
