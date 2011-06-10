﻿local VM=VendingMachine

function VM:IsTradeskillOpen()
	if TradeSkillFrame and TradeSkillFrame:IsShown() then
		return not IsTradeSkillLinked()
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
	VM:SelectTradeSkill(item)
	local ret=GetTradeskillRepeatCount()
	SelectTradeSkill(index)
	return ret
end

function VM:OpenTradeskill(Tradeskill)
	self:HardDrive(true,"/cast "..Tradeskill)
	self:WaitExp(nil,VM.IsTradeskillOpen)
	self:SleepFrame(10,0.5)
end

function VM:CraftItem(itemID,numCraft)
	local numAvailable,index=self:GetCraftingNumAvailable(itemID)
	if not numAvailable then return 0 end
	if not numCraft or numCraft>numAvailable then
		numCraft=numAvailable
	end
	if numCraft<=0 then return 0 end
	self:HardDrive(true,("/run DoTradeSkill(%d,%d)"):format(index,numAvailable))
	self:WaitExp(nil,function () return UnitCastingInfo("player") end)
	self:WaitSteadyValue(15,0.5,function () return self:GetTradeskillRepeatCount(itemID)==1 end)
	self:WaitSteadyValue(15,0.5,function () return not UnitCastingInfo("player") end)
	return numCraft
end

function VM:GetCraftingNumAvailable(itemID)
	if not VM:IsTradeskillOpen() then return 0 end
	if not itemID then return 0 end
	
	for index=1,GetNumTradeSkills() do
		local item=self:GetItemID(GetTradeSkillItemLink(index))
		if item==itemID then
			local _,_,numAvailable=GetTradeSkillInfo(index)
			return numAvailable,index
		end
	end
end

function VM:RemoveTradeskillFilters()
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
