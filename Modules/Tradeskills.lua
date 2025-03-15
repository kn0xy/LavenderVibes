-- Recipe Tracking Module
local lv = LavenderVibes
local playerName = UnitName("player")

-- Initialize module options
if not LavenderOptions.Tradeskills then
	LavenderOptions.Tradeskills = {}
end
if not LavenderInventory then
	LavenderInventory = {}
end
if not LavenderInventory[playerName] then
	LavenderInventory[playerName] = {}
end
if not LavenderInventory[playerName].Recipes then
	LavenderInventory[playerName].Recipes = {}
end



-- Initialize main frame status bar
local function initStatusBar(frame)
	local statusBar = CreateFrame("StatusBar", nil, frame)
	statusBar:SetWidth(268)
	statusBar:SetHeight(15)
	statusBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 73, -37)
	statusBar:SetMinMaxValues(0, 1)
	statusBar:SetValue(0)

	-- bar texture
	local tsBar = statusBar:CreateTexture(nil, "ARTWORK")
	statusBar:SetStatusBarTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar")
	statusBar:SetStatusBarColor(0.25, 0.25, 0.75)

	-- bar border
	local tsBorder = CreateFrame("Button", nil, statusBar)
	tsBorder:SetWidth(281)
	tsBorder:SetHeight(32)
	tsBorder:SetPoint("LEFT", statusBar, "LEFT", -5, 0)
	tsBorder:SetNormalTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-BarBorder")

	-- skill name
	statusBar.Skill = statusBar:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	statusBar.Skill:SetPoint("LEFT", statusBar, "LEFT", 6, 1)

	-- skill rank
	statusBar.Rank = statusBar:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	statusBar.Rank:SetWidth(128)
	statusBar.Rank:SetHeight(15)
	statusBar.Rank:SetPoint("LEFT", statusBar.Skill, "RIGHT", 13, 0)
	statusBar.Rank:SetJustifyH("LEFT")
	--statusBar.Rank:SetText("Rank")

	return statusBar
end


-- Aggregate data for main frame dropdowns
local function getDropdownsData()
	local professions = {}
	local characters = {}

	local function isUnique(val)
		for _, v in ipairs(professions) do
			if val == v then
				return false
			end
		end
		return true
	end

	for name,toon in pairs(LavenderInventory) do
		local tName = lv.Util.ColorTextByClass(name, toon.Class)
		if(LavenderInventory[name].Recipes ~= nil) then tinsert(characters, tName) end
		if toon.Recipes ~= nil then
			for prof,info in pairs(toon.Recipes) do
				if isUnique(prof) then
					tinsert(professions, prof)
				end
			end
		end
	end

	return professions, characters
end


-- Initialize main frame dropdowns
local function initDropdowns(frame)
	local professions, characters = getDropdownsData()
	local ts = lv.Modules.Tradeskills

	-- Professions
	local profsDropdown = CreateFrame("Frame", "LavenderTradeskillsProfsDropdown", frame, "UIDropDownMenuTemplate")
	profsDropdown:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -25, -66)
	for _,prof in ipairs(professions) do ts.Filter.Profs[prof] = true end
	UIDropDownMenu_Initialize(profsDropdown, function()
		-- create menu item for each unique profession
		for p,prof in ipairs(professions) do
			if(ts.Filter.Profs[prof] == true) then
				local found = false
				local item = {
					text = prof,
					func = function()
						local tv = this.value
						UIDropDownMenu_SetSelectedValue(profsDropdown, tv)
						
						-- failsafe for filter (set toon name when profession is selected and the currently selected toon doesnt have the selected profession)
						local tw = ts:GetToonsWith(tv)
						local tdv = lv.Util.StripColor(UIDropDownMenu_GetSelectedValue(ts.Frame.ToonsMenu))
						if tdv ~= nil then
							for i,toon in ipairs(tw) do
								if toon == tdv then found = true end
							end
							if not found then
								local theClass = LavenderInventory[tw[1]].Class
								local theText = lv.Util.ColorTextByClass(tw[1], theClass)
								UIDropDownMenu_SetText(theText, ts.Frame.ToonsMenu)
								UIDropDownMenu_SetSelectedValue(ts.Frame.ToonsMenu, theText)
							end
						end

						ts.FilterRecipes()
					end
				};
				if item then UIDropDownMenu_AddButton(item) end
			end
		end
	end);
	UIDropDownMenu_SetWidth(120, profsDropdown);
	UIDropDownMenu_SetText("Profession", profsDropdown)
	ts.Professions = professions

	-- Characters
	local toonsDropdown = CreateFrame("Frame", "LavenderTradeskillsToonsDropdown", frame, "UIDropDownMenuTemplate")
	toonsDropdown:SetPoint("RIGHT", profsDropdown, "LEFT", 35, 0)
	UIDropDownMenu_Initialize(toonsDropdown, function()
		-- create menu item for each toon
		for t,toon in ipairs(characters) do
			local item = {
				text = toon,
				func = function()
					local tv = this.value
					local gpf = lv.Util:StripColor(tv)
					ts.Filter.Profs = ts:GetProfessionsFor(gpf)
					UIDropDownMenu_SetSelectedValue(toonsDropdown, tv)
					
					-- set profession dropdown to first available for the selected toon
					local pVal = UIDropDownMenu_GetSelectedValue(profsDropdown)
					if(ts.Filter.Profs[pVal] == nil) then
						local iProfs = {}
						for prof,_ in pairs(ts.Filter.Profs) do tinsert(iProfs, prof) end
						UIDropDownMenu_SetSelectedValue(profsDropdown, iProfs[1])
						UIDropDownMenu_SetText(iProfs[1], profsDropdown)
					end

					ts.FilterRecipes()
				end
			}
			
			if item then UIDropDownMenu_AddButton(item) end
		end
	end);
	UIDropDownMenu_SetWidth(120, toonsDropdown);
	UIDropDownMenu_SetText("Character", toonsDropdown)

	return profsDropdown, toonsDropdown
end


-- Initialize main frame recipes list
local function initRecipesList(frame, ts)
	local color = ts.SkillColor["trivial"]

	local hlFrame = CreateFrame("Frame", nil, frame)
	hlFrame:SetWidth(293)
	hlFrame:SetHeight(16)
	hlFrame:Hide()
	hlFrame.texture = hlFrame:CreateTexture(nil, "ARTWORK")
	hlFrame.texture:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight2")
	hlFrame.texture:SetWidth(293)
	hlFrame.texture:SetHeight(16)
	hlFrame.texture:SetPoint("TOPLEFT", hlFrame, "TOPLEFT", 0, 0)
	hlFrame.texture:SetVertexColor(color.r, color.g, color.b)
	frame.Highlight = hlFrame

	local buttons = {}
	for i = 1,8 do
		local btn = CreateFrame("Button", nil, frame, "ClassTrainerSkillButtonTemplate")
		btn.Index = tostring(i)
		btn:SetNormalTexture("")
		btn:SetHighlightTexture("")
		btn:SetWidth(293)
		btn:SetHeight(16)
		btn:GetFontString():SetPoint("TOPLEFT", btn, "TOPLEFT", 22, 0)
		btn:SetText("Skill " .. tostring(i))
		btn:SetTextColor(color.r, color.g, color.b)
		btn:SetScript("OnEnter", nil)
		btn:SetScript("OnLeave", nil)
		btn:SetScript("OnClick", function()
			--LavenderPrint("Clicked skill " .. btn.Index)
			local txt = btn:GetText()
			local io = string.find(txt, " %[")
			if io then txt = string.sub(txt, 0, io) end
			hlFrame:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 1)
			local colr = btn.Colr
			hlFrame.texture:SetVertexColor(colr.r, colr.g, colr.b)
			btn:LockHighlight()
			ts.SelectedSkill = txt
			ts.SelectedIndex = btn:GetID()
			ts.SelectedItemId = btn.ItemID
			ts:UpdateRecipesList()
			ts:UpdateDetails()
		end)
		if(i < 2) then
			btn:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -98)
			hlFrame:SetPoint("TOPLEFT", btn, "TOPLEFT", -2, 1)
		else
			btn:SetPoint("TOPLEFT", buttons[i-1], "BOTTOMLEFT", 0, 0)
		end
		buttons[i] = btn
	end

	frame.Skills = buttons	
end


-- Initialize main frame details section
local function initDetailsSection(frame)
	local details = CreateFrame("ScrollFrame", "LavenderVibesTradeskillsDetails", frame, "ClassTrainerDetailScrollFrameTemplate")
	details:SetWidth(297)
	details:SetHeight(176)
	details:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -234)

	local ds = CreateFrame("Frame", "LavenderVibesTradeskillsDetailsScroll", details)
	ds:SetWidth(297)
	ds:SetHeight(150)
	ds:SetPoint("TOPLEFT", details, "TOPLEFT", 0, 0)

	ds.SkillName = ds:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
	ds.SkillName:SetWidth(244)
	ds.SkillName:SetHeight(16)
	ds.SkillName:SetPoint("TOPLEFT", ds, "TOPLEFT", 50, -5)
	ds.SkillName:SetJustifyH("LEFT")
	ds.SkillName:SetText("Skill Name")

	ds.ReqLabel = ds:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	ds.ReqLabel:SetPoint("TOPLEFT", ds.SkillName, "BOTTOMLEFT", 0, 0)
	ds.ReqLabel:SetJustifyH("LEFT")
	ds.ReqLabel:SetText("Requires:")

	ds.ReqText = ds:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
	ds.ReqText:SetWidth(180)
	ds.ReqText:SetJustifyH("LEFT")
	ds.ReqText:SetPoint("TOPLEFT", ds.ReqLabel, "TOPRIGHT", 4, 0)
	ds.ReqText:SetText("Tim")

	ds.HeaderLeft = ds:CreateTexture(nil, "BACKGROUND")
	ds.HeaderLeft:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-DetailHeaderLeft")
	ds.HeaderLeft:SetWidth(256)
	ds.HeaderLeft:SetHeight(64)
	ds.HeaderLeft:SetPoint("TOPLEFT", ds, "TOPLEFT", -1, 3)

	ds.HeaderRight = ds:CreateTexture(nil, "BACKGROUND")
	ds.HeaderRight:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-DetailHeaderRight")
	ds.HeaderRight:SetWidth(64)
	ds.HeaderRight:SetHeight(64)
	ds.HeaderRight:SetPoint("TOPLEFT", ds.HeaderLeft, "TOPRIGHT", 0, 0)

	ds.SkillIcon = CreateFrame("Button", nil, ds)
	ds.SkillIcon:SetWidth(37)
	ds.SkillIcon:SetHeight(37)
	ds.SkillIcon:SetPoint("TOPLEFT", ds, "TOPLEFT", 6, -2)
	ds.SkillIcon.texture = ds.SkillIcon:CreateTexture(nil, "ARTWORK")
	ds.SkillIcon.texture:SetWidth(39)
	ds.SkillIcon.texture:SetHeight(39)
	ds.SkillIcon.texture:SetPoint("TOPLEFT", ds.SkillIcon, "TOPLEFT", 0, 0)

	ds.SkillIcon.Count = ds.SkillIcon:CreateFontString(nil, "ARTWORK", "NumberFontNormal")
	ds.SkillIcon.Count:SetJustifyH("RIGHT")
	ds.SkillIcon.Count:SetPoint("BOTTOMRIGHT", ds.SkillIcon, "BOTTOMRIGHT", -5, 2)

	ds.ReagentLabel = ds:CreateFontString(nil, "BACKGROUND", "GameFontNormalSmall")
	ds.ReagentLabel:SetPoint("TOPLEFT", ds, "TOPLEFT", 8, -47)
	ds.ReagentLabel:SetText("Reagents:")
	
	ds.Reagent1 = CreateFrame("Button", "LavenderVibesTradeskillsReagent1", ds, "QuestItemTemplate")
	ds.Reagent1:SetPoint("TOPLEFT", ds.ReagentLabel, "BOTTOMLEFT", -5, -6)

	ds.Reagent2 = CreateFrame("Button", "LavenderVibesTradeskillsReagent2", ds, "QuestItemTemplate")
	ds.Reagent2:SetPoint("LEFT", ds.Reagent1, "RIGHT", 0, 0)

	ds.Reagent3 = CreateFrame("Button", "LavenderVibesTradeskillsReagent3", ds, "QuestItemTemplate")
	ds.Reagent3:SetPoint("TOPLEFT", ds.Reagent1, "BOTTOMLEFT", 0, -2)

	ds.Reagent4 = CreateFrame("Button", "LavenderVibesTradeskillsReagent4", ds, "QuestItemTemplate")
	ds.Reagent4:SetPoint("LEFT", ds.Reagent3, "RIGHT", 0, 0)

	ds.Reagent5 = CreateFrame("Button", "LavenderVibesTradeskillsReagent5", ds, "QuestItemTemplate")
	ds.Reagent5:SetPoint("TOPLEFT", ds.Reagent3, "BOTTOMLEFT", 0, -2)

	ds.Reagent6 = CreateFrame("Button", "LavenderVibesTradeskillsReagent6", ds, "QuestItemTemplate")
	ds.Reagent6:SetPoint("LEFT", ds.Reagent5, "RIGHT", 0, 0)

	ds.Reagent7 = CreateFrame("Button", "LavenderVibesTradeskillsReagent7", ds, "QuestItemTemplate")
	ds.Reagent7:SetPoint("TOPLEFT", ds.Reagent5, "BOTTOMLEFT", 0, -2)

	ds.Reagent8 = CreateFrame("Button", "LavenderVibesTradeskillsReagent8", ds, "QuestItemTemplate")
	ds.Reagent8:SetPoint("LEFT", ds.Reagent7, "RIGHT", 0, 0)

	details.Reagents = {}
	for i=1,8 do
		local reagent = ds["Reagent" .. tostring(i)]
		reagent:SetID(i)
		reagent.hasItem = 1
		reagent:SetScript("OnEnter", function()
			GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT", -3, 0);
			GameTooltip:SetHyperlink(reagent.ItemLink)
		end)
		reagent:SetScript("OnLeave", function()
			GameTooltip:Hide();
		end)
		reagent:SetScript("OnClick", function()
			LavenderPrint("clicked " .. reagent:GetID())
		end)
		reagent:Show()
		tinsert(details.Reagents, reagent)
	end

	details.Scroll = ds
	details:SetScrollChild(ds)
	return details
end


-- Initialize main frame bottom buttons
local function initBottomButtons(frame, ts)
	-- far left
	frame.Btn1 = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.Btn1:SetWidth(80)
	frame.Btn1:SetHeight(22)
	frame.Btn1:SetPoint("CENTER", frame, "TOPLEFT", 58, -421)
	frame.Btn1:SetText("Reset")
	frame.Btn1:SetScript("OnClick", function() ts:ResetFrame() end)
	frame.Btn1:Disable()

	-- inner left
	frame.Btn2 = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.Btn2:SetWidth(80)
	frame.Btn2:SetHeight(22)
	frame.Btn2:SetPoint("CENTER", frame, "TOPLEFT", 140, -421)
	frame.Btn2:SetText("Search")
	frame.Btn2:Disable()

	-- inner right
	frame.Btn3 = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.Btn3:SetWidth(80)
	frame.Btn3:SetHeight(22)
	frame.Btn3:SetPoint("CENTER", frame, "TOPLEFT", 222, -421)
	frame.Btn3:SetText("Watson")
	frame.Btn3:Disable()

	-- far right
	frame.Btn4 = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.Btn4:SetWidth(80)
	frame.Btn4:SetHeight(22)
	frame.Btn4:SetPoint("CENTER", frame, "TOPLEFT", 303, -421)
	frame.Btn4:SetText("Exit")
	frame.Btn4:SetScript("OnClick", function() frame:Hide() end)
end


-- Initialize main frame borders
local function initFrameBorders(frame)
	-- top left border
	local topLeft = frame:CreateTexture(nil, "BORDER")
	topLeft:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-TopLeft")
	topLeft:SetWidth(256)
	topLeft:SetHeight(256)
	topLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)

	-- top right border
	local topRight = frame:CreateTexture(nil, "BORDER")
	topRight:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-TopRight")
	topRight:SetWidth(128)
	topRight:SetHeight(256)
	topRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)

	-- bottom left border
	local bottomLeft = frame:CreateTexture(nil, "BORDER")
	bottomLeft:SetTexture("Interface\\TradeSkillFrame\\UI-TradeSkill-BotLeft")
	bottomLeft:SetWidth(256)
	bottomLeft:SetHeight(256)
	bottomLeft:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)

	-- bottom right border
	local bottomRight = frame:CreateTexture(nil, "BORDER")
	bottomRight:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-BotRight")
	bottomRight:SetWidth(128)
	bottomRight:SetHeight(256)
	bottomRight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)

	-- skill border left
	local tsBorderLeft = frame:CreateTexture(nil, "ARTWORK")
	tsBorderLeft:SetTexture("Interface\\TradeSkillFrame\\UI-TradeSkill-SkillBorder")
	tsBorderLeft:SetWidth(256)
	tsBorderLeft:SetHeight(8)
	tsBorderLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", 63, -50)
	tsBorderLeft:SetTexCoord(0, 1.0, 0, 0.25)

	-- skill border right
	local tsBorderRight = frame:CreateTexture(nil, "ARTWORK")
	tsBorderRight:SetTexture("Interface\\TradeSkillFrame\\UI-TradeSkill-SkillBorder")
	tsBorderRight:SetWidth(28)
	tsBorderRight:SetHeight(8)
	tsBorderRight:SetPoint("LEFT", tsBorderLeft, "RIGHT", 0, 0)
	tsBorderRight:SetTexCoord(0, 0.109375, 0.25, 0.5)

	-- skill bar left
	local tsBarLeft = frame:CreateTexture(nil, "ARTWORK")
	tsBarLeft:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar")
	tsBarLeft:SetWidth(256)
	tsBarLeft:SetHeight(16)
	tsBarLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -221)
	tsBarLeft:SetTexCoord(0, 1.0, 0, 0.25)

	-- skill bar right
	local tsBarRight = frame:CreateTexture(nil, "ARTWORK")
	tsBarRight:SetTexture("Interface\\ClassTrainerFrame\\UI-ClassTrainer-HorizontalBar")
	tsBarRight:SetWidth(75)
	tsBarRight:SetHeight(16)
	tsBarRight:SetPoint("LEFT", tsBarLeft, "RIGHT", 0, 0)
	tsBarRight:SetTexCoord(0, 0.29296875, 0.25, 0.5)
end

-- Initialize the main Tradeskills frame
local function initFrame(ts)
	-- parent frame
	local frame = CreateFrame("Frame", "LavenderTradeskillsFrame", UIParent)
	frame:SetPoint("TOP", UIParent, "TOP", 0, -104)
	frame:SetWidth(384)
	frame:SetHeight(512)
	frame:SetToplevel(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	initFrameBorders(frame)
	
	-- portrait frame
	frame.Portrait = frame:CreateTexture(nil, "BACKGROUND")
	frame.Portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", 7, -6)
	frame.Portrait:SetWidth(60)
	frame.Portrait:SetHeight(60)
	frame.Portrait:SetTexture("Interface\\AddOns\\LavenderVibes\\Textures\\lvicon_128_old")

	-- title bar text
	frame.Title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.Title:SetPoint("TOP", frame, "TOP", 0, -17)
	frame.Title:SetText("Lavender Vibes")

	-- close button
	local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -29, -8)

	-- skill status bar
	frame.StatusBar = initStatusBar(frame)

	-- dropdown menus (professions, characters)
	lv.Hooks.add_action("tradeskills_initialized", function()
		frame.ProfsMenu, frame.ToonsMenu = initDropdowns(frame)
	end)

	-- recipes scroll frame
	frame.Recipes = CreateFrame("ScrollFrame", "LavenderVibesTradeskillsRecipesScrollFrame", frame, "ClassTrainerListScrollFrameTemplate")
	frame.Recipes:SetWidth(296)
	frame.Recipes:SetHeight(130)
	frame.Recipes:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -67, -96)
	frame.Recipes:SetScript("OnVerticalScroll", function()
		local ts = LavenderVibes.Modules.Tradeskills
		FauxScrollFrame_OnVerticalScroll(16, ts.UpdateRecipesList);
	end)
	
	-- recipes list buttons
	initRecipesList(frame, ts)

	-- details section
	frame.Details = initDetailsSection(frame)
	frame.Details.Scroll:Hide()

	-- bottom buttons
	initBottomButtons(frame, ts)

	-- close frame when escape key pressed
	tinsert(UISpecialFrames, "LavenderTradeskillsFrame")

	-- handle frame shown
	frame:SetScript("OnShow", function()
		frame:Show()
		PlaySound("igCharacterInfoOpen");
	end)

	-- handle frame hidden
	frame:SetScript("OnHide", function() 
		PlaySound("igCharacterInfoClose");
	end)

	-- handle frame drag to move
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function() frame:StartMoving() end)
	frame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
	
	-- hide frame until called
	frame:Hide()
	return frame
end


-- Get all reagents required for the specified recipe
local function GetRecipeReagents(recipeId)
	local reagentInfo = {}
	local numReagents = GetTradeSkillNumReagents(recipeId);
	for i=1,numReagents do
		local rName, rTexture, rCount = GetTradeSkillReagentInfo(recipeId, i);
		local rLink = GetTradeSkillReagentItemLink(recipeId, i)
		tinsert(reagentInfo, {
			Link = rLink,
			Count = rCount
		});
	end
	
	return reagentInfo
end


-- Filter out all duplicate reagents
local function GetUniqueReagents(recipes)
	local unique = {}
	
	local function isUnique(val)
		for _, v in ipairs(unique) do
			if val == v then
				return false
			end
		end
		return true
	end

	for _, recipe in ipairs(recipes) do
		local reagents = recipe.Reagents
		for r,reagent in ipairs(reagents) do
			if isUnique(reagent.Name) then
				tinsert(unique, reagent.Link)
			end
		end
	end
	
	return unique
end


-- Get all known recipes for the currently opened tradeskill
local function GetKnownRecipes(frame)
    if not frame or not frame:IsShown() then
        LavenderPrint("Please open a profession window first.")
        return
    end

    local numSkills = GetNumTradeSkills()
	local profession, current, max = GetTradeSkillLine()
    local knownRecipes = {}

    for i = 1, numSkills do
        local skillName, skillType = GetTradeSkillInfo(i)

        if skillType ~= "header" then -- Exclude category headers
            local itemLink = GetTradeSkillItemLink(i)
			local reagents = GetRecipeReagents(i)
			local tools = GetTradeSkillTools(i)
			local recipe = {
				ItemLink = itemLink,
				ColrCode = skillType,
				Reagents = reagents
			}
			if tools then recipe.Tools = tools end
            tinsert(knownRecipes, recipe)
        end
    end

    if table.getn(knownRecipes) > 0 then
		if not LavenderInventory[playerName].Recipes then
			LavenderInventory[playerName].Recipes = {}
		end
		LavenderInventory[playerName].Recipes[profession] = {
			["List"] = knownRecipes,
			["CLvl"] = current,
			["MLvl"] = max,
			["Time"] = time()
		}
    else
        LavenderPrint("LavenderTradeskills: No known recipes found.")
    end
	
end


-- List all known recipes in the specified chat channel
local function ListCachedRecipes(channel)
	local profs = LavenderInventory[playerName].Recipes
	if not profs then
		LavenderPrint("No known recipes on this character.", "Death Knight")
		return
	end
	for key,prof in pairs(profs) do
		lv.Throttle.Add(key, channel)
		for _,recipe in ipairs(prof) do
			local str = recipe.ItemLink .. " - "
			local tr = table.getn(recipe.Reagents)
			for r,reagent in ipairs(recipe.Reagents) do
				str = str .. "(" .. tostring(reagent.Count) .. ") " .. reagent.Link
				if(r < tr) then str = str .. ", " end
			end
			lv.Throttle.Add(str, channel)
		end
		lv.Throttle.Add(" ----- ", channel)
	end
end


-- Initialize recipe tracking frame
local function initRecipeTrackingFrame()
	local recipeFrame = CreateFrame("Frame")
	recipeFrame:RegisterEvent("TRADE_SKILL_SHOW")
	recipeFrame:SetScript("OnEvent", function()
		GetKnownRecipes(recipeFrame)
	end)
	return recipeFrame
end



local function lvTradeskills()
	local ts = {}

	ts.RecipeTracking = initRecipeTrackingFrame()

	ts.SkillColor = {}
	ts.SkillColor["optimal"] = { r = 1.00, g = 0.50, b = 0.25 }
	ts.SkillColor["medium"]	= { r = 1.00, g = 1.00, b = 0.00 }
	ts.SkillColor["easy"] = { r = 0.25, g = 0.75, b = 0.25 }
	ts.SkillColor["trivial"] = { r = 0.50, g = 0.50, b = 0.50 }
	ts.SkillColor["header"]	= { r = 1.00, g = 0.82, b = 0 }
	
	ts.Filter = {
		Toons = {},
		Profs = {}
	}

	ts.Frame = initFrame(ts)
	
	ts.Listed = {}
	ts.NumListed = 0

	ts.SelectedIndex = 0
	ts.SelectedItemId = 0
	ts.SelectedSkill = ""


	-- Update the recipes list buttons based on scroll position
	ts.UpdateRecipesList = function()
		local hl = ts.Frame.Highlight
		hl:Hide()

		local recs = ts.Frame.Recipes
		local numSkills = ts.NumListed
		local skillOffset = FauxScrollFrame_GetOffset(recs);
		FauxScrollFrame_Update(recs, numSkills, 8, 16, nil, nil, nil, hl, 293, 316)
		for i=1, 8, 1 do
			local skillIndex = i + skillOffset;
			local skillButton = ts.Frame.Skills[i]
			
			if(skillIndex <= numSkills) then
				local skill = ts.Listed[skillIndex]
				local itemId, skillName = ts:ParseItemLink(skill.ItemLink)

				-- set button widths based on whether scrollbar is shown/hidden
				if recs:IsVisible() then
					skillButton:SetWidth(293);
				else
					skillButton:SetWidth(323);
				end

				-- set row and text color
				local color = ts.SkillColor[skill.ColrCode]
				if color then 
					skillButton:SetTextColor(color.r, color.g, color.b)
					skillButton.Colr = color
				end

				-- set highlight
				if(ts.SelectedIndex == "" or skillIndex ~= ts.SelectedIndex) then
					skillButton:UnlockHighlight()
				else
					skillButton:LockHighlight()
					hl:SetPoint("TOPLEFT", skillButton, "TOPLEFT", 0, 0)
					hl.texture:SetVertexColor(color.r, color.g, color.b)
					hl:Show()
				end

				-- set the IDs and show this bitch
				skillButton.ItemID = itemId;
				skillButton:SetID(skillIndex);
				skillButton:Show();

				-- determine how many can be made
				if(LavenderOptions.module_Inventory_enabled == true) then
					local qty = skill.CanMake or 0
					if(qty > 0) then
						skillName = skillName .. " [" .. qty .. "]"
					end
				end
				skillButton:SetText(skillName)

				skillButton:Show()
			else
				skillButton:Hide()
			end
		end
	end


	-- Determine how many of the specified item can be made
	-- *** This function will fail if the Inventory module is not enabled
	ts.GetNumCanMake = function(self, itemId)
		if self and not itemId then itemId = self end

		local canMake = 9999

		local reagents = ts:GetReagentsForItem(itemId)
		for r,reagent in ipairs(reagents) do
			local itemId = ts:ParseItemLink(reagent.Link)
			local iHave = lv.Modules.Inventory:GetAllQuantityFor(itemId)
			local rCanMake = floor(iHave / reagent.Count)
			if(rCanMake < canMake) then canMake = rCanMake end
		end
		
		if(canMake ~= 9999) then return canMake end
		return 0
	end


	-- Get item data for the specified itemId
	ts.GetItemData = function(self, itemId)
		if self and not itemId then itemId = self end
		if itemId then
			local sName, sLink, iRarity, iLevel, iMinLevel, sType, iStack, idk, sTexture = GetItemInfo(itemId);
			-- LavenderPrint("name = " .. sName)
			-- LavenderPrint("type = " .. sType)
			-- LavenderPrint("stack = " .. iStack)
			-- LavenderPrint("? = " .. idk)
			-- LavenderPrint("tex = " .. sTexture)
			return {
				["Name"]    = sName,
				["Link"]    = sLink,
				["Quality"] = iRarity,
				["Type"]    = sType,
				["Stack"]   = iStack,
				["Texture"] = sTexture
			}
		end
		return false
	end


	-- Determine how many of each recipe can be made
	ts.UpdateRecipesCanMake = function()
		for t,skill in ipairs(ts.Listed) do
			local itemId = ts:ParseItemLink(skill.ItemLink)
			ts.Listed[t].CanMake = ts:GetNumCanMake(itemId)
		end
	end


	-- Update the details section when a skill is selected
	ts.UpdateDetails = function()
		local ds = ts.Frame.Details.Scroll
		
		-- set the skill name
		ds.SkillName:SetText(" " .. ts.SelectedSkill);
		ds.SkillName:Show()

		-- fix wonky positioning
		ds.SkillName:SetPoint("TOPLEFT", ds, "TOPLEFT", 47, -5)
		ds.ReqLabel:SetPoint("TOPLEFT", ds.SkillName, "BOTTOMLEFT", 3, 0)

		-- get the item data
		local data = ts:GetItemData(ts.SelectedItemId);

		-- set the skill icon
		ds.SkillIcon.texture:SetTexture(data.Texture)
		ds.SkillIcon.texture:Show()
		ds.SkillIcon:SetScript("OnEnter", function()
			GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT", -3, 0);
			GameTooltip:SetHyperlink(data.Link)
		end)
		ds.SkillIcon:SetScript("OnLeave", function()
			GameTooltip:Hide();
		end)
		ds.SkillIcon:Show()

		-- reagents
		local reagents = ts:GetReagentsForSelected()
		local numReagents = table.getn(reagents)
		for i,r in ipairs(reagents) do
			local elem = ds["Reagent" .. tostring(i)]
			local elemName = getglobal("LavenderVibesTradeskillsReagent" .. i .. "Name")
			local elemCount = getglobal("LavenderVibesTradeskillsReagent" .. i .. "Count")

			-- set icon
			SetItemButtonTexture(elem, r.Texture)

			-- set name text
			elemName:SetText(r.Name)

			-- set count (num required) text
			if(LavenderOptions.module_Inventory_enabled == true) then
				local itemId = ts:ParseItemLink(r.ItemLink)
				local qty = lv.Modules.Inventory:GetAllQuantityFor(itemId)
				elemCount:SetText(tostring(qty) .. " /" ..tostring(r.Count));
				if(qty == 0) then
					-- gray out the item
					SetItemButtonTextureVertexColor(elem, 0.5, 0.5, 0.5);
					elemName:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
				else
					-- dont gray out the item
					SetItemButtonTextureVertexColor(elem, 1, 1, 1);
					elemName:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
				end
			else
				elemCount:SetText(tostring(r.Count));
			end
			
			-- set itemid for mouseover
			elem.ItemLink = r.ItemLink

			elem:Show()
		end

		for i=numReagents+1, 8 do
			local elem = ds["Reagent" .. tostring(i)]
			elem:Hide()
		end

		ts.Frame.Details.Scroll:Show()
		ts.Frame.Details:UpdateScrollChildRect()
	end


	-- Get required reagents for the specified itemId
	ts.GetReagentsForItem = function(self, itemId)
		local toon = lv.Util:StripColor(UIDropDownMenu_GetSelectedValue(ts.Frame.ToonsMenu))
		local prof = UIDropDownMenu_GetSelectedValue(ts.Frame.ProfsMenu)
		local data = LavenderInventory[toon].Recipes[prof].List
		for i,d in ipairs(data) do
			local did = ts:ParseItemLink(d.ItemLink)
			if(did == itemId) then
				return d.Reagents
			end
		end
		return false
	end


	-- Get required reagents for the currently selected skill
	ts.GetReagentsForSelected = function()
		local toon = lv.Util:StripColor(UIDropDownMenu_GetSelectedValue(ts.Frame.ToonsMenu))
		local prof = UIDropDownMenu_GetSelectedValue(ts.Frame.ProfsMenu)
		local data = LavenderInventory[toon].Recipes[prof].List[ts.SelectedIndex]
		local reagents = {}
		for i,r in ipairs(data.Reagents) do
			local itemId, itemName = ts:ParseItemLink(r.Link)
			local itemData = ts:GetItemData(itemId)
			local reagent = {
				["Count"]    = r.Count,
				["ItemLink"] = itemData.Link,
				["Name"]     = itemName,
				["Texture"]  = itemData.Texture
			}
			tinsert(reagents, reagent)
		end
		return reagents
	end


	-- Update status bar
	ts.UpdateStatusBar = function()
		local bar = ts.Frame.StatusBar
		local toon = lv.Util.StripColor(UIDropDownMenu_GetSelectedValue(ts.Frame.ToonsMenu))
		local prof = UIDropDownMenu_GetSelectedValue(ts.Frame.ProfsMenu)
		local td = LavenderInventory[toon].Recipes[prof]
		local cl = td.CLvl
		local ml = td.MLvl

		bar.Skill:SetText(prof)
		bar.Rank:SetText(tostring(cl) .. "/" .. tostring(ml))
		bar:SetMinMaxValues(0, ml)
		bar:SetValue(cl)
	end


	-- Reset to factory defaults
	ts.ResetFrame = function()
		-- internal vars
		ts.Listed = {}
		ts.NumListed = 0
		ts.SelectedSkill = ""
		ts.SelectedItemId = 0
		ts.Filter.Toons = {}
		ts.Filter.Profs = {}
		for _,prof in ipairs(ts.Professions) do ts.Filter.Profs[prof] = true end

		-- status bar
		local bar = ts.Frame.StatusBar
		bar:SetMinMaxValues(0, 1)
		bar:SetValue(0)
		bar.Skill:SetText("")
		bar.Rank:SetText("")

		-- dropdowns
		local tm = ts.Frame.ToonsMenu
		local pm = ts.Frame.ProfsMenu
		UIDropDownMenu_SetSelectedValue(tm, nil)
		UIDropDownMenu_SetSelectedValue(pm, nil)
		UIDropDownMenu_SetText("Character", tm)
		UIDropDownMenu_SetText("Profession", pm)

		-- recipes list (skill buttons)
		ts.UpdateRecipesList()
		for b,btn in ipairs(ts.Frame.Skills) do
			btn:Hide()
		end
		
		-- details section
		ts.Frame.Details.Scroll:Hide()

		-- bottom buttons
		ts.Frame.Btn1:Disable()
	end


	-- Parse an item link to extract the name and item ID
	ts.ParseItemLink = function(self, itemLink)
		if self and not itemLink then itemLink = self end
		if not itemLink then
			LavenderPrint("Item link is nil.")
			return nil
		end
		
		local itemId, skillName

		-- Find the starting position of the item ID
		local startIdx = string.find(itemLink, "item:")
		if startIdx then
			-- Find the next ':' after "item:"
			local endIdx = string.find(itemLink, ":", startIdx + 5) 
			if endIdx then
				-- Extract the item ID
				itemId = tonumber(string.sub(itemLink, startIdx + 5, endIdx - 1))
			else
				LavenderPrint("Item link format is incorrect for item: " .. itemLink)
			end
		end

		-- Find the starting position of the item name
		local nameSidx = string.find(itemLink, "|h%[")
		if nameSidx then
			nameSidx = nameSidx + 3
			-- Find the next ']' after the opening '['
			local nameEidx = string.find(itemLink, "%]", nameSidx)
			if nameEidx then
				-- Extract the item name
				skillName = string.sub(itemLink, nameSidx, nameEidx - 1) 
			else
				LavenderPrint("Item link format is incorrect for item: " .. itemLink)
			end
		end
		
		return itemId, skillName
	end


	-- Get a table of all cached recipes data
	ts.GetData = function()
		local data = {}
		for name,toon in pairs(LavenderInventory) do
			if toon.Recipes ~= nil then
				data[name] = toon.Recipes
			end
		end
		return data
	end


	-- Get all toons with the specified profession
	ts.GetToonsWith = function(self, prof)
		if self and not prof then prof = self end
		local toons = {}
		local data = ts.GetData()
		for name,profs in pairs(data) do
			for _prof,pData in pairs(profs) do
				if(_prof == prof) then
					tinsert(toons, name)
				end
			end
		end
		return toons
	end


	-- Get professions known by the specified character
	ts.GetProfessionsFor = function(self, toon)
		if self and not toon then toon = self end
		local professions = {}
		local data = ts.GetData()
		for name,profs in pairs(data) do
			if(name == toon) then
				for prof,info in pairs(profs) do
					professions[prof] = true
				end
			end
		end
		return professions
	end


	-- Filter displayed recipes based on selected filters
	ts.FilterRecipes = function()
		local toon = UIDropDownMenu_GetSelectedValue(ts.Frame.ToonsMenu)
		local prof = UIDropDownMenu_GetSelectedValue(ts.Frame.ProfsMenu)
		if toon ~= nil then
			-- toon was set
			if(prof ~= nil) then
				-- LETS GO!!!
				local key = lv.Util.StripColor(toon)
				local sb = getglobal("LavenderVibesTradeskillsRecipesScrollFrameScrollBar")
				FauxScrollFrame_SetOffset(ts.Frame.Recipes, 0);
				sb:SetMinMaxValues(0, 0); 
				sb:SetValue(0);
				ts.Listed = LavenderInventory[key].Recipes[prof].List
				ts.NumListed = table.getn(ts.Listed)
				ts:UpdateRecipesList()
				ts:UpdateStatusBar()
				ts.Frame.Btn1:Enable()
				ts.Frame.Highlight:Hide()
				if(LavenderOptions.module_Inventory_enabled == true) then
					ts:UpdateRecipesCanMake()
				end
				ts.Frame.Details.Scroll:Hide()
				return
			else
				LavenderPrint("toon = " .. toon .. ", prof = nil")
				return
			end
		else
			-- no toon was set
			if prof ~= nil then 
				-- pick the toon with the highest skill in selected profession
				local toons = ts:GetToonsWith(prof)
				local theToon = toons[1]
				local ttClass = LavenderInventory[theToon].Class
				local setVal = lv.Util.ColorTextByClass(theToon, ttClass)
				UIDropDownMenu_SetSelectedValue(ts.Frame.ToonsMenu, setVal)
				UIDropDownMenu_SetText(setVal, ts.Frame.ToonsMenu)
				ts.FilterRecipes()
				return
			end
		end
	end
	

	-- Display additional subcommands
	ts.DisplaySubcommands = function()
		local ctbc = LavenderVibes.Util.ColorTextByClass
		local function helpCommand(cmd, desc)
			LavenderPrint("*  " .. ctbc("/lv ts "..cmd, "Mage") .. " - " .. desc)
		end
		LavenderPrint("")
		LavenderPrint("Lavender Vibes Tradeskills Subcommands:")

		-- reset
		helpCommand("reset", "Clear selected filters and reset the Tradeskills frame.")

		-- share
		local strShare = "List the current player's known recipes in the specified "
		strShare = strShare .. ctbc("channel", "Hunter") .. ". Valid channels are "
		strShare = strShare .. ctbc("say", "Hunter") .. ", " .. ctbc("party", "Hunter") .. ", " .. ctbc("guild", "Hunter") .. ", "
		strShare = strShare .. ctbc("yell", "Hunter") .. ", and " .. ctbc("raid", "Hunter") .. "."
		helpCommand("share " .. ctbc("{channel}", "Hunter"), strShare)
		LavenderPrint("")


	end
	

	-- Handle slash commands
	ts.HandleSlashCommands = function(args)
		if(args == "") then
			if(ts.Frame:IsShown()) then
				ts:Hide()
			else
				ts:Show()
			end
			
		else
			local params = LavenderVibes.Util.Split(args)
			
			-- display additional commands
			if(params[1] == "?") then
				ts:DisplaySubcommands()
				return
			end

			-- reset main frame
			if(params[1] == "reset") then
				ts:ResetFrame()
				return
			end
			
			-- share / output to chat
			if(params[1] == "share") then
				if not params[2] then
					LavenderPrint("Missing channel.", "Death Knight")
				else
					local channel = params[2]
					ListCachedRecipes(channel)
				end
			end

		end
	end


	-- Top level function to show the main frame
	ts.Show = function()
		lv.Hooks.do_action("hide_all")
		ts.Frame:Show()
	end


	-- Top level function to hide the main frame
	ts.Hide = function()
		ts.Frame:Hide()
	end

	
	-- Register slash commands
	lv.Commands.Add("ts", ts.HandleSlashCommands, "Show/hide the Tradeskills window.", true)
	
	-- Hook to hide the window
	lv.Hooks.add_action("hide_all", function() ts.Frame:Hide() end)
	
	-- Hook to unload the module
	lv.Hooks.add_action("unload_module_Tradeskills", function()
		-- * remove slash commands

		-- * remove hooks

		-- hide frames
		ts.Frame:Hide()
	end)


	LavenderVibes.Modules.Tradeskills = ts
	lv.Hooks.do_action("tradeskills_initialized")
end




-- Hook to register the module
lv.Hooks.add_action("modules_available", function() tinsert(LavenderVibes.Modules, "Tradeskills") end)


-- Hook to initialize the module
lv.Hooks.add_action("load_module_Tradeskills", lvTradeskills)

