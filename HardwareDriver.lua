﻿local VM=VendingMachine

VM.HardDriveButtonBG=CreateFrame("Frame",nil,UIParent)
VM.HardDriveButtonBG:SetWidth(30)
VM.HardDriveButtonBG:SetHeight(18)
VM.HardDriveButtonBG:SetPoint("TOPRIGHT")
VM.HardDriveButtonBG:SetFrameStrata("TOOLTIP")
VM.HardDriveButtonBG.texture=VM.HardDriveButtonBG:CreateTexture()
VM.HardDriveButtonBG.texture:SetAllPoints()
VM.HardDriveButtonBG.texture:SetTexture(1,1,1,0.2)	

VM.HardDriveButton=CreateFrame("Button","VendingMachineDriveButton",VM.HardDriveButtonBG,"SecureActionButtonTemplate")
VM.HardDriveButton:SetNormalFontObject(GameFontNormal)
VM.HardDriveButton:SetHighlightFontObject(GameFontHighlight)
VM.HardDriveButton:SetDisabledFontObject(GameFontDisable)
VM.HardDriveButton:SetAllPoints()
VM.HardDriveButton:SetText("VMD")
VM.HardDriveButton:Disable()

VM.HardDriveQueue={}

VM.HardDriveKey=0x76
---[[
VM.HardDriveButton:SetScript("PreClick",function (self,button)
	if InCombatLockdown() then return end
	local nextThread=VM.HardDriveQueue[1]
	if not nextThread then
		self:SetAttribute("type",nil)
		return
	end
	if nextThread.isSecure then
		self:SetAttribute("type", "macro")
		self:SetAttribute("macrotext",nextThread.action)
	else
		pcall(nextThread.action)
	end
end)

VM.HardDriveButton:SetScript("PostClick",function (self,button)
	if InCombatLockdown() then return end
	VM.HardDriveButton:Disable()
	self:SetAttribute("type",nil)
	local nextThread=VM.HardDriveQueue[1]
	if nextThread then
		tremove(VM.HardDriveQueue,1)
		nextThread.thread:HardResume("HardDrive")
	end
	VM:HardDriveNext()
end)

function VM:HardDriveRaw(isSecure,action,preCallback,...)
	tinsert(VM.HardDriveQueue,{
		thread=self,
		isSecure=isSecure,
		action=action,
		preCallback=preCallback and {preCallback,...}
	})
	VM:HardDriveNext()
	return self:Suspend()
end

function VM:HardDrive(isSecure,action)
	self:HardDriveRaw(isSecure,action,self.SetStatus,self,"keypress_vk",self.HardDriveKey)
	self:SetStatus("none")
end

function VM:HardDriveNext()
	local nextThread=VM.HardDriveQueue[1]
	if nextThread then
		VM.HardDriveButton:Enable()
		if nextThread.preCallback then
			pcall(unpack(nextThread.preCallback))
		end
	end
end

do return end
--]]
--------------------------------------------------------------------
--[[
-- An simple example without SecureTemplate:
local _,ret,status
repeat
	ret,status=self:HardDrive(false,myFunc)
until ret=="HardDrive" and status=="Done" or someExitingCondition

-- An simple example with SecureTemplate
local _,ret,status
repeat
	ret,status=self:HardDrive(true,"/cast mySpell\n/y i wanna yell something")
until ret=="HardDrive" and status=="Done" or someExitingCondition

-- An example with dynamic SecureTemplate request
local _,ret,status
repeat
	ret,status=self:HardDrive(true,getMyDynamicAction(args))
until ret=="HardDrive" and status=="Done" or someExitingCondition

-- Another example with dynamic SecureTemplate request, high effiency when complex dynamic action calculating
local _,ret,status
repeat
	if status=="PreClick" then
		ret,status=self:HardDrive(true,getMyDynamicAction(args))
	else
		ret,status=self:HardDrive(true,nil)
	end
until ret=="HardDrive" and status=="Done" or someExitingCondition
 ]]
local status={}
-- Internal status for HardDriver (status.status):
-- idle			the driver is idle and waiting for request
-- busy			the driver is busy processing another thread, only valid from self:HardDriverStatus()
-- running		the driver is currently waiting for keypress
-- preclick		PreClick is triggered, calling back for further instructions
-- click		PreClick finished setting button. SecureActionButtonTemplate is processing action body	

VM.HardDriveButton:SetScript("PreClick",function (self,button)
	if InCombatLockdown() then return end
	if not status.thread then
		self:SetAttribute("type",nil)
		return
	end
	if status.status~="running" then return end
	status.status="preclick"
	-- Consider that HardResume(...) may not resume thread at correct entry (inside self:HardDrive(...)),
	-- no data is expected from HardResume(...). If its a correct resume, HardDrive(...) will do that stuff.
	status.thread:HardResume("HardDrive","PreClick")
	-- We assume that all lua scripts are processed after each EndScene()
	-- so that combat lockdown status will not be changed during any resume-yield cycle of a thread.
	-- Then no need to worry about another InCombatLockdown()
	status.status="click"
	if status.isSecure then
		if type(status.action)=="string" then
			self:SetAttribute("type", "macro")
			self:SetAttribute("macrotext",status.action)
		elseif type(status.action)=="table" then
			for key,value in pairs(status.action) do
				self:SetAttribute(key,value)
			end
		end
	elseif type(status.action)=="function" then
		pcall(status.action)
	end
end)

VM.HardDriveButton:SetScript("PostClick",function (self,button)
	if InCombatLockdown() then return end
	VM.HardDriveButton:Disable()
	self:SetAttribute("type",nil)
	if type(status.action)=="table" then
		for key,value in pairs(status.action) do
			self:SetAttribute(key,nil)
		end
	end
	if status.thread then
		return status.thread:HardResume("HardDrive","Done")
	end
end)

function VM:HardDriverStatus()
	if status.status~="idle" then
		if status.thread==self then
			return status.status
		else
			return "busy"
		end
	else
		return "idle"
	end
end

function VM:HardDrive(type,isSecure,action)
	
	if self:HardDriverStatus()=="busy" or InCombatLockdown() then
		return "HardDrive","Waiting",self:YieldThread()
	end
	status.thread=self
	status.isSecure=isSecure
	status.action=action
	if status.status=="idle" then
		status.status="running"
		VM.HardDriveButton:Enable()
		self:SetStatus("keypress_vk",self.HardDriveKey)
		local _,_,event,arg1,arg2=self:YieldThread()
		-- The resume could be by an user HardDrive request, internal PreClick, LibThread AutoResume, or other unknown source
		self:HardDriveStop()
		if arg1=="HardDrive" then
			return arg1,arg2
		else
			return "HardDrive","Failed",event
		end
	elseif status.status=="preclick" then
		self:YieldThread()
	end
	
end

function VM:HardDriveStop()
	status.status="idle"
	status.thread=nil
	status.isSecure=nil
	status.action=nil
end