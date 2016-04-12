------------------------------------------------------------------
-- MiniMapView.lua
-- Author     : liyongguang
-- Date       : 2015-08-19
-- Description: 小地图
------------------------------------------------------------------

local bold = 4

local MiniMapView = class("MonsterFactory",
    function ()
        return cc.LayerColor:create(cc.c4b(255, 255, 255, 120), 256, 192)
    end 
    )


function MiniMapView:create(gameView)
    local self = MiniMapView.new(gameView)
    return self
end

function MiniMapView:ctor(gameView)
    self.gameView = gameView
    local floodDrawer = cc.DrawNode:create()
    self.floodDrawer = floodDrawer
    self:addChild(floodDrawer, 10)
    local heroDrawer = cc.DrawNode:create()
    self.heroDrawer = heroDrawer
    self:addChild(heroDrawer, 10)
    self:init()
    StartNodeTimer(self, function () self:update() end, 0.05)
end

-------------------------------------------------
-- 初始化地图信息
-------------------------------------------------
function MiniMapView:init()
    -- local x = os.clock()
    self.floodDrawer:clear()
    self.heroDrawer:clear()
    local map       = self.gameView.map.map
    self.mapSize    = map:getMapSize()
    self.tileSize   = map:getTileSize()
    self.floorLayer = map:getLayer("floor")
    self:setContentSize( cc.size(self.mapSize.width*bold,self.mapSize.height*bold) )
    self:setPosition( cc.p(ConstScreenWidth-self.mapSize.width*bold,ConstScreenHeight-self.mapSize.height*bold) )
   
    self:updateFloor()
end
-------------------------------------------------
-- 更新 （还没做优化）
-------------------------------------------------
function MiniMapView:update()
    self.heroDrawer:clear()
    self:updatePlayerPos()
    self:updateMonsterPos()
end

-------------------------------------------------
-- 绘制地板
-------------------------------------------------
function MiniMapView:updateFloor()
    local size  = self.mapSize 
    local layer = self.floorLayer
    for h=0, size.height-1 do
        for w=0, size.width-1 do
            local t = layer:getTileGIDAt(cc.p(w,h))
            if t ~= 0 then
                -- print(w*bold+bold/2)
                self.floodDrawer:drawSolidRect(cc.p( w*bold,(size.height-h)*bold-bold ), cc.p(w*bold+bold,(size.height-h)*bold), cc.c4f(0,0,0,1))
            end
        end
    end
end
-------------------------------------------------
-- 更新玩家位置。
-------------------------------------------------
function MiniMapView:updatePlayerPos()
    if not self.gameView.hero then
        return 
     end
    local x,y   = self.gameView.hero:getPosition()
    local w     = math.floor( x / 32 ) 
    local h     = math.floor( y / 32 ) - 1
    local size  = self.mapSize 
    -- self.drawNode:drawDot(cc.p( w*bold,h*bold-bold ), bold, cc.c4f(1,1,0,1))
    self.heroDrawer:drawSolidRect(cc.p( w*bold,h*bold-bold ), cc.p(w*bold+bold,(h+1)*bold), cc.c4f(1,1,0,1))
end
-------------------------------------------------
-- 更新怪物位置
-------------------------------------------------
function MiniMapView:updateMonsterPos()
    for k,v in pairs( self.gameView.monsters ) do
        local x,y   = v:getPosition()
        local w     = math.floor( x / 32 )
        local h     = math.floor( y / 32 )
        local size  = self.mapSize 
        self.heroDrawer:drawSolidRect(cc.p( w*bold,h*bold-bold ), cc.p(w*bold+bold,h*bold), cc.c4f(1,0,0,1))
    end
end

return MiniMapView
