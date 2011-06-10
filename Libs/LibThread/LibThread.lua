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

function private.OnUpdate(self,elapsed)
	if #threads>0 then
		lib.timeAvail=lib.timeAvail or private.getTimeAvail()
		for index,thread in ipairs(threads) do thread._yieldThread=nil end
		while lib.timeAvail>=0 do
			if not private.dispatchNext() then return end
		end
		lib.timeAvail=nil
	end
end

local tmpEventList={}
function private.OnEvent(frame,event,...)
	if not eventReg[event] then return end
	wipe(tmpEventList)
	repeat	--Move all unsuspended thread to temp table and unregister all events for them
		local cont=true	--to avoid an infinite loop dispatching one thread
		for index,thread in ipairs(eventReg[event]) do
			if not thread._suspended then
				tinsert(tmpEventList,thread)
				thread:UnregisterAllEvents()
				cont=false break
			end
		end
	until cont
	for index,thread in ipairs(tmpEventList) do private.dispatchThread(thread,event,...) end
end

function private.getTimeAvail()
	return (lib.speed/100)^2.5 * 0.1 + 0.015
end

function private.dispatchNext()
	for index,thread in ipairs(threads) do
		if not (thread._yieldThread or thread._suspended) and thread:Status()=="suspended" then
			if thread._sleep then
				local timeElapsed=GetTime()-thread._sleep
				if thread._sleepTime and timeElapsed>=thread._sleepTime then
					thread:UnregisterAllEvents()
					private.dispatchThread(thread,"THREAD_TIMEOUT",timeElapsed)
					return true
				end
			else
				private.dispatchThread(thread,"THREAD_AUTODISPATCH")
				return true
			end
		end
	end
end

function private.dispatchThread(thread,...)
	thread.sliceAvail=lib.timeAvail or 0	--Thread may be dispatched by an event, then timeAvail is nil. Thread should yield on next available yield()
	thread.sliceCount=0
	thread.sliceStart=GetTime()
	thread.sliceElapsed=0
	lib.running=thread
	print("Dispatch thread",thread,...)
	if type(thread.yieldCallback)=="function" then
		pcall(thread.yieldCallback,thread,resume(thread._coroutine,thread,...))
	else
		resume(thread._coroutine,thread,...)	--Return value has been ignored if there's no yieldCallback
	end
	if lib.timeAvail then lib.timeAvail=lib.timeAvail-(GetTime()-thread.sliceStart) end
	lib.running=nil
	if thread:Status()=="dead" or thread._disposed then	--Cleanup for dead or disposed thread
		if type(thread.callback)=="function" then pcall(thread.callback,thread) end
		print("Removing thread",thread)
		thread:UnregisterAllEvents()
		private.tableRemove(threads,thread)
	end
	while #newthreads>0 do	--New threads created during executing this thread
		private.insertByPrio(threads,newthreads[1])	--Move them to thread list
		print("New thread move",newthreads[1])
		tremove(newthreads,1)
	end
end

function private.insertByPrio(table,obj)	--Insert an obj to a table sorted by prio, keeping the table sorted.
	for index,value in ipairs(table) do
		if value.prio<obj.prio then return tinsert(table,index,obj) end
	end
	return tinsert(table,obj)
end

function private.tableRemove(table,item)
	for index,value in ipairs(table) do
		if value==item then return tremove(table,index) end
	end
end

private.threadmt={
	__index=function(table,key)
		local ext=rawget(table,"externalLib")
		return control[key] or (ext and ext[key]) or rawget(table,key)
	end,
	__newindex=function(table,key,value)
		rawset(table,key,value)
		if key=="prio" then
			local function sortfunc(thread1,thread2) return thread1.prio>thread2.prio end
			print("changing prio for",table,"from",table.prio,"to",value)
			table.sort(thread,sortfunc)
			for event,list in pairs(eventReg) do
				table.sort(list,sortfunc)
			end
		end
	end,
}

do
	function control.error(self,message,level)	--Generate an error for a thread if it's not in silent mode, and return THREAD_ERROR token
		local message=("%s: %s"):format(_GlobalName,message or "unknown error")
		local level=level or 1
		if not self.silent then error(message,level+1) end
		return self,"THREAD_ERROR",message
	end
	
	function control.Yield(self,...)
		if not self:Status()=="running" then return self:error("Cannot yield a coroutine outside it",2) end
		return yield(...)
	end
	
	function control.YieldThread(self,...)	--Yield and temporary suspend until next OnUpdate
		self._yieldThread=true
		return self:Yield(...)
	end

	function control.YieldAuto(self,...)
		self.sliceCount=self.sliceCount+1
		local curTime
		local mod=self.sliceCount%100
		if mod==1 then	--Get exact time elapsed every 100 yields
			curTime=GetTime()
			self.sliceElapsed=curTime-self.sliceStart
		else
			curTime=self.sliceStart+self.sliceElapsed+mod/(self.sliceCount-mod)*self.sliceElapsed
		end
		if curTime-self.sliceStart>self.sliceAvail or self._suspended then	--End this slice and record time elapsed
			self.totalElapsed=self.totalElapsed+(GetTime()-self.sliceStart)
			self.totalCount=self.totalCount+self.sliceCount
			return self:Yield(...)
		end
	end

	function control.Sleep(self,delay,...)
		local delay=tonumber(delay)
		if delay<=0 then return self:error("Delay must be greater than zero.") end
		self._sleep=GetTime()
		self._sleepTime=delay
		return self:YieldThread(...)	--This yield could be dispatched by lib
	end
	
	function control.WaitEvent(self,TimeOut,...)
		if not self:Status()=="running" then return self:error("WaitEvent can only be called in running thread",2) end
		
		local eventList=self._eventList
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
			if #eventReg[event]==0 then private.frame:RegisterEvent(event) print("RegisterEvent:",event) end
			private.insertByPrio(eventReg[event],self)
			ValidEvent=true
		end
		
		if not ValidEvent then return self:error("No valid event asserted for WaitEvent",2) end
		self._sleep=GetTime()
		self._sleepTime=TimeOut
		return self:Yield()
	end
	
	function control.UnregisterAllEvents(self)
		self._sleep=nil
		self._sleepTime=nil
		assert(self._eventList,"Can't find event registry for thread")
		for event in pairs(self._eventList) do
			eventReg[event]=eventReg[event] or {}
			private.tableRemove(eventReg[event],self)
			if #eventReg[event]==0 then private.frame:UnregisterEvent(event) print("UnregisterEvent:",event) end
		end
		wipe(self._eventList)
	end

	function control.Status(self)
		return status(self._coroutine)
	end

	function control.Suspend(self,...)	--Suspend a thread and wait for resuming
		self._suspended=true
		if self:Status()=="running" then return self:Yield(...) end
	end

	function control.Resume(self)	--Resume a thread on next dispatch duty
		if self:Status()=="suspended" then
			self._suspended=nil
			self:UnregisterAllEvents()
		end
	end
	
	function control.HardResume(self,...)
		if not self:Status()=="suspended" then return self:error(("Cant resume a %s thread"):format(self:Status()),2) end
		self._suspended=nil
		self:UnregisterAllEvents()
		private.dispatchThread(self,"THREAD_HARDRESUME",...)
	end

	function control.Dispose(self,...)
		self:UnregisterAllEvents()
		self._disposed=true
		self._suspended=true	--To simplify AutoYield logic, also put flag on 'suspended'.
		if self:Status()=="running" then return self:Yield(...) end	--This function may be called inside coroutine itself
	end
end

function lib:New(func,prio,callback,yieldCallback)
	if type(func)~="function" then error(("Usage: %s:New(func,prio,callback) :'func' - function expected, got %s."):format(_GlobalName,type(func))) end
	if prio and type(prio)~="number" then error(("Usage: %s:New(func,prio,callback) :'prio' - number expected, got %s."):format(_GlobalName,type(prio))) end
	if callback and type(callback)~="function" then error(("Usage: %s:New(func,prio,callback) :'callback' - function expected, got %s."):format(_GlobalName,type(callback))) end
	
	local thread=setmetatable({
		_coroutine=coroutine.create(func),
		totalElapsed=0,
		totalCount=0,
		callback=callback,
		yieldCallback=yieldCallback,
		prio=prio or 50,
		_eventList={},
	},private.threadmt)
	if not lib.running or lib.running.prio>prio then	--If the dispatcher is not currently processing a thread
		private.insertByPrio(threads,thread)			--or the processing thread is higher priority than new one
		print("thread established:",thread,"prio",prio)
	else
		tinsert(newthreads,thread)
	end
	return thread
end

function lib:GetNumThreads()
	return #threads
end

function lib:GetThread(index)
	return threads[index]
end

function lib:IsThread(obj)
	return type(obj)=="table" and getmetatable(obj)==private.threadmt
end

function lib:GetRunningThread()
	return lib.running
end

private.frame=CreateFrame("Frame","LibBulkFunctionDispatchFrame")
private.frame:SetScript("OnUpdate",private.OnUpdate)
private.frame:SetScript("OnEvent",private.OnEvent)
