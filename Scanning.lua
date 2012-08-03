local VM=VendingMachine

local wipe=table.wipe
-- local Scan = VM:NewModule("Scan")

VM.CachedPostPrice = {}

function VM:GetAuctionConfig(item, key)
	local item = self:GetItemID(item)
	local config = VM.db.AuctionConfig or {}
	if not config[key] then return nil end
	return config[key][item] or config[key].default
end

function VM:SetAuctionConfig(item, key, value)
	VM.db.AuctionConfig = VM.db.AuctionConfig or {}
	local item = item
	if not item == "default" then
		item = self:GetItemID(item)
	end
	local config = VM.db.AuctionConfig
	config[key] = config[key] or {}
	config[key][item] = value
end

function VM:StartScan(itemList, isPosting, isCancelling)
	local itemList = self:FormatItemList(itemList,
		function (var1, var2)
			return GetItemCount(var1) > GetItemCount(var2)
		end
	)
	
	
end

function VM:GetAuctionItemProfitExpectation(item)
	local itemID = self:GetItemID(item)
	
	
end

local function PostAuction(itemLink, minBid, buyoutPrice, runTime, stackSize, numStacks)
	local bag, slot = self:FindContainerItem(itemLink)
	if bag and slot then
		ClearCursor()
		PickupContainerItem(bag, slot)
		ClickAuctionSellItemButton()
		StartAuction(minBid, buyoutPrice, runTime, stackSize, numStacks)
	end
end

function VM:QueueAuctionPost(itemLink, minBid, buyoutPrice, runTime, stackSize, numStacks)
	local itemLink=self:GetSafeLink(itemLink)
	self.HardwareQueue:AddItem{PostAuction, minBid, buyoutPrice, runTime, stackSize, numStacks}
end

VM:NewThread("AuctionTracker", function (self)
	while true do
		local _, event, arg1, arg2, arg3, arg4 = self:WaitEvent(nil, "CHAT_MSG_SYSTEM")
		
	end
end, 1)