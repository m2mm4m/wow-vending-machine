local VM=VendingMachine

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
local status={}
VM.HardDriveButton:SetScript("PreClick",function (self,button)
	if InCombatLockdown() then return end
	if not status.thread then
		self:SetAttribute("type",nil)
		return
	end
	status.status="post"
	status.thread:HardResume("HardDrive","Post")
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
		status.thread:HardResume("HardDrive","Done")
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

function VM:HardDrive(type,...)
	local isSecure,action=...
	
	local status=status.status
	if status=="busy" then
		self:YieldThread()
		return "HardDrive","Waiting"
	end
	status.thread=self
	status.isSecure=isSecure
	status.action=action
	if status.status=="idle" or status.status=="running" then
		status.status="running"
		local _,_,event,arg1,arg2=self:YieldThread()
		if arg1=="HardDrive" then
			return arg1,arg2
		else
			return "HardDrive","Failed"
		end
	elseif status.status=="post" then
		self:Yield()
	end
	
end

function VM:HardDriveStop()
	status.status="idle"
	status.thread=nil
	status.isSecure=nil
	--status.
end
