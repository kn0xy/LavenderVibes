local playerName = UnitName("player")
local playerClass = UnitClass("player")


local function initThisToon(itemInventory)
	if LavenderInventory == nil then
		LavenderInventory = {}
	end
	
	if LavenderInventory[playerName] == nil then
		local toon = LavenderVibes.Util.ColorTextByClass(playerName, playerClass)
		LavenderPrint("Lavender Vibes Inventory: Added character " .. toon)
		LavenderInventory[playerName] = {
			["Class"] = UnitClass("player"),
			["Items"] = {},
			["BankCached"] = 0,
			["Banked"] = {}
		}
	end
	
	itemInventory.BankItems = LavenderInventory[playerName]["Banked"]
end


-- Create a tooltip-like frame for the dropdown menu
local function initOptionsMenu(daddyFrame)	
	local menuTooltip = CreateFrame("Frame", "LavenderOptionsMenuTooltip", daddyFrame)
	menuTooltip:SetWidth(150)
	menuTooltip:SetHeight(131)
	menuTooltip:Hide() -- Hide by default

	-- Set a backdrop for the menu
	menuTooltip:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 }
	})
	menuTooltip:SetBackdropColor(0, 0, 0, 0.8)
	menuTooltip:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)

	-- Function to initialize menu items
	function menuTooltip:CreateItem(text, onClick)
		local button = CreateFrame("Button", nil, menuTooltip)
		button:SetWidth(140)
		button:SetHeight(20)

		-- Set highlight effect
		local highlight = button:CreateTexture(nil, "HIGHLIGHT")
		highlight:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight")
		highlight:SetBlendMode("ADD")
		highlight:SetAllPoints(button)

		-- Position a text label
		button.Label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		button.Label:SetTextColor(125/255, 102/255, 183/255)
		button.Label:SetPoint("LEFT", button, "LEFT", 5, 0)
		button.Label:SetText(text)

		-- Set click behavior
		button:SetScript("OnClick", function()
			onClick()
			menuTooltip:Hide() -- Hide menu after clicking
		end)

		return button
	end
	
	-- Initialize menu items
	menuTooltip.Option1 = menuTooltip:CreateItem("Daddy 1", function() LavenderPrint("Option 1 Selected") end)
	menuTooltip.Option1:SetPoint("TOPLEFT", menuTooltip, "TOPLEFT", 5, -5)
	menuTooltip.Option2 = menuTooltip:CreateItem("Daddy 2", function() LavenderPrint("Option 2 Selected") end)
	menuTooltip.Option2:SetPoint("TOPLEFT", menuTooltip.Option1, "BOTTOMLEFT", 0, -5)
	menuTooltip.Option3 = menuTooltip:CreateItem("Daddy 3", function() LavenderPrint("Option 3 Selected") end)
	menuTooltip.Option3:SetPoint("TOPLEFT", menuTooltip.Option2, "BOTTOMLEFT", 0, -5)
	menuTooltip.Option4 = menuTooltip:CreateItem("Daddy 4", function() LavenderPrint("Option 4 Selected") end)
	menuTooltip.Option4:SetPoint("TOPLEFT", menuTooltip.Option3, "BOTTOMLEFT", 0, -5)
	menuTooltip.Option5 = menuTooltip:CreateItem("Daddy 5", function() LavenderPrint("Option 5 Selected") end)
	menuTooltip.Option5:SetPoint("TOPLEFT", menuTooltip.Option4, "BOTTOMLEFT", 0, -5)

	return menuTooltip
end


-- Initialize the Share button
local function initShareButton(daddyFrame, itemInventory)
	local toggleMenu = daddyFrame.ToggleMenu
	local toggleButton = CreateFrame("Button", "LavenderItemInventoryShareButton", daddyFrame, "UIPanelButtonTemplate")
	toggleButton:SetText("Share")
	toggleButton:SetWidth(100)
	toggleButton:SetHeight(24)
	toggleButton:SetPoint("BOTTOMRIGHT", daddyFrame, "BOTTOMRIGHT", -20, 15)
	toggleButton:SetScript("OnClick", function()
		-- Show or hide the tooltip menu
		if toggleMenu:IsShown() then
			toggleMenu:Hide()
			PlaySound("igMainMenuOptionCheckBoxOff");
		else
			-- Option: Output to /say
			toggleMenu.Option1.Label:SetText("|cffffffff/s            Say|r")
			toggleMenu.Option1:SetScript("OnClick", function()
				itemInventory.OutputToChat("say")
				toggleMenu:Hide()
			end)
			
			-- Option: Output to /party 
			toggleMenu.Option2.Label:SetText("|cffaaabfe/p           Party|r")
			toggleMenu.Option2:SetScript("OnClick", function()
				itemInventory.OutputToChat("party")
				toggleMenu:Hide()
			end)
			
			-- Option: Output to /guild
			toggleMenu.Option3.Label:SetText("|cff20ff20/g           Guild|r")
			toggleMenu.Option3:SetScript("OnClick", function()
				itemInventory.OutputToChat("guild")
				toggleMenu:Hide()
			end)
			
			-- Option: Output to /yell
			toggleMenu.Option4.Label:SetText("|cffff2020/y           Yell|r")
			toggleMenu.Option4:SetScript("OnClick", function()
				itemInventory.OutputToChat("yell")
				toggleMenu:Hide()
			end)
			
			-- Option: Output to /raid
			toggleMenu.Option5.Label:SetText("|cffff7f3f/r            Raid|r")
			toggleMenu.Option5:SetScript("OnClick", function()
				itemInventory.OutputToChat("raid")
				toggleMenu:Hide()
			end)
			
			-- Display the menu
			toggleMenu:SetPoint("TOP", toggleButton, "BOTTOM", 0, -5)
			toggleMenu:Show()
			PlaySound("igMainMenuOptionCheckBoxOn");
		end
	end)
	
	return toggleButton
end


-- Initialize the Character selector dropdown
local function initCharacterFilter(daddyFrame, itemInventory)
	local dropDown = CreateFrame("Frame", "LavenderInventoryCharacterDropDown", daddyFrame, "UIDropDownMenuTemplate")
	dropDown:SetPoint("BOTTOMLEFT", daddyFrame, "BOTTOMLEFT", 5, 10)
	 
	UIDropDownMenu_SetWidth(80, dropDown)
	UIDropDownMenu_Initialize(dropDown, function(frame, level, menuList) 
		local info = {}
		
		-- define list item click handler
		info.func = function()
			local bagsFrame = daddyFrame.BagsItemsFrame.ItemListFrame
			local bankFrame = daddyFrame.BankItemsFrame.ItemListFrame
			local thisText = this:GetText()
			UIDropDownMenu_SetSelectedValue(dropDown, thisText)
			itemInventory:FilterLists()
		end
		
		-- add option: all toons
		info.text, info.arg1 = "All", 1
		info.textR, info.textG, info.textB = 0.6, 0.6, 0.6
		UIDropDownMenu_AddButton(info)
		
		-- add option: current toon
		local ctc = UnitClass("player")
		info.text, info.arg1, info.checked = playerName, 2, false
		info.textR, info.textG, info.textB = LavenderVibes.Util.RgbClassColor(ctc)
		UIDropDownMenu_AddButton(info)
		
		-- add options: other toons
		local startingIndex = 3
		for toon,data in pairs(LavenderInventory) do
			local toonName = toon
			if toonName ~= playerName then
				info.text, info.arg1, info.checked = toonName, startingIndex, false
				info.textR, info.textG, info.textB = LavenderVibes.Util.RgbClassColor(data["Class"])
				UIDropDownMenu_AddButton(info)
				startingIndex = startingIndex + 1
			end
		end
	end)
	
	-- default to current player
	UIDropDownMenu_SetSelectedValue(dropDown, playerName)

	return dropDown
end


-- Initialize the Item Name Filter textbox
local function initNameFilter(daddyFrame, itemInventory)
	local r, g, b = LavenderVibes.Util:LavRGB()
	local editBox = CreateFrame("EditBox", "LavenderInventoryNameFilterEditBox", daddyFrame)
	editBox:SetWidth(150)
	editBox:SetHeight(22)
	editBox:SetPoint("BOTTOMLEFT", daddyFrame, "BOTTOMLEFT", 245, 17)
	editBox:SetFont("Fonts\\FRIZQT__.TTF", 11, "GameFontHighlight")
	editBox:SetAutoFocus(false)
	editBox:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
		tile = true, edgeSize = 1, tileSize = 5
	})
	editBox:SetBackdropColor(0, 0, 0, 1)
	editBox:SetBackdropBorderColor(r, g, b, 0.33)
	editBox:SetTextInsets(5, 5, 0, 0)
	editBox:SetMaxLetters(50)
	editBox:SetText("Search...")
	editBox:SetTextColor(r, g, b, 0.75)

	-- Clear focus when enter or escape pressed
	editBox:SetScript("OnEnterPressed", function() editBox:ClearFocus() end)
	editBox:SetScript("OnEscapePressed", function() editBox:ClearFocus() end)
	
	-- Update lists whenever user enters text
	editBox:SetScript("OnTextChanged", function() itemInventory:FilterLists() end)
	
	-- Handle focus lost
	editBox:SetScript("OnEditFocusLost", function()
		local text = string.gsub(editBox:GetText(), "%s+", "")
		if(text == "") then
			editBox:SetText("Search...")
			editBox:SetTextColor(r, g, b, 0.75)
			editBox:SetBackdropBorderColor(r, g, b, 0.33)
		end
	end)
	
	-- Handle focus gained
	editBox:SetScript("OnEditFocusGained", function()
		local text = editBox:GetText()
		if(text == "Search...") then
			editBox:SetText("")
			editBox:SetTextColor(1, 1, 1)
			editBox:SetBackdropBorderColor(r, g, b, 1)
		else
			editBox:HighlightText()
		end
	end)

	return editBox
end


-- Initialize the Item Quality filter dropdown
local function initQualityFilter(daddyFrame, itemInventory)
	local dropDown = CreateFrame("Frame", "LavenderInventoryQualityDropDown", daddyFrame, "UIDropDownMenuTemplate")
	dropDown:SetPoint("BOTTOMLEFT", daddyFrame, "BOTTOMLEFT", 115, 10)
	 
	UIDropDownMenu_SetWidth(80, dropDown)
	UIDropDownMenu_SetText("Filter", dropDown)
	UIDropDownMenu_Initialize(dropDown, function(frame, level, menuList) 
		local info = {}
		info.keepShownOnClick = true
		
		-- define list item click handler
		info.func = function()
			local thisText = this:GetText()
			if this.checked then
				-- uncheck / set to false
				itemInventory.Filters[thisText] = false
			else
				-- check / set to true
				itemInventory.Filters[thisText] = true
			end
			
			itemInventory:FilterLists()
		end
		
		-- generate dropdown list items
		local qualityOptions = {"Shit", "Common", "Uncommon", "Rare", "Epic", "Legendary"}
		for o,opt in ipairs(qualityOptions) do
			info.text, info.checked = opt, itemInventory.Filters[opt]
			info.textR, info.textG, info.textB = LavenderVibes.Util.RgbQualityColor(opt)
			UIDropDownMenu_AddButton(info)
		end
		
	end)

	return dropDown
end


-- Initialize the sort selector dropdown
local function initSortFilter(daddyFrame, itemInventory)
	local dropDown = CreateFrame("Frame", "LavenderInventorySortByDropDown", daddyFrame, "UIDropDownMenuTemplate")
	dropDown:SetPoint("BOTTOMRIGHT", daddyFrame, "BOTTOMRIGHT", -110, 10) 
	UIDropDownMenu_SetWidth(80, dropDown)
	UIDropDownMenu_SetText("Sort", dropDown)
	UIDropDownMenu_Initialize(dropDown, function(frame, level, menuList) 
		local info = {}
		
		-- define list item click handler
		info.func = function()
			itemInventory.SortedBy = this:GetText()
			itemInventory:FilterLists()
		end
		
		-- add option: by quality
		local sortByQuality = false
		if(itemInventory.SortedBy == "Item Quality") then
			sortByQuality = true
		end
		info.text, info.checked, info.arg1 = "Item Quality", sortByQuality, 1
		UIDropDownMenu_AddButton(info)
		
		-- add option: alphabetically
		local sortAlphabetically = false
		if(itemInventory.SortedBy == "Alphabetically") then
			sortAlphabetically = true
		end
		info.text, info.checked, info.arg1 = "Alphabetically", sortAlphabetically, 2
		UIDropDownMenu_AddButton(info)
		
	end)
	
	-- default to "Item Quality"
	if not itemInventory.SortedBy then
		itemInventory.SortedBy = "Item Quality"
	end

	return dropDown
end

-- Add specified items to the specified list
local function addListItems(list, items)
	list:Clear()

	for itemId, itemData in pairs(items) do
		local numSpaces = 8
		if(tonumber(itemData.totalQty) > 9) then numSpaces = 6 end
		if(tonumber(itemData.totalQty) > 99) then numSpaces = 4 end
		if(tonumber(itemData.totalQty) > 999) then numSpaces = 2 end
		
		local msg = itemData.totalQty
		local mSpaces = 0
		while(mSpaces < numSpaces) do
			msg = msg .. " "
			mSpaces = mSpaces + 1
		end
		msg = msg .. itemData.itemLink
		
		list:AddMessage(msg)	
	end
end


-- Initialize the main frame options
local function initMainOptions(daddyFrame, itemInventory)
	-- Create the dynamic toggle menu
	daddyFrame.ToggleMenu = initOptionsMenu(daddyFrame)
	
	-- Create the Share button
	daddyFrame.ShareButton = initShareButton(daddyFrame, itemInventory)
	
	-- Create the Sort By dropdown
	daddyFrame.SortFilter = initSortFilter(daddyFrame, itemInventory)
	
	-- Create the item name filter textbox
	daddyFrame.NameFilter = initNameFilter(daddyFrame, itemInventory)

	-- Create the item quality filter dropdown
	daddyFrame.QualityFilter = initQualityFilter(daddyFrame, itemInventory)
	
	-- Create the account character filter dropdown
	LavenderVibes.Hooks.add_action("inventory_initialized", function()
		daddyFrame.ToonFilter = initCharacterFilter(daddyFrame, itemInventory)
	end)
end


-- Initialize the main frame
local function initDaddyFrame(itemInventory)
	local r, g, b = LavenderVibes.Util:LavRGB()
	local daddyFrame = CreateFrame("Frame", "LavenderInventoryFrame", UIParent)
	daddyFrame:SetWidth(633)
	daddyFrame:SetHeight(480)
	daddyFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 75)
	daddyFrame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		tile = false,
		tileSize = 0,
		edgeSize = 1,
		insets = { left = 1, right = 1, top = 1, bottom = 1 }
	})
	daddyFrame:SetBackdropBorderColor(r, g, b)
	daddyFrame:Hide()

	-- Title text
	daddyFrame.title = daddyFrame:CreateFontString(nil, "ARTWORK")
	daddyFrame.title:SetPoint("TOP", daddyFrame, "TOP", 0, -10)
	daddyFrame.title:SetTextColor(r, g, b)
	daddyFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 14, "GameFontNormal")
	daddyFrame.title:SetText("Inventory")
	daddyFrame.title:SetTextHeight(15)

	-- Close button
	daddyFrame.closeButton = CreateFrame("Button", "LavenderInventoryCloseButton", daddyFrame, "UIPanelCloseButton")
	daddyFrame.closeButton:SetPoint("TOPRIGHT", daddyFrame, "TOPRIGHT", 0, 0)
	daddyFrame.closeButton:SetScript("OnClick", function()
		PlaySound("igMainMenuClose")
		daddyFrame:Hide()
		daddyFrame.ToggleMenu:Hide()
	end)
	
	-- Draggable
	daddyFrame:EnableMouse(true)
	daddyFrame:SetMovable(true)
	daddyFrame:RegisterForDrag("LeftButton")
	daddyFrame:SetScript("OnDragStart", function() daddyFrame:StartMoving() end)
	daddyFrame:SetScript("OnDragStop", function() daddyFrame:StopMovingOrSizing() end)
	
	--daddyFrame:RegisterEvent("PLAYER_MONEY")
	daddyFrame:SetScript("OnEvent", function()
		LavenderPrint(arg1)
		LavenderPrint(arg2)
		LavenderPrint(arg3)
	end)
	
	-- Close frame when escape key pressed
	table.insert(UISpecialFrames, "LavenderInventoryFrame")
	
	-- Handle frame shown
	daddyFrame:SetScript("OnShow", function()
		PlaySound("igBackPackClose")
		if not daddyFrame.isInitialized then
			itemInventory:FilterUniqueItems()
			
			daddyFrame.isInitialized = true
		end
		itemInventory:FilterLists()
	end)
	
	-- Clear focus on name filter textbox when frame clicked
	daddyFrame:SetScript("OnMouseDown", function()
		daddyFrame.NameFilter:ClearFocus()
	end)

	return daddyFrame

end


-- Initialize scroll buttons for the items lists
local function scrollButtonsForItemsList(itemListFrame)
	-- Add 'Scroll Up' button
	local upButton = CreateFrame("Button", "$parentUpButton", itemListFrame)
	upButton.clickDelay = 0
	upButton:SetWidth(26)
	upButton:SetHeight(26)
	upButton:SetPoint("TOPRIGHT", itemListFrame, "TOPRIGHT", 0, -10)
	upButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up")
	upButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Down")
	upButton:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Disabled")
	upButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
	upButton:SetScript("OnLoad", function() MessageFrameScrollButton_OnLoad() end)
	upButton:SetScript("OnUpdate", function()
		if(itemListFrame:AtTop()) then
			upButton:Disable()
		else
			upButton:Enable()
		end
		MessageFrameScrollButton_OnUpdate(arg1)
	end)
	upButton:SetScript("OnClick", function()
		if(upButton:GetButtonState() == "PUSHED") then
			PlaySound("igChatScrollUp")
		end
		if IsShiftKeyDown() then 
			while not itemListFrame:AtTop() do 
				itemListFrame:ScrollUp()
			end
		end
	end)
	
	-- Add 'Scroll Down' button
	local downButton = CreateFrame("Button", "$parentDownButton", itemListFrame)
	downButton.clickDelay = 0
	downButton:SetWidth(26)
	downButton:SetHeight(26)
	downButton:SetPoint("BOTTOMRIGHT", itemListFrame, "BOTTOMRIGHT", 0, -6)
	downButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
	downButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
	downButton:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled")
	downButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
	downButton:SetScript("OnLoad", function() MessageFrameScrollButton_OnLoad() end)
	downButton:SetScript("OnUpdate", function() 
		if(itemListFrame:AtBottom()) then
			downButton:Disable()
		else
			downButton:Enable()
		end
		MessageFrameScrollButton_OnUpdate(arg1)
	end)
	downButton:SetScript("OnClick", function()
		if(downButton:GetButtonState() == "PUSHED") then PlaySound("igChatScrollDown") end
		if IsShiftKeyDown() then itemListFrame:ScrollToBottom() end
	end)
		
	return upButton, downButton
end


-- Get human readable time from BankCached timestamp
-- (move this to util)
local function getBankCache(toon)
	local bankCached = "Never"
	local bc = LavenderInventory[toon].BankCached
	if(bc and bc > 0) then
		local function stripZero(str)
			if(string.sub(str, 0, 1) == "0") then
				str = string.sub(str, 1)
			end
			return str
		end
		local bct = date("*t", bc)
		local hour = stripZero(tostring(bct.hour))
		if(hour == "0") then hour = "12" end
		local ap = "am"
		if(bct.hour >= 12) then
			local niceHour = bct.hour - 12
			hour = stripZero(tostring(niceHour))
			ap = "pm"
		end
		local mins = tostring(bct.min)
		if(bct.min < 10) then mins = "0" .. tostring(bct.min) end
		local month = stripZero(tostring(bct.month))
		local day = stripZero(tostring(bct.day))
		local year = string.sub(tostring(bct.year), 3)
		bankCached = month .. "/" .. day .. "/" .. year .. " " .. hour
		bankCached = bankCached .. ":" .. mins .. ap
	end
	
	return bankCached
end


-- tooltip
local function listStatsTooltip()
	-- num items total
	-- num items unique
	-- (if > 0) num grays
	-- (if > 0) num whites
	-- (if > 0) num greens
	-- (if > 0) num blues
	-- (if > 0) num epics

end


-- Initialize a new item list container frame
local function itemListContainerFrame(name, daddyFrame)
	local frameName = "Lavender"..name.."ItemInventoryFrame"
	local inventoryFrame = CreateFrame("Frame", frameName, daddyFrame)
	local r, g, b = LavenderVibes.Util:LavRGB()
	local width = 300
	inventoryFrame:SetWidth(width)
	inventoryFrame:SetHeight(400)
	inventoryFrame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 }
	})
	inventoryFrame:SetBackdropBorderColor(r, g, b, 1)
	
	-- Add header text
	inventoryFrame.header = CreateFrame("Frame", nil, inventoryFrame)
	inventoryFrame.header:SetWidth(width)
	inventoryFrame.header:SetHeight(14)
	inventoryFrame.header:SetPoint("TOPLEFT", inventoryFrame, "TOPLEFT", 0, -12);
	inventoryFrame.headerText = inventoryFrame.header:CreateFontString(nil, "ARTWORK");
	inventoryFrame.headerText:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE, MONOCHROME")
	inventoryFrame.headerText:SetPoint("TOP", inventoryFrame.header, "TOP");
	inventoryFrame.headerText:SetText(name .. " Items");
	inventoryFrame.headerText:SetTextColor(r, g, b)
	inventoryFrame.header:EnableMouse(true)
	inventoryFrame.header:SetScript("OnEnter", function()
		GameTooltip:SetOwner(inventoryFrame.header, "ANCHOR_CURSOR")
		GameTooltip:AddLine(name.." Items", r, g, b)
		GameTooltip:AddLine("Stats", 0.8, 0.8, 0.8)
		GameTooltip:AddLine("Mo Staz", 0.8, 0.8, 0.8)
		GameTooltip:Show()
	end)
	inventoryFrame.header:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	-- Add a scrollable message frame to display items
	local ilfName = "Lavender" .. name .. "ItemListMessageFrame"
	local itemListFrame = CreateFrame("ScrollingMessageFrame", ilfName, inventoryFrame)
	itemListFrame:SetWidth(280)
	itemListFrame:SetHeight(350)
	itemListFrame:SetPoint("TOP", inventoryFrame, "TOP", 10, -20)
	itemListFrame:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
	itemListFrame:SetJustifyH("LEFT")
	itemListFrame:SetMaxLines(9999)
	itemListFrame:SetSpacing(4)
	itemListFrame:SetFading(false)
	

	-- Handle mouse wheel scrolling
	itemListFrame:SetScript("OnMouseWheel", function()
		if(arg1 > 0) then
			for i = 1,3 do itemListFrame:ScrollUp() end 
		elseif(arg1 < 0) then
			for i = 1,3 do itemListFrame:ScrollDown() end
		end
	end)
	itemListFrame:EnableMouseWheel(true)
	
	-- Handle itemLink clicked
	itemListFrame:SetScript("OnHyperlinkClick", function()
		if string.sub(arg1, 1, 5) == "item:" then
			-- arg1 = link
			-- arg2 = text
			-- arg3 = button 
			if IsControlKeyDown() then
				DressUpItemLink(arg2);
			elseif IsShiftKeyDown() then
				if ChatFrameEditBox:IsVisible() then
				    ChatFrameEditBox:Insert(arg2);
				else
				    
					LavenderPrint(arg1)
				end
			else
				local x, y = GetCursorPosition()
				ShowUIPanel(ItemRefTooltip);
				ItemRefTooltip:SetOwner(UIParent, "ANCHOR_CURSOR");
				ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE");
				ItemRefTooltip:SetHyperlink(arg1);
				ItemRefTooltip:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
			end
		end
	end)
	
	-- Handle itemLink mouseover
	itemListFrame:SetScript("OnHyperlinkEnter", function()
		-- show tooltip
		GameTooltip:SetOwner(itemListFrame, "ANCHOR_CURSOR")
		GameTooltip:SetHyperlink(arg1)
		
		
		
		if(UIDropDownMenu_GetText(daddyFrame.ToonFilter) == "All") then
			-- find out how many we have and where
			local itemInventory = LavenderVibes.Modules.Inventory
			local item_id = itemInventory.GetItemIdFromLink(arg1)
			local got_some = itemInventory:WhereTheyAt(item_id)
			local ctbc = LavenderVibes.Util.ColorTextByClass
			local spacerAdded = false
			for i,item in ipairs(got_some) do
				if not spacerAdded then 
					GameTooltip:AddLine(" ")
					spacerAdded = true
				end
				local class = LavenderInventory[item.where]["Class"]
				local str = ctbc(item.where, class) .. " - " .. item.at
				GameTooltip:AddDoubleLine(str, item.howmany)
			end
		end
		
		
		GameTooltip:Show()
	end)
	
	-- Handle itemLink mouseout
	itemListFrame:SetScript("OnHyperlinkLeave", function()
		GameTooltip:Hide()
	end)
	
	-- Add scroll buttons
	local btnUp, btnDown = scrollButtonsForItemsList(itemListFrame)
	itemListFrame:SetScript("OnUpdate", function()
		-- hide scroll buttons if less than scrollable items are displayed
		if(itemListFrame:GetNumLinesDisplayed() < 20) then
			btnUp:Hide()
			btnDown:Hide()
		else
			btnUp:Show()
			btnDown:Show()
		end
	end)
	
	-- Add "Last Updated" text
	inventoryFrame.LastUpdated = inventoryFrame:CreateFontString(nil, "ARTWORK");
	inventoryFrame.LastUpdated:SetFont("Fonts\\FRIZQT__.TTF", 10)
	inventoryFrame.LastUpdated:SetPoint("BOTTOM", inventoryFrame, "BOTTOM", 0, 8)
	inventoryFrame.LastUpdated:SetTextColor(r, g, b)
	
	-- create a public reference to the itemListFrame
	inventoryFrame.ItemListFrame = itemListFrame

	return inventoryFrame
end



local function getBagsCached(toon)
	if LavenderInventory[toon].BagsCached then
		return LavenderVibes.Util.TimeSince(LavenderInventory[toon].BagsCached)
	end

	return false
end

-- Initialize the bags items frame
local function initBagsItemsFrame(daddyFrame, itemInventory)
	local inventoryFrame = itemListContainerFrame("Bags", daddyFrame)
	inventoryFrame:SetPoint("TOPLEFT", daddyFrame, "TOPLEFT", 20, -30)
	
	-- register events
	inventoryFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
	inventoryFrame:SetScript("OnEvent", function()
		if(arg1 == "player") then
			itemInventory.GetInventoryItems()
		end
	end)
	
	return inventoryFrame
end



	

-- Initialize the bank items frame
local function initBankItemsFrame(daddyFrame, itemInventory)
	local bankCached = getBankCache(playerName)
	local inventoryFrame = itemListContainerFrame("Bank", daddyFrame)
	inventoryFrame:SetPoint("TOPRIGHT", daddyFrame, "TOPRIGHT", -20, -30)
	inventoryFrame.LastUpdated:SetText("Last Updated: " .. bankCached)
	
	-- register events
	inventoryFrame:RegisterEvent("BANKFRAME_OPENED")
	inventoryFrame:RegisterEvent("BANKFRAME_CLOSED")
	inventoryFrame:SetScript("OnEvent", function()

		local bagsItems, bankItems = itemInventory:FilterUniqueItems()
		local count = 0
		for tippy,gary in pairs(bankItems) do count = count + 1 end
		
		-- update db
		if(count > 0) then
			LavenderInventory[playerName]["BankCached"] = time()
			LavenderInventory[playerName]["Banked"] = bankItems
			LavenderVibes.Hooks.do_action("inventory_bank_cached")
		end
	end)
	

	return inventoryFrame
end


-- Initialize the module
local function lvItemInventory()

	local itemInventory = {};
	
	-- Define item list filters
	itemInventory.Filters = {
		["Shit"]      = true,
		["Common"]    = true,
		["Uncommon"]  = true,
		["Rare"]      = true,
		["Epic"]      = true,
		["Legendary"] = true
	}
	
	
	-- Create frame
	itemInventory.initFrame = function()
		local daddyFrame = initDaddyFrame(itemInventory)
		daddyFrame.BagsItemsFrame = initBagsItemsFrame(daddyFrame, itemInventory)
		daddyFrame.BankItemsFrame = initBankItemsFrame(daddyFrame, itemInventory)
		
		
		-- initialize options menus
		initMainOptions(daddyFrame, itemInventory)
		
		return daddyFrame
	end
	
	
	-- Clear lists
	itemInventory.ClearLists = function()
		itemInventory.Frame.BagsItemsFrame.ItemListFrame:Clear()
		itemInventory.Frame.BankItemsFrame.ItemListFrame:Clear()
	end
	
	
	-- Add items to list
	itemInventory.AddListItems = addListItems
	
	
	-- Load items lists for the specified toon
	itemInventory.LoadListsFor = function(toon)
		if LavenderInventory[toon] ~= nil then
			local bagsItems = LavenderInventory[toon]["Items"]
			local bankItems = LavenderInventory[toon]["Banked"]
			return bagsItems, bankItems
		end
		return false
	end
	
	
	-- Load item lists for all toons
	itemInventory.LoadListsForAll = function()
		local allItems = {}
		
		for toon,data in pairs(LavenderInventory) do
			-- bags items
			local toonItems = data["Items"]
			for i,item in pairs(toonItems) do
				local iItem = {
					bagId = 1,
					bagItemLink = item.itemLink,
					bagItemQty = item.totalQty
				}
				tinsert(allItems, iItem)
			end
			
			-- bank items
			local toonBanks = data["Banked"]
			for b,bank in pairs(toonBanks) do
				local bItem = {
					bagId    = -1,
					bagItemLink = bank.itemLink,
					bagItemQty = bank.totalQty
				}
				tinsert(allItems, bItem)
			end
		end
		
		return itemInventory:FilterUniqueItems(allItems)
	end
	
	
	-- Determine the location(s) of a specific item
	itemInventory.WhereTheyAt = function(self, itemId)
		local results = {}
		
		for toon,data in pairs(LavenderInventory) do
			-- bags items
			local toonItems = data["Items"]
			for i,item in pairs(toonItems) do
				if(i == itemId) then
					local qty = item.totalQty
					local result = {
						where = toon,
						at = "Bags",
						howmany = qty
					}
					tinsert(results, result)
				end
			end
			
			-- bank items
			local toonBanks = data["Banked"]
			for b,bank in pairs(toonBanks) do
				if(b == itemId) then
					local qty = bank.totalQty
					local result = {
						where = toon,
						at = "Bank",
						howmany = qty
					}
					tinsert(results, result)
				end
				
			end
		end
		
		return results
	end
	
	
	-- Filter lists
	itemInventory.FilterLists = function()
		local bagsFrame = itemInventory.Frame.BagsItemsFrame.ItemListFrame
		local bankFrame = itemInventory.Frame.BankItemsFrame.ItemListFrame
		local bagsItems = {}
		local bankItems = {}
		local filteredBags = {}
		local filteredBank = {}
		
		-- determine items to filter based on selected toon
		local toon = UIDropDownMenu_GetSelectedValue(itemInventory.Frame.ToonFilter)
		if(toon == "All") then
			bagsItems, bankItems = itemInventory.LoadListsForAll()
		elseif(toon == playerName) then
			bagsItems, bankItems = itemInventory.BagsItems, itemInventory.BankItems
		else
			bagsItems, bankItems = itemInventory.LoadListsFor(toon)
		end
		
		-- restrict items to filter based on search param
		local search = itemInventory.Frame.NameFilter:GetText()
		if(search ~= "Search..." and search ~= "") then
			bagsItems = itemInventory.SearchFilter(search, bagsItems)
			bankItems = itemInventory.SearchFilter(search, bankItems)
		end
		
		-- filter bags items
		for i,item in pairs(bagsItems) do
			local link = item.itemLink
			local quality = itemInventory.GetItemQualityFromLink(link)
			if(itemInventory.Filters[quality] == true) then
				tinsert(filteredBags, item)
			end
		end
		
		-- filter bank items
		if bankItems then
			for b,bank in pairs(bankItems) do
				local link = bank.itemLink
				local quality = itemInventory.GetItemQualityFromLink(link)
				if(itemInventory.Filters[quality] == true) then
					tinsert(filteredBank, bank)
				end
			end
		end
		
		
		-- enumerate item qualities for sorting
		local itemQuality = {
			["Shit"]      = 1,
			["Common"]    = 2,
			["Uncommon"]  = 3,
			["Rare"]      = 4,
			["Epic"]      = 5,
			["Legendary"] = 6
		}
		
		-- function to sort lists alphabetically
		local function alphabetically(a, b)
			local aName = itemInventory.GetItemNameFromLink(a.itemLink)
			local bName = itemInventory.GetItemNameFromLink(b.itemLink)
			local _, _, aRest, aNum = string.find(aName, "^(.-)%s*(%d+)$")
			local _, _, bRest, bNum = string.find(bName, "^(.-)%s*(%d+)$")
			
			-- if both names contain numbers then compare them numerically
			if(aNum ~= nil and bNum ~= nil) then
				return tonumber(aNum) < tonumber(bNum)
			end
			
			return aName < bName
		end
		
		-- function to sort lists by quality then alphabetically (default)
		local function filterSort(a, b)
			local aQuality = itemQuality[itemInventory.GetItemQualityFromLink(a.itemLink)]
			local bQuality = itemQuality[itemInventory.GetItemQualityFromLink(b.itemLink)]
			if(aQuality < bQuality) then
				return true
			elseif(aQuality > bQuality) then
				return false
			end
			
			return alphabetically(a, b)
		end
		
		-- sort lists by filter value
		if(itemInventory.SortedBy == "Item Quality") then
			table.sort(filteredBags, filterSort)
			table.sort(filteredBank, filterSort)
		else
			table.sort(filteredBags, alphabetically)
			table.sort(filteredBank, alphabetically)
		end
		
		-- display filtered lists
		addListItems(bagsFrame, filteredBags)
		addListItems(bankFrame, filteredBank)
		
		
		-- update the BagsCached string
		local bgcs = itemInventory.Frame.BagsItemsFrame.LastUpdated
		if(toon == "All") then
			bgcs:Hide()
		else
			local cache = getBagsCached(toon)
			if cache then
				bgcs:SetText("Last Updated: " .. cache)
				bgcs:Show()
			else
				bgcs:Hide()
			end
		end
		
		
		-- update the BankCached string
		local bcFrame = itemInventory.Frame.BankItemsFrame.LastUpdated
		if(toon == "All") then
			bcFrame:Hide()
		else
			bcFrame:Show()
			bcFrame:SetText("Last Updated: " .. getBankCache(toon))
		end
	end
	
	
	-- Filter list items by the specified search term
	itemInventory.SearchFilter = function(term, list)
		local matches = {}
		
		term = string.lower(term)
		
		for i,item in pairs(list) do
			local itemName = itemInventory.GetItemNameFromLink(item.itemLink)
			if itemName then
				local name = string.lower(itemName)
				if string.find(name, term, 1, true) then
					tinsert(matches, item)
				end
			end
		end
		
		return matches
	end
	
	
	-- Output to chat
	itemInventory.OutputToChat = function(channel)

		-- valid channels:
		-- "SAY", "PARTY", "GUILD", "YELL", "RAID"
		
		local uniques = itemInventory:FilterUniqueItems()
		for itemId, itemData in pairs(uniques) do
			-- throttle messages
			LavenderVibes.Throttle.Add(itemData.totalQty .. " x " .. itemData.itemLink, channel)
		end
	end
	
	
	-- Get item ID from item Link 
	itemInventory.GetItemIdFromLink = function(itemLink)

		if not itemLink then
			LavenderPrint("Item link is nil.")
			return nil
		end

		-- Find the starting position of the item ID
		local startIdx = string.find(itemLink, "item:")
		if startIdx then
			-- Find the next ':' after "item:"
			local endIdx = string.find(itemLink, ":", startIdx + 5) 
			if endIdx then
				-- Extract the item ID
				local itemID = string.sub(itemLink, startIdx + 5, endIdx - 1) 
				return tonumber(itemID)
			else
				LavenderPrint("Item link format is incorrect for item: " .. itemLink)
			end
		end

		return nil
	end
	
	
	-- Get item quality from item link
	itemInventory.GetItemQualityFromLink = function(itemLink)
		local quality = {
			["9d9d9d"] = "Shit",
			["ffffff"] = "Common",
			["1eff00"] = "Uncommon",
			["0070dd"] = "Rare",
			["a335ee"] = "Epic",
			["ff8000"] = "Legendary"
		}
		local color = string.sub(itemLink, 5, 10)
		return quality[color]
	end
	
	
	-- Get item name from item link
	itemInventory.GetItemNameFromLink = function(itemLink)
		if not itemLink then
			LavenderPrint("Item link is nil.")
			return ""
		end
		
		-- Find the starting position of the item name
		local startIdx = string.find(itemLink, "|h%[")
		if startIdx then
			startIdx = startIdx + 3
			-- Find the next ']' after the opening '['
			local endIdx = string.find(itemLink, "%]", startIdx)
			if endIdx then
				-- Extract the item name
				return string.sub(itemLink, startIdx, endIdx - 1) 
			else
				LavenderPrint("Item link format is incorrect for item: " .. itemLink)
			end
		end
		
		return ""
	end
	
	
	-- Get all items in inventory 
	itemInventory.GetInventoryItems = function()
		local inventoryItems = {};
		local bankItems = {};
		
		for bag = -1, 11 do
			local numSlots = GetContainerNumSlots(bag)			
			if numSlots > 0 then
				for slot = 1, numSlots do
					local texture, itemCount = GetContainerItemInfo(bag, slot);
					local link = GetContainerItemLink(bag, slot);
					if link then 
						local bagItem = {
							bagId = bag,
							bagSlot = slot,
							bagItemLink = link,
							bagItemQty = itemCount
						};
						tinsert(inventoryItems, bagItem);
					end
				end
			end
		end
		LavenderInventory[playerName]["BagsCached"] = time()
		
		return inventoryItems;
	end


	-- Filter unique items
	itemInventory.FilterUniqueItems = function(self, items)
		local paraMi = false
		if not items then 
			items = itemInventory:GetInventoryItems()
			paraMi = true
		end
		
		
		-- filter unique items and sum their quantities
		local bagsUniques = {}
		local bankUniques = {}
		local bagsItemsCount = 0
		local bankItemsCount = 0
		for index, item in ipairs(items) do
			local itemLink = item.bagItemLink
			local itemId = itemInventory.GetItemIdFromLink(itemLink)
			local itemQty = item.bagItemQty
			
			-- items in bank
			if(itemInventory.InBank(item.bagId)) then
				if bankUniques[itemId] then
					-- if item already exists, add to the quantity
					bankUniques[itemId].totalQty = bankUniques[itemId].totalQty + itemQty
				else
					-- if item doesn't exist, add it as a new entry
					bankUniques[itemId] = {
						itemLink = itemLink,
						totalQty = itemQty
					}
					bankItemsCount = bankItemsCount + 1
				end
			else
			-- items in bags
				if bagsUniques[itemId] then
					-- if item already exists, add to the quantity
					bagsUniques[itemId].totalQty = bagsUniques[itemId].totalQty + itemQty
				else
					-- if item doesn't exist, add it as a new entry
					bagsUniques[itemId] = {
						itemLink = itemLink,
						totalQty = itemQty
					}
					bagsItemsCount = bagsItemsCount + 1
				end
			end
		end
		
		if(paraMi) then
			-- update db for current player
			if bagsItemsCount > 0 then 
				itemInventory.BagsItems = bagsUniques 
				LavenderInventory[playerName]["Items"] = bagsUniques;
			end
			if bankItemsCount > 0 then 
				itemInventory.BankItems = bankUniques
				LavenderInventory[playerName]["Banked"] = bankUniques;
			end
		end
		
		-- /run LavenderVibes.Util.PrintTable(LavenderInventory["Betty"]["Banked"])
		
		return bagsUniques, bankUniques
	end
	
	
	-- Determine whether item is in bank or bags
	itemInventory.InBank = function(bagSlot)
		if(bagSlot < 0 or bagSlot > 4) then
			return true
		else
			return false
		end
	end


	-- Get the total "all" quantity of an item
	itemInventory.GetAllQuantityFor = function(self, itemId)
		if self and not itemId then itemId = self end
		local allBags, allBank = itemInventory:LoadListsForAll()
		local qty = 0

		if(allBags[itemId] ~= nil) then
			qty = qty + allBags[itemId].totalQty
		end
		if(allBank[itemId] ~= nil) then
			qty = qty + allBank[itemId].totalQty
		end
		
		return qty
	end
	
	
	-- Function to show the main window
	itemInventory.Show = function()
		LavenderVibes.Util:HideAll()
		itemInventory.Frame:Show()
	end
	
	-- List module sub-commands
	itemInventory.ListSubcommands = function()
		LavenderPrint("Lavender Inventory Sub-Commands:")

	end
	
	-- Handle slash commands
	itemInventory.handleSlashCommands = function(args)
		if(args == "") then
			itemInventory:Show()
		else
			local params = LavenderVibes.Util.Split(args)

			-- `?`: List sub-commands
			if(params[1] == "?") then
				itemInventory:ListSubcommands()
				return
			end

			-- `share`: Share items to chat channel
			if(params[1] == "share") then
				if(params[2]) then
					local channel = params[2]
					itemInventory.OutputToChat(channel)
				else
					local msg1 = LavenderVibes.Util.ColorTextByClass("You must specify which channel to share to.", "Rogue")

					LavenderPrint("|r" .. msg1)
					LavenderPrint("Valid channels:|r say, party, guild, yell, raid")
					LavenderPrint("")
				end

				return
			end

		end
	end
	
	
	-- Register slash commands
	itemInventory.registerSlashCommands = function()
		LavenderVibes.Commands.Add("inv", itemInventory.handleSlashCommands, "Show/refresh the Inventory window.", true)
	end
	
	-- Initialize module
	initThisToon(itemInventory)
	itemInventory.Frame = itemInventory:initFrame()
	itemInventory:registerSlashCommands()
	LavenderVibes.Modules.Inventory = itemInventory
	LavenderVibes.Hooks.do_action("inventory_initialized")
	
	-- Hook to hide the window
	LavenderVibes.Hooks.add_action("hide_all", function() itemInventory.Frame:Hide() end)
	
	-- Hook to unload the module
	LavenderVibes.Hooks.add_action("unload_module_Inventory", function()
		-- * remove slash commands

		-- * remove hooks

		-- hide frames
		itemInventory.Frame:Hide()
	end)
end


-- Hook to register the module
LavenderVibes.Hooks.add_action("modules_available", function() tinsert(LavenderVibes.Modules, "Inventory") end)


-- Hook to initialize the module
LavenderVibes.Hooks.add_action("load_module_Inventory", lvItemInventory)

