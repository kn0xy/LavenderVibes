
local function lvPanel_Bags(panel)

	local lavBags = {};
	lavBags.frame = nil;
	
	-- Get all options related to this widget
	lavBags.getOptions = function()
		if(LavenderOptions._BagsDisplay == nil) then LavenderOptions._BagsDisplay = "open" end
		if(LavenderOptions._BagsShowIcon == nil) then LavenderOptions._BagsShowIcon = true end
		if(LavenderOptions._BagsShowLabel == nil) then LavenderOptions._BagsShowLabel = true end
		
		local _options = {
			display = LavenderOptions._BagsDisplay,
			showIcon = LavenderOptions._BagsShowIcon,
			showLabel = LavenderOptions._BagsShowLabel
		}
		
		lavBags.options = _options	
		return _options
	end
	
	
	-- Initialize widget frame
	lavBags.init = function()
		if not (lavBags.frame == nil) then return end
		local options = lavBags.getOptions()
		
		-- Create a frame to display the bags info
		local bagsFrame = CreateFrame("Button", "LavenderBagsFrame", panel)
		bagsFrame:SetWidth(100)
		bagsFrame:SetHeight(14)
		bagsFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 1, 0)
		bagsFrame:RegisterEvent("BAG_UPDATE");
		bagsFrame:SetScript("OnEvent", lavBags.update)
		
		-- Add a bag icon
		local bagTexture = bagsFrame:CreateTexture("LavenderBagsIcon", "ARTWORK")
		bagTexture:SetTexture("Interface\\Icons\\INV_Misc_Bag_08")
		bagTexture:SetWidth(14)
		bagTexture:SetHeight(14)
		bagTexture:SetPoint("TOPLEFT", bagsFrame, "TOPLEFT")
		if not options.showIcon then bagTexture:Hide() end
		lavBags.icon = bagTexture
		
		-- Create a font string for the bags display
		local txtOffset = 16
		if not options.showIcon then txtOffset = 0 end
		local bagsText = bagsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		bagsText:SetPoint("LEFT", bagsFrame, "LEFT", txtOffset, 0)
		bagsText:SetTextColor(1, 1, 1, 1)
		bagsText:SetFont("Fonts\\FRIZQT__.TTF", 10.17)--#bricksquad
		lavBags.text = bagsText
		
		-- Define tooltip functionality
		lavBags.DefaultLCAction = "interact"
		bagsFrame:SetScript("OnEnter", function()
			local r, g, b = LavenderVibes.Util:LavRGB()
			if LavenderOptions.module_Inventory_enabled then 
				lavBags.LCAction = "open Lavender Inventory"
			else
				lavBags.LCAction = lavBags.DefaultLCAction
			end
			GameTooltip:SetOwner(bagsFrame, "ANCHOR_NONE")
			GameTooltip:SetPoint("TOPLEFT", bagsFrame, "BOTTOMLEFT", 10, -5)
			GameTooltip:AddLine("Bags", r, g, b)
			GameTooltip:AddLine("Left-click to " .. lavBags.LCAction, 0.9, 0.9, 0.9)
			GameTooltip:AddLine("Right-click for options", 0.9, 0.9, 0.9)
			GameTooltip:Show()
		end)
		bagsFrame:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
			
		-- Create a context menu
		local contextFrame = CreateFrame("Frame", "LavenderBagsRightClickContextMenu", UIParent, "UIDropDownMenuTemplate")
		lavBags.contextFrame = contextFrame
		UIDropDownMenu_Initialize(contextFrame, lavBags.initContextMenu, "MENU");
		
		-- Define click handlers
		bagsFrame:RegisterForClicks("RightButtonDown", "LeftButtonUp")
		bagsFrame:EnableMouse(true)
		bagsFrame:SetScript("OnClick", function()
			if(arg1 == "LeftButton") then
				-- left click
				if(LavenderOptions.module_Inventory_enabled) then 
					LavenderVibes.Modules.Inventory:Show()
				else
					ToggleDropDownMenu(1, nil, contextFrame, bagsFrame, 0, -1);
				end
			else
				-- right click
				ToggleDropDownMenu(1, nil, contextFrame, bagsFrame, 0, -1);
			end
			GameTooltip:Hide()
		end)
		
		-- Publicize reference to frame
		lavBags.frame = bagsFrame
		
		-- Show the output
		lavBags.update()
	end
	
	
	-- Initialize the context menu
	lavBags.initContextMenu = function()
		local opt = {}

		-- Menu Title
		opt = {
			text = "Bags Info",
			notClickable = true,
			notCheckable = true,
			isTitle = true
		}
		UIDropDownMenu_AddButton(opt);
		
		-- Option: [Slots Available]
		opt = {
			text = "Slots Available",
			textR = 0.9, textG = 0.9, textB = 0.9,
			value = "open",
			func = function() 
				UIDropDownMenu_SetSelectedValue(lavBags.contextFrame, "open", false)
				LavenderOptions._BagsDisplay = "open"
				lavBags.update()
			end
		}
		UIDropDownMenu_AddButton(opt);
		
		-- Option: [Slots Used]
		opt = {
			text = "Slots Used",
			textR = 0.9, textG = 0.9, textB = 0.9,
			value = "used",
			func = function()
				UIDropDownMenu_SetSelectedValue(lavBags.contextFrame, "used", false)
				LavenderOptions._BagsDisplay = "used"
				lavBags.update()
			end
		}
		UIDropDownMenu_AddButton(opt);
		
		-- Set selected value for display option (toggle)
		UIDropDownMenu_SetSelectedValue(lavBags.contextFrame, LavenderOptions._BagsDisplay, false)
			
		-- Spacer
		opt = {notClickable = true, notCheckable = true}
		UIDropDownMenu_AddButton(opt);
		
		-- Title: Options
		opt.isTitle = true;
		opt.text = "Options";
		UIDropDownMenu_AddButton(opt);
		
		-- Option: Show/Hide Icon
		opt = {
			text = "Show Icon",
			textR = 0.9, textG = 0.9, textB = 0.9,
			keepShownOnClick = true,
			checked = LavenderOptions._BagsShowIcon,
			func = function()
				if(LavenderOptions._BagsShowIcon == true) then
					-- hide icon
					LavenderOptions._BagsShowIcon = false
					lavBags.icon:Hide()
					lavBags.text:SetPoint("LEFT", lavBags.frame, "LEFT", 0, -0.5)
				else
					-- show icon
					LavenderOptions._BagsShowIcon = true
					lavBags.icon:Show()
					lavBags.text:SetPoint("LEFT", lavBags.frame, "LEFT", 16, -0.5)
				end
			end
		}
		UIDropDownMenu_AddButton(opt);
		
		-- Option: Show/Hide Label
		opt = {
			text = "Show Label",
			textR = 0.9, textG = 0.9, textB = 0.9,
			keepShownOnClick = true,
			checked = LavenderOptions._BagsShowLabel,
			func = function()
				if(LavenderOptions._BagsShowLabel == true) then
					-- hide label
					LavenderOptions._BagsShowLabel = false
				else
					-- show label
					LavenderOptions._BagsShowLabel = true
				end
				lavBags.update()
			end
		}
		UIDropDownMenu_AddButton(opt);
	end
	

	-- Determine the total number of inventory slots and unoccupied slots
	lavBags.getInventorySlots = function()
		local totalSlots = 0
		local emptySlots = 0

		for bag = 0, 4 do
			local numSlots = GetContainerNumSlots(bag)
			if numSlots then
				totalSlots = totalSlots + numSlots
				for slot = 1, numSlots do
					if not GetContainerItemLink(bag, slot) then
						emptySlots = emptySlots + 1
					end
				end
			end
		end

		return totalSlots, emptySlots
	end


	-- Update the widget output
	lavBags.update = function()
		local prefix = "Bags: "
		if not LavenderOptions._BagsShowLabel then prefix = "" end
		
		local total, empty = lavBags:getInventorySlots()
		if(LavenderOptions._BagsDisplay == "used") then
			local used = total - empty
			lavBags.text:SetText(prefix .. tostring(used) .. " / " .. tostring(total))
		else
			lavBags.text:SetText(prefix .. tostring(empty) .. " / " .. tostring(total))
		end
	end
	
	
	-- Define alias functions 
	lavBags.Hide = function() lavBags.frame:Hide() end
	lavBags.Show = function() lavBags.frame:Show() end


	-- Vamanos
	lavBags:init()
	return lavBags
end


LavenderVibes.Hooks.add_action("panel_initialized", function()
	LavenderVibes.Modules.Panel.Widgets:Add(
		"Bags", 
		"Show the number of bag spaces remaining or bag spaces used",
		lvPanel_Bags
	)
end)
