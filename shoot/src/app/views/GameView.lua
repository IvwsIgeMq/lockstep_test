
-- GameView is a combination of view and controller
local GameView              = class("GameView", cc.Layer)
local Hero                  = import("..models.Hero")
local Map                   = import("..models.Map")
local Monster               = import("..models.Monster")
local ControllView          = import(".ControllView")
local MonsterFactory        = import("..models.MonsterFactory")

function GameView:create(tcp)
    local self = GameView.new(tcp)
    return self
end

function GameView:ctor(tcp)
    self.input = {
        angle = 0,
        length = 0
    }
    self.tcp = tcp

    local map = Map:create()
    self:addChild(map.map,2)
    -- map.map:setPosition(cc.p(-200,0))
    self:setScale(0.8)
    self.map = map

    self.isMonsterHost = false



 -- local controllView = ControllView:create(self)
 -- self:addChild(controllView)
 -- self.controllView = controllView

    local ndFollow = cc.Node:create()
    self:addChild(ndFollow)
    self.ndFollow = ndFollow -- 跟随节点

    self.monsters = {}
    self:registerContactEvent()
    self.heroList = {}
    self.sendCommand = {}
    self.serverFrameKeyLIst = {}
    self.viewFrameKeyList = {}
    self.interval= 0
    self.keyLen = 0
end


function GameView:updateLogic (world,forwardTime,logic_frame)
  math.randomseed(logic_frame)
   self:doCommand(world,forwardTime,logic_frame)
   if logic_frame%10 == 0 then
      -- self:addMonster({})
      -- self.tcp:sendMessage(-100,{time = socket.gettime()})
   end
   world:step(0) --让 node 位置更新物理对象
   self:visit()
   for k,hero in pairs(self.heroList) do
      hero:logicUpdate(forwardTime)
   end
   for k,monster in pairs(self.monsters) do
      monster:logicUpdate(forwardTime)
   end

end

function GameView:viewUpdate (dt,world,forwardTime)
   if self.interval >=forwardTime then
      local key = table.remove(self.serverFrameKeyLIst,1)
      local len = #self.serverFrameKeyLIst
      if key  then
         self:updateLogic(world,forwardTime,key)
         self.keyLen = math.ceil(self.tcp.rtt/forwardTime)
         -- print("self.keyLen",self.keyLen,self.tcp.rtt)
         if len > self.keyLen  then
            self.interval = self.interval -forwardTime
            self.keyLen = 0
         else
            self.interval  = 0
         end
         table.insert(self.viewFrameKeyList,key)
      end
      self:sendCommands()

   end
   self.interval  = self.interval +dt
end



function GameView:addMonster (info)
  local monster = MonsterFactory:createMonster(self)

  table.insert(self.monsters, monster.mId, monster)
   self:ShowBloodSprite(1,monster)
  monster:setSnapshot(info.snapshot)
end



function GameView:getHero(ID)
	return self.heroList[ID]
end


function GameView:removeHero (ID)
   local hero = self.heroList[ID]
   if hero then
        print("清理对象",tolua.isnull(hero),hero)
        hero.shadow:removeFromParentAndCleanup(true)
        hero:removeFromParentAndCleanup(true)
      self.heroList[ID] = nil
   end
end

function GameView:setSnapshot (snapshot)
   if not snapshot then
      return
   end
   for i,heroSnapshot in ipairs(snapshot.players) do
      self:addHero(heroSnapshot)
   end
   for i,monsterSnapshot in ipairs(snapshot.monsters) do
      self:addMonster(monsterSnapshot)
   end
end
function GameView:addHero(info)
    if self.heroList[info.ID] then
      return
     end
    local hero = Hero:create(self.map:getBirthPos())

    self:addChild(hero,4)
    self:addChild(hero.shadow,4)
    if not self.hero  then
        self.hero = hero
        hero.isPlayer = true
    end
    hero:setGameView(self)
    self.heroList[info.ID] = hero
    self:ShowBloodSprite(1,hero)
    hero:setSnapshot(info.snapshot)
    print("增加解色",info.ID)
end

function GameView:makeSnapshot(logic_frame)
   local info ={}
   info.players = {}
   info.monsters = {}
   info.logic_frame = logic_frame
   for k,hero in pairs(self.heroList) do
      local snapshot = hero:makeSnapshot()
      table.insert(info.players,{ID = k,snapshot = snapshot})
   end
   for k,hero in pairs(self.monsters) do
      local snapshot = hero:makeSnapshot()
      table.insert(info.monsters,{ID =k,snapshot = snapshot})
   end
   return info
end
function GameView:doCommand(world,forwardTime,logic_frame)
	for key, hero in pairs(self.heroList) do
        hero:doCommand(world,forwardTime,logic_frame)
	end
   world:step(0)
   world:step(forwardTime)
   self:visit()
   for key, hero in pairs(self.heroList) do
      hero:stopPhysics()
   end
end

function GameView:sendCommands ()
   for k,v in pairs(self.sendCommand) do
      self.tcp:sendMessage(k,v)
   end
   self.sendCommand = {}
end


function GameView:ShowBloodSprite(step,heroPro)
    local top_path = 'battle/'
    local s_path_bg = top_path..'battle_frame_blood_bg.png'
    local s_path_green = top_path..'battle_frame_blood_green.png'
    local s_path_red = top_path..'battle_frame_blood_red.png'

    performWithDelay(self,function()
        print(heroPro.name,heroPro.skeletonNode)
        local width,height = heroPro.skeletonNode:getBoundingBox().width,heroPro.skeletonNode:getBoundingBox().height
        -- local width,height = 100,step == 1 and 220 or 130
        local hero_blood = cc.Sprite:create(s_path_bg)
        hero_blood:setPosition(cc.p(0, height))
        heroPro.skeletonNode:addChild(hero_blood)

        local ProgressBar = cc.ProgressTimer:create(cc.Sprite:create(step == 1 and s_path_green or s_path_red))
        ProgressBar:setType(cc.PROGRESS_TIMER_TYPE_BAR)
        ProgressBar:setMidpoint(cc.p(0,0))
        ProgressBar:setBarChangeRate(cc.p(1,0))
        ProgressBar:setAnchorPoint(cc.p(0.5, 0.5))
        ProgressBar:setPosition(cc.p(hero_blood:getContentSize().width/2, hero_blood:getContentSize().height/2))

        hero_blood:addChild(ProgressBar)

        ProgressBar:setPercentage(100)

        heroPro.bloodSpriteBg = hero_blood
        heroPro.bloodSprite = ProgressBar
     end,0.01)
end

function GameView:update()
    self:followHero()

end

function GameView:updateInput( angle, length )
    self.input.angle = angle
    self.input.length = length
    self:answerInput()
end

function GameView:answerInput()
    local input = self.input
    if self.hero then
      self.hero:answerInput(input.angle,input.length)
   end
end

-- 镜头跟随
function GameView:followHero()

    -- local function fnTimer()
    if self.hero then
    self.ndFollow:setPosition(self.hero.shadow:getPosition())
    end
        -- 取屏幕中心点的坐标
        local offsetMid = self.ndFollow:convertToNodeSpace(ConstScreenCamera)
        local szMap = self.map.size

        local x, y = self:getPosition()
        x = x + offsetMid.x
        y = y + offsetMid.y

        if x > 0 then
            x = 0
        end

        local minX = ConstScreenWidth - szMap.width
        if x < minX  then
            x = minX
        end

        if y > 0 then
            y = 0
        end

        local minY = ConstScreenHeight - szMap.height
        if y < minY then
            y = minY
        end

        -- 改变场景节点
        self:setPosition(x, y)

        self.ndBg:setPosition( x/self.ndBg.mulX,y/self.ndBg.mulY )
        -- print(x.."   "..y)
        --  print(x/self.ndBg.mulX.."       "..y/self.ndBg.mulY)
    -- end
    -- local nd = cc.Node:create()
    -- -- 启动定时器
    -- StartNodeTimer(nd, fnTimer, 0.01)
    -- self:addChild(nd)
end

-- 创建背景
function GameView:setBg( bg )

    self.ndBg = bg

    self.ndBg.mulX = (self.map.map:getContentSize().width - ConstScreenWidth) / (self.ndBg:getContentSize().width - ConstScreenWidth)
    self.ndBg.mulY = (self.map.map:getContentSize().height - ConstScreenHeight) / (self.ndBg:getContentSize().height - ConstScreenHeight)
-- print(self.ndBg.mulX.."  "..self.ndBg.mulY )
--  g_sceneUIRoot:setScale(0.3)
end


-- 碰撞检测
function GameView:registerContactEvent()

    local function onContactBegin(contact)
        local a = contact:getShapeA():getBody()
        local b = contact:getShapeB():getBody()
        if a:getCategoryBitmask() + b:getCategoryBitmask() == ConstBitTypeHero + ConstBitTypeFloor then
            -- if not self.hero.jumping then return true end
            local heroNode = nil
            local floorNode  = nil
            if a:getCategoryBitmask() == ConstBitTypeHero then
                heroNode  = a
                floorNode = b
            else
                floorNode = a
                heroNode  = b
            end
            -- print(heroNode:getVelocity().x)
            -- Log(contact:getContactData())
   --              Log(contact:getContactData().normal)


           -- print(heroNode:getPositionY().."     "..floorNode:getPosition().y)
             if self.hero.dir == 1 and contact:getContactData().normal.x ~= 0 and
                contact:getContactData().normal.y ~= 1 then
                -- local x,y = self.hero:getPosition()
                -- self.hero:runAction(cc.Place:create(cc.p(x-5,y)))
                heroNode:getNode():setMoving(false)
                heroNode:getNode().flag = 1
                -- print("111111")

                return true
             elseif  self.hero.dir == -1 and  contact:getContactData().normal.x ~= 0 and
                contact:getContactData().normal.y ~= 1  then
                heroNode:getNode():setMoving(false)
                heroNode:getNode().flag = -1
                -- local x,y = self.hero:getPosition()
                -- self.hero:runAction(cc.Place:create(cc.p(x+5,y)))
                return true
             end
             if contact:getContactData().normal.y == 1 then
                heroNode:getNode():jumpGround()
                return true
             end
             -- print("nnnnnnn")
            -- if contact:getContactData().normal.x == -1 or contact:getContactData().normal.x == 1 then
            --     heroNode:getNode():setMoving(false)
            --     heroNode:getNode().temp = false
            --     return true
            -- end

            return true
        elseif a:getCategoryBitmask() + b:getCategoryBitmask() == ConstBitTypeBullet + ConstBitTypeFloor then
            local node = nil
            if a:getCategoryBitmask() == ConstBitTypeBullet then
                node = a:getNode()
            else
                node = b:getNode()
            end
            if not node.bounce then
                node:blast()
            end
            return true
        elseif a:getCategoryBitmask() + b:getCategoryBitmask() == ConstBitTypeBullet + ConstBitTypeMonster then
            local monsterNode = nil
            local bulletNode  = nil
            if a:getCategoryBitmask() == ConstBitTypeMonster then
                monsterNode = a:getNode()
                bulletNode  = b:getNode()
            else
                monsterNode = b:getNode()
                bulletNode  = a:getNode()
            end

            monsterNode:dead(2)
            bulletNode:blast()
            return true
        -- elseif a:getCategoryBitmask() + b:getCategoryBitmask() == ConstBitTypeHero + ConstBitTypeMonster then
        --     return false
        elseif a:getCategoryBitmask() + b:getCategoryBitmask() == ConstBitTypeFloor + ConstBitTypeMonster then
            local node = nil
            if a:getCategoryBitmask() == ConstBitTypeMonster then
                node = a:getNode()
            else
                node = b:getNode()
            end
            node:jumpGround()
        elseif a:getCategoryBitmask() + b:getCategoryBitmask() == ConstBitTypeHero + ConstBitTypeProp then
            local propNode = nil
            local heroNode = nil
            if a:getCategoryBitmask() == ConstBitTypeProp then
                propNode = a:getNode()
                heroNode = b:getNode()
            else
                propNode = b:getNode()
                heroNode = a:getNode()
            end
            propNode:removeSelf()
            heroNode:skill1()
        elseif a:getCategoryBitmask() + b:getCategoryBitmask() == ConstBitTypeHero + ConstBitTypeMonster then
            local heroNode  = nil
            if a:getCategoryBitmask() == ConstBitTypeHero then
                heroNode = a:getNode()
            else
                heroNode = b:getNode()
            end

            heroNode:dead(1)
            heroNode:hurt()
        else
            return false
        end

        return true
    end

    -- local i = 1
    -- local function onContactPre(contact)
    --     local a = contact:getShapeA():getBody()
    --     local b = contact:getShapeB():getBody()
    --     if a:getCategoryBitmask() + b:getCategoryBitmask() == ConstBitTypeHero + ConstBitTypeFloor then

    --     end
    --     return true
    -- end

    -- local function onContactPost(contact)
    --     local a = contact:getShapeA():getBody()
    --     local b = contact:getShapeB():getBody()
    --     if a:getCategoryBitmask() + b:getCategoryBitmask() == ConstBitTypeHero + ConstBitTypeFloor then

    --     end
    --     return true
    -- end

    -- local function onContactEnd(contact)
    --     local a = contact:getShapeA():getBody()
    --     local b = contact:getShapeB():getBody()
    --     if a:getCategoryBitmask() + b:getCategoryBitmask() == ConstBitTypeHero + ConstBitTypeFloor then
    --         Log(contact:getContactData().normal)
    --         if contact:getContactData().normal.y ~= 0 then
    --             self.hero.flag = 0
    --         end
    --     end
    --     return true
    -- end

    local contactListener = cc.EventListenerPhysicsContact:create();
    contactListener:registerScriptHandler(onContactBegin, cc.Handler.EVENT_PHYSICS_CONTACT_BEGIN)
    -- contactListener:registerScriptHandler(onContactPre, cc.Handler.EVENT_PHYSICS_CONTACT_PRESOLVE)
 --   contactListener:registerScriptHandler(onContactPost, cc.Handler.EVENT_PHYSICS_CONTACT_POSTSOLVE)
    -- contactListener:registerScriptHandler(onContactEnd, cc.Handler.EVENT_PHYSICS_CONTACT_SEPARATE)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(contactListener, self);
end

return GameView
