local VM=VendingMachine

VM.DEList={
	61979,		--Ashen Pigment
	-- 61978,		--Blackfallow Ink
	52988,		--Whiptail
	52987,		--Twilight Jasmine
	52983,		--Cinderbloom
	52984,		--Stormvine
	-- 52985,		--Azshara's Veil
	-- 52986,		--Heartblossom

	52185,		--Elementium Ore
	53038,		--Obsidium Ore

	52306,				--Jasper Ring
	52310,				--Jasper Ring (Rare)
	52307,				--Alicite Pendant
	52312,				--Alicite Pendant (Rare)
	52309,				--Nightstone Choker
	52314,				--Nightstone Choker (Rare)
	52492,		--Carnelian Spikes
	52329,		--Life
}
VM.CraftList={
	43124,		--Ethereal Ink
	43126,		--Ink of the Sea
	61978,		--Blackfallow Ink
	61981,		--Inferno Ink
	
	52306,		--Jasper Ring
	52307,		--Alicite Pendant
	52309,		--Nightstone Choker
}
if UnitName("player")=="\195\141\195\172" or UnitName("player")=="凌蓝果树" or UnitName("player")=="那个图腾" then
	VM.MailList={
		[61978]="歆颜尐美",		--Blackfallow Ink
		-- [61979]="歆颜尐美",		--Ashen Pigment
		[61981]="歆颜尐美",	--Inferno Ink
	}
else
	VM.MailList={
		-- [61979]="Chengguan",	--Ashen Pigment
		-- [61980]="Millionaires",	--Burning Embers
		[61978]="Inkinv",		--Blackfallow Ink
		[61981]="Luxinv",	--Inferno Ink
		[52555]="Enchinv",	--Hypnotic Dust
		[52718]="Enchinv",	--Lesser Celestial Essence
		[52719]="Enchinv",	--Greater Celestial Essence

		[52178]="Jcinv",		--Zephyrite
		[{	52179,				--Alicite
			52180,				--Nightstone
			52182,				--Jasper
		}]="Jcinv",
		[{	52190,				--Inferno Ruby
			52193,				--Ember Topaz
			52177,				--Carnelian
			52181,				--Hessonite
		}]="Lanaya",
		[{	52191,				--Ocean Sapphire
			52192,				--Dream Emerald
			52194,				--Demonseye
			52195,				--Amberjewel
		}]="Jcinv",
	}
end

VM:NewProcessor("AutoCraft",function(self)
	local mailList={[{
		52306,				--Jasper Ring
		52310,				--Jasper Ring (Rare)
		52307,				--Alicite Pendant
		52312,				--Alicite Pendant (Rare)
		52309,				--Nightstone Choker
		52314,				--Nightstone Choker (Rare)
	}]="Weiba",}
	while true do
		self:WaitExp(nil,self.IsPlayerIdle)
		for index,item in ipairs(VM.CraftList) do
			self:CraftItem(item)
			if not self:CanLootItem(item,1) then break end
		end
		if self:IsMailOpen() then
			for itemID,sendTarget in pairs(mailList) do
				self:MailBulkItem(itemID,sendTarget)
			end
			self:SleepFrame(10,0.5)
		end
		
		local available=0
		for index,item in ipairs(VM.CraftList) do
			available=available+self:GetCraftingNumAvailable(item)
		end
		if available==0 then
			for index,item in ipairs(VM.CraftList) do
				if self:TakeTradeskillRegent(item) then break end
			end
		end
		self:YieldThread()
	end
end)

VM:NewProcessor("AutoDE",function(self)
	local autoDEFrame=AutoDEPromptYes and AutoDEPromptYes:GetParent()
	assert(autoDEFrame,"Cant find Enchantrix")
	
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

		if enableAutoSend and self:IsMailOpen() then
			for itemID,sendTarget in pairs(VM.MailList) do
				self:MailBulkItem(itemID,sendTarget)
			end
			-- self:SleepFrame(10,0.5)
		end

		if self:IsMailOpen() then
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

VM:NewProcessor("Remail",function (self)
	local mailList={
		[52988]=true,
		[52987]=true,
		[52983]=true,
		[52984]=true,
		[52985]=true,
		[52986]=true,
		[52185]=true,		--Elementium Ore
		[53038]=true,		--Obsidium Ore
	}
	if UnitName("player")=="Paupers" then
		for key,value in pairs(mailList) do mailList[key]="Chengguan" end
	elseif UnitName("player")=="Pchinv" then
		for key,value in pairs(mailList) do mailList[key]="Pikkachu" end
	end
	-- print("Remail...")
	while true do
		-- print("PostalOpenAll:",self.externalLib,VM.PostalOpenAll)
		print(self:PostalOpenAll(),"taken")
		self:YieldThread()
		for itemID,sendTarget in pairs(mailList) do
			self:MailBulkItem(itemID,sendTarget)
		end
	end
end)

function VM:PostalOpenAll()
	if not IsAddOnLoaded("Postal") then LoadAddOn("Postal") end
	local Postal = LibStub("AceAddon-3.0"):GetAddon("Postal",true)
	assert(Postal,"Cannot find Postal")
	local Postal_OpenAll = Postal:GetModule("OpenAll")
	local PostalL=LibStub("AceLocale-3.0"):GetLocale("Postal")
	
	local startTime=time()
	local count=0
	Postal_OpenAll:OpenAll()
	repeat
		self:WaitSteadyValue(20,1+select(3,GetNetStats())/1000,GetInboxNumItems)
		self:WaitSteadyValue(nil,1,InboxCloseButton.IsShown,InboxCloseButton)
		local numItems,totalItems=GetInboxNumItems()
		count=totalItems-numItems
		if totalItems==0 then break end
		if PostalOpenAllButton:GetText()=="Open All" then
			print("break")
			break
		elseif self:HasMailToLoot() then
			Postal_OpenAll:OpenAll()
		end
	until PostalOpenAllButton:GetText()==PostalL["Open All"] or time()-startTime>300
	return count
end

-------------------------------------------------------------

local TSMAuc=LibStub and LibStub("AceAddon-3.0") and LibStub("AceAddon-3.0"):GetAddon("TradeSkillMaster_Auctioning",true)
if not TSMAuc then return end
local Post = TSMAuc:GetModule("Post")
local Cancel = TSMAuc:GetModule("Cancel")

local TSMAuc_L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Auctioning") -- loads the localization table

function VM:IsAHOpen()
	return AuctionFrame and AuctionFrame:IsShown()
end

--Move to AH and open AuctionFrame
function VM:OpenAH(AHPath,AuctioneerName)
	if self:IsAHOpen() then return true end

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
	local ret=self:WaitExp(10,self.IsAHOpen,self)
	self:SetStatus("none")

	if not ret then print("OpenAH failed opening AH?") return false end
	--Since there could be loads of script to run at the beginning of AUCTION_HOUSE_SHOW, wait for em
	self:SleepFrame(15,0.5)	--Sleep for 15 OnUpdates, with at least 0.5 sec
	GetOwnerAuctionItems()
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

function VM:GetTSMStatus()
	local minorBar,majorBar=TSMMinorStatusBar,TSMMajorStatusBar
	return (minorBar and minorBar:GetValue() or 0).."-"..(majorBar and majorBar:GetValue() or 0)
end

function VM:PostAuctions(AHPath,AuctioneerName)
	local ret=self:OpenAH(AHPath,AuctioneerName)
	if not ret then print("failed opending AH?") return false end

	rawset(TSMAuc.db.global,"bInfo","_#A#A#X")

	self:PostScan()
	self:Sleep(1)

	local haveShown=false
	local lastUpdate,prevStatus=time()
	while true do
		if prevStatus==self:GetTSMStatus() then
			if time()-lastUpdate>60 then print(prevStatus,self:GetTSMStatus(),time(),lastUpdate) break end
		else
			lastUpdate,prevStatus=time(),self:GetTSMStatus()
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
	TSMAuc.Post:StopPosting()
	self:SetStatus("none")
	self:SleepFrame(15,0.5)
	return true
end

function VM:CancelAuctions(AHPath,AuctioneerName)
	local ret=self:OpenAH(AHPath,AuctioneerName)
	if not ret then return 0 end

	self:CancelScan()
	self:Sleep(1)
	local count=0
	local haveShown=false
	local lastUpdate,prevStatus=time()
	while true do
		if prevStatus==self:GetTSMStatus() then
			if time()-lastUpdate>60 then print(prevStatus,self:GetTSMStatus(),time(),lastUpdate) break end
		else
			lastUpdate,prevStatus=time(),self:GetTSMStatus()
		end

		if (TSMAuc.Manage.doneCanceling and TSMAuc.Manage.doneCanceling:IsShown()) or (haveShown and Cancel.frame and not Cancel.frame:IsShown()) then break end
		if Post.frame and Post.frame:IsShown() then haveShown=true end
		if Cancel.frame and Cancel.frame.button:IsEnabled() then
			self:HardDrive(true,"/click TSMAucCancelButton")
			local text=Cancel.frame.button:GetText()
			count=tonumber(text:match("Cancel Auction %d+ / (%d+)")) or count
		end
		self:YieldThread()
	end
	TSMAuc.Cancel:StopCanceling()
	self:SetStatus("none")
	self:SleepFrame(15,0.5)	--Sleep for 15 OnUpdates, with at least 0.5 sec
	return count
end

function VM:OpenMail(timeout)
	if self:IsMailOpen() then return true end
	local timeout=timeout or 10
	self:SetStatus("mouseclick",1,0)	--Flag for "mouseclick"
	local ret=self:WaitExp(timeout,self.IsMailOpen,self)
	if not ret then return false end
	self:SetStatus("none")
	self:WaitEvent(5,"MAIL_INBOX_UPDATE")

	self:WaitSteadyValue(nil,1,InboxCloseButton.IsShown,InboxCloseButton)

	-- print("BC collection completed")
	self:SleepFrame(10,0.5)
	return true
end

function VM:TakeMails(MailPath,MailFacing,View)
	local count=0
	local mailopen=self:IsMailOpen()
	if not mailopen then
		SetView(View)
		self:MoveRoute(MailPath)
		self:SetPlayerFacing(MailFacing)
		SetView(View)
		mailopen=self:OpenMail()
	end
	if mailopen then
		print("open mail")
		count=self:PostalOpenAll()
		-- self:WaitSteadyValue(nil,nil,function()
			-- local cur,total=GetInboxNumItems()
			-- count=total-cur
			-- if cur==0 then return true end
			-- return cur
			-- return PostalOpenAllButton:GetText()=="Open All"
		-- end)
	end
	return count
end

VM:NewProcessor("DalaSell",function (self)
	-- local AHPath={{0.39080762863159, 0.2708243727684,2},{0.38750076293945, 0.25654846429825}}
	local AHPath={{0.39034032821655,0.27777343988419},{0.38976144790649,0.2540397644043}}
	local AuctioneerName="Brassbolt Mechawrench"
	if GetLocale()=="zhCN" then AuctioneerName="布拉斯博特·机钳" end
	local MailPath={{0.39074057340622, 0.2659507393837},{0.39034032821655,0.27777343988419},{0.40370684862137, 0.32425612211227,0.5}}
	local MailFacing=3.8213820457458

	local count=0
	local prevTakeMail=time()
	while true do
		if self:IsMailOpen() or count>0 or time()-prevTakeMail>1200 then
			count=self:TakeMails(MailPath,MailFacing,1)
			prevTakeMail=time()
		end
		print("posting auctions")
		self:PostAuctions(AHPath,AuctioneerName)
		if count<10 then
			print("cancelling auctions")
			self:Sleep(1)
			count=count+self:CancelAuctions(AHPath,AuctioneerName)
			print("count",count)
		end
	end
end,
function (self)
	self:SetStatus("none")
end)

VM:NewProcessor("ExodarSell",function (self)
	-- local AHPath={{0.39080762863159, 0.2708243727684,2},{0.38750076293945, 0.25654846429825}}
	local AHPath={{0.60774600505829,0.52000331878662},{0.63213300704956, 0.58582437038422}}
	local AuctioneerName="Auctioneer Iressa"
	-- if GetLocale()=="zhCN" then AuctioneerName="布拉斯博特·机钳" end
	local MailPath={{0.63213300704956, 0.58582437038422},{0.60774600505829,0.52000331878662},{0.60023027658463, 0.51842176914215,0.5}}
	local MailFacing=1.8157052993774
	local goldReserve=500
	local sendGoldMin=5000
	local sendGoldTarget="Pikkachu"
	
	_G["DoEmote"]=function() end
	
	-- print(MailPath[#MailPath][1],MailPath[#MailPath][2],self:GetPlayerPos())
	local count=0
	local prevTakeMail=time()
	while true do
		if self:IsMailOpen() or (self:CalcDistance(MailPath[#MailPath][1],MailPath[#MailPath][2],select(3,self:GetPlayerPos()))<=MailPath[#MailPath][3]) or count>0 or time()-prevTakeMail>1200 then
			count=self:TakeMails(MailPath,MailFacing,1)
			local gold=(floor(GetMoney()/10000/goldReserve)-1)*goldReserve
			if gold>=sendGoldMin then
				self:MailMoney(gold,sendGoldTarget)
			end
			prevTakeMail=time()
		end
		print("posting auctions")
		self:PostAuctions(AHPath,AuctioneerName)
		if count<10 then
			print("cancelling auctions")
			self:Sleep(1)
			count=count+self:CancelAuctions(AHPath,AuctioneerName)
			print("count",count)
		end
		self:PostAuctions(AHPath,AuctioneerName)
	end
end,
function (self)
	self:SetStatus("none")
end)
