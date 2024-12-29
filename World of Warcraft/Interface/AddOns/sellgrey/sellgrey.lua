function SellGreyItems()
	TotalPrice = 0
	for myBags = 0,4 do
		for bagSlots = 1, GetContainerNumSlots(myBags) do
			CurrentItemLink = GetContainerItemLink(myBags, bagSlots)
				if CurrentItemLink then
					_, _, itemRarity, _, _, _, _, _, _, _, itemSellPrice = GetItemInfo(CurrentItemLink)
					_, itemCount = GetContainerItemInfo(myBags, bagSlots)
					if itemRarity == 0 and itemSellPrice ~= 0 then
						TotalPrice = TotalPrice + (itemSellPrice * itemCount)
						print("Sold: ".. CurrentItemLink .. " for " .. GetCoinTextureString(itemSellPrice * itemCount))
						UseContainerItem(myBags, bagSlots)
					end
				end
		end
	end
	if TotalPrice ~= 0 then
		print("Total Price for all items: " .. GetCoinTextureString(TotalPrice))
	else
		print("No items were sold.")
	end
end

function pdt_ListLimitedItems()
	for nItems = 1, GetMerchantNumItems() do
		iName, _, iPrice, _, NumAvailable, _, _ = GetMerchantItemInfo(nItems)
		if NumAvailable > 0 then
			if not DidIFindSomething then print("Listing Limited Items") end
			DidIFindSomething = true
			print("Page: " .. (floor(nItems/10,0)+1) .. " Slot: " .. (mod(nItems,10)) .. " has " .. GetMerchantItemLink(nItems) .. " for " .. GetCoinTextureString(iPrice) .. " each.")
		end
	end
	if not DidIFindSomething then print("No Limited Items Found") end
	DidIFindSomething = false
end

function pdt_BuyLimitedItems()
	if IsAltKeyDown() then
		for nItems = 1, GetMerchantNumItems() do
			iName, _, iPrice, _, NumAvailable, _, _ = GetMerchantItemInfo(nItems)
			if NumAvailable > 0 then
				print("Buying: (" .. NumAvailable .. ")" .. GetMerchantItemLink(nItems) .. " for " .. GetCoinTextureString(iPrice*NumAvailable) )
				StackSize = select( 8, GetItemInfo( GetMerchantItemLink( nItems ) ) )
				if StackSize > 1 then
					BuyMerchantItem(nItems, NumAvailable)	
				else
					for BuyInSingles = 1, NumAvailable do
						BuyMerchantItem(nItems)
					end
				end
			end
		end
	else
		print("Hold the ALT key down and click this button to buy ALL limited items.")
		pdt_ListLimitedItems()
	end
end