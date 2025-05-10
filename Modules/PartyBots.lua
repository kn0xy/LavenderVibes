-- Lavender Vibes Module: Party Bots

local function lvPartyBots()
    local lv = LavenderVibes

    local partyBots = {
        Bots = {},
        LastPausedTime = {},
        Encounters = {},
        IsFirstLogin = true,
        AttachedButtons = {},
        AllPaused = false,
        AllStaying = false
    }    

    -- Initialize the main menu
    local function initializeMenu(level)
        if not level then level = 1 end
        
        local menuItems = {
            {
                text = "Actions",
                hasArrow = true,
                value = "ACTIONS",
                menuList = {
                    {
                        text = "Register Party",
                        notCheckable = true,
                        func = function()
                            partyBots:QuickLoad()
                            CloseDropDownMenus()
                        end
                    },
                    {
                        text = "Unregister All Bots",
                        notCheckable = true,
                        func = function()
                            for botName, _ in pairs(partyBots.Bots) do
                                partyBots:UnregisterBot(botName)
                            end
                            CloseDropDownMenus()
                        end
                    }
                }
            },
            {
                text = "Options",
                hasArrow = true,
                value = "WINDOW_OPTIONS",
                menuList = {
                    -- {
                    --     isTitle = true,
                    --     text = "Window Options", 
                    --     notCheckable = true,
                    -- },
                    {
                        text = "Show Pause All Button",
                        keepShownOnClick = true,
                        checked = LavenderOptions._PartyBotsShowPauseAllButton,
                        func = function()
                            if not this.checked then
                                LavenderOptions._PartyBotsShowPauseAllButton = true
                                partyBots.pauseAllButton:Show()
                            else
                                LavenderOptions._PartyBotsShowPauseAllButton = false
                                partyBots.pauseAllButton:Hide() 
                            end
                        end
                    },
                    {
                        text = "Show Stay All Button",
                        keepShownOnClick = true,
                        checked = LavenderOptions._PartyBotsShowStayAllButton,
                        func = function()
                            if not this.checked then
                                LavenderOptions._PartyBotsShowStayAllButton = true
                                partyBots.stayAllButton:Show()
                            else
                                LavenderOptions._PartyBotsShowStayAllButton = false
                                partyBots.stayAllButton:Hide() 
                            end
                        end
                    }
                }
            },
            
            {
                text = partyBots.AllPaused and "Unpause All" or "Pause All",
                notCheckable = true,
                func = function()                           
                    partyBots:PauseAllBots()
                end
            },
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
        frame:SetWidth(110)
        frame:SetHeight(55)
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
                ToggleDropDownMenu(1, nil, contextMenu, "cursor", 0, 85)
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
        end)

        -- Track frame visibility changes
        frame:SetScript("OnHide", function()
            LavenderOptions._PartyBotsFrameShown = false
        end)
        frame:SetScript("OnShow", function()
            partyBots:updateBotFrames()
            LavenderOptions._PartyBotsFrameShown = true
        end)
        
        if not LavenderOptions._PartyBotsFrameShown then
            frame:Hide()
        end
        
        return frame
    end


    local function initPauseAllButton()
        -- Create Pause All button
        local frame = partyBots.Frame
        local btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        btn:SetWidth(100)
        btn:SetHeight(20)
        btn:SetText(partyBots.AllPaused and "Unpause All" or "Pause All")
        btn:SetScript("OnClick", function()
            partyBots:PauseAllBots()
        end)

        if not LavenderOptions._PartyBotsShowPauseAllButton then
            btn:Hide()
        else
            partyBots:attachButton(btn)
        end

        -- Set show/hide scripts to manage attachment
        btn:SetScript("OnShow", function() partyBots:attachButton(btn) end)
        btn:SetScript("OnHide", function() partyBots:detachButton(btn) end)

        partyBots.pauseAllButton = btn
    end

    local function initStayAllButton()
        -- Create Stay All button
        local frame = partyBots.Frame
        local btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        btn:SetWidth(100)
        btn:SetHeight(20)
        btn:SetText(partyBots.AllStaying and "Unstay All" or "Stay All")
        btn:SetScript("OnClick", function()
            partyBots:StayAllBots()
        end)

        if not LavenderOptions._PartyBotsShowStayAllButton then
            btn:Hide()
        else
            partyBots:attachButton(btn)
        end

        -- Set show/hide scripts to manage attachment
        btn:SetScript("OnShow", function() partyBots:attachButton(btn) end)
        btn:SetScript("OnHide", function() partyBots:detachButton(btn) end)

        partyBots.stayAllButton = btn
    end

    -- Initialize actions
    local function initActions()
        initPauseAllButton()
        initStayAllButton()
    end

    -- Function to add button to attached buttons
    function partyBots.attachButton(self, button)
        if self and not button then button = self end
        table.insert(partyBots.AttachedButtons, button)
        partyBots:updateButtonPositions()
    end

    -- Function to remove button from attached buttons
    function partyBots.detachButton(self, button)
        if self and not button then button = self end
        for i, attachedButton in ipairs(partyBots.AttachedButtons) do
            if attachedButton == button then
                table.remove(partyBots.AttachedButtons, i)
                break
            end
        end
        partyBots:updateButtonPositions()
    end

    -- Function to update button positions
    function partyBots.updateButtonPositions()
        local lastButton = nil
        for _, button in ipairs(partyBots.AttachedButtons) do
            if button:IsShown() then
                if lastButton and lastButton ~= button then
                    button:SetPoint("TOP", lastButton, "BOTTOM", 0, -2)    
                else
                    button:SetPoint("TOP", partyBots.Frame, "BOTTOM", 0, -2)
                end
        
                lastButton = button
            end
        end
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
            
            --button:EnableMouse(true)
            button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            button:SetScript("OnClick", function()
                if arg1 == "LeftButton" then
                    -- Set Focus marker
                    SendChatMessage(".partybot focusmark " .. button.marker, "SAY")
                else
                    -- Set CC marker    
                    SendChatMessage(".partybot ccmark " .. button.marker, "SAY")
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

            -- Check for pause all messages
            local pattern = "all party bots paused"
            if string.find(string.lower(message), string.lower(pattern)) then
                -- all bots were paused
                for botName, _ in pairs(partyBots.Bots) do
                    partyBots.LastPausedTime[botName] = GetTime()
                end
                partyBots:updatePauseAllButton()
                return
            end

            pattern = "all party bots unpaused"
            if string.find(string.lower(message), string.lower(pattern)) then
                -- all bots were unpaused
                partyBots.LastPausedTime = {}
                partyBots:updatePauseAllButton()
                return
            end

            -- Check for stay all messages
            pattern = "all party bots will stay in position"
            if string.find(string.lower(message), string.lower(pattern)) then
                -- all bots will stay
                for botName, _ in pairs(partyBots.Bots) do
                    partyBots.Bots[botName].staying = true
                end
                partyBots:updateStayAllButton()
                return
            end

            pattern = "all party bots are free to move"
            if string.find(string.lower(message), string.lower(pattern)) then
                -- all bots are free to move
                for botName, _ in pairs(partyBots.Bots) do
                    partyBots.Bots[botName].staying = false
                end
                partyBots:updateStayAllButton()
                return
            end
            
            for botName, _ in pairs(partyBots.Bots) do
                -- Check for pause messages
                pattern = botName .. " paused"
                if string.find(string.lower(message), string.lower(pattern)) then
                    -- bot was paused
                    partyBots.LastPausedTime[botName] = GetTime()
                    return
                else
                    pattern = botName .. " unpaused"
                    if string.find(string.lower(message), string.lower(pattern)) then
                        -- bot was unpaused
                        partyBots.LastPausedTime[botName] = nil
                        return
                    end
                end

                -- Check for stay messages
                pattern = botName .. " will stay in position"
                if string.find(string.lower(message), string.lower(pattern)) then
                    -- bot will stay in position
                    partyBots.Bots[botName].staying = true
                    return
                else
                    pattern = botName .. " is free to move"
                    if string.find(string.lower(message), string.lower(pattern)) then
                        -- bot is free to move
                        partyBots.Bots[botName].staying = false
                        return
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
        targetOpFrame.callback = nil
        targetOpFrame:SetScript("OnUpdate", function()
            targetOpFrame.elapsed = targetOpFrame.elapsed + arg1
            if targetOpFrame.elapsed >= 0.15 then
                if targetOpFrame.targetToRestore then
                    TargetByName(targetOpFrame.targetToRestore, true)
                elseif targetOpFrame.shouldClear then
                    ClearTarget()
                end
                targetOpFrame:Hide()
            end
        end)
        targetOpFrame:SetScript("OnHide", function()
            targetOpFrame.elapsed = 0
            targetOpFrame.targetToRestore = nil
            targetOpFrame.shouldClear = false
            if targetOpFrame.callback ~= nil then
                targetOpFrame.callback()
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

    function partyBots.checkStaying(self, playerName)
        if self and not playerName then playerName = self end
        if not playerName then return false end
        return partyBots.Bots[playerName].staying
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
        
        -- Calculate required width based on number of bots
        local frameSize = 35 -- 30px frame + 5px spacing
        local framesPerRow = 5
        local numBots = table.getn(botNames)
        local minWidth = 115
        local maxWidth = framesPerRow * frameSize + 10 -- 10px padding
        local requiredWidth = math.max(minWidth, math.min(maxWidth, math.min(numBots, framesPerRow) * frameSize + 10))
        
        -- Update frame width if needed
        if self.Frame:GetWidth() ~= requiredWidth then
            self.Frame:SetWidth(requiredWidth - 5)
        end
        
        -- Grid View Layout
        local xOffset, yOffset = 5, -5
        local currentRow, currentCol = 0, 0
        
        for i = 1, numBots do
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
            
            -- Function to update tooltip
            local function updateTooltip()
                GameTooltip:Hide()
                GameTooltip:SetOwner(botFrame, "ANCHOR_RIGHT")
                GameTooltip:ClearLines()
                GameTooltip:AddLine(lv.Util.ColorTextByClass(name, class), 1, 1, 1)
                if partyBots.checkPaused(name) then
                    GameTooltip:AddLine("Paused", 1, 0, 0)
                else
                    GameTooltip:AddLine("Active", 0, 1, 0)
                end
                if partyBots.checkStaying(name) then
                    GameTooltip:AddLine("Staying", 1, 0, 0)
                end
                GameTooltip:Show()
            end
            
            -- Add tooltip
            botFrame:SetScript("OnEnter", updateTooltip)
            botFrame:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            
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
                        -- Shift + Right click: Stay/Unstay
                        TargetByName(name, true)
                        if partyBots.checkStaying(name) then    
                            SendChatMessage(".partybot unstay", "SAY")
                        else
                            SendChatMessage(".partybot stay", "SAY")
                        end
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

                -- Update tooltip if it's showing
                lv.Util.SetTimeout(0.25, function()
                    if GameTooltip:IsOwned(botFrame) then updateTooltip() end
                end)
                

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


    function partyBots.PauseAllBots()
        if partyBots.AllPaused then
            SendChatMessage(".partybot unpause all", "SAY")
        else
            SendChatMessage(".partybot pause all", "SAY")
        end

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
            SendChatMessage(".partybot pause all", "SAY")

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

    -- Function to clear all registered bots
    partyBots.ClearAllBots = function(self)
        for botName, _ in pairs(self.Bots) do
            self:UnregisterBot(botName)
        end
        LavenderPrint("Cleared all registered bots")
    end

    -- Check if all bots are paused
    partyBots.toggleAllPaused = function()
        if partyBots.AllPaused then
            return false
        else
            return true
        end
    end

    -- Update pause all button text
    partyBots.updatePauseAllButton = function()
        if not partyBots.pauseAllButton then return end
        if partyBots.AllPaused then
            partyBots.pauseAllButton:SetText("Pause All")
            partyBots.AllPaused = false
        else
            partyBots.pauseAllButton:SetText("Unpause All")
            partyBots.AllPaused = true
        end
    end

    -- Update stay all button text
    partyBots.updateStayAllButton = function()
        if not partyBots.stayAllButton then return end
        if partyBots.AllStaying then
            partyBots.stayAllButton:SetText("Unstay All")
            partyBots.AllStaying = false
        else
            partyBots.stayAllButton:SetText("Stay All")
            partyBots.AllStaying = true
        end
    end

    function partyBots.StayAllBots()
        if partyBots.AllStaying then
            SendChatMessage(".partybot unstay all", "SAY")
        else
            SendChatMessage(".partybot stay all", "SAY")
        end
    end

    -- Initialize module
    partyBots.Frame = initDaddyFrame()
    partyBots.currentView = "grid"
    partyBots.registerSlashCommands()
    partyBots.MarkerMenu = CreateMarkerMenu()
    initEventHandlers()
    initActions()
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
        partyBots.partyEventFrame:UnregisterAllEvents()
        
        -- Clean up target operation frame
        if partyBots.targetOpFrame then
            partyBots.targetOpFrame:Hide()
            partyBots.targetOpFrame:UnregisterAllEvents()
            partyBots.targetOpFrame:SetScript("OnUpdate", nil)
            partyBots.targetOpFrame = nil
        end
        
        -- Remove slash commands
        lv.Commands.Remove("pb")
        
        -- Hide frames
        if partyBots.Frame then
            partyBots.Frame:Hide()
        end

        LavenderOptions["module_PartyBots_enabled"] = false

        LavenderPrint("Lavender Vibes: PartyBots module unloaded.")
    end)
end

-- Hook to register the module
LavenderVibes.Hooks.add_action("modules_available", function() tinsert(LavenderVibes.Modules, "PartyBots") end)


-- Hook to initialize the module
LavenderVibes.Hooks.add_action("load_module_PartyBots", lvPartyBots)