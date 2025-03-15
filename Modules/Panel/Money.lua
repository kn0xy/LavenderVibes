
local function lvPanel_Money(panel)

    local lavMoney = {}

    -- Get all options related to this widget
	lavMoney.getOptions = function()
		if(LavenderOptions._MoneyDisplay == nil) then LavenderOptions._MoneyDisplay = "self" end
		
		local _options = {
			display = LavenderOptions._MoneyDisplay
		}
		
		lavMoney.options = _options	
		return _options
	end

    -- Save current player money to cache
    lavMoney.SaveMoney = function()
        if(LavenderOptions.module_Inventory_enabled) then 
            local playerName = UnitName("player")
            LavenderInventory[playerName]["Money"] = GetMoney()
        end    
    end

    -- Convert an amount in copper to a readable string
    lavMoney.ReadableMoney = function(money)
        local gold, silver, copper = lavMoney.ParseMoney(money)
        local readable = gold .. "g "
        readable = readable .. "|cffe7e7e7" .. silver .. "s|r "
        readable = readable .. "|cffbb792e" .. copper .. "c|r"
        return readable
    end

    -- Break down an amount in copper to 3 variables: gold, silver, copper
    lavMoney.ParseMoney = function(money)
        local gold = math.floor(money / 10000)
        local silver = math.floor(math.mod(money, 10000) / 100)
        local copper = math.mod(money, 100)
        return gold, silver, copper
    end


    -- Get the amount to use for the widget display
    lavMoney.GetMoney = function()
        if(lavMoney.options.display == "self") then
            return GetMoney()
        else
            -- get money for all saved characters
            local total = 0
            local allMoney = lavMoney:GetAllMoney()
            for i,v in ipairs(allMoney) do
                total = total + v.amount
            end
            return total
        end
    end


    -- Get cached money for all toons
    lavMoney.GetAllMoney = function()
        local all = {}
        lavMoney:SaveMoney()
        for k,v in pairs(LavenderInventory) do
            if(v.Money ~= nil) then
                local name = LavenderVibes.Util.ColorTextByClass(k, v.Class)
                local cMoney = {
                    ["name"] = name,
                    ["amount"] = v.Money
                }
                tinsert(all, cMoney)
            end
        end
        return all
    end

    -- Update the widget output
	lavMoney.update = function()
        local money = lavMoney.GetMoney()
        local g,s,c = lavMoney.ParseMoney(money)
        lavMoney.Gold:SetText(tostring(g))
        lavMoney.Silver:SetText(tostring(s))
        lavMoney.Copper:SetText(tostring(c))
        lavMoney.SaveMoney()
	end

    -- Initialize the context menu
	lavMoney.initContextMenu = function()
		local opt = {}

		-- Menu Title
		opt = {
			text = "Show money from",
			notClickable = true,
			notCheckable = true,
			isTitle = true
		}
		UIDropDownMenu_AddButton(opt);

        -- Option: [All]
		opt = {
			text = "All",
			textR = 0.9, textG = 0.9, textB = 0.9,
			value = "all",
			func = function()
				UIDropDownMenu_SetSelectedValue(lavMoney.contextFrame, "all", false)
				LavenderOptions._MoneyDisplay = "all"
                lavMoney.options.display = "all"
				lavMoney.update()
			end
		}
		UIDropDownMenu_AddButton(opt);
		
		-- Option: [Only Me]
		opt = {
			text = "Only Me",
			textR = 0.9, textG = 0.9, textB = 0.9,
			value = "self",
			func = function() 
				UIDropDownMenu_SetSelectedValue(lavMoney.contextFrame, "self", false)
				LavenderOptions._MoneyDisplay = "self"
                lavMoney.options.display = "self"
				lavMoney.update()
			end
		}
		UIDropDownMenu_AddButton(opt);
		
		-- Set selected value for display option (toggle)
		UIDropDownMenu_SetSelectedValue(lavMoney.contextFrame, LavenderOptions._MoneyDisplay, false)
			
		-- Spacer
		opt = {notClickable = true, notCheckable = true}
		UIDropDownMenu_AddButton(opt);
		
		-- Title: Options
		opt.isTitle = true;
		opt.text = "Options";
		UIDropDownMenu_AddButton(opt);
		
		-- Option: Manage List
		opt = {
			text = "Manage List",
			textR = 0.9, textG = 0.9, textB = 0.9,
            notCheckable = true,
			func = function()
				LavenderPrint("open window to remove unwanted data")
			end
		}
		UIDropDownMenu_AddButton(opt);
	end

    -- Initialize money widget frame
    lavMoney.init = function()
        if not (lavMoney.frame == nil) then return end

        local options = lavMoney:getOptions()

        -- Create a frame to display the money info
		local moneyFrame = CreateFrame("Button", "LavenderMoneyFrame", panel)
		moneyFrame:SetWidth(100)
		moneyFrame:SetHeight(14)
		moneyFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 100, 0)
		moneyFrame:RegisterEvent("PLAYER_MONEY");
		moneyFrame:SetScript("OnEvent", lavMoney.update)

        -- Add gold icon
		local goldTexture = moneyFrame:CreateTexture("LavenderMoneyGoldIcon", "ARTWORK")
		goldTexture:SetTexture("Interface\\MoneyFrame\\UI-MoneyIcons")
		goldTexture:SetWidth(14)
		goldTexture:SetHeight(14)
		goldTexture:SetPoint("TOPLEFT", moneyFrame, "TOPLEFT")
        goldTexture:SetTexCoord(0, 0.25, 0, 1)

        -- Add gold label
        local goldLabel = moneyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		goldLabel:SetPoint("LEFT", moneyFrame, "LEFT", 14, -0.5)
		goldLabel:SetTextColor(1, 1, 1, 1)
		goldLabel:SetFont("Fonts\\FRIZQT__.TTF", 10.17)--#bricksquad
		lavMoney.Gold = goldLabel
		
        -- Add silver icon
		local silverTexture = moneyFrame:CreateTexture("LavenderMoneySilverIcon", "ARTWORK")
		silverTexture:SetTexture("Interface\\MoneyFrame\\UI-MoneyIcons")
		silverTexture:SetWidth(14)
		silverTexture:SetHeight(14)
		silverTexture:SetPoint("LEFT", goldLabel, "RIGHT", 5, 0.5)
        silverTexture:SetTexCoord(0.25, 0.5, 0, 1)

        -- Add silver label
        local silverLabel = moneyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		silverLabel:SetPoint("LEFT", silverTexture, "RIGHT", 0, 0)
		silverLabel:SetTextColor(1, 1, 1, 1)
		silverLabel:SetFont("Fonts\\FRIZQT__.TTF", 10.17)--#bricksquad
		lavMoney.Silver = silverLabel

        -- Add copper icon
		local copperTexture = moneyFrame:CreateTexture("LavenderMoneyCopperIcon", "ARTWORK")
		copperTexture:SetTexture("Interface\\MoneyFrame\\UI-MoneyIcons")
		copperTexture:SetWidth(14)
		copperTexture:SetHeight(14)
		copperTexture:SetPoint("LEFT", silverLabel, "RIGHT", 5, 0)
        copperTexture:SetTexCoord(0.5, 0.75, 0, 1)

        -- Add copper label
        local copperLabel = moneyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		copperLabel:SetPoint("LEFT", copperTexture, "RIGHT", 0, 0)
		copperLabel:SetTextColor(1, 1, 1, 1)
		copperLabel:SetFont("Fonts\\FRIZQT__.TTF", 10.17)--#bricksquad
		lavMoney.Copper = copperLabel
		
		-- Define tooltip functionality
		moneyFrame:SetScript("OnEnter", function()
			local r, g, b = LavenderVibes.Util:LavRGB()
			GameTooltip:SetOwner(moneyFrame, "ANCHOR_NONE")
			GameTooltip:SetPoint("TOPLEFT", moneyFrame, "BOTTOMLEFT", 10, -5)
			GameTooltip:AddLine("Money", r, g, b)
			GameTooltip:AddLine("Right-click for options", 0.9, 0.9, 0.9)

            if(lavMoney.options.display == "all") then
                GameTooltip:AddLine(" ")
                for i,v in ipairs(lavMoney:GetAllMoney()) do
                    local rm = lavMoney.ReadableMoney(v.amount)
                    GameTooltip:AddDoubleLine(v.name, rm)
                end

            end
			GameTooltip:Show()
		end)
		moneyFrame:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)
			
		-- Create a context menu
		local contextFrame = CreateFrame("Frame", "LavenderMoneyRightClickContextMenu", UIParent, "UIDropDownMenuTemplate")
		lavMoney.contextFrame = contextFrame
		UIDropDownMenu_Initialize(contextFrame, lavMoney.initContextMenu, "MENU");
		
		-- Define click handlers
		moneyFrame:RegisterForClicks("RightButtonDown", "LeftButtonUp")
		moneyFrame:EnableMouse(true)
		moneyFrame:SetScript("OnClick", function()
			if(arg1 == "LeftButton") then
				-- left click
				ToggleDropDownMenu(1, nil, contextFrame, moneyFrame, 0, -1);
			else
				-- right click
				ToggleDropDownMenu(1, nil, contextFrame, moneyFrame, 0, -1);
			end
			GameTooltip:Hide()
		end)
		
		-- Publicize reference to frame
		lavMoney.frame = moneyFrame
		
		-- Show the output
		lavMoney.update()
    end

    -- Define alias functions 
	lavMoney.Hide = function() lavMoney.frame:Hide() end
	lavMoney.Show = function() lavMoney.frame:Show() end

    -- Vamanos
	lavMoney:init()
	return lavMoney
end

LavenderVibes.Hooks.add_action("panel_initialized", function()
	LavenderVibes.Modules.Panel.Widgets:Add(
		"Money", 
		"Show the total money of each character on your account",
		lvPanel_Money
	)
end)