------------------------------------------------------------------
-- BulletLine.lua
-- Author     : liyongguang
-- Date       : 2015-08-13
-- Description: 直线子弹
------------------------------------------------------------------

local BulletBase = import(".BulletBase")

local BulletLine = class("BulletLine",BulletBase)


function BulletLine:create(texPath,attr)
    local self = BulletLine.new(texPath,attr)
    return self
end

-------------------------------------------------
-- 初始化
-------------------------------------------------
function BulletLine:ctor(texPath,attr)

    local spr = cc.Sprite:create(texPath)
    self.spr = spr

    self.bounce = false     --能否反弹
    self.track  = false     --能否追踪

    for k,v in pairs(attr) do
        self[k] = v

    end
   
    self.width  = 50
    self.height = 30
    self:createPhysicsBody()
    spr:setScale(0.5)
    self:addChild(spr)
    self.body:setGravityEnable(false)

    self.body:setCategoryBitmask(ConstBitTypeBullet)   
    self.body:setContactTestBitmask(ConstBitTypeAll)  
    self.body:setCollisionBitmask(ConstBitTypeAll)    

    self:setPosition(self.pos)
    self:setRotation(-self.degree)
    self.speedMax = 1000
    local ratio = math.rad(self.degree)
    local speedX = self.speedMax*math.cos(ratio)
    local speedY = self.speedMax*math.sin(ratio)
    self.body:setVelocity(cc.p(speedX,speedY)) 

    self:extraInitByType()


     -- local pos = { x = 900,y = 500}
     -- local x,y = self:getPosition()

     -- print("x "..x.."   y"..y)
    -- print(attr.degree.."    "..math.deg( cc.pToAngleSelf(cc.p(pos.x-x,pos.y-y)) ) )
end

-------------------------------------------------
-- 额外初始化
-------------------------------------------------
function BulletLine:extraInitByType(  )
    if self.ty == 1 then
        
    elseif self.ty == 2 then
        self.track      = true     --能否追踪
        self.rotaSpeed  = 0         --角速度
        self.rotaRapid  = 0         --角速度
        if self.goal then
            self:schedulerUpdate()
        end
    end
    self.spr:runAction( cc.Sequence:create( cc.DelayTime:create(2),cc.CallFunc:create(function() self:removeSelf() end) ))
end

------------------------------------------------
-- 启用定时器
-------------------------------------------------
function BulletLine:update()
    local monster = self.goal
    if not monster.alive then
        self.goal = self:lockMonster()
        if not self.goal then self:stopUpdate() end
    end
    local pos = { x = monster:getPositionX(), y = monster:getPositionY()}
    local x,y = self:getPosition()

    local degree = math.deg( cc.pToAngleSelf(cc.p(pos.x-x,pos.y-y)) )
    if self.degree - degree > 180 then degree = degree + 360 end       --取旋转方向
    if self.rotaRapid == 0 then
        self.rotaRapid = (degree - self.degree) /150
    end
     -- print("degree  "..degree.."    "..self.rotaSpeed)
     --  print(degree)
       -- print(self.degree.."   "..degree.."    "..self.degree - degree.."  "..self.rotaSpeed )

    if math.abs( self.degree - degree ) <= math.abs(self.rotaSpeed) then
        self.degree = degree
        -- print("ssssssssssss")
    else
        self.degree = self.degree + self.rotaSpeed
        self:setRotation(-self.degree)
    end 
   

    local ratio = math.rad(self.degree)
    local speedX = self.speedMax*math.cos(ratio)
    local speedY = self.speedMax*math.sin(ratio)
   
    self.body:setVelocity(cc.p(speedX,speedY)) 

    if self.rotaSpeed <= 10 then
        self.rotaSpeed = self.rotaSpeed + self.rotaRapid
    end
    -- print(self.rotaSpeed)
end

-------------------------------------------------
-- 锁定攻击目标
-------------------------------------------------
function BulletLine:lockMonster( )
    local monster = nil
    local minDis = 1000000
    local flag = false
    local posX,posY = self:getPosition()
    for k,v in pairs(self.pNode.monsters) do
            if v then
                local x,y = v:getPosition()
                local dis = math.sqrt(math.pow(posX-x,2)+math.pow(posY-y,2))
                if dis < minDis then
                    -- print(dis)
                    minDis = dis
                    monster = v
                end
            end
    end
    return monster
end
-------------------------------------------------
-- 启用定时器
-------------------------------------------------
function BulletLine:schedulerUpdate()
    StartNodeTimer(self, function () self:update() end, 0.01)
end
-------------------------------------------------
-- 停用定时器
-------------------------------------------------
function BulletLine:stopUpdate()
    StopNodeTimer(self)
end

function BulletLine:blast()
    self.spr:setTexture("bullet-hit.png")

    self.body:removeFromWorld()

    self.spr:runAction( cc.Sequence:create( cc.FadeOut:create(0.4),cc.CallFunc:create(function() self:removeSelf() end) ))
end 



return BulletLine
