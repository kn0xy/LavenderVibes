

-- Define options to show in the config window
local LavenderConfigOptions = {
	["MinimapButton"] = "Minimap Button",
	["MinimapClock"]  = "Minimap Clock/Timer",
	["Inventory"]	  = "Account Inventory",
	["Panel"] 		  = "Top Info Panel",
	["Tradeskills"]   = "Account Tradeskills"
}


-- Create a frame for the config window
local function initConfigWindow()
	local configFrame = CreateFrame("Frame", "LavenderConfigFrame", UIParent)
	configFrame:SetWidth(270)
	configFrame:SetHeight(300)
	configFrame:SetPoint("CENTER", UIParent, "CENTER")
	configFrame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 }
	})
	configFrame:SetBackdropColor(0, 0, 0, 1)
	configFrame:Hide()

	-- Title text
	configFrame.title = configFrame:CreateFontString(nil, "ARTWORK")
	configFrame.title:SetPoint("TOP", configFrame, "TOP", 0, -15)
	configFrame.title:SetTextColor(125/255, 102/255, 183/255)
	configFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE, MONOCHROME")
	configFrame.title:SetText("Lavender Modules")


	-- Close button
	configFrame.closeButton = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
	configFrame.closeButton:SetWidth(80)
	configFrame.closeButton:SetHeight(22)
	configFrame.closeButton:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -25, 25)
	configFrame.closeButton:SetText("Close")
	configFrame.closeButton:SetScript("OnClick", function()
		configFrame:Hide()
	end)

	-- Details Frame
	local detailsFrame = CreateFrame("Frame", "LAVENDERdetailsFrame", configFrame)
	detailsFrame:SetWidth(250)
	detailsFrame:SetHeight(200)
	detailsFrame:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -20, -38)
	detailsFrame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 }
	})
	detailsFrame:SetBackdropColor(0, 0, 0, 1)
	detailsFrame:Hide()
	configFrame.Details = detailsFrame
	configFrame.DetailsButtons = {}
	
	-- Handle frame shown
	configFrame.Options = {};
	configFrame.LoadOptions = function()
		LavenderVibes.Util:HideAll()
		for k,v in LavenderOptions do
			if(string.sub(k, 1, 1) ~= "_") then
				--DEFAULT_CHAT_FRAME:AddMessage("k = " .. tostring(k) .. " and v = " .. tostring(v));
				local elem = configFrame.Options[k]
				--DEFAULT_CHAT_FRAME:AddMessage("elem = " .. tostring(elem));
				if elem then elem:SetChecked(v) end
			end
		end
		configFrame:Show()
	end
	
	-- Close frame when escape key pressed
	table.insert(UISpecialFrames, "LavenderConfigFrame")

	return configFrame
end



-- Function to set value for an option
local function setOption(option, value)
	LavenderOptions[option] = value
end


-- Function to create the Details button for a checkbox option
local function optionDetailsButton(cb, frame)
	local detailsButton = CreateFrame("Button", "$parentDetails", cb)
	detailsButton:SetWidth(32)
	detailsButton:SetHeight(32)
	detailsButton:SetPoint("LEFT", cb, "LEFT", 208, 0)
	detailsButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
	detailsButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
	detailsButton:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled")
	detailsButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
	detailsButton:SetScript("OnClick", function()
		if(frame.Details:IsShown()) then
			frame:HideDetails()
		else
			frame:ShowDetails(detailsButton:GetName())
		end
	end)
	
	tinsert(frame.DetailsButtons, detailsButton)
	return detailsButton
end


-- Function to create a checkbox option
local function cbOption(pos, name, label, checked)
	local key = "module_"..name.."_enabled"
	local x = 15
	local y = -40 * pos
	local cbName = key .. "CheckButton"
	local frame = LavenderVibes.Config
	local checkbox = CreateFrame("CheckButton", cbName, frame, "UICheckButtonTemplate")
	checkbox:SetWidth(30)
	checkbox:SetHeight(30)
	checkbox:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
	checkbox.label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	checkbox.label:SetFont("Fonts\\FRIZQT__.TTF", 11)
	checkbox.label:SetPoint("LEFT", checkbox, "RIGHT", 0, 0)
	checkbox.label:SetText(label)
	checkbox.details = optionDetailsButton(checkbox, frame)
	checkbox:SetChecked(checked)
	checkbox:SetScript("OnClick", function()
		local self = LavenderVibes.Modules[name]
		local checked = true
		if not checkbox:GetChecked() then checked = false end
		setOption(key, checked)
		if checked then
			LavenderVibes.Hooks.do_action("load_module_"..name)
		else
			LavenderVibes.Hooks.do_action("unload_module_"..name)
			
		end
	end)
	LavenderVibes.Config.Options[key] = checkbox
end




-- Create interface options for the config window
local function initConfigWindowOptions()
	local opts = LavenderOptions
	local index = 1
	for name, desc in LavenderConfigOptions do
		cbOption(index, name, desc, opts[name])
		index = index + 1
	end
end




local function helpBtn()
	-- Create the button
	local myFrame = CreateFrame("Button", "MyAddonButton", UIParent, "UIPanelButtonTemplate")
	myFrame:SetWidth(20)
	myFrame:SetHeight(20)
	myFrame:SetPoint("CENTER", UIParent, "CENTER")
	myFrame:SetText("")
	myFrame:EnableMouse(true)

	-- Add a question mark icon texture
	local icon = myFrame:CreateTexture(nil, "ARTWORK")
	icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")  -- Path to the question mark icon
	icon:SetAllPoints(myFrame)  -- Make the icon fill the entire button


	myFrame:SetScript("OnEnter", function(self)
		-- Show a tooltip
		GameTooltip:SetOwner(myFrame, "ANCHOR_RIGHT")
		GameTooltip:SetText("My Button", 1, 1, 1)
		GameTooltip:AddLine("This is a tooltip for my button.", 1, 1, 1, true)
		GameTooltip:Show()
	end)


	myFrame:SetScript("OnLeave", function(self)
		
		-- Hide the tooltip
		GameTooltip:Hide()
	end)

end


LavenderVibes.Config = initConfigWindow()
function LavenderVibes.Config:Init()
	initConfigWindowOptions()
end


-- Function to show option details
function LavenderVibes.Config:ShowDetails(selected)
	local frame = LavenderVibes.Config
	local btns = frame.DetailsButtons
	
	for b,btn in ipairs(btns) do
		if(btn:GetName() ~= selected) then
			btn:Disable()
		else
			btn:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
			btn:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
		end
	end
	
	frame:SetWidth(525)
	frame.Details:Show()
	
	-- do something with the selected value
	local stop = string.len(selected) - 26
	selected = string.sub(selected, 8, stop)
	
	local bill = LavenderVibes.Modules[selected].ConfigDetails
	if bill ~= nil then
		bill:SetPoint("TOPLEFT", frame.Details, "TOPLEFT", 5, -5)
		bill:SetParent(frame.Details)
		bill:SetWidth(frame.Details:GetWidth() - 10)
		bill:SetHeight(frame.Details:GetHeight() - 10)
		
		bill:SetFrameStrata("Dialog")
		bill:Show()
	else
		LavenderPrint("No configuration options available for the " .. selected .. " module.")
	end
end



-- Function to hide option details
function LavenderVibes.Config:HideDetails()
	local frame = LavenderVibes.Config
	local btns = frame.DetailsButtons
	
	for b,btn in ipairs(btns) do
		btn:Enable()
		btn:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
		btn:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
	end
	
	frame:SetWidth(272)
	frame.Details:Hide()
end


-- Function to create a checkbox option for the details window
function LavenderVibes.Config:DetailsCbOption(frame, pos, name, label, checked, ttFunc, cbFunc)
	local x = 10
	local y = (-32 * (pos - 1)) - 25
	local cbName = name .. "CheckButton"
	local checkbox = CreateFrame("CheckButton", cbName, frame, "UICheckButtonTemplate")
	checkbox:SetWidth(20)
	checkbox:SetHeight(20)
	checkbox:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
	checkbox.label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	checkbox.label:SetFont("Fonts\\FRIZQT__.TTF", 10)
	checkbox.label:SetPoint("LEFT", checkbox, "RIGHT", 3, 0)
	checkbox.label:SetText(label)
	checkbox:SetChecked(checked)
	checkbox:SetScript("OnClick", function()
		if cbFunc then 
			cbFunc(checkbox)
		else
			LavenderPrint("Unhandled OnClick event from " .. cbName, "Death Knight")
		end
	end)
	
	if ttFunc then
		checkbox:SetScript("OnEnter", function()
			ttFunc(checkbox)
		end)
		
		checkbox:SetScript("OnLeave", function() GameTooltip:Hide() end)
	end
	
	return checkbox
end


-- hook to hide window
LavenderVibes.Hooks.add_action("hide_all", function() LavenderVibes.Config:Hide() end)

