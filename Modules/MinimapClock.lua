-- Lavender Vibes Module: Minimap Clock

local function lvMinimapClock()
	local miniClock = {};
	miniClock.frame = nil;
	miniClock.text = nil;
	miniClock.tooltip = false;
	miniClock.init = function()
		if not (miniClock.frame == nil) then return end
		
		-- Register slash commands
		miniClock.registerSlashCommands()
		
		-- Create a frame to display the time
		local timeFrame = CreateFrame("Button", "LocalTimeFrame", Minimap)
		timeFrame:SetWidth(100)
		timeFrame:SetHeight(20)
		timeFrame:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, -20)
		timeFrame.rc = false

		-- Create a font string for the time display
		local timeText = timeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		timeText:SetPoint("CENTER", timeFrame, "CENTER")
		timeText:SetTextColor(1, 1, 1, 1)
		miniClock.text = timeText
		
		-- Update the time every second
		timeFrame.timeLastUpdate = 0
		timeFrame:SetScript("OnUpdate", function()
			local timeNow = time()
			local elapsed = timeNow - timeFrame.timeLastUpdate
			if elapsed >= 1 then
				miniClock.update()
				timeFrame.timeLastUpdate = timeNow
			end
			
			-- Show tooltip on mouseover
			if(MouseIsOver(timeFrame) and GetMouseFocus() == timeFrame) then
				local display = ""
				if(LavenderOptions._ClockDisplay == "clock") then
					display = miniClock.sessionPlayed()
				elseif(LavenderOptions._ClockDisplay == "session") then
					display = miniClock.currentTime()
				else
					-- show timer
				end
				GameTooltip:SetOwner(timeFrame, "ANCHOR_RIGHT")
				GameTooltip:SetText(display, 1, 1, 1, 1, true)
				GameTooltip:Show()
				miniClock.tooltip = true
			else
				if miniClock.tooltip then
					GameTooltip:Hide()
					miniClock.tooltip = false
				end
			end
		end)
		
		-- Create a context menu
		local contextFrame = CreateFrame("Frame", "LavenderClockContextMenu", UIParent, "UIDropDownMenuTemplate")
		UIDropDownMenu_Initialize(contextFrame, miniClock.initContextMenu, "MENU");
		miniClock.contextFrame = contextFrame

		-- Set up OnClick to show the context menu
		timeFrame:EnableMouse(true)
		timeFrame:SetScript("OnMouseDown", function()
			ToggleDropDownMenu(1, nil, contextFrame, timeFrame, 0, 0);
			UIDropDownMenu_SetSelectedValue(contextFrame, LavenderOptions._ClockDisplay, false)
		end)
		
		miniClock.frame = timeFrame
		miniClock.update()
	end

	miniClock.initContextMenu = function()
		local menuItems = {
			{ text = "Current Time", value = "clock" },
			{ text = "This Session", value = "session" },
			{ text = "New Timer", value = "timer" }
		}
		for i, item in pairs(menuItems) do
			local val = item.value
			local txt = item.text
			item.func = function() 
				UIDropDownMenu_SetSelectedValue(miniClock.contextFrame, val, false)
				LavenderOptions._ClockDisplay = val
				if(val == "timer") then miniClock:newTimer() end
				miniClock:update()
			end
			UIDropDownMenu_AddButton(item);
		end
	end

	miniClock.update = function()
		local hours, minutes = GetGameTime()
		local ampm = 'AM'
		if(hours >= 12) then
			ampm = 'PM'
			if(hours > 12) then
				hours = hours - 12;
			end
		end
		
		if(LavenderOptions._ClockDisplay == "clock") then
			-- show current time
			miniClock.text:SetText(miniClock.currentTime())
		elseif(LavenderOptions._ClockDisplay == "session") then
			-- current session time played (elapsed)
			miniClock.text:SetText(miniClock.sessionPlayed())
		elseif(LavenderOptions._ClockDisplay == "timer") then
			-- new timer
			miniClock.text:SetText(miniClock.timerElapsed())
		else 
			-- reset to show current time
			miniClock.text:SetText(miniClock.currentTime())
			LavenderOptions._ClockDisplay = "clock"
		end
	end
	
	miniClock.registerSlashCommands = function()
		LavenderVibes.Commands.Add("clock", miniClock.handleSlashCommands, "Commands to control the clock.")
		
	end
	
	miniClock.handleSlashCommands = function(args)
		if(args == "") then
			LavenderPrint("Lavender Vibes Clock/Timer Sub-Commands:", "Druid")
			LavenderPrint("TODO: add sub-commands for MinimapClock")
		elseif(args == "hide") then
			miniClock.frame:Hide()
		elseif(args == "show") then
			miniClock.frame:Show()
		end
	end

	miniClock.disable = function()
		miniClock.frame:Hide()
	end

	miniClock.enable = function()
		if miniClock.frame == nil then miniClock:init() end
		miniClock.frame:Show()
	end

	miniClock.currentTime = function()
		local hours, minutes = GetGameTime()
		local ampm = 'AM'
		if(hours >= 12) then
			ampm = 'PM'
			if(hours > 12) then
				hours = hours - 12;
			end
		elseif(hours == 0) then
			hours = 12
		end
		
		return string.format("%2d:%02d", hours, minutes) .. ' ' .. ampm
	end

	miniClock.sessionPlayed = function()
		local startTime = LavenderVibes.Session
		if not startTime then startTime = 0 end
		local endTime = time()
		local difference = endTime - startTime
		local hours = math.floor(difference / 3600)
		local mins = math.floor((difference - (hours * 3600)) / 60)
		local seconds = difference - (hours * 3600) - (mins * 60)
		local played = ""
		if hours > 0 then
			played = tostring(hours) .. "h " .. tostring(mins) .. "m "
		else
			played = tostring(mins) .. "m "
		end
		played = played .. tostring(seconds) .. "s"
		return played
	end

	miniClock.timerStart = time()
	miniClock.newTimer = function()
		miniClock.timerStart = time()
	end

	miniClock.timerElapsed = function()
		local startTime = miniClock.timerStart
		local endTime = time()
		local difference = endTime - startTime
		local hours = math.floor(difference / 3600)
		local mins = math.floor((difference - (hours * 3600)) / 60)
		local seconds = difference - (hours * 3600) - (mins * 60)
		local elapsed = ""
		if hours > 0 then
			elapsed = tostring(hours) .. "h " .. tostring(mins) .. "m "
		else
			elapsed = tostring(mins) .. "m "
		end
		elapsed = elapsed .. tostring(seconds) .. "s"
		return elapsed
	end

	miniClock:init()
	LavenderVibes.Modules.MinimapClock = miniClock
	
	-- hook to disable module
	LavenderVibes.Hooks.add_action("unload_module_MinimapClock", miniClock.disable)
end

local function registerModule()
	table.insert(LavenderVibes.Modules, "MinimapClock")
end 

LavenderVibes.Hooks.add_action("load_module_MinimapClock", lvMinimapClock);
LavenderVibes.Hooks.add_action("modules_available", registerModule)