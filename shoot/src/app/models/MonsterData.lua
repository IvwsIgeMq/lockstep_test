------------------------------------------------------------------
-- MonsterData.lua
-- Author     : ganronghong
-- Date       : 2015-08-19
-- Description: 怪物数值
------------------------------------------------------------------

local MonsterData = {}

--获取属性
function MonsterData:getMonsertData(Id)
    local data = {}
    data.Live = 1000  --总血量
    data.blood = data.Live --当前血量

    return data
end

return MonsterData
