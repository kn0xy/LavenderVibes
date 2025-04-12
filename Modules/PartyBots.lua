-- Lavender Vibes Module: Party Bots

local function lvPartyBots()
    local lv = LavenderVibes

    local partyBots = {
        Bots = {},
        LastPausedTime = {},
        Encounters = {}
    }

    -- Initialize baron button option
    if LavenderOptions._PartyBotsShowBaronButton == nil then
        LavenderOptions._PartyBotsShowBaronButton = false
    end

    -- Initialize the main menu
    local function initializeMenu(level)
        if not level then level = 1 end
        
        local menuItems = {
            {
                text = "Bot Controls",
                hasArrow = true,
                value = "BOT_CONTROLS",
                menuList = {
                    {
                        text = "Pause All",
                        notCheckable = true,
                        func = function()                           
                            partyBots:PauseAllBots()
                        end
                    }
                }
            },
            {
                text = "Window Options",
                hasArrow = true,
                value = "WINDOW_OPTIONS",
                menuList = {
                    {
                        isTitle = true,
                        text = "Window Options", 
                        notCheckable = true,
                    },
                    {
                        text = "Register Party",
                        notCheckable = true,
                        func = function()
                            partyBots:QuickLoad()
                        end
                    },
                    {
                        text = "Unregister All Bots",
                        notCheckable = true,
                        func = function()
                            for botName, _ in pairs(partyBots.Bots) do
                                partyBots:UnregisterBot(botName)
                            end
                        end
                    },  
                    {
                        text = "Show Baron Button",
                        keepShownOnClick = false,
                        checked = LavenderOptions._PartyBotsShowBaronButton,
                        func = function()
                            if not this.checked then
                                LavenderOptions._PartyBotsShowBaronButton = true
                                partyBots.baronButton:Show()
                            else
                                LavenderOptions._PartyBotsShowBaronButton = false
                                partyBots.baronButton:Hide() 
                            end
                        end
                    }
                }
            }
        }

        
        if level == 1 then
            -- Top level menu items
            for _, item in ipairs(menuItems) do
                item.notCheckable = true
                UIDropDownMenu_AddButton(item, level)
            end
        else
            -- Submenu items
            local value = UIDROPDOWNMENU_MENU_VALUE
            for _, parentItem in ipairs(menuItems) do
                if parentItem.value == value then
                    for _, subItem in ipairs(parentItem.menuList) do
                        UIDropDownMenu_AddButton(subItem, level)
                    end
                    break
                end
            end
        end
    end

    -- Initialize the main frame
    local function initDaddyFrame()
        local frame = CreateFrame("Button", "LavenderBotsFrame", UIParent)
        frame:SetWidth(116)
        frame:SetHeight(80)
        -- Set initial position, either from saved options or default center
        if LavenderOptions._PartyBotsFramePos then
            frame:SetPoint(LavenderOptions._PartyBotsFramePos.point, UIParent, 
                LavenderOptions._PartyBotsFramePos.relativePoint, 
                LavenderOptions._PartyBotsFramePos.xOfs, 
                LavenderOptions._PartyBotsFramePos.yOfs)
        else
            frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:SetScript("OnClick", function(self, arg1)
            if arg1 == "RightButton" then
                partyBots.currentView = "grid"
                partyBots:updateBotFrames()
            end
        end)
        
        -- Create background
        frame.bg = frame:CreateTexture(nil, "BACKGROUND")
        frame.bg:SetAllPoints(true)
        frame.bg:SetTexture(0, 0, 0, 0.5)
        
        -- Create context menu
        local contextMenu = CreateFrame("Frame", "LavenderBotsContextMenu", UIParent, "UIDropDownMenuTemplate")
        
        -- Create header for dragging
        local header = CreateFrame("Button", nil, frame)
        header:SetHeight(20)
        header:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        header:EnableMouse(true)
        header:RegisterForDrag("LeftButton")
        header:SetScript("OnDragStart", function() frame:StartMoving() end)
        header:SetScript("OnDragStop", function() 
            frame:StopMovingOrSizing()
            -- Store frame position in LavenderOptions
            local point, _, relativePoint, xOfs, yOfs = frame:GetPoint()
            LavenderOptions._PartyBotsFramePos = {
                point = point,
                relativePoint = relativePoint,
                xOfs = xOfs,
                yOfs = yOfs
            }
        end)
        header:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        header:SetScript("OnClick", function()
            if arg1 == "RightButton" then
                UIDropDownMenu_Initialize(contextMenu, initializeMenu, "MENU")
                ToggleDropDownMenu(1, nil, contextMenu, "cursor", 0, 70)
            end
        end)
        
        -- Header background
        header.bg = header:CreateTexture(nil, "BACKGROUND")
        header.bg:SetAllPoints(true)
        header.bg:SetTexture(0.2, 0.2, 0.2, 0.8)
        
        -- Header text
        local headerText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        headerText:SetPoint("LEFT", header, "LEFT", 5, 0)
        headerText:SetText("Party Bots")
        
        -- Create content frame for bot squares/rows
        local content = CreateFrame("Frame", nil, frame)
        content:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -5)
        content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 5)
        frame.content = content
        
        -- Close button
        frame.closeButton = CreateFrame("Button", nil, header, "UIPanelCloseButton")
        frame.closeButton:SetPoint("TOPRIGHT", header, "TOPRIGHT", 6, 6)
        frame.closeButton:SetScript("OnClick", function()
            PlaySound("igMainMenuClose")
            frame:Hide()
            LavenderOptions._PartyBotsFrameShown = false
        end)

        -- Track frame visibility changes
        frame:SetScript("OnHide", function()
            LavenderOptions._PartyBotsFrameShown = false
        end)
        frame:SetScript("OnShow", function()
            LavenderOptions._PartyBotsFrameShown = true
        end)
        
        if not LavenderOptions._PartyBotsFrameShown then
            frame:Hide()
        end
        
        return frame
    end


    local function initBaronButton()
        -- Create Baron button
        local frame = partyBots.Frame
        partyBots.baronButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        partyBots.baronButton:SetWidth(100)
        partyBots.baronButton:SetHeight(20)
        partyBots.baronButton:SetPoint("TOP", frame, "BOTTOM", 0, -5)
        partyBots.baronButton:SetText("Get Out!")
        partyBots.baronButton:SetScript("OnClick", function()
            partyBots:targetPlayerByName("Catatonic")
            lv.Throttle.Add(".partybot pause", "SAY")
            lv.Throttle.Add(".partybot cometome", "SAY")
            LavenderVibes.Util.SetTimeout(0.35, function()
                partyBots:targetPlayerByName("Moonkorius")
                lv.Throttle.Add(".partybot pause", "SAY")
                lv.Throttle.Add(".partybot cometome", "SAY")
            end)
        end)
        partyBots.baronButton:Hide()
    end


    

    -- Initialize encounters
    local function initEncounters()
        initBaronButton()
    end

    -- Function to target a specific player by name
    partyBots.targetPlayerByName = function(self, playerName)
        if not playerName then return false end
        
        -- Check if player is in our party/raid first
        for i = 1, GetNumPartyMembers() do
            if UnitName("party"..i) == playerName then
                TargetUnit("party"..i)
                return true
            end
        end

        -- Not found in party, try targeting by name
        TargetByName(playerName, true)
        
        -- Verify we got the right target
        if UnitName("target") == playerName then
            return true
        end
    
        return false
    end

    

    -- Create menu for selecting target marker for focusmark
    local function CreateMarkerMenu()
        local markers = {
            {icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcons", coord = {0.75, 1, 0.25, 0.5}, name = "skull"},
            {icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcons", coord = {0.5, 0.75, 0.25, 0.5}, name = "cross"},
            {icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcons", coord = {0.25, 0.5, 0.25, 0.5}, name = "square"},
            {icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcons", coord = {0, 0.25, 0.25, 0.5}, name = "moon"},
            {icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcons", coord = {0, 0.25, 0, 0.25}, name = "star"},
            {icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcons", coord = {0.25, 0.5, 0, 0.25}, name = "circle"},
            {icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcons", coord = {0.5, 0.75, 0, 0.25}, name = "diamond"},
            {icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcons", coord = {0.75, 1, 0, 0.25}, name = "triangle"},
        }
    
        local container = CreateFrame("Frame", "LVMarkerContainer", UIParent)
        container:SetWidth(140) -- 4 columns * 30px + padding
        container:SetHeight(80) -- 2 rows * 30px + padding
        container:SetFrameLevel(100) -- Ensure it appears on top
        container:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        container:SetBackdropColor(0, 0, 0, 0.8)
        container:Hide()
        container:EnableMouse(true)
       
        -- Hide on mouse out
        container:SetScript("OnLeave", function()
            if not MouseIsOver(container) then
                container:Hide()
            end
        end)
    
        for i, marker in ipairs(markers) do
            local button = CreateFrame("Button", nil, container)
            button:SetWidth(30)
            button:SetHeight(30)
            button.marker = marker.name
            
            local row = math.floor((i-1) / 4)
            local col = math.mod(i-1, 4)
            button:SetPoint("TOPLEFT", container, "TOPLEFT", 10 + (col * 30), -10 - (row * 30))
    
            local texture = button:CreateTexture(nil, "ARTWORK")
            texture:SetTexture(marker.icon)
            texture:SetTexCoord(unpack(marker.coord))
            texture:SetAllPoints(true)
            texture:SetAlpha(0.8)
    
            button:SetScript("OnClick", function()
                if IsShiftKeyDown() then
                    -- Set CC marker    
                    SendChatMessage(".partybot ccmark " .. button.marker, "SAY")
                else
                    -- Set Focus marker
                    SendChatMessage(".partybot focusmark " .. button.marker, "SAY")
                end
                partyBots.targetOpFrame.elapsed = 0
                partyBots.targetOpFrame:Show()
                container:Hide()
            end)
    
            -- Add hover effect
            button:SetScript("OnEnter", function()
                texture:SetAlpha(1.0)
            end)
            button:SetScript("OnLeave", function()
                texture:SetAlpha(0.8)
            end)
        end
    
        return container
    end
    

    -- Get current party members
    local function getPartyMembers()
        -- Get current party members
        local currentPartyMembers = {}
        if GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do
                local name = UnitName("party"..i)
                if name then
                    currentPartyMembers[name] = true
                end
            end
        end
        return currentPartyMembers
    end

    -- Initialize event handlers
    local function initEventHandlers()
        -- Handle system chat events (for tracking bot paused/unpaused status)
        local chatEventFrame = CreateFrame("Frame")
        chatEventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
        chatEventFrame:SetScript("OnEvent", function()
            local message = arg1
            if not message then return end
            
            -- Check for pause messages
            for botName, _ in pairs(partyBots.Bots) do
                local pattern = botName .. " paused"
                if string.find(string.lower(message), string.lower(pattern)) then
                    -- bot was paused
                    partyBots.LastPausedTime[botName] = GetTime()
                else
                    pattern = botName .. " unpaused"
                    if string.find(string.lower(message), string.lower(pattern)) then
                        -- bot was unpaused
                        partyBots.LastPausedTime[botName] = nil
                    end
                end
            end
        end)
        partyBots.chatEventFrame = chatEventFrame


        -- Handle party changes
        local partyEventFrame = CreateFrame("Frame")
        partyEventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
        partyEventFrame:SetScript("OnEvent", function()
            local currentPartyMembers = getPartyMembers()
            
            -- Check each bot and unregister if they're no longer in party
            for botName, _ in pairs(partyBots.Bots) do
                if not currentPartyMembers[botName] then
                    partyBots:UnregisterBot(botName)
                    LavenderPrint(string.format("%s has left the party - unregistered", botName))
                end
            end
        end)
        partyBots.partyEventFrame = partyEventFrame

        -- Handle targeting operations
        local targetOpFrame = CreateFrame("Frame")
        targetOpFrame:Hide()
        targetOpFrame.elapsed = 0
        targetOpFrame.targetToRestore = nil
        targetOpFrame.shouldClear = false
        targetOpFrame:SetScript("OnUpdate", function()
            targetOpFrame.elapsed = targetOpFrame.elapsed + arg1
            if targetOpFrame.elapsed >= 0.15 then
                if targetOpFrame.targetToRestore then
                    TargetByName(targetOpFrame.targetToRestore, true)
                elseif targetOpFrame.shouldClear then
                    ClearTarget()
                end
                targetOpFrame:Hide()
                targetOpFrame.elapsed = 0
                targetOpFrame.targetToRestore = nil
                targetOpFrame.shouldClear = false
            end
        end)
        partyBots.targetOpFrame = targetOpFrame
    end

    

    -- Check if a bot was recently paused (within last 300 seconds)
    partyBots.checkPaused = function(playerName)
        local currentTime = GetTime()
        local pauseTime = partyBots.LastPausedTime[playerName]
        if pauseTime and (currentTime - pauseTime) <= 300 then
            return true -- paused
        end
        return false -- not paused
    end

    -- Update all bot frames based on current view
    partyBots.updateBotFrames = function(self)
        if not self.Frame then return end
        
        -- Hide all existing frames first
        for _, botData in pairs(self.Bots) do
            botData.frame:Hide()
        end
        
        -- Get list of bots
        local botNames = {}
        for botName, _ in pairs(self.Bots) do
            table.insert(botNames, botName)
        end
        
        -- Grid View Layout
        local xOffset, yOffset = 5, -5
        local maxWidth = self.Frame:GetWidth() - 10
        local frameSize = 35 -- 30px frame + 5px spacing
        local framesPerRow = 3
        
        local currentRow, currentCol = 0, 0
        for i = 1, table.getn(botNames) do
            local botName = botNames[i]
            local botData = self.Bots[botName]
            
            botData.frame:Show()
            botData.frame:SetPoint("TOPLEFT", self.Frame.content, "TOPLEFT",
                xOffset + (currentCol * frameSize),
                -yOffset - (currentRow * frameSize))
            
            currentCol = currentCol + 1
            if currentCol >= framesPerRow then
                currentCol = 0
                currentRow = currentRow + 1
            end
        end
    end

    -- Create or update a bot frame
    local function updateBotFrame(name, class)
        if not partyBots.Frame then return end
        
        -- Create bot frame if it doesn't exist
        if not partyBots.Bots[name] then
            -- Create grid view frame as a Button
            local botFrame = CreateFrame("Button", nil, partyBots.Frame.content)
            botFrame:SetWidth(30)
            botFrame:SetHeight(30)
            
            -- Create background texture
            local bg = botFrame:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(true)
            
            -- Create name text
            local nameText = botFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            nameText:SetPoint("CENTER", botFrame, "CENTER", 0, 0)
            local shortName = string.sub(name, 1, 4)
            nameText:SetText(lv.Util.ColorTextByClass(shortName, class))
            
            -- Add click handler
            botFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
            botFrame:SetScript("OnClick", function()
                -- Save current target
                local hadTarget = UnitExists("target")
                local previousTarget = nil
                if hadTarget then
                    previousTarget = UnitName("target")
                end

                if IsShiftKeyDown() then
                    if(arg1 == "LeftButton") then
                        -- Shift + Left click: Unregister bot
                        partyBots:UnregisterBot(name)
                    elseif(arg1 == "RightButton") then
                        -- Shift + Right click: Unregister bot
                        partyBots:UnregisterBot(name)
                    end
                else
                    -- Target the bot
                    TargetByName(name, true)
                    if UnitExists("target") then
                        if arg1 == "LeftButton" then
                            -- Left click: Come to me
                            SendChatMessage(".partybot cometome", "SAY")
                            
                        elseif arg1 == "MiddleButton" then
                            -- Middle click: Set Marker Assignment
                            partyBots.MarkerMenu:ClearAllPoints()
                            partyBots.MarkerMenu:SetPoint("BOTTOM", botFrame, "TOP", 0, -5)
                            partyBots.MarkerMenu:SetFrameLevel(this:GetFrameLevel() + 10)
                            partyBots.MarkerMenu:Show()
                        elseif arg1 == "RightButton" then
                            -- Right click: Pause/Unpause
                            if partyBots.checkPaused(name) then
                                SendChatMessage(".partybot unpause", "SAY")
                            else
                                SendChatMessage(".partybot pause", "SAY")
                            end
                        end
                    end
                end
            
                -- Queue target restoration with a delay
                if previousTarget then
                    partyBots.targetOpFrame.targetToRestore = previousTarget
                else
                    partyBots.targetOpFrame.shouldClear = true
                end
                if(arg1 == "MiddleButton") then return end
                partyBots.targetOpFrame.elapsed = 0
                partyBots.targetOpFrame:Show()
            end)


            --- TODO::
            -- add pause all

            -- add attack start
            
            
            partyBots.Bots[name] = {
                frame = botFrame,
                bg = bg,
                nameText = nameText,
                class = class,
                shortName = shortName
            }
        end
        
        -- Update bot frame appearance and name text color
        local r, g, b = lv.Util.RgbClassColor(class)
        if not r then
            LavenderPrint("Invalid target.")
            return false
        end
        partyBots.Bots[name].bg:SetTexture(r, g, b, 0.8)
        partyBots.Bots[name].nameText:SetText(lv.Util.ColorTextByClass(partyBots.Bots[name].shortName, class))
        partyBots.Bots[name].class = class
        
        -- Update all frames based on current view
        partyBots:updateBotFrames()
    end

    

    -- Check if a unit is a party bot
    partyBots.unitIsBot = function(name)
        if not name then return false end
        
        -- Check if the unit exists in our bots table
        return partyBots.Bots[name] ~= nil
    end

    -- Find a unit ID by name
    partyBots.findUnitIDByName = function(self, searchName)
        -- Check target first
        if UnitName("target") == searchName and UnitIsFriend("player", "target") and partyBots.unitInParty(searchName) then
            return "target"
        end
        -- Check party members
        for i = 1, GetNumPartyMembers() do
            if UnitName("party"..i) == searchName then
                return "party"..i
            end
        end
        return nil

    end

    -- Check if a unit is in the current party
    partyBots.unitInParty = function(name)
        for i = 1, GetNumPartyMembers() do
            if UnitName("party"..i) == name then
                return true
            end
        end
    end

    

    -- Register a new bot
    partyBots.RegisterBot = function(self, name, class)
        if not name or not class then return end

        if not partyBots.unitInParty(name) then
            LavenderPrint(string.format("Cannot register %s - not in party", name))
            return false
        end

        if partyBots.unitIsBot(name) then
            LavenderPrint(string.format("Cannot register %s - already a bot", name))
            return false
        end

        local unitID = partyBots:findUnitIDByName(name)
        if unitID then
            local _, unitClass = UnitClass(unitID)
            if unitClass then
                class = lv.Util.UCFirst(unitClass)
            end
        end
        
        updateBotFrame(name, class)
    end

    -- Function to show the frame
    partyBots.Show = function(self)
        self.Frame:Show()
        LavenderOptions._PartyBotsFrameShown = true
    end

    -- Function to hide the frame
    partyBots.Hide = function(self)
        self.Frame:Hide()
        LavenderOptions._PartyBotsFrameShown = false
    end

    -- Quick load
    partyBots.QuickLoad = function(self)
        -- Show the window if it was previously shown
        if LavenderOptions._PartyBotsFrameShown then
            self:Show()
        end
            
        -- Register all party members as bots
        for i = 1, GetNumPartyMembers() do
            local name = UnitName("party"..i)
            if name then
                local _, class = UnitClass("party"..i)
                if class then
                    self:RegisterBot(name, lv.Util.UCFirst(class))
                    LavenderPrint(string.format("Registered %s as a bot (%s)", name, class))
                end
            end
        end
    end

    -- List module sub-commands
    partyBots.ListSubcommands = function(self)
        LavenderPrint("Party Bots Sub-Commands:")
        LavenderPrint("  /lv pb - Register current target as a bot (or show the window if no target exists)")
        LavenderPrint("  /lv pb register [botName] - Register a player as a bot")
        LavenderPrint("  /lv pb unreg [botName] - Unregister a player as a bot")
        LavenderPrint("  /lv pb toggle - Toggle the window")
        LavenderPrint("  /lv pb quick - Show window and register party members")
        LavenderPrint("  /lv pb ? - Show this help message")
    end


    -- Handle slash commands
    partyBots.handleSlashCommands = function(args)
        if args == "" then
            -- Check if we have a target
            if UnitExists("target") then
                local name = UnitName("target")
                local _, class = UnitClass("target")                
                if name then
                    if class then
                        if partyBots:RegisterBot(name, class) then
                            LavenderPrint(string.format("Registered %s as a bot (%s)", name, class))
                        end
                    else
                        LavenderPrint("Could not detect class. Usage: /lv pb [name]")
                    end
                else
                    LavenderPrint("Debug: Could not get target name")
                end
            else
                -- no target selected, show the window
                partyBots:Show()
            end
        elseif args == "?" then
            partyBots:ListSubcommands()

        elseif args == "unreg" then
            local _, _, name = string.find(args, "%s?(%w*)")
            if not name then
                LavenderPrint("Usage: /lv pb unreg [name]")
                return
            end
            partyBots:UnregisterBot(name)

        elseif args == "toggle" then
            if partyBots.Frame and partyBots.Frame:IsShown() then
                partyBots.Frame:Hide()
            else
                partyBots.Frame:Show()
            end

        elseif string.find(args, "^register%s+(.+)$") then
            local _, _, name = string.find(args, "^register%s+(.+)$")
            if not name then
                LavenderPrint("Usage: /lv pb register [name]") 
                return
            else
                name = lv.Util.UCFirst(name)
            end

            local class = nil
            local unitID = partyBots:findUnitIDByName(name)
            if unitID then
                local _, detectedClass = UnitClass(unitID)
                if detectedClass then
                    class = detectedClass
                end
            end

            if class then
                partyBots:RegisterBot(name, lv.Util.UCFirst(class))
                LavenderPrint(string.format("Registered %s as a bot (%s)", name, class))
            else
                LavenderPrint("Name = " .. name)
                LavenderPrint("UnitID = " .. unitID)
                LavenderPrint("Class = " .. class)
                LavenderPrint("Could not detect class. Usage: /lv pb register [name]")
            end

        elseif args == "pauseall" then
            -- Save current target
            local hadTarget = UnitExists("target")
            local previousTarget = nil
            if hadTarget then
                previousTarget = UnitName("target")
            end

            -- Clear target before sending command
            ClearTarget()

            -- Send pause command
            SendChatMessage(".partybot pause", "SAY")

            -- Restore previous target after delay
            if hadTarget and previousTarget then
                partyBots.targetOpFrame.targetToRestore = previousTarget
                partyBots.targetOpFrame:Show()
            end
        elseif args == "quick" then
            partyBots:QuickLoad()
        else
            -- local _, _, name, class = string.find(args, "%s?(%w+)%s*(%w*)")
            local _, _, name = string.find(args, "%s?(%w*)")
            if not name then
                LavenderPrint("Usage: /lv pb [name]")
                return
            end

            local class = nil
            local unitID = partyBots:findUnitIDByName(name)
            if unitID then
                local _, detectedClass = UnitClass(unitID)
                if detectedClass then
                    class = detectedClass
                end
            end
            
            if class then
                partyBots:RegisterBot(name, lv.Util.UCFirst(class))
                LavenderPrint(string.format("Registered %s as a bot (%s)", name, class))
            else
                LavenderPrint("STOP IT! Let me play my show God dammit!")
            end
        end
    end

    -- Register slash commands
    partyBots.registerSlashCommands = function()
        lv.Commands.Add("pb", partyBots.handleSlashCommands, "Register a party member as a bot", true)
    end

    -- Function to unregister a bot
    partyBots.UnregisterBot = function(self, name)
        if not name or not self.Bots[name] then 
            LavenderPrint("Invalid bot name provided for unregistration")
            return false 
        end
        
        -- Clean up frames
        if self.Bots[name].frame then
            self.Bots[name].frame:Hide()
            self.Bots[name].frame:SetScript("OnClick", nil)
            self.Bots[name].frame = nil
        end
        if self.Bots[name].listFrame then
            self.Bots[name].listFrame:Hide()
            self.Bots[name].listFrame:SetScript("OnClick", nil)
            self.Bots[name].listFrame = nil
        end
        
        -- Clean up any remaining references
        if self.Bots[name].bg then
            self.Bots[name].bg:SetTexture(nil)
            self.Bots[name].bg = nil
        end
        if self.Bots[name].nameText then
            self.Bots[name].nameText:SetText("")
            self.Bots[name].nameText = nil
        end
        
        -- Remove from bots table
        self.Bots[name] = nil
        
        -- Remove from paused time tracking
        self.LastPausedTime[name] = nil
        
        -- Update display
        self:updateBotFrames()
        
        LavenderPrint(string.format("Successfully unregistered bot: %s", name))
        return true
    end

    -- Initialize module
    partyBots.Frame = initDaddyFrame()
    partyBots.currentView = "grid"
    partyBots.registerSlashCommands()
    partyBots.MarkerMenu = CreateMarkerMenu()
    initEventHandlers()
    initEncounters()
    lv.Modules.PartyBots = partyBots

    -- Hook to hide the window
    lv.Hooks.add_action("hide_all", function() 
        if partyBots.Frame then
            partyBots.Frame:Hide() 
        end
    end)

    -- Hook to unload the module
    lv.Hooks.add_action("unload_module_PartyBots", function()
        -- Unregister events
        partyEventFrame:UnregisterAllEvents()
        
        -- Clean up target operation frame
        if partyBots.targetOpFrame then
            partyBots.targetOpFrame:Hide()
            partyBots.targetOpFrame:SetScript("OnUpdate", nil)
            partyBots.targetOpFrame = nil
        end
        
        -- Remove slash commands
        lv.Commands.Remove("pb")
        
        -- Hide frames
        if partyBots.Frame then
            partyBots.Frame:Hide()
        end
    end)
end

-- Hook to register the module
LavenderVibes.Hooks.add_action("modules_available", function() tinsert(LavenderVibes.Modules, "PartyBots") end)


-- Hook to initialize the module
LavenderVibes.Hooks.add_action("load_module_PartyBots", lvPartyBots)