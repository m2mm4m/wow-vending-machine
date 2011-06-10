local VM=VendingMachine

function VM:CanLootItem(item,quantity)
	local item=self:GetItemID(item)
	if not item then return false end
	local itemFamily=GetItemFamily(item)
	local maxStack=select(8,GetItemInfo(item))
	
	for bag=0,NUM_BAG_SLOTS do
		local freeSlots,bagType=GetContainerNumFreeSlots(bag)
		if bagType and (bagType==0 or bit.band(bagType,itemFamily)>0) then
			if freeSlots>0 then return true end
			for slot=1,GetContainerNumSlots(bag) do
				local _,count=GetContainerItemInfo(bag,slot)
				local itemID=GetContainerItemID(bag,slot)
				if itemID==item and count and count+quantity<=maxStack then
					return true
				end
			end
		end
	end
	return false
end

function VM:IsLastMail(mailID)
	local packageIcon,stationeryIcon,sender,subject,money,CODAmount,daysLeft,itemCount,wasRead,wasReturned,textCreated,canReply,isGM,itemQuantity=GetInboxHeaderInfo(mailID)
	local count=0
	for attachmentIndex=1,ATTACHMENTS_MAX_SEND do
		local name=GetInboxItem(mailID,attachmentIndex)
		if name then
			count=count+1
		end
	end
	return money==0 and count==0
end

function VM:LootMailItem(item,quantity,taken)
	local totalTaken=taken or 0
	local current=current or 0
	for mailID=1,GetInboxNumItems() do
		local packageIcon,stationeryIcon,sender,subject,money,CODAmount,daysLeft,itemCount,wasRead,wasReturned,textCreated,canReply,isGM,itemQuantity=GetInboxHeaderInfo(mailID)
		--print("|cffff0000mail",mailID,"CODAmount",CODAmount,"itemCount",itemCount)
		if not CODAmount or CODAmount==0 then
			for attachmentIndex=1,(itemCount and ATTACHMENTS_MAX_SEND or 0) do
				local itemID=self:GetItemID(GetInboxItemLink(mailID,attachmentIndex))
				if itemID==item then
					local name,itemTexture,count,quality,canUse = GetInboxItem(mailID,attachmentIndex)
					if self:CanLootItem(item,count) then
						--print("|cffff0000mail",mailID," att",attachmentIndex,GetInboxItemLink(mailID,attachmentIndex),count,itemID,item)
						TakeInboxItem(mailID,attachmentIndex)
						
						local _,event,msg
						repeat
							_,event,msg=self:WaitEvent(nil,"MAIL_INBOX_UPDATE","UI_ERROR_MESSAGE")
						until not (event=="UI_ERROR_MESSAGE" and msg~=INVENTORY_FULL)
						
						totalTaken=totalTaken+count
						if self:IsLastMail(mailID) then
							--print("|cffffff00-Wait another update")
							self:WaitEvent(5,"MAIL_INBOX_UPDATE")
						else
							--print("not last mail")
						end
						self:SleepFrame(8,0.3)
						if quantity and totalTaken>=quantity then
							return totalTaken
						else
							return self:LootMailItem(item,quantity,totalTaken)
						end
					end
				end
			end
		end
	end
	return totalTaken
end

function VM:GetItemCountInMail(itemID)
	local itemID=self:GetItemID(itemID)
	local count=0
	for mailID=1,GetInboxNumItems() do
		for attachmentIndex=1,ATTACHMENTS_MAX_SEND do
			local InboxItemID=self:GetItemID(GetInboxItemLink(mailID,attachmentIndex))
			if InboxItemID==itemID then
				local name,itemTexture,count,quality,canUse = GetInboxItem(mailID,attachmentIndex)
				count=count+quality
			end
		end
	end
	return count
end

function VM:MailBulkItem(item,sendTarget)
	if not (MailFrame and MailFrame:IsShown()) then return end
	local sendItem=self:GetItemID(item)
	local itemName,_,_,_,_,_,_,maxStack=GetItemInfo(item)
	if not sendItem then return end
	
	while self:GetNumItemStacks(sendItem)>=12 do
		ClearSendMail()
		
		local numpicked=0
		for bag=0,NUM_BAG_SLOTS do
			for slot=1,GetContainerNumSlots(bag) do
				if self:GetItemID(GetContainerItemLink(bag,slot))==sendItem and numpicked<ATTACHMENTS_MAX_SEND and maxStack==select(2,GetContainerItemInfo(bag,slot)) then
					PickupContainerItem(bag, slot)
					ClickSendMailItemButton()
					numpicked=numpicked+1
				end
			end
		end
		
		SendMail(sendTarget,itemName,"")
		
		local _,event=self:WaitEvent(5,"MAIL_FAILED","MAIL_SEND_SUCCESS")
		if event=="MAIL_FAILED" or event=="MAIL_SEND_SUCCESS" then
			print("Successfully sent "..itemName)
		else
			print("Error sending mail for "..itemName)
		end
		self:SleepFrame(10,0.5)
	end
	
end

function VM:MailTest()
	VM:NewThread(function(self)
		self:MailBulkItem(61979,"Chengguan")
		self:MailBulkItem(61980,"Millionaires")
	end)
end
