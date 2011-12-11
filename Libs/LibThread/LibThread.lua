local _VERSION = 11
local _GlobalName="LibThread"
if _G[_GlobalName] and _G[_GlobalName].version >= _VERSION then return end
if not _G[_GlobalName] then _G[_GlobalName] = {} end
local lib = _G[_GlobalName]
lib.version = _VERSION

local GetTime=GetTime
--local GetFramerate=GetFramerate
local status=coroutine.status
local yield=coroutine.yield
local resume=coroutine.resume
local wipe=table.wipe
local unpack=unpack
local pcall=pcall

-- lib.MIN_FPS=20
-- lib.MIN_CPU_TIME=0.1
-- lib.FPS_CAP=1/(1/lib.MIN_FPS-lib.MIN_CPU_TIME)
lib.speed=50

local private, control, threads, newthreads, eventReg={}, {}, {}, {}, {}
local print=function(...)  end

--Get property table for a thread
local function p(thread)
	if type(thread)~="table" then return {} end
	local meta=getmetatable(thread)
	return meta and meta.___LibThread or {}
end

function private.OnUpdate(self,elapsed)
	if #threads>0 then
		lib.timeAvail=lib.timeAvail or private.getTimeAvail()
		for index,thread in ipairs(threads) do p(thread).yieldThread=nil end
		while lib.timeAvail>=0 do
			if not private.dispatchNext() then return end
		end
		lib.timeAvail=nil
	end
end

local tmpEventList={}
function private.EventHandler(frame,event,...)
	if not eventReg[event] then return end
	wipe(tmpEventList)
	repeat	--Move all unsuspended thread to temp table and unregister all events for them
		local cont=true	--to avoid an infinite loop dispatching one thread
		for index,thread in ipairs(eventReg[event]) do
			if not p(thread).suspended then
				tinsert(tmpEventList,thread)
				thread:UnregisterAllEvents()
				cont=false
				break
			end
		end
	until cont
	
	-- Dispatch them now
	for index,thread in ipairs(tmpEventList) do
		lib:DispatchThread(thread,event,...)
	end
end

function private.getTimeAvail()
	return (lib.speed/100)^2.5 * 0.1 + 0.015
end

function private.dispatchNext()
	for index,thread in ipairs(threads) do
		local p=p(thread)
		if not (p.yieldThread or p.suspended) and thread:IsSuspended() then
			if p.sleep then
				local timeElapsed=GetTime()-p.sleep
				if p.sleepTime and timeElapsed>=p.sleepTime then
					thread:UnregisterAllEvents()
					lib:DispatchThread(thread,"THREAD_TIMEOUT",timeElapsed)
					return true
				end
			else
				lib:DispatchThread(thread,"THREAD_AUTODISPATCH")
				return true
			end
		end
	end
end

function private.insertByPrio(table,obj)	--Insert an obj to a table sorted by prio, keeping the table sorted.
	local prio=p(obj).prio
	for index,value in ipairs(table) do
		if p(value).prio<prio then return tinsert(table,index,obj) end
	end
	return tinsert(table,obj)
end

function private.tableRemove(table,item)
	for index,value in ipairs(table) do
		if value==item then return tremove(table,index) end
	end
end

function private.MT_index(table,key)
	local ext=rawget(table,"externalLib")
	return control[key] or (ext and ext[key]) or rawget(table,key)
end

function control:error(message,level)	--Generate an error for a thread if it's not in silent mode, and return THREAD_ERROR token
	local message=("%s: %s"):format(_GlobalName,message or "unknown error")
	local level=tonumber(level) or 1
	if not p(self).silent then error(message,level+1) end
	return self,"THREAD_ERROR",message
end

function control:Yield(...)
	if not self:IsRunning() then return self:error("Cannot yield a coroutine outside it",2) end
	return yield(...)
end

function control:YieldThread(...)	--Yield and temporary suspend until next OnUpdate
	p(self).yieldThread=true
	return self:Yield(...)
end

function control:YieldAuto(...)
	local p=p(self)
	p.sliceCount=p.sliceCount+1
	local curTime
	local mod=p.sliceCount%100
	if mod==1 then	--Get exact time elapsed every 100 yields
		curTime=GetTime()
		p.sliceElapsed=curTime-p.sliceStart
	else
		curTime=p.sliceStart+p.sliceElapsed+mod/(p.sliceCount-mod)*p.sliceElapsed
	end
	if curTime-p.sliceStart>p.sliceAvail or p.suspended then	--End this slice and record time elapsed
		p.totalElapsed=p.totalElapsed+(GetTime()-p.sliceStart)
		p.totalCount=p.totalCount+p.sliceCount
		return self:Yield(...)
	end
end

function control:Sleep(delay,...)
	local delay=tonumber(delay)
	if delay<=0 then return self:error("Delay must be greater than zero.") end
	p(self).sleep=GetTime()
	p(self).sleepTime=delay
	return self:YieldThread(...)	--This yield could be dispatched by lib
end

function control:WaitEvent(TimeOut,...)
	if not self:IsRunning() then return self:error("WaitEvent can only be called in a running thread",2) end
	
	local eventList=p(self).eventList
	local ValidEvent
	local TimeOut=tonumber(TimeOut)
	if TimeOut and TimeOut<=0 then TimeOut=nil end
	
	self:UnregisterAllEvents()
	for index,event in pairs{...} do
		if type(event)=="string" then
			eventList[event]=true
		elseif type(event)=="table" then
			for index,event in pairs(event) do eventList[event]=true end
		else
			return self:error("Invalid event type for arguement #"..(index+1),2)
		end
	end
	
	for event in pairs(eventList) do
		eventReg[event]=eventReg[event] or {}
		if #eventReg[event]==0 then private.frame:RegisterEvent(event) end
		private.insertByPrio(eventReg[event],self)
		ValidEvent=true
	end
	
	if not ValidEvent then return self:error("No valid event asserted for WaitEvent",2) end
	p(self).sleep=GetTime()
	p(self).sleepTime=TimeOut
	return self:Yield()
end

function control:UnregisterEvent(event)
	local p=p(self)
	if p.eventList[event] then
		if not eventReg[event] then return end
		private.tableRemove(eventReg[event],self)
		if #eventReg[event]==0 and private.frame:IsEventRegistered(event) then
			private.frame:UnregisterEvent(event)
		end
		p.eventList[event]=nil
	end
end

function control:GetNumEventsRegistered()
	local count,countR=0
	for event in pairs(p.eventList) do
		count=count+1
		if private.frame:IsEventRegistered(event) then countR=countR+1 end
	end
	return count,countR
end

function control:UnregisterAllEvents()
	local p=p(self)
	p.sleep=nil
	p.sleepTime=nil
	for event in pairs(p.eventList) do
		self:UnregisterEvent(event)
	end
end

function control:IsEventRegistered(event)
	return p(self).eventList[event],private.frame:IsEventRegistered(event)
end

function control:Status()
	return status(p(self).coroutine)
end

function control:IsDead()
	return self:Status()=="dead" or p(self).disposed
end

function control:IsRunning()
	return self:Status()=="running"
end

function control:IsSuspended()
	return self:Status()=="suspended"
end

function control:Suspend(...)	--Suspend a thread and wait for resuming
	p(self).suspended=true
	if self:IsRunning() then return self:Yield(...) end
end

function control:Resume()	--Resume a thread on next dispatch duty
	if self:IsSuspended() then
		p(self).suspended=nil
		self:UnregisterAllEvents()
	end
end

function control:HardResume(...)
	if not self:IsSuspended() then return self:error(("Cant resume a %s thread"):format(self:Status()),2) end
	if self:IsDead() then return self:error("Cant resume a dead thread") end
	p(self).suspended=nil
	self:UnregisterAllEvents()
	lib:DispatchThread(self,"THREAD_HARDRESUME",...)
end

function control:Dispose(...)
	self:UnregisterAllEvents()
	p(self).disposed=true
	p(self).suspended=true	--To simplify AutoYield logic, also put flag on 'suspended'.
	if self:IsRunning() then return self:Yield(...) end	--This function may be called inside coroutine itself
end

function control:SetPriority(prio)
	local p=p(self)
	p.prio=prio
	for event in pairs(p.eventList) do
		private.tableRemove(eventReg[event],self)
		private.insertByPrio(eventReg[event],self)
	end
end

function control:GetProperty()
	return p(self)
end

--------------------------------------------
------------- Public Functions -------------
--------------------------------------------

function lib:New(func,prio,callback,yieldCallback)
	if type(func)~="function" then error(("Usage: %s:New(func,prio,callback) :'func' - function expected, got %s."):format(_GlobalName,type(func))) end
	if prio and type(prio)~="number" then error(("Usage: %s:New(func,prio,callback) :'prio' - number expected, got %s."):format(_GlobalName,type(prio))) end
	if callback and type(callback)~="function" then error(("Usage: %s:New(func,prio,callback) :'callback' - function expected, got %s."):format(_GlobalName,type(callback))) end
	
	local thread=setmetatable({},{
		__index=private.MT_index,
		___LibThread={
			VERSION=_VERSION,
			coroutine=coroutine.create(func),
			totalElapsed=0,
			totalCount=0,
			callback=callback,
			yieldCallback=yieldCallback,
			prio=prio or 50,
			eventList={},
		},
	})
	if not private.running or p(private.running).prio>prio then	--If the dispatcher is not currently processing a thread
		private.insertByPrio(threads,thread)			--or the processing thread is higher priority than new one
	else
		tinsert(newthreads,thread)
	end
	return thread
end

function lib:DispatchThread(thread,...)
	local p=p(thread)
	p.sliceAvail=lib.timeAvail or 0	--Thread may be dispatched by an event, then timeAvail is nil. Thread should yield on next available yield()
	p.sliceCount=0
	p.sliceStart=GetTime()
	p.sliceElapsed=0
	private.running=thread
	if type(thread.yieldCallback)=="function" then
		pcall(thread.yieldCallback,thread,resume(p.coroutine,thread,...))
	else
		resume(p.coroutine,thread,...)	--Return value has been ignored if there's no yieldCallback
	end
	if lib.timeAvail then lib.timeAvail=lib.timeAvail-(GetTime()-p.sliceStart) end
	private.running=nil
	if thread:Status()=="dead" or p.disposed then	--Cleanup for dead or disposed thread
		if type(thread.callback)=="function" then pcall(thread.callback,thread) end
		thread:UnregisterAllEvents()
		private.tableRemove(threads,thread)
	end
	while #newthreads>0 do	--New threads created during executing this thread
		private.insertByPrio(threads,newthreads[1])	--Move them to thread list
		tremove(newthreads,1)
	end
end

function lib:FireEvent(event,...)
	return private.EventHandler(nil,event,...)
end

function lib:GetNumThreads()
	return #threads
end

function lib:GetThread(index)
	return threads[index]
end

function lib:IsThread(obj)
	return type(obj)=="table" and p(obj).VERSION
end

function lib:GetRunningThread()
	return private.running
end

private.frame=CreateFrame("Frame","LibBulkFunctionDispatchFrame")
private.frame:SetScript("OnUpdate",private.OnUpdate)
private.frame:SetScript("OnEvent",private.EventHandler)
