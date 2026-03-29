
local function lvPanel_Coords(panel)

	local lavCoords = {}

	lavCoords.panelHidden = false
	lavCoords.updateInterval = 0.5
	lavCoords.elapsed = 0

	-- Get the world map frame
	local function getWorldMapFrame()
		return getglobal("WorldMapFrame")
	end

	local function getWorldMapButton()
		return getglobal("WorldMapButton")
	end

	-- Ensure the defaults are set
	lavCoords.ensureDefaults = function()
		if LavenderOptions._CoordsShowOnMap == nil then
			LavenderOptions._CoordsShowOnMap = true
		end
		if LavenderOptions._CoordsShowZone == nil then
			LavenderOptions._CoordsShowZone = false
		end
		if LavenderOptions._CoordsShowIcon == nil then
			LavenderOptions._CoordsShowIcon = true
		end
	end

	-- Format the coordinates
	lavCoords.formatPercentCoords = function(px, py)
		if not px or not py or (px <= 0 and py <= 0) then
			return nil
		end
		return string.format("%.1f, %.1f", px * 100, py * 100)
	end

	-- Show/hide the panel icon
	lavCoords.applyPanelIconLayout = function()
		if not lavCoords.icon or not lavCoords.text then return end
		local parent = lavCoords.text:GetParent()
		if not parent then return end
		if LavenderOptions._CoordsShowIcon then
			lavCoords.icon:Show()
			lavCoords.text:SetPoint("LEFT", parent, "LEFT", 16, -0.5)
		else
			lavCoords.icon:Hide()
			lavCoords.text:SetPoint("LEFT", parent, "LEFT", 0, -0.5)
		end
	end

	-- Check whether to display the world map coords
	lavCoords.isWorldMapCoordsOptionOn = function()
		local v = LavenderOptions._CoordsShowOnMap
		if v == false or v == 0 then return false end
		if type(v) == "string" and string.lower(v) == "false" then return false end
		return true
	end

	-- Update the panel coords
	lavCoords.update = function()
		lavCoords.ensureDefaults()
		SetMapToCurrentZone()
		local px, py = GetPlayerMapPosition("player")
		local coordStr = lavCoords.formatPercentCoords(px, py) or "--"
		if LavenderOptions._CoordsShowZone then
			local z = GetZoneText()
			if z and z ~= "" then
				coordStr = z .. "  " .. coordStr
			end
		end
		lavCoords.text:SetText(coordStr)
	end

	-- Update the world map coords
	lavCoords.updateWorldMapCoords = function()
		if not lavCoords.worldMapText then return end
		local mb = getWorldMapButton()
		local cursorStr = "--"
		if mb and mb:IsVisible() then
			local x, y = GetCursorPosition()
			x = x / mb:GetEffectiveScale()
			y = y / mb:GetEffectiveScale()
			local cx, cy = mb:GetCenter()
			local width = mb:GetWidth()
			local height = mb:GetHeight()
			if cx and cy and width > 0 and height > 0 then
				local adjY = (cy + (height / 2) - y) / height
				local adjX = (x - (cx - (width / 2))) / width
				if adjX >= -0.02 and adjX <= 1.02 and adjY >= -0.02 and adjY <= 1.02 then
					cursorStr = string.format("%.1f, %.1f", adjX * 100, adjY * 100)
				end
			end
		end

		local ppx, ppy = GetPlayerMapPosition("player")
		local playerStr = lavCoords.formatPercentCoords(ppx, ppy) or "--"
		lavCoords.worldMapText:SetText("Cursor: " .. cursorStr .. "     Player: " .. playerStr)
	end

	-- Show/hide the world map bar
	lavCoords.applyWorldMapOverlay = function()
		if not lavCoords.isWorldMapCoordsOptionOn() and lavCoords.worldMapBar then
			lavCoords.worldMapBar:Hide()
		end
	end

	-- Initialize the world map bar
	lavCoords.initWorldMapBar = function()
		if lavCoords.worldMapBar then return end
		local btn = getWorldMapButton()
		if not btn then return end

		local bar = CreateFrame("Frame", nil, btn)
		local w = btn:GetWidth()
		if not w or w < 50 then w = 400 end
		bar:SetWidth(math.min(w - 16, 280))
		bar:SetHeight(22)
		bar:SetPoint("BOTTOM", btn, "BOTTOM", 0, 8)
		bar:SetFrameLevel(btn:GetFrameLevel() + 20)

		bar:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = nil,
			tile = true,
			tileSize = 16,
			edgeSize = 0,
			insets = { left = 4, right = 4, top = 2, bottom = 2 }
		})
		bar:SetBackdropColor(0, 0, 0, 0.88)

		local txt = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		local r, g, b = LavenderVibes.Util:LavRGB()
		txt:SetFont("Fonts\\FRIZQT__.TTF", 11)
		txt:SetPoint("CENTER", bar, "CENTER", 0, 0)
		txt:SetJustifyH("CENTER")
		txt:SetTextColor(r, g, b, 1)
		lavCoords.worldMapText = txt

		lavCoords.worldMapBar = bar
		bar:Hide()
	end

	-- Show coords on the world map overlay bar when the world map button is visible
	lavCoords.onWorldMapButtonUpdate = function()
		lavCoords.ensureDefaults()
		if lavCoords.panelHidden or not lavCoords.isWorldMapCoordsOptionOn() then
			if lavCoords.worldMapBar then lavCoords.worldMapBar:Hide() end
			return
		end
		local btn = getWorldMapButton()
		if not btn or not btn:IsVisible() then
			if lavCoords.worldMapBar then lavCoords.worldMapBar:Hide() end
			return
		end
		lavCoords.initWorldMapBar()
		if not lavCoords.worldMapBar then return end
		local bw = btn:GetWidth()
		if bw and bw > 60 then
			lavCoords.worldMapBar:SetWidth(math.min(bw - 16, 280))
		end
		lavCoords.worldMapBar:Show()
		lavCoords.updateWorldMapCoords()
	end

	-- Hook the world map button
	lavCoords.hookWorldMapButton = function()
		if lavCoords._wmButtonHooked then return end
		local btn = getWorldMapButton()
		if not btn then return end
		lavCoords._wmButtonHooked = true
		btn:SetScript("OnUpdate", function()
			local dt = arg1
			-- Call the FrameXML global so `this` is correct inside Blizzard's handler.
			if WorldMapButton_OnUpdate then
				WorldMapButton_OnUpdate(dt)
			end
			lavCoords.onWorldMapButtonUpdate()
		end)
	end

	-- Make sure world map is ready before hooking
	lavCoords.tryHookWorldMapButton = function()
		if lavCoords._wmButtonHooked then return end
		lavCoords.hookWorldMapButton()
	end

	-- Initialize the context menu
	lavCoords.initContextMenu = function()
		lavCoords.ensureDefaults()
		local opt = {}

		-- Title: Panel
		opt = {
			text = "Panel",
			notClickable = true,
			notCheckable = true,
			isTitle = true
		}
		UIDropDownMenu_AddButton(opt)

		-- Option: [Show Icon]
		opt = {
			text = "Show Icon",
			textR = 0.9, textG = 0.9, textB = 0.9,
			keepShownOnClick = true,
			checked = LavenderOptions._CoordsShowIcon,
			func = function()
				LavenderOptions._CoordsShowIcon = not LavenderOptions._CoordsShowIcon
				lavCoords.applyPanelIconLayout()
			end
		}
		UIDropDownMenu_AddButton(opt)
		
		-- Option: [Show Zone]
		opt = {
			text = "Show Zone",
			textR = 0.9, textG = 0.9, textB = 0.9,
			keepShownOnClick = true,
			checked = LavenderOptions._CoordsShowZone,
			func = function()
				LavenderOptions._CoordsShowZone = not LavenderOptions._CoordsShowZone
				lavCoords.update()
			end
		}
		UIDropDownMenu_AddButton(opt)

		-- Spacer
		opt = {notClickable = true, notCheckable = true}
		UIDropDownMenu_AddButton(opt);
		
		-- Title: World Map
		opt.isTitle = true;
		opt.text = "World Map";
		UIDropDownMenu_AddButton(opt);

		-- Option: [Show Overlay]
		opt = {
			text = "Show Overlay",
			textR = 0.9, textG = 0.9, textB = 0.9,
			keepShownOnClick = true,
			checked = lavCoords.isWorldMapCoordsOptionOn(),
			func = function()
				LavenderOptions._CoordsShowOnMap = not lavCoords.isWorldMapCoordsOptionOn()
				lavCoords.applyWorldMapOverlay()
			end
		}
		UIDropDownMenu_AddButton(opt)
	end

	-- Initialize the coords panel widget
	lavCoords.init = function()
		if lavCoords.frame ~= nil then return end
		lavCoords.ensureDefaults()

		local coordsFrame = CreateFrame("Button", "LavenderCoordsFrame", panel)
		coordsFrame:SetWidth(200)
		coordsFrame:SetHeight(14)
		coordsFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 230, 0)

		local mapIcon = coordsFrame:CreateTexture("LavenderCoordsIcon", "ARTWORK")
		mapIcon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
		mapIcon:SetWidth(14)
		mapIcon:SetHeight(14)
		mapIcon:SetPoint("TOPLEFT", coordsFrame, "TOPLEFT")
		lavCoords.icon = mapIcon

		local coordsText = coordsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		coordsText:SetTextColor(1, 1, 1, 1)
		coordsText:SetFont("Fonts\\FRIZQT__.TTF", 10.17)
		coordsText:SetJustifyH("LEFT")
		lavCoords.text = coordsText
		lavCoords.applyPanelIconLayout()

		coordsFrame:SetScript("OnUpdate", function()
			lavCoords.elapsed = lavCoords.elapsed + arg1
			if lavCoords.elapsed >= lavCoords.updateInterval then
				lavCoords.elapsed = 0
				lavCoords.update()
			end
		end)

		coordsFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
		coordsFrame:RegisterEvent("MINIMAP_ZONE_CHANGED")
		coordsFrame:SetScript("OnEvent", function()
			lavCoords.tryHookWorldMapButton()
			lavCoords.update()
		end)

		local contextFrame = CreateFrame("Frame", "LavenderCoordsContextMenu", UIParent, "UIDropDownMenuTemplate")
		lavCoords.contextFrame = contextFrame
		UIDropDownMenu_Initialize(contextFrame, lavCoords.initContextMenu, "MENU")

		coordsFrame:RegisterForClicks("RightButtonDown", "LeftButtonUp")
		coordsFrame:EnableMouse(true)
		coordsFrame:SetScript("OnClick", function()
			if arg1 == "LeftButton" then
				local wf = getWorldMapFrame()
				if wf and wf:IsVisible() then
					HideUIPanel(wf)
				else
					ShowUIPanel(wf)
				end
			else
				ToggleDropDownMenu(1, nil, contextFrame, coordsFrame, 0, -1)
				GameTooltip:Hide()
			end
		end)

		coordsFrame:SetScript("OnEnter", function()
			local r, g, b = LavenderVibes.Util:LavRGB()
			GameTooltip:SetOwner(coordsFrame, "ANCHOR_NONE")
			GameTooltip:SetPoint("TOPLEFT", coordsFrame, "BOTTOMLEFT", 10, -5)
			GameTooltip:AddLine("Map coordinates", r, g, b)
			GameTooltip:AddLine("Left-click to open map", 0.9, 0.9, 0.9)
			GameTooltip:AddLine("Right-click for options", 0.9, 0.9, 0.9)
			GameTooltip:Show()
		end)
		coordsFrame:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		lavCoords.frame = coordsFrame
		lavCoords.tryHookWorldMapButton()
		lavCoords.update()
	end

	lavCoords.Hide = function()
		lavCoords.panelHidden = true
		lavCoords.frame:Hide()
		if lavCoords.worldMapBar then lavCoords.worldMapBar:Hide() end
	end
	lavCoords.Show = function()
		lavCoords.panelHidden = false
		lavCoords.frame:Show()
		lavCoords.tryHookWorldMapButton()
		lavCoords.applyWorldMapOverlay()
	end

	lavCoords:init()
	return lavCoords
end

LavenderVibes.Hooks.add_action("panel_initialized", function()
	LavenderVibes.Modules.Panel.Widgets:Add(
		"Coords",
		"Show character position within the current zone",
		lvPanel_Coords
	)
end)
