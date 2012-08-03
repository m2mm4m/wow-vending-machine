local _VERSION = 10
local _GlobalName="VendingMachine"
if _G[_GlobalName] and _G[_GlobalName].version >= _VERSION then return end
local VM = {}
if not _G[_GlobalName] then _G[_GlobalName] = VM end

_G["VM"]=VM
VM.version = _VERSION
VM.UIVer=select(4,GetBuildInfo())
VM.LogLevel=5
local LT=LibThread

VM.StatusCode={
	none=0,
	
	keypress_preset=11,
	
	keypress_asc=21,
	keydown_asc=22,
	keyup_asc=23,
	
	keypress_vk=31,
	keydown_vk=32,
	keyup_vk=33,
	
	mouseclick=51,
	mousemove=52,
	mousesetpreset=53,
	mousemove_left=56,
	mousemove_right=57,
	mousemove_up=58,
	mousemove_down=59,
}

-- VM.Modules={}
-- VM.__ModuleMeta={
	-- __index=function (table,key)
		-- return rawget(table,key) or rawget(VM,key)
	-- end,
-- }
-- VM.__MainMeta={
	-- __index=function (table,key)
		-- local value=rawget(table,key)
		-- if type(value)=="nil" then
			
		-- end
	-- end,
-- }

-- function VM:NewModule(name,module)
	-- if type(name)~="string" then return end
	-- local module=module or {}
	-- setmetatable(module,VM.__ModuleMeta)
	-- VM.Modules[name]=module
	-- return module
-- end

function VM:GetLatency(latencyType)
	if type(latencyType)=="string" and latencyType:lower()=="world" then
		return select(4,GetNetStats())/1000
	else
		return select(3,GetNetStats())/1000
	end
end

function VM:GetSafeLink(link)
	if not link then return end
	local _,link=GetItemInfo(link)
	if not link then
		if LT:IsThread(self) and self:GetProperty(_GlobalName)==_VERSION then
			self:WaitEvent(5,"GET_ITEM_INFO_RECEIVED")
			_,link=GetItemInfo(link)
		else
			return
		end
	end
	link = link and link:match("|H(.-):([-0-9]+):([0-9]+)|h")
	return link and link:gsub(":0:0:0:0:0:0", "")
end

function VM:GetItemID(link)
	if not link then return end
	if type(link)=="table" then return self:Operator("GetItemID",link) end
	if type(link)=="number" or tonumber(link) or link:find("item:(%d+)") then
		local reqlink=select(2,GetItemInfo(link))
		if reqlink then
			link=reqlink
		elseif LT:IsThread(self) and self:GetProperty(_GlobalName)==_VERSION then
			self:WaitEvent(5,"GET_ITEM_INFO_RECEIVED")
			link=select(2,GetItemInfo(link))
		else
			print("Failed converting link", link)
			return
		end
	else
		link=select(2,GetItemInfo(link))
	end
	link=link and link:match("item:(%d+)")
	return tonumber(link)
end

function VM:FormatItemList(itemList, sortFunc)
	local itemListReversed = {}
	local itemListFormatted = {}
	-- Get standard link list
	for index, value in pairs(itemList) do
		local link = self:GetItemLink(value)
		if link then
			itemListReversed[link] =true
		end
	end
	
	for link in pairs(itemListReversed) do
		tinsert(itemListFormatted, link)
	end
	
	if type(sortFunc) == "function" then
		table.sort(itemListFormatted, sortFunc)
	end
	return itemListFormatted
end

function VM:FindContainerItem(itemID)
	local itemID=self:GetItemID(itemID)
	for bag=0,NUM_BAG_SLOTS do
		for slot=1,GetContainerNumSlots(bag) do
			if itemID==self:GetItemID(GetContainerItemLink(bag,slot)) then
				return bag,slot
			end
		end
	end
end

function VM:GetNumItemStacks(itemID)
	local itemID=self:GetItemID(itemID)
	local maxStack=select(8,GetItemInfo(itemID))
	if not maxStack then return 0 end
	local stackCount=0
	for bag=0,NUM_BAG_SLOTS do
		for slot=1,GetContainerNumSlots(bag) do
			if itemID==self:GetItemID(GetContainerItemLink(bag,slot)) then
				local _,count=GetContainerItemInfo(bag,slot)
				if count==maxStack then
					stackCount=stackCount+1
				end
			end
		end
	end
	return stackCount
end

function VM:Operator(operator,arg1,...)
	if type(arg1)=="table" then
		local r={}
		for index=1,#arg1 do
			local ret=self:Operator(operator,arg1[index],...)
			if ret then
				tinsert(r,ret)
			end
		end
		return r
	else
		local status,value
		if type(operator)=="string" and type(self[operator])=="function" then
			status,value=pcall(self[operator],self,arg1,...)
		elseif type(operator)=="function" then
			status,value=pcall(operator,arg1,...)
		end
		if status then return value end
	end
end

function VM:sum(t)
	if not t then return 0 end
	if type(t)~="table" then return tonumber(t) end
	local sum=0
	for index,value in ipairs(t) do
		local v=tonumber(value)
		sum=sum+v
	end
	return sum
end

local TableReverseCache=setmetatable({},{__mode="kv"})
function VM:reverse(t)
	if type(t)=="nil" then return {} end
	if TableReverseCache[t] then return TableReverseCache[t] end
	local r={}
	if type(t)=="table" then
		for index,value in pairs(t) do
			r[value]=index
		end
	else
		r[t]=t
	end
	TableReverseCache[t]=r
	return r
end

function VM:WaitEventConditional(timeOut, condition, ...)
	local startTime=GetTime()
	repeat
		local ret={self:WaitEvent(timeOut-(GetTime()-startTime), ...)}
		if condition(unpack(ret)) then
			return unpack(ret)
		end
	until GetTime()-startTime>=timeOut
	return self, "THREAD_TIMEOUT", GetTime()-startTime
end

function VM:WaitSteadyValue(minCount,minTime,func,...)
	local count=0
	local time=GetTime()
	local minCount=minCount or 0
	local minTime=minTime or 0
	local value=func(...)	--ignored possible errors, just trace back to previous call
	repeat
		self:YieldThread()
		local newvalue=func(...)
		if newvalue==value then
			count=count+1
		else
			count=0
			time=GetTime()
			value=newvalue
		end
	until value and count>minCount and GetTime()-time>minTime
	return value
end

function VM:WaitExp(timeOut,func,...)
	local startTime=GetTime()
	while (not timeOut) or (GetTime()-startTime<timeOut) do
		if func(...) then return true end
		self:YieldThread()
	end
	return false
end

function VM:SleepFrame(minCount,minTime)
	local startTime=GetTime()
	for index=1,minCount do
		self:YieldThread()
	end
	if minTime then
		local timeRemaining=minTime-(GetTime()-startTime)
		if timeRemaining>0 then self:Sleep(timeRemaining) end
	end
end

function VM:WaitSecureHook(timeOut,func)
	self:RegisterSecureHook(func)
	return self:WaitEventConditional(timeOut,
		function (self, event, funcName)
			if event=="SECURE_HOOK_CALLED" and funcName==func then
				return true
			end
		end, "SECURE_HOOK_CALLED")
end

do
	local SecureHookRegistry={}
	function VM:RegisterSecureHook(func)
		if SecureHookRegistry[func] then
			return
		else
			local function hookFunc(...)
				LT:FireEvent("SECURE_HOOK_CALLED", func, ...)
			end
			hooksecurefunc(func, hookFunc)
		end
	end
	
	local SlashCmdRegistry={}
	function VM:RegisterSlashCmd(cmd, ...)
		
	end
	
	function VM:UnregisterSlashCmd(cmd, ...)
	
	end
end

function VM:NewThread(arg1, arg2, arg3, arg4)
	local prio, name, func, isPrivate
	if type(arg1)=="function" then
		func=arg1
		prio=arg2
	else
		name=arg1
		func=arg2
		prio=arg3
		isPrivate=arg4
	end
	prio=prio or 50
	local thread=LT:New(func,prio)
	thread:SetName(name)
	thread:SetProperty("externalLib", VM)
	thread:SetProperty(_GlobalName, _VERSION)
	if name and not isPrivate then VM[name]=thread end
	return thread
end

local ProcessorPrototype={}
function ProcessorPrototype:Start()
	if self.thread then
		return ("%s already exists"):format(self.name)
	else
		VM.processors[self.name]=self
		self.thread=VM:NewThread(self.name.."Thread", self.constructor, self.prio)
		return ("%s started"):format(self.name)
	end
end

function ProcessorPrototype:Stop()
	if VM.processors[self.name]==self and self.thread then
		self.thread:Dispose()
		if self.destructor then pcall(self.destructor,self.thread) end
		self.thread=nil
		return ("%s stopped"):format(self.name)
	else
		return ("%s doesn't exist"):format(self.name)
	end
end

function ProcessorPrototype:Toggle()
	if self.thread then
		return self:Stop()
	else
		return self:Start()
	end
end

function ProcessorPrototype:SetAutoRun(autorun,charName,realmName)
	local db=VM.db
	if not db then print("Can't find VMDB") return end
	db.AutoRunProcessor=db.AutoRunProcessor or {}
	local token=self.name.."-"..(realmName or GetRealmName()).."-"..(charName or UnitName("player"))
	if autorun then
		db.AutoRunProcessor[token]=true
	else
		db.AutoRunProcessor[token]=nil
	end
end

function ProcessorPrototype:__meta_call(...)
	local func=self.__call or self.Toggle
	return func(self,...)
end

function VM:NewProcessor(name,constructor,destructor,prio)
	if not name or not constructor then return end
	VM.processors=VM.processors or {}
	local obj=setmetatable({name=name,constructor=constructor,destructor=destructor,prio=prio,},{__call=ProcessorPrototype.__meta_call,})
	for key,value in pairs(ProcessorPrototype) do
		obj[key]=value
	end
	if VM.processors[name] then
		VM.processors[name]:Stop()
	end
	VM.processors[name]=obj
	VM[name]=obj		--Override previous processor if any
end

function VM:callback(...)
	print("|cff00ff00callback",self:GetName(),...)
end

function VM:yieldCallback(ret,...)
	if not ret then
		print("|cff0000ffyC error",self:GetName(),...)
	end
end

function VM:log(level,...)
	if level<=VM.LogLevel then print(format(...)) end
end

local prevStatus,thisStatus
function VM:SetStatus(status,arg1,arg2)
	prevStatus=thisStatus
	local status=status or "none"
	if not VM.db.StatusEnabled then status="none" end
	local arg1=arg1 or 0
	local arg2=arg2 or 0
	status=VM.StatusCode[status] or status
	VM.StatusTexture:SetTexture(status/255,arg1/255,arg2/255,1)
	thisStatus=("%d-%d-%d"):format(status,arg1,arg2)
	return thisStatus==prevStatus
end

function VM:InputBox(prompt,keylist)
	return self:MsgBox(prompt,"ic",keylist)
end

function VM:MsgBox(prompt,map,keylist)
	local t,_,arg1,arg2={}		--t holds a unique table which is a key identifying the correct resuming call
	local function callback(text)	--Create a closure that can resume the thread with t
		if self:IsDead() then return end
		self:HardResume(t,text)
	end
	IGAS:MsgBox(prompt,map,callback,keylist)
	repeat
		_,_,arg1,arg2=self:Suspend()
	until arg1==t
	return arg2
end

VM:NewThread("VMInit", function (self)
	VM.StatusFrame=CreateFrame("Frame","VendingMachineStatusFrame",nil)
	VM.StatusTexture=VM.StatusFrame:CreateTexture("$parentOverlay","OVERLAY")

	VM.StatusFrame:SetPoint("TOPLEFT",UIParent,"TOPLEFT",0,0)
	VM.StatusFrame:SetWidth(5)
	VM.StatusFrame:SetHeight(5)
	VM.StatusTexture:SetAllPoints()
	VM.StatusFrame:SetFrameStrata("TOOLTIP")
	
	self:WaitEvent(2,"VARIABLES_LOADED")		--!!! This is a test condition !!!
	
	if not VendingMachineDB then VendingMachineDB={} end
	local db=VendingMachineDB
	VM.db=db
	db.StatusEnabled=true
	self:SetStatus("none")
	
	if db.AutoRunProcessor then
		self:SleepFrame(20,1)
		for name,processor in pairs(VM.processors or {}) do
			if db.AutoRunProcessor[name.."-"..GetRealmName().."-"..UnitName("player")] then
				processor:Start()
			end
		end
	end
end)
VM.VMInit:HardResume()
