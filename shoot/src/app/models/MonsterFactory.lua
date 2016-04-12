------------------------------------------------------------------
-- MonsterFactory.lua
-- Author     : liyongguang
-- Date       : 2015-08-17
-- Description: 怪物工厂
------------------------------------------------------------------

local Monster   = import(".Monster")

local MonsterFactory = class("MonsterFactory")

MonsterFactory.monsters = {}
MonsterFactory.mId = 1

-------------------------------------------------
-- 创建怪物
-------------------------------------------------
function MonsterFactory:createMonster( pnode )
    local monster = Monster:create()
    local obj = pnode.map.monsterObjs[math.random(#pnode.map.monsterObjs)]
    monster:setPosition(cc.p(obj.x,obj.y))
    monster.shadow:setPosition(cc.p(obj.x,obj.y))
    pnode:addChild(monster,3)
    pnode:addChild(monster.shadow,3)
   --  print("loggingcreateMonster",pnode)
    monster:setGameView(pnode)
    -- table.insert(self.monsters,monster)
    monster.mId = MonsterFactory.mId
    MonsterFactory.mId = MonsterFactory.mId + 1

    return monster
end

-------------------------------------------------
-- 获取怪物列表
-------------------------------------------------
function MonsterFactory:getMonsters( pnode )
    return self.monsters
end

return MonsterFactory
