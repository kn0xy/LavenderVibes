local function lvMinimapButton()
	if not LavenderVibes.Modules.MinimapButton then
	
		-- Initialize module options
		if not LavenderOptions.MinimapButton then
			LavenderOptions.MinimapButton = {
				showBorder = true,
				showIcon = true,
				showTooltip = true,
				leftClickAction = "config", -- config or tradeskills
				rightClickAction = "menu" -- menu or tradeskills
			}
		end

		-- Create a new frame for the minimap button
		local minimapButton = CreateFrame("Button", "LavenderMinimapButton", Minimap)
		minimapButton:SetFrameStrata("BACKGROUND")
		minimapButton:SetWidth(32)
		minimapButton:SetHeight(32)

		-- Set the default position 
		if not LavenderOptions._MinimapBtnPos then
			LavenderOptions._MinimapBtnPos = 139
		end

		-- Add background texture 
		minimapButton.texture = minimapButton:CreateTexture(nil, "ARTWORK")
		minimapButton.texture:SetTexture("Interface\\AddOns\\LavenderVibes\\Textures\\lvicon_128_old")
		minimapButton.texture:SetWidth(24)
		minimapButton.texture:SetHeight(24)
		minimapButton.texture:SetTexCoord(-0.05, 1.05, -0.05, 1.05)
		minimapButton.texture:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", 4, -3)

		-- Add border texture
		minimapButton.border = minimapButton:CreateTexture(nil, "OVERLAY")
		minimapButton.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
		minimapButton.border:SetWidth(56)
		minimapButton.border:SetHeight(56)
		minimapButton.border:SetPoint("CENTER", minimapButton, "CENTER", 11, -11)

		-- Make the button draggable
		minimapButton:SetMovable(true)
		minimapButton:EnableMouse(true)
		minimapButton:RegisterForDrag("LeftButton")
		minimapButton:SetScript("OnDragStart", function()
			minimapButton:SetScript("OnUpdate", function()
				local mx, my = Minimap:GetCenter()
				local px, py = GetCursorPosition()
				local scale = UIParent:GetEffectiveScale()
				px, py = px / scale, py / scale
				local position = math.deg(math.atan2(py - my, px - mx))
				if position <= 0 then
					position = position + 360
				elseif position > 360 then
					position = position - 360
				end
				minimapButton:UpdatePosition(position)
			end)
		end)
		minimapButton:SetScript("OnDragStop", function()
			minimapButton:SetScript("OnUpdate", nil)
		end)
		
		-- Position the button around the minimap
		minimapButton.UpdatePosition = function(self, position)
			local angle = math.rad(position)
			local x = math.cos(angle) * 80
			local y = math.sin(angle) * 80
			minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
			LavenderOptions._MinimapBtnPos = position
		end

		-- Add click functionality
		minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		minimapButton:SetScript("OnClick", function()
			if(arg1 == "LeftButton") then
				-- left click
				if LavenderOptions.MinimapButton.leftClickAction == "config" then
					LavenderVibes.Config:LoadOptions()
				else
					LavenderVibes.Modules.Tradeskills:Show()
				end
			else
				-- right click
				if LavenderOptions.MinimapButton.rightClickAction == "menu" then
					ToggleDropDownMenu(1, nil, minimapButton.contextMenu, "cursor", 0, 0)
				else
					LavenderVibes.Modules.Tradeskills:Show()
				end
			end
		end)

		-- Create context menu
		local contextMenu = CreateFrame("Frame", "LavenderMinimapContextMenu", UIParent, "UIDropDownMenuTemplate")
		minimapButton.contextMenu = contextMenu
		
		-- Initialize context menu
		UIDropDownMenu_Initialize(contextMenu, function(frame, level, menuList)
			local info = {}
			
			-- Title
			info.text = "Lavender Vibes"
			info.isTitle = true
			info.notClickable = true
			info.notCheckable = true
			info.disabled = true
			UIDropDownMenu_AddButton(info)
			
			-- Tradeskills option
			info.text = "Tradeskills"
			info.isTitle = false
			info.notClickable = false
			info.notCheckable = true
			info.disabled = false
			info.func = function()
				LavenderVibes.Modules.Tradeskills:Show()
			end
			UIDropDownMenu_AddButton(info)
			
			-- Config option
			info.text = "Config"
			info.isTitle = false
			info.notClickable = false
			info.notCheckable = true
			info.disabled = false
			info.func = function()
				LavenderVibes.Config:LoadOptions()
			end
			UIDropDownMenu_AddButton(info)
		end, "MENU")

		-- Add tooltip functionality
		minimapButton:SetScript("OnEnter", function()
			if not LavenderOptions.MinimapButton.showTooltip then return end
			local r, g, b = LavenderVibes.Util:LavRGB()
			GameTooltip:SetOwner(minimapButton, "ANCHOR_BOTTOMLEFT")
			GameTooltip:AddLine("Lavender Vibes", r, g, b)
			GameTooltip:AddLine("Left-click to " .. (LavenderOptions.MinimapButton.leftClickAction == "config" and "open config" or "open tradeskills"), 0.8, 0.8, 0.8)
			GameTooltip:AddLine("Right-click to " .. (LavenderOptions.MinimapButton.rightClickAction == "menu" and "show menu" or "open tradeskills"), 0.8, 0.8, 0.8)
			GameTooltip:Show()
		end)
		minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

		-- Set the initial button position
		minimapButton:UpdatePosition(LavenderOptions._MinimapBtnPos)
		
		-- Add function to update button visibility
		minimapButton.UpdateVisibility = function(self)
			if LavenderOptions.MinimapButton.showIcon then
				if self.border then
					if LavenderOptions.MinimapButton.showBorder then
						self.border:Show()
					else
						self.border:Hide()
					end
				end
				if self.texture then
					self.texture:Show()
				end
			else
				if self.border then
					self.border:Hide()
				end
				if self.texture then
					self.texture:Hide()
				end
			end
		end
		
		-- Update initial visibility
		minimapButton:UpdateVisibility()
		
		-- Module initialized
		LavenderVibes.Modules.MinimapButton = minimapButton
		LavenderVibes.Hooks.do_action("MinimapButton_initialized")

		-- hook to unload the module
		LavenderVibes.Hooks.add_action("unload_module_MinimapButton", function() 
			minimapButton:Hide()
		end)
	else
		LavenderVibes.Modules.MinimapButton:Show()
	end
end

-- Initialize configuration options
local function initMinimapButtonConfig()
	local configFrame = CreateFrame("Frame", "LavenderMinimapButtonConfigFrame")
	local configTitle = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	configTitle:SetFont("Fonts\\FRIZQT__.TTF", 11)
	configTitle:SetPoint("TOP", configFrame, "TOP", 0, -10)
	configTitle:SetText("Minimap Button Options")

	-- Show Border option
	local showBorder = LavenderVibes.Config:DetailsCbOption(
		configFrame, 1, "LavenderMinimapButtonShowBorder", "Show Border",
		LavenderOptions.MinimapButton.showBorder,
		function(cb)
			GameTooltip:SetOwner(cb, "ANCHOR_CURSOR")
			GameTooltip:SetPoint("BOTTOMLEFT", cb, "TOPRIGHT", 0, -3)
			GameTooltip:AddLine("Show the border around the minimap button")
			GameTooltip:Show()
		end,
		function(cb)
			LavenderOptions.MinimapButton.showBorder = cb:GetChecked()
			if LavenderVibes.Modules.MinimapButton then
				LavenderVibes.Modules.MinimapButton:UpdateVisibility()
			end
		end
	)

	-- Show Icon option
	local showIcon = LavenderVibes.Config:DetailsCbOption(
		configFrame, 2, "LavenderMinimapButtonShowIcon", "Show Icon",
		LavenderOptions.MinimapButton.showIcon,
		function(cb)
			GameTooltip:SetOwner(cb, "ANCHOR_CURSOR")
			GameTooltip:SetPoint("BOTTOMLEFT", cb, "TOPRIGHT", 0, -3)
			GameTooltip:AddLine("Show the icon on the minimap button")
			GameTooltip:Show()
		end,
		function(cb)
			LavenderOptions.MinimapButton.showIcon = cb:GetChecked()
			if LavenderVibes.Modules.MinimapButton then
				LavenderVibes.Modules.MinimapButton:UpdateVisibility()
			end
		end
	)

	-- Show Tooltip option
	local showTooltip = LavenderVibes.Config:DetailsCbOption(
		configFrame, 3, "LavenderMinimapButtonShowTooltip", "Show Tooltip",
		LavenderOptions.MinimapButton.showTooltip,
		function(cb)
			GameTooltip:SetOwner(cb, "ANCHOR_CURSOR")
			GameTooltip:SetPoint("BOTTOMLEFT", cb, "TOPRIGHT", 0, -3)
			GameTooltip:AddLine("Show tooltip when hovering over the minimap button")
			GameTooltip:Show()
		end,
		function(cb)
			LavenderOptions.MinimapButton.showTooltip = cb:GetChecked()
		end
	)

	-- Left Click Action dropdown
	local leftClickDropdown = CreateFrame("Frame", "LavenderMinimapButtonLeftClickDropdown", configFrame, "UIDropDownMenuTemplate")
	leftClickDropdown:SetPoint("TOPLEFT", showTooltip, "BOTTOMLEFT", 0, -10)
	UIDropDownMenu_SetWidth(120, leftClickDropdown)
	UIDropDownMenu_SetText(LavenderOptions.MinimapButton.leftClickAction == "config" and "Open Config" or "Open Tradeskills", leftClickDropdown)

	-- Create button for left click dropdown
	local leftClickButton = CreateFrame("Button", "LavenderMinimapButtonLeftClickButton", leftClickDropdown)
	leftClickButton:SetAllPoints(leftClickDropdown)
	leftClickButton:SetScript("OnClick", function()
		ToggleDropDownMenu(1, nil, leftClickDropdown, "cursor", 0, 0)
	end)

	UIDropDownMenu_Initialize(leftClickDropdown, function(frame, level, menuList)
		local info = {}
		info.func = function()
			local value = this.value
			LavenderOptions.MinimapButton.leftClickAction = value
			UIDropDownMenu_SetText(value == "config" and "Open Config" or "Open Tradeskills", leftClickDropdown)
		end
		info.text = "Open Config"
		info.value = "config"
		info.notCheckable = false
		info.checked = LavenderOptions.MinimapButton.leftClickAction == "config"
		UIDropDownMenu_AddButton(info)
		info.text = "Open Tradeskills"
		info.value = "tradeskills"
		info.checked = LavenderOptions.MinimapButton.leftClickAction == "tradeskills"
		UIDropDownMenu_AddButton(info)
	end)

	-- Right Click Action dropdown
	local rightClickDropdown = CreateFrame("Frame", "LavenderMinimapButtonRightClickDropdown", configFrame, "UIDropDownMenuTemplate")
	rightClickDropdown:SetPoint("TOPLEFT", leftClickDropdown, "BOTTOMLEFT", 0, -10)
	UIDropDownMenu_SetWidth(120, rightClickDropdown)
	UIDropDownMenu_SetText(LavenderOptions.MinimapButton.rightClickAction == "menu" and "Show Menu" or "Open Tradeskills", rightClickDropdown)

	-- Create button for right click dropdown
	local rightClickButton = CreateFrame("Button", "LavenderMinimapButtonRightClickButton", rightClickDropdown)
	rightClickButton:SetAllPoints(rightClickDropdown)
	rightClickButton:SetScript("OnClick", function()
		ToggleDropDownMenu(1, nil, rightClickDropdown, "cursor", 0, 0)
	end)

	UIDropDownMenu_Initialize(rightClickDropdown, function(frame, level, menuList)
		local info = {}
		info.func = function()
			local value = this.value
			LavenderOptions.MinimapButton.rightClickAction = value
			UIDropDownMenu_SetText(value == "menu" and "Show Menu" or "Open Tradeskills", rightClickDropdown)
		end
		info.text = "Show Menu"
		info.value = "menu"
		info.notCheckable = false
		info.checked = LavenderOptions.MinimapButton.rightClickAction == "menu"
		UIDropDownMenu_AddButton(info)
		info.text = "Open Tradeskills"
		info.value = "tradeskills"
		info.checked = LavenderOptions.MinimapButton.rightClickAction == "tradeskills"
		UIDropDownMenu_AddButton(info)
	end)

	configFrame.Options = {showBorder, showIcon, showTooltip, leftClickDropdown, rightClickDropdown}
	return configFrame
end

-- Initialize config when module is initialized
LavenderVibes.Hooks.add_action("MinimapButton_initialized", function()
	LavenderVibes.Modules.MinimapButton.ConfigDetails = initMinimapButtonConfig()
end)

-- hook to register the module
LavenderVibes.Hooks.add_action("modules_available", function() tinsert(LavenderVibes.Modules, "MinimapButton") end)

-- hook to the load the module
LavenderVibes.Hooks.add_action("load_module_MinimapButton", lvMinimapButton);

