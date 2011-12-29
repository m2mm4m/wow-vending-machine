local _GLOBALNAME="WoWDriver"
_G[_GLOBALNAME]={}
local WD=_G[_GLOBALNAME]

WD.APPTITLE="WoW Driver"
WD.AUTHOR="llxibo"
WD.MAX_TIMER=20

function WD:error(msg)
	if not WD.SILENT_MODE then
		Msgbox(msg)
	end
end

function WD:LoadLib(file)
	if not file then return end
	local ret,result=loadfile(file)
	if not ret then
		WD:error(("Error compiling lib %s: %s"):format(file,result or "UNKNOWN ERROR"))
	end
	local ret,result=pcall(ret,_GLOBALNAME,WD)
	if not ret then
		WD:error(("Error loading lib %s: %s"):format(file,result or "UNKNOWN ERROR"))
	end
end

function WD:Init()
	Menu("Tray","Tip",WD.APPTITLE.." powered by "..WD.AUTHOR)
	_G["AHKCallbackFunc"]=WD.AHKCallback
	
	WD:LoadLib("ClientControl")
end

do
	local reg={}
	function WD.AHKCallback(refStr)
		-- Msgbox(refStr)
		local index=refStr:match("WoWDrv_Timer(%d+)")
		index=index and tonumber(index)
		if index and reg[index] then
			local info=reg[index]
			info.func(unpack(info.args))
		end
	end
	
	function WD:AddTimer(...)
		for index=1,WD.MAX_TIMER do
			if not reg[index] then
				reg[index]={}
				WD:SetTimer(index,...)
				return index
			end
		end
	end
	
	function WD:SetTimer(index,interval,func,...)
		if not reg[index] then return end
		local info=reg[index]
		info.interval=interval
		info.func=func
		info.args={...}
		SetTimer("WoWDrv_Timer"..index,interval)
	end
	
	function WD:RemoveTimer(index)
		reg[index]=nil
		SetTimer("WoWDrv_Timer"..index,"Off")
	end
end

WD:Init()
