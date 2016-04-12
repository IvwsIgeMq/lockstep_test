--临时

-- 物体类型(用于碰撞检测)
ConstBitTypeHero 			= 1       	 	-- 0000001 主角
ConstBitTypeFloor 			= 2      		-- 0000010 地板
ConstBitTypeBullet			= 4      		-- 0000100 子弹
ConstBitTypeMonster			= 8      		-- 0001000 怪物
ConstBitTypeProp			= 16      		-- 0010000 道具
ConstBitTypeNil			=32 				-- 0100000

ConstBitTypeAll 			= -1   			-- 所有物体


ConstScreenWidth = display.width   -- 屏幕宽
ConstScreenHeight = display.height  -- 屏幕高

ConstScreenMid = {x=ConstScreenWidth/2, y=ConstScreenHeight/2} -- 屏幕中心点
ConstScreenCamera = { x= ConstScreenWidth*2/5, y = ConstScreenHeight*2/5 } --镜头

MATERIAL_DEFAULT = cc.PhysicsMaterial(0.01, 0, 0)

function Must(val, msg)
	msg = msg or "function Must not pass"
	if not val then
		error(msg, 2) -- 2表示显示上层调用
	end
	return val
end

-- 有序显示对象key
-- 参数 sFind: 要查找的单词
function LogKeys(obj, sFind)
	if obj[".isclass"] then
		obj = getmetatable(obj)
	end

	local fnPick = function() return true end
	if sFind then
		sFind = sFind:upper()
		fnPick = function(s)
			return s:upper():find(sFind)
		end
	end

	local arr = List()
	for k, _v in pairs(obj) do
		if fnPick(k) then
			arr:insert(k)
		end
	end
	Log(arr:sort())
end

-- Log 支持多参数
function Log(...)
	local args = {...}
	if #args == 0 then
		return DoLogOne(nil)
	end

	for _k, v in pairs(args) do
		DoLogOne(v)
	end
end

function DoLogOne(obj)
	local sType = type(obj)
	if 'table' == sType then
		local parentDic = {} -- 记录父节点
		parentDic[obj] = true
		local tabCount = 1       -- 缩进数
		local mt = getmetatable(obj)
		if mt and mt.__index == IList then
			print("{   -- is List class")
		else
			print("{")
		end
		for k, v in pairs(obj) do
			DoLogTableKV(k, v, tabCount, parentDic)
		end
		print("}")
	elseif 'string' == sType then
		print("\'" .. obj:toText() .. "\'")
	elseif 'number' == sType then
		print(obj)
	elseif 'boolean' == sType then
		print(obj)
	else
		print(sType)
	end
end

function DoLogTableKV(k, obj, tabCount, parentDic)
	local sOut = string.rep(' ', tabCount * 4)

	local function fnValToText(val)
		local sType = type(val)
		if sType == 'string' then
			return "\'" .. val .. "\'"
		elseif sType == 'number' then
			return "" .. val
		elseif val == true then
			return "true"
		elseif val == false then
			return "false"
		else
			return "nil, -- not support value type " .. sType
		end
	end

	local function fnIsAZ_az(val)
		if (val:head() == '_') or
			("a" <= val and val <= "z") or
			("A" <= val and val <= "Z") then
			return true
		else
			return false
		end
	end

	local function fnKeyToText(val)
		-- key只能是string, number类型
		local sType = type(val)
		if sType == 'string' then
		--	if val:len() == 8 then -- 可能是64位int
				return "['" .. val .. "']"
		--	elseif val:allIs(fnIsAZ_az) then
		--		return val:toText()
		--	else
		--		return "['" .. val:toText() .. "']"
		--	end
		elseif sType == 'number' then
			return "[" .. val .. "]"
		else
			return "-- not support key type " .. sType
		end
	end

	-- 判断是否table
	local sType = type(obj)
	if 'table' ~= sType then
		sOut = sOut .. fnKeyToText(k) .. " = " .. fnValToText(obj) .. ","
		print(sOut)
		return
	end

	-- 判断是否存在父节点死循环
	if parentDic[obj] then
		sOut = sOut .. fnKeyToText(k) .. " = " .. "nil" .. "," .. " -- can not print parent table!"
		print(sOut)
		return
	end

	parentDic[obj] = true -- 记录父节点
	tabCount = tabCount + 1   -- 缩进数 + 1
	print(sOut .. fnKeyToText(k) .. " = ")
	local mt = getmetatable(obj)
	if mt and mt.__index == IList then
		print(sOut .. "{   -- is List class ")
	else
		print(sOut .. "{")
	end

	for k, v in pairs(obj) do
		DoLogTableKV(k, v, tabCount, parentDic)
	end
	print(sOut .. "},")
	parentDic[obj] = nil -- 解除记录
end

-- 显示图片占用内存
function LogPicMem()
	cc.TextureCache:getInstance():dumpCachedTextureInfo()
end



----------------------------------------------------------------------
-- 功能: 建列表列表
function List(ls)
	ls = ls or {}
	setmetatable(ls, {__index=IList})
	return ls
end


-- 列表的具体实现
IList = {}

----------------------------------------------------------------------
-- 功能: 转成文本
function IList:toText()
	return string:join(self, ",")
end

----------------------------------------------------------------------
-- 功能: 在尾部加入列表
function IList:appendList(arr, fnCond)
	fnCond = fnCond or function() return true end
	for _k, v in pairs(arr) do
		if fnCond(v) then
			self:insert(v)
		end
	end
	return self
end

----------------------------------------------------------------------
-- 功能: 转化成新列表
function IList:convert(fnConvertValue)
	local retList = List()
	for k, v in pairs(self) do
		retList[k] = fnConvertValue(v)
	end
	return retList
end

----------------------------------------------------------------------
-- 描述：UI通用函数
----------------------------------------------------------------------
----------------------------------------------------------------------
-- 功  能：停止节点定时器
----------------------------------------------------------------------
function StopNodeTimer(nd)
	nd:stopAllActions()
end

----------------------------------------------------------------------
-- 功  能：开始节点定时器
----------------------------------------------------------------------
function StartNodeTimer(nd, fnTimer, seconds, bSkipFirst)
	nd:stopAllActions()

	local acList = {}
	if bSkipFirst then -- 跳过第一次
        table.insert(acList,cc.DelayTime:create(seconds))
        table.insert(acList,cc.CallFunc:create(fnTimer))
    else
        table.insert(acList,cc.CallFunc:create(fnTimer))
        table.insert(acList,cc.DelayTime:create(seconds))
    end

	nd:runAction(cc.RepeatForever:create(cc.Sequence:create(acList)))
end

----------------------------------------------------------------------
-- 功  能：开始节点定时器一次
----------------------------------------------------------------------
function StartNodeTimerOnce(nd, fnTimer, seconds)
	nd:stopAllActions()
	local acList = {}
    table.insert(acList,cc.DelayTime:create(seconds))
    table.insert(acList,cc.CallFunc:create(fnTimer))
    nd:runAction(cc.Sequence:create(acList))
end
