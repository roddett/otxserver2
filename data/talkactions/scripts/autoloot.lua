-- Column -> ALTER TABLE `players` ADD autoloot BLOB NOT NULL AFTER `conditions`;
-- Clean Settings -> UPDATE `players` SET `autoloot` = ""; 

local autoLoot = {}
autoLoot.blockedIds = {}
autoLoot.maxSlots = 5 -- # if you set a lower value than the previous one, you should clean the autoloot settings to reset the players item slots

local isValidItem = function(itemId)
	local it = getItemInfo(itemId)
	return (
		it.movable and 
		it.pickupable and 
		it.worth == 0 and
		it.corpseType == 0
	)
end

local getInputItem = function(typeInput)

	local itemId = tonumber(typeInput) or (getItemIdByName(typeInput) or 0)
	local itemType = getItemInfo(itemId)

	if not itemType then
		return false
	end

	return itemId
end

local useSystem = getBooleanFromString(getConfigValue('useAutoLoot'))
function onSay(cid, words, param, channel)

	if not useSystem then
		return false
	end

	if not checkExhausted(cid, 666, 10) then
		return true
	end

	param = param:lower()
	params = param:explode(",")

-- ###### Miscellaneous Commands ##### --
	if (param == "on") then
		if getAutoLootSetting(cid, AUTOLOOT_STATUS) then
			return doPlayerSendCancel(cid, "Your autoloot is currently active.")
		end

		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[Auto-Loot]: You have enabled the autoloot feature.")
		return setAutoLootSetting(cid, AUTOLOOT_STATUS, 1)
	end

	if (param == "off") then
		if not getAutoLootSetting(cid, AUTOLOOT_STATUS) then
			return doPlayerSendCancel(cid, "Your autoloot is currently disable.")
		end

		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_RED, "[Auto-Loot]: You have disabled the autoloot feature.")
		return setAutoLootSetting(cid, AUTOLOOT_STATUS, 0)
	end

	if (params[1] == "gold" or params[1] == "money") then

		if params[2] == "on" then
			if getAutoLootSetting(cid, AUTOLOOT_GOLD) then
				return doPlayerSendCancel(cid, "Your autoloot is currently colleting gold.")
			end

			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[Auto-Loot]: You autoloot is now collecting gold coins.")
			return setAutoLootSetting(cid, AUTOLOOT_GOLD, 1)
		end

		if params[2] == "off" then
			if not getAutoLootSetting(cid, AUTOLOOT_GOLD) then
				return doPlayerSendCancel(cid, "Your autoloot is not colleting gold.")
			end

			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_RED, "[Auto-Loot]: Your autoloot is not collecting gold coins anymore.")
			return setAutoLootSetting(cid, AUTOLOOT_GOLD, 0)
		end
	end

	if (params[1] == "bank" or params[1] == "transfer") then
		if params[2] == "on" then
			if getAutoLootSetting(cid, AUTOLOOT_BANK) then
				return doPlayerSendCancel(cid, "Your autoloot is currently sending gold coins to your bank account.")
			end

			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[Auto-Loot]: Your autoloot now will send the gold coins to your bank account.")
			return setAutoLootSetting(cid, AUTOLOOT_BANK, 1)
		end

		if params[2] == "off" then
			if not getAutoLootSetting(cid, AUTOLOOT_BANK) then
				return doPlayerSendCancel(cid, "Your autoloot is not sending gold coins to your bank account.")
			end

			doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_RED, "[Auto-Loot]: Your autoloot will no longer send the gold coins to your bank account.")
			return setAutoLootSetting(cid, AUTOLOOT_BANK, 0)
		end
	end

-- ###### List Commands ##### --
	local currentLootList = getAutoLootList(cid)
	if (params[1] == "add") then

		local itemId = params[2]
		if not itemId then
			return doPlayerSendCancel(cid, "Please input the item id or name.")
		end

		itemId = getInputItem(itemId)
		if not itemId then
			return doPlayerSendCancel(cid, "This item does not exists.")
		end

		if not isValidItem(itemId) then
			return doPlayerSendCancel(cid, "This item is not valid, please add another one.")
		end

		if isInArray(autoLoot.blockedIds, itemId) then
			return doPlayerSendCancel(cid, "This item cannot be added to the list.")
		end

		if getAutoLootItemId(cid, itemId) then
			return doPlayerSendCancel(cid, "You already have this item on your list.")
		end

		if #currentLootList >= autoLoot.maxSlots then
			return doPlayerSendCancel(cid, "You cannot add more items to your list.")
		end

		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[Auto-Loot]: You have added -> " .. getItemNameById(itemId) .. " <- to your list.")
		return setAutoLootItemId(cid, itemId)
	end

	if (params[1] == "remove") then

		local itemId = params[2]
		if not itemId then
			return doPlayerSendCancel(cid, "Please input the item id or name.")
		end

		itemId = (getInputItem(itemId) or 0)
		if not getAutoLootItemId(cid, itemId) then
			return doPlayerSendCancel(cid, "This item is not on your list.")
		end

		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_RED, "[Auto-Loot]: You have removed -> " .. getItemNameById(itemId) .. " <- from your list.")
		return eraseAutoLootItemId(cid, itemId)
	end

	if (params[1] == "list") then

		local outputList = {}
		for i = 1, math.max(autoLoot.maxSlots, #currentLootList) do
			outputList[#outputList + 1] = "Item Slot [" .. i .. "] -> " .. (currentLootList[i] and getItemNameById(currentLootList[i]) or "empty")
		end

		return doPlayerPopupFYI(cid, "[+] AutoLoot List [+] \n\n" .. table.concat(outputList, "\n"))
	end

	if (params[1] == "clear") then

		if #currentLootList <= 0 then
			return doPlayerSendCancel(cid, "Your autoloot list is currently empty.")
		end

		doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "[Auto-Loot]: Your item list has been reseted.")
		return clearAutoLootList(cid)
	end

	return doPlayerPopupFYI(cid, table.concat({
		"[+] AutoLoot Commands [+]", "", -- # new line
		"!autoloot [on / off]",
		"!autoloot add, item",
		"!autoloot remove, item",
		"!autoloot list",
		"!autoloot clear", "",
		"Status: " .. (getAutoLootSetting(cid, AUTOLOOT_STATUS) and "active" or "disable"), "",
		"[+] Gold Commands [+]", "",
		"!autoloot gold, [on / off]",
		"!autoloot transfer, [on / off]", "",
		"Status: " .. (getAutoLootSetting(cid, AUTOLOOT_GOLD) and "active" or "disable"),
		"Bank Transfer: " .. (getAutoLootSetting(cid, AUTOLOOT_BANK) and "yes" or "no")
	}, "\n"))
end
