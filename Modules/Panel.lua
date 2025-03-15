--LavenderPanel (info bar)
local lv = LavenderVibes

-- Initialize Panel Widgets
local function initPanelWidgets(panel)

    local widgets = {
        -- Define registry tables
        ["_widgets"] = {},
		["_options"] = {}
    }

    -- Define function to return the ID of a widget 
    widgets.GetWidgetId = function(widget)
        local wType = type(widget)
        if(wType == "number") then
            -- widget param is a number
            return widget
        elseif(wType == "string") then
            -- widget param is a string
            for i,w in ipairs(widgets._widgets) do
                -- lookup by LavenderName
                if(w.LavName == widget) then
                    return i
                end
            end
        else
            -- widget param is a widget
            for i,w in ipairs(widgets._widgets) do
                if(w == widget) then
                    return i
                end
            end
        end
        
        return 0
    end

    -- Define function to register a widget
    widgets.Add = function(self, name, tooltip, callback)
		if self and not widget then widget = self end
		local opts = LavenderOptions.Panel
		local active = opts["widget_" .. name .. "_active"]
        tinsert(widgets._widgets, {
			LavName = name,
			LavInit = callback,
			LavActive = active,
			LavTip = tooltip
		});
		widgets:Update()
		--LavenderPrint(table.getn(widgets._widgets))
    end
    -- Define function to activate a widget
    widgets.Activate = function(self, widget)
		if self and not widget then widget = self end
        local id = widgets.GetWidgetId(widget)
        if(id > 0 and widgets._widgets[id] ~= nil) then
			widgets:ToggleActivated(id, true)
        end
    end

    -- Define function to deactivate a widget
    widgets.Deactivate = function(self, widget)
		if self and not widget then widget = self end
        local id = widgets.GetWidgetId(widget)
        if(id > 0 and widgets._widgets[id] ~= nil) then
            widgets:ToggleActivated(id, false)
        end
        
    end
	
	
	-- Define function to toggle activated state
	widgets.ToggleActivated = function(self, id, active)
		local this = widgets._widgets[id]
		local name = this.LavName
		local tip = this.LavTip
		local pkey = "widget_" .. name .. "_active"
		if active and not this.LavInitd then
			local initLav = this.LavInit
			this = this.LavInit(panel)
			this.LavName = name
			this.LavInit = initLav
			this.LavTip = tip
			this.LavInitd = true
		end
		this.LavActive = active
		
		widgets._widgets[id] = this
		
		LavenderOptions.Panel[pkey] = active
		
		if active then
			this:Show()
		else 
			if(this.LavInitd) then this:Hide() end
		end
	end
	
	
	-- Define function to get the first available widget slot
	widgets.GetFirstFreeSlot = function()
	
	
	end
	

    -- Define function to hide a widget
    widgets.Hide = function(self, widget)
		if self and not widget then widget = self end
        local id = widgets.GetWidgetId(widget)
        if(id > 0 and widgets._widgets[id] ~= nil) then
            widgets._widgets[id].LavHidden = true
        end
        widgets:Update()
    end

    -- Define function to hide all widgets
    widgets.HideAll = function()
        for i,w in pairs(widgets._widgets) do
            widgets._widgets[i].LavHidden = true
        end
        widgets:Update()
    end

    -- Define function to show a widget
    widgets.Show = function(self, widget)
        local id = widgets.GetWidgetId(widget)
        if(id > 0 and widgets._widgets[id] ~= nil) then
            widgets._widgets[id].LavHidden = false
        end
        widgets:Update()
    end

    -- Define function to show all widgets
    widgets.ShowAll = function()
        for i,w in pairs(widgets._widgets) do
            widgets._widgets[i].LavHidden = false
        end
        widgets:Update()
    end

    -- Define function to update/refresh widgets
    widgets.Update = function()
        for i,w in pairs(widgets._widgets) do
            -- determine which widgets should be shown
			if w.LavActive then
				widgets:Activate(i)
			else
				widgets:Deactivate(i)
			end
			
			-- do some fancy ish to:
            -- * position activated widgets in order
            -- * hide on demand (activated and position preserved)
        end
    end

    -- Define function to list all registered widgets
    widgets.List = function()
        return widgets._widgets
    end

    -- Define function to list all activated widgets
    widgets.Active = function()
        local active = {}
        for i,w in pairs(widgets._widgets) do
            if(w.LavenderActive == true) then
                tinsert(active, w)
            end
        end
        return active
    end

    -- Define function to list all hidden widgets
    widgets.Hidden = function()
        local hidden = {}
        for i,w in pairs(widgets._widgets) do
            if(w.LavenderHidden == true) then
                tinsert(hidden, w)
            end
        end
    end
	
	return widgets
end


-- Initialize Panel Configuration Options
local function initPanelConfig()
	local panel = LavenderVibes.Modules.Panel
	local configFrame = CreateFrame("Frame", "LavenderPanelConfigFrame")
	local configTitle = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	configTitle:SetFont("Fonts\\FRIZQT__.TTF", 11)
	configTitle:SetPoint("TOP", configFrame, "TOP", 0, -10)
	configTitle:SetText("Panel Widgets")
	local options = {}
	local widgets = panel.Widgets:List()
	for i,w in ipairs(widgets) do
		local opt = "LavenderPanelWidget" .. w.LavName
		--DetailsCbOption(frame, pos, name, label, checked, ttFunc, cbFunc)
		local lavTip = "fuck you"
		if w.LavTip then lavTip = w.LavTip end
		tinsert(options, LavenderVibes.Config:DetailsCbOption(
			configFrame, i, opt, w.LavName, w.LavActive,
			function(cb)
				-- on hover
				GameTooltip:SetOwner(cb, "ANCHOR_CURSOR")
				GameTooltip:SetPoint("BOTTOMLEFT", cb, "TOPRIGHT", 0, -3)
				GameTooltip:AddLine(lavTip)
				GameTooltip:Show()
			end,
			function(cb)
				-- on click
				local tf = "false"
				if cb:GetChecked() then tf = "true" end
				LavenderPrint("Clicked " .. cb:GetName() .. ": " .. tf)
			end
		));
	end
	configFrame.Options = options
	return configFrame
end

LavenderVibes.Hooks.add_action("panel_initialized", function(panel)
	LavenderVibes.Util.SetTimeout(2, function()
		if not panel.ConfigDetails then
			panel.ConfigDetails = initPanelConfig()
		end
	end)
end)

-- Initialize Panel module
local function lvPanel()

	-- Initialize module options
	if not LavenderOptions.Panel then
		LavenderOptions.Panel = {}
	end

    -- Create panel frame
    local panel = CreateFrame("Frame", "LavenderVibesPanelFrame", UIParent)
    panel:SetWidth(UIParent:GetWidth() - (Minimap:GetWidth() / 6))
	panel:SetHeight(14)
    panel:SetPoint("TOPLEFT", UIParent, "TOPLEFT")
	
	--[[panel:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
		tile = true, edgeSize = 1, tileSize = 5
	})--]]
	

    -- Initialize widgets
	local widgets = initPanelWidgets(panel)
    panel.Widgets = widgets
	
	-- Handle slash commands
	
	panel.HandleSlashCommands = function(cmd)
		
	end
	lv.Commands.Add("panel", panel.handleSlashCommands, "Configure the info panel.", true)

    -- Hook to unload the module
	lv.Hooks.add_action("unload_module_Panel", function()
		-- * remove slash commands
		
		-- * remove hooks

		-- hide frames
		panel:Hide()
	end)

    -- Module initialized
    lv.Modules.Panel = panel
    lv.Hooks.do_action("panel_initialized", panel)
end

-- Hook to register the module
LavenderVibes.Hooks.add_action("modules_available", function() tinsert(LavenderVibes.Modules, "Panel") end)


-- Hook to load the module
LavenderVibes.Hooks.add_action("load_module_Panel", lvPanel)