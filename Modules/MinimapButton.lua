


local function lvMinimapButton()
	if not LavenderVibes.Modules.MinimapButton then
	
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
				LavenderVibes.Config:LoadOptions()
			else
				-- right click
				LavenderVibes.Modules.Tradeskills:Show()
			end
		end)

		-- Add tooltip functionality
		minimapButton:SetScript("OnEnter", function()
			local r, g, b = LavenderVibes.Util:LavRGB()
			GameTooltip:SetOwner(minimapButton, "ANCHOR_BOTTOMLEFT")
			GameTooltip:AddLine("Lavender Vibes", r, g, b)
			GameTooltip:AddLine("Left-click to interact", 0.8, 0.8, 0.8)
			GameTooltip:AddLine("Right-click for options", 0.8, 0.8, 0.8)
			GameTooltip:Show()
		end)
		minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

		-- Set the initial button position
		minimapButton:UpdatePosition(LavenderOptions._MinimapBtnPos)
		
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

-- hook to register the module
LavenderVibes.Hooks.add_action("modules_available", function() tinsert(LavenderVibes.Modules, "MinimapButton") end)

-- hook to the load the module
LavenderVibes.Hooks.add_action("load_module_MinimapButton", lvMinimapButton);

