------------------------------------------------------------------
-- Map.lua
-- Author     : liyongguang
-- Date       : 2015-08-12
-- Description: 地图类
------------------------------------------------------------------

local Prop = import(".Prop")

local Map = class("Map")

local MATERIAL_DEFAULT = cc.PhysicsMaterial(1, 1, 0)

-- 创建
function Map:create(  )
	local self = Map.new()
	return self
end

function Map:ctor()

	self:init()
end

--初始化
function Map:init()
	self.birthObj 		= nil		--出生点
	self.foodObjs 		= {}		--物品点
	self.monsterObjs 	= {}		--怪物点
	self.map = ccexp.TMXTiledMap:create("demo.tmx")
	self.size = self.map:getContentSize()

 	self:createFloorObject()	
 	self:createFoodObject()
 	self:createMonsterObject()
	self:createBirthObject()				
end

--创建碰撞层
function Map:createFloorObject()
	local group = self.map:getObjectGroup("floor")
	if not tolua.isnull( group ) then
		local objs = group:getObjects()
		 -- Log(objs)
		for k, v in pairs(objs) do
			if v.polylinePoints then
				local pts = List(v.polylinePoints):convert(function(xy) return cc.p(xy.x, -xy.y) end)
				local body = cc.PhysicsBody:createEdgeChain(pts,MATERIAL_DEFAULT)
				body.type = v.type
		
				body:setDynamic(false)
				body:setCategoryBitmask(ConstBitTypeFloor)
				body:setContactTestBitmask(ConstBitTypeAll)
				body:setCollisionBitmask(ConstBitTypeAll)

				local ndChain = cc.Node:create()
				ndChain:setPhysicsBody(body)
				ndChain:setPosition(v.x, v.y)
				self.map:addChild(ndChain)
			else
				local body = cc.PhysicsBody:createEdgeBox(v, MATERIAL_DEFAULT)
				body:setDynamic(false)
				body:setCategoryBitmask(ConstBitTypeFloor); -- 种类设为无害障碍
				body:setContactTestBitmask(ConstBitTypeAll); -- 只与飞机接触时，可被函数监听
				body:setCollisionBitmask(ConstBitTypeAll);     -- 可以任何物体碰撞
				local ndBox = cc.Node:create()
				ndBox:setPhysicsBody(body)
				ndBox:setPosition(v.x + v.width/2, v.y + v.height/2)
				self.map:addChild(ndBox)

			end
		end

	end
end

--创建物品出生点
function Map:createFoodObject()
	local group = self.map:getObjectGroup("food")
	if not tolua.isnull( group ) then
		local objs = group:getObjects()
		 -- Log(objs)
		for k, v in pairs(objs) do
			local prop = Prop:create(1,cc.p( v.x, v.y ))
			self.map:addChild(prop)
			table.insert(self.foodObjs, v)
		end
	end
	return self.foodObjs
end

--创建怪物出生点
function Map:createMonsterObject()
	local group = self.map:getObjectGroup("monster")
	if not tolua.isnull( group ) then
		local objs = group:getObjects()
		 -- Log(objs)
		for k, v in pairs(objs) do
			table.insert(self.monsterObjs, v)
		end
	end
	return self.monsterObjs
end

--创建主角出生点
function Map:createBirthObject()
	local group = self.map:getObjectGroup("start")
	if not tolua.isnull( group ) then
		local objs = group:getObjects()[1]
		self.birthObj = objs
	end
	return self.birthObj
end

--获取出生点坐标
function Map:getBirthPos()
	local obj = self.birthObj or self:createBirthObject()
	return cc.p(obj.x, obj.y)
end

return Map
