local VM=VendingMachine

function VM:IsTradeskillOpen()
	local tradeskillName,rank,maxLevel=GetTradeSkillLine()
	if tradeskillName~="UNKNOWN" and not IsTradeSkillLinked() then
		return tradeskillName,rank,maxLevel
	end
end

function VM:SelectTradeSkill(item)
	if type(item)=="number" and item<=GetNumTradeSkills() then
		return SelectTradeSkill(item)
	end
	local itemID=self:GetItemID(item)
	for index=1,GetNumTradeSkills() do
		local item=self:GetItemID(GetTradeSkillItemLink(index))
		if item==itemID then
			return SelectTradeSkill(index)
		end
	end
end

function VM:GetTradeskillRepeatCount(item)
	local index=GetTradeSkillSelectionIndex()
	self:SelectTradeSkill(item)
	local ret=GetTradeskillRepeatCount()
	SelectTradeSkill(index)
	return ret
end

function VM:OpenTradeskill(Tradeskill,retry)
	local retry=retry or 0
	if retry>5 then return false end
	self:HardDrive(true,"/cast "..Tradeskill)
	self:WaitExp(nil,self.IsTradeskillOpen)
	self:SleepFrame(10,0.5)
	if not self:IsTradeskillOpen()==Tradeskill then
		return self:OpenTradeskill(Tradeskill,retry+1)
	end
	return true
end

--TODO: return the actual number of item crafted
function VM:CraftItem(itemID, numCraft)
	if not self:IsTradeskillOpen() then return 0 end
	local numAvailable,index=self:GetCraftingNumAvailable(itemID)
	if not numAvailable then return 0 end
	local numCraft=numCraft
	if not numCraft or numCraft>numAvailable then
		numCraft=numAvailable
	end
	if numCraft<=0 then return 0 end
	self:HardDrive(true,("/run DoTradeSkill(%d,%d)"):format(index,numCraft))
	self:WaitExp(nil,function () return UnitCastingInfo("player") end)
	self:WaitSteadyValue(15,0.5,function () return self:GetTradeskillRepeatCount(itemID)==1 end)
	self:WaitSteadyValue(15,0.5,function () return not UnitCastingInfo("player") end)
	return numCraft
end

function VM:GetCraftingRegentList(itemID)
	if not self:IsTradeskillOpen() then return {} end
	local skillIndex=self:GetTradeskillIndexByItem(itemID)
	if not skillIndex then return {} end
	local t={}
	for reagentIndex=1,GetTradeSkillNumReagents(skillIndex) do
		local reagentName, reagentTexture, reagentCount, playerReagentCount = GetTradeSkillReagentInfo(skillIndex, reagentIndex)
		local link = self:GetItemID(GetTradeSkillReagentItemLink(skillIndex, reagentIndex))
		t[link]=reagentCount
	end
	return t
end

function VM:GetCraftingNumAvailableInMail(itemID)
	if not self:IsTradeskillOpen() then return 0 end
	local skillIndex=self:GetTradeskillIndexByItem(itemID)
	if not skillIndex then return 0 end
	local available
	for reagentIndex=1,GetTradeSkillNumReagents(skillIndex) do
		local reagentName, reagentTexture, reagentCount, playerReagentCount = GetTradeSkillReagentInfo(skillIndex, reagentIndex)
		local link = self:GetItemID(GetTradeSkillReagentItemLink(skillIndex, reagentIndex))
		local count=floor((self:GetItemCountInMail(link)+playerReagentCount)/reagentCount)
		available=min(count, available or count)
	end
	return (available or 0), skillIndex
end

function VM:GetCraftingNumAvailable(itemID)
	if not self:IsTradeskillOpen() then return 0 end
	local index=self:GetTradeskillIndexByItem(itemID)
	if not index then return 0 end
	local _,_,numAvailable=GetTradeSkillInfo(index)
	return numAvailable,index
end

function VM:GetTradeskillIndexByItem(itemID)
	local itemID=self:GetItemID(itemID)
	for index=1,GetNumTradeSkills() do
		local item=self:GetItemID(GetTradeSkillItemLink(index))
		if item==itemID then
			return index
		end
	end
end

function VM:RemoveTradeskillFilters()
	if not self:IsTradeskillOpen() then return end
	if TradeSkillFilterBarExitButton then
		TradeSkillFilterBarExitButton:Click()
	end
	if TradeSkillFrameSearchBox then
		TradeSkillFrameSearchBox:SetText("")
	end
	for i=GetNumTradeSkills(), 1, -1 do
		local _, sType, _, isExpanded = GetTradeSkillInfo(i)
		if sType == "header" and not isExpanded then
			ExpandTradeSkillSubClass(i)
		end
	end
end
