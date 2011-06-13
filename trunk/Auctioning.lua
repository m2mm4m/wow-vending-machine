local VM=VendingMachine
local TSMAuc=LibStub and LibStub("AceAddon-3.0") and LibStub("AceAddon-3.0"):GetAddon("TradeSkillMaster_Auctioning",true)
if not TSMAuc then return end
local Post = TSMAuc:GetModule("Post")
local Cancel = TSMAuc:GetModule("Cancel")

local TSMAuc_L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Auctioning") -- loads the localization table

--Move to AH and open AuctionFrame
function VM:OpenAH(AHPath,AuctioneerName)
	if AuctionFrame and AuctionFrame:IsShown() then return true end
	
	self:MoveRoute(AHPath)
	
	local name=AuctioneerName or "Auctioneer"
	for index=1,10 do
		if UnitName("target") and UnitName("target"):find(name) then break end
		self:HardDrive(true,"/target "..name)
	end
	if not (UnitName("target") and UnitName("target"):find(name)) then
		print("OpenAH failed selecting target?")
		return false
	end
	
	self:SetStatus("keypress_vk",0xDE,0)
	local ret=self:WaitExp(10,function () return AuctionFrame and AuctionFrame:IsShown() end)
	self:SetStatus("none")
	
	if not ret then print("OpenAH failed opening AH?") return false end
	
	--Since there could be loads of script to run at the beginning of AUCTION_HOUSE_SHOW, wait for em
	self:SleepFrame(15,0.5)	--Sleep for 15 OnUpdates, with at least 0.5 sec
	return true
end

--An ugly call to TSMAuc.Post.StartScan()
function VM:PostScan()
	for index,value in ipairs(TSMAPI.private.functions) do
		if value.module=="TradeSkillMaster_Auctioning" and value.tooltip==TSMAuc_L["Auctioning - Post"] then
			TSMAPI.private:ShowFunctionPage(index)
			return
		end
	end
end

function VM:CancelScan()
	for index,value in ipairs(TSMAPI.private.functions) do
		if value.module=="TradeSkillMaster_Auctioning" and value.tooltip==TSMAuc_L["Auctioning - Cancel"] then
			TSMAPI.private:ShowFunctionPage(index)
			return
		end
	end
end

--Go to AH and post items
local TSMAucDBMeta={__index=function (table,key)
	print("Attempt to get",key,":",debugstack())
	if key=="bInfo" then
		return "_#A#A#X"
	end
	return rawget(table,key)
end,
__newindex=function (table,key,value)
	if key=="bInfo" then
		print("Attempt to set bInfo",debugstack())
		return
	end
	return rawset(table,key,value)
end,}

function VM:PostAuctions(AHPath,AuctioneerName)
	local ret=self:OpenAH(AHPath,AuctioneerName)
	if not ret then print("failed opending AH?") return false end
	
	local minorBar,majorBar=TSMMinorStatusBar,TSMMajorStatusBar
	if not minorBar or not majorBar then return 0 end

	rawset(TSMAuc.db.global,"bInfo","_#A#A#X")

	self:PostScan()
	self:Sleep(1)

	local haveShown=false
	local minorStatus,majorStatus,lastUpdate
	while true do
		if minorStatus==minorBar:GetValue() and majorStatus==majorBar:GetValue() then
			if time()-lastUpdate>30 then break end
		else
			minorStatus,majorStatus,lastUpdate=minorBar:GetValue(),TSMMajorStatusBar:GetValue(),time()
		end
		
		if (TSMAuc.Manage.donePosting and TSMAuc.Manage.donePosting:IsShown()) or (haveShown and Post.frame and not Post.frame:IsShown()) then break end
		if Post.frame and Post.frame:IsShown() then haveShown=true end
		if Post.frame and Post.frame.button:IsEnabled() then
			self:HardDrive(true,"/click TSMAucPostButton")
		end
		-- if Post.frame and Post.frame.button:IsEnabled() then
			-- self:SetStatus("keypress_vk",0x78,0)
		-- else
			-- self:SetStatus("none")
		-- end
		self:YieldThread()
	end
	self:SetStatus("none")
	self:SleepFrame(15,0.5)
	return true
end

function VM:CancelAuctions(AHPath,AuctioneerName)
	local ret=self:OpenAH(AHPath,AuctioneerName)
	if not ret then return 0 end
	
	local minorBar,majorBar=TSMMinorStatusBar,TSMMajorStatusBar
	if not minorBar or not majorBar then return 0 end
	
	self:CancelScan()
	self:Sleep(1)
	local count=0
	local haveShown=false
	local minorStatus,majorStatus,lastUpdate
	while true do
		if minorStatus==minorBar:GetValue() and majorStatus==majorBar:GetValue() then
			if time()-lastUpdate>30 then break end
		else
			minorStatus,majorStatus,lastUpdate=minorBar:GetValue(),TSMMajorStatusBar:GetValue(),time()
		end
		
		if (TSMAuc.Manage.doneCanceling and TSMAuc.Manage.doneCanceling:IsShown()) or (haveShown and Cancel.frame and not Cancel.frame:IsShown()) then break end
		if Post.frame and Post.frame:IsShown() then haveShown=true end
		if Cancel.frame and Cancel.frame.button:IsEnabled() then
			self:SetStatus("keypress_vk",0x78,0)
			local text=Cancel.frame.button:GetText()
			count=tonumber(text:match("Cancel Auction %d+ / (%d+)")) or count
		else
			self:SetStatus("none")
		end
		self:YieldThread()
	end
	self:SetStatus("none")
	self:SleepFrame(15,0.5)	--Sleep for 15 OnUpdates, with at least 0.5 sec
	return count
end

function VM:OpenMail(timeout)
	local timeout=timeout or 10
	self:SetStatus("mouseclick",1,0)	--Flag for "mouseclick"
	local ret=self:WaitExp(timeout,function() return MailFrame and MailFrame:IsShown() end)
	if not ret then return false end
	self:SetStatus("none")
	
	self:WaitSteadyValue(nil,1,InboxCloseButton.IsShown,InboxCloseButton)
	
	-- print("BC collection completed")
	self:SleepFrame(10,0.5)
	return true
end

function VM:TakeMails(MailPath,MailFacing,View)
	if not IsAddOnLoaded("Postal") then LoadAddOn("Postal") end
	local Postal = LibStub("AceAddon-3.0"):GetAddon("Postal",true)
	assert(Postal,"Cannot find Postal")
	local Postal_OpenAll = Postal:GetModule("OpenAll")
	
	local count
	SetView(View)
	self:MoveRoute(MailPath)
	self:SetPlayerFacing(MailFacing)
	SetView(View)
	if self:OpenMail() then
		print("open mail")
		Postal_OpenAll:OpenAll()
		
		self:WaitSteadyValue(nil,nil,function()
			local cur,total=GetInboxNumItems()
			count=total-cur
			if cur==0 then return true end
			return PostalOpenAllButton:GetText()=="Open All"
		end)
	end
	return count
end

VM.DEList={
	52988,		--Whiptail
	52987,		--Twilight Jasmine
	52983,		--Cinderbloom
	52984,		--Stormvine
	52985,		--Azshara's Veil
	-- 52986,		--Heartblossom
	
	52185,		--Elementium Ore
	53038,		--Obsidium Ore
	
	52306,		--Jasper Ring
	52492,		--Carnelian Spikes
}
VM.CraftList={
	61978,		--Blackfallow Ink
	61981,		--Inferno Ink
}
VM.MailList={
	-- [61979]="Chengguan",	--Ashen Pigment
	-- [61980]="Millionaires",	--Burning Embers
	[61978]="Tuixin",		--Blackfallow Ink
	[61981]="Millionaires",	--Inferno Ink
	[52555]="Millionaires",	--Hypnotic Dust
	[52718]="Millionaires",	--Lesser Celestial Essence
	[52719]="Millionaires",	--Greater Celestial Essence
	
	[52177]="Yalanayika",	--Carnelian
	[{	52178,				--Zephyrite
		52179,				--Alicite
		52180,				--Nightstone
		52181,				--Hessonite
		52182,				--Jasper
	}]="Yalanayika",
	[52190]="Yalanayika",	--Inferno Ruby
	[{	52191,				--Ocean Sapphire
		52192,				--Dream Emerald
		52193,				--Ember Topaz
		52194,				--Demonseye
		52195,				--Amberjewel
	}]="Yalanayika",
}

VM:NewProcessor("AutoDE",function(self)
	local autoDEFrame=AutoDEPromptYes and AutoDEPromptYes:GetParent()
	if not autoDEFrame then
		print("Cant find Enchantrix")
		return
	end
	
	local function isIdle()
		if LootFrame:IsShown() then return false end
		if UnitCastingInfo("player") then return false end
		if GetUnitSpeed("player")~=0 then return false end
		if IsFalling("player") then return false end
		if UnitIsDeadOrGhost("player") then return false end
		return autoDEFrame:IsShown()
	end
	local enableAutoSend=self:MsgBox("Do you want to enable AutoSend?","n")
	
	while true do
		self:WaitExp(nil,isIdle)
		self:HardDrive(true,"/click AutoDEPromptYes")
		self:WaitExp(nil,isIdle)
		self:SleepFrame(10,0.5)
		
		if self:IsTradeskillOpen() then
			for index,item in ipairs(VM.CraftList) do
				if self:GetCraftingNumAvailable(item)>=80 then
					self:CraftItem(item)
				end
			end
		end
		
		if enableAutoSend and MailFrame and MailFrame:IsShown() then
			for itemID,sendTarget in pairs(VM.MailList) do
				self:MailBulkItem(itemID,sendTarget)
			end
			-- self:SleepFrame(10,0.5)
		end
		
		if MailFrame and MailFrame:IsShown() then
			for index,takeItemID in ipairs(VM.DEList) do
				self:LootMailItem(takeItemID)
			end
			-- self:SleepFrame(10,0.5)
		end
	end
end,
function (self)
	self:SetStatus("none")
end)

VM:NewProcessor("DalaSell",function (self)
	local AHPath={{0.39080762863159, 0.2708243727684,2},{0.38750076293945, 0.25654846429825}}
	local AuctioneerName="Brassbolt Mechawrench"
	local MailPath={{0.39080762863159, 0.2708243727684,2},{0.40370684862137, 0.32425612211227,0.5}}
	local MailFacing=3.8213820457458
	
	local count=0
	while true do
		print("posting auctions")
		self:PostAuctions(AHPath,AuctioneerName)
		if count<10 then
			print("cancelling auctions")
			self:Sleep(1)
			count=count+self:CancelAuctions(AHPath,AuctioneerName)
			print("count",count)
		end
		if count>0 then
			count=self:TakeMails(MailPath,MailFacing,1)
		end
	end
end,
function (self)
	self:SetStatus("none")
end)
