-- Global function to print message to default chat window
function LavenderPrint(message, class)
	--local mensaje = "|cff8974be" .. message .. "|r"
	local mensaje = "|cffa190cb" .. message .. "|r"
	if class ~= nil then
		mensaje = LavenderVibes.Util.ColorTextByClass(message, class)
	end
	DEFAULT_CHAT_FRAME:AddMessage(mensaje)
end




local util = {}

-- Utility: Lavender RGB values (#a190cb)
util.LavRGB = function()
	local r = 161/255
	local g = 144/255
	local b = 203/255
	return r, g, b
end


-- Utility: Color text by class
util.ColorTextByClass = function(txt, class)
	local classColor;
	if(class == "Death Knight") then
		classColor = "|cffc41e3a";
	elseif(class == "Demon Hunter") then
		classColor = "|cffa330c9";
	elseif(class == "Druid") then
		classColor = "|cffff7c0a";
	elseif(class == "Hunter") then
		classColor = "|cffaad372";
	elseif(class == "Mage") then
		classColor = "|cff3fc7eb";
	elseif(class == "Monk") then
		classColor = "|cff00ff98";
	elseif(class == "Paladin") then
		classColor = "|cfff48cba";
	elseif(class == "Priest") then
		classColor = "|cffffffff";
	elseif(class == "Rogue") then
		classColor = "|cfffff468";
	elseif(class == "Shaman") then
		classColor = "|cff0070dd";
	elseif(class == "Warlock") then
		classColor = "|cff8788ee";
	elseif(class == "Warrior") then
		classColor = "|cffc69b6d";
	end
	return classColor .. txt .. "|r";
end


-- Utility: Strip color from text
util.StripColor = function(self, txt)
	if self and not txt then txt = self end
	if txt then
		if(string.sub(txt, 0, 4) == "|cff") then
			local stop = string.find(txt, "|r", 11)
			if stop then stop = stop - 1 end
			txt = string.sub(txt, 11, stop)
		end
	end
	return txt
end


-- Utility: Get class color as RGB values
util.RgbClassColor = function(class)
	local classColors = {
        ["Death Knight"] = {196, 30, 58},   -- #c41e3a
        ["Demon Hunter"] = {163, 48, 201},  -- #a330c9
        ["Druid"] = {255, 124, 10},         -- #ff7c0a
        ["Hunter"] = {170, 211, 114},       -- #aad372
        ["Mage"] = {63, 199, 235},          -- #3fc7eb
        ["Monk"] = {0, 255, 152},           -- #00ff98
        ["Paladin"] = {244, 140, 186},      -- #f48cba
        ["Priest"] = {255, 255, 255},       -- #ffffff
        ["Rogue"] = {255, 244, 104},        -- #fff468
        ["Shaman"] = {0, 112, 221},         -- #0070dd
        ["Warlock"] = {135, 136, 238},      -- #8788ee
        ["Warrior"] = {198, 155, 109},      -- #c69b6d
    }
	
	if classColors[class] then
		local cc = classColors[class]
		local r = cc[1] / 255
		local g = cc[2] / 255
		local b = cc[3] / 255
		return r, g, b
	end
	
	return false
end


-- Utility: Get item quality color as RGB values
util.RgbQualityColor = function(quality)
	local colors = {
		["Shit"] = {157, 157, 157},
		["Common"] = {255, 255, 255},
		["Uncommon"] = {30, 255, 0},
		["Rare"] = {0, 112, 221},
		["Epic"] = {163, 53, 238},
		["Legendary"] = {255, 128, 0}
	}
	
	if colors[quality] then
		local qc = colors[quality]
		local r = qc[1] / 255
		local g = qc[2] / 255
		local b = qc[3] / 255
		return r, g, b
	end
	
	return false
end


-- Utility: Print table to chat frame
util.PrintTable = function(tbl, indent)
    indent = indent or 0
    local prefix = string.rep("  ", indent)  -- Indentation for nested tables
    for key, value in pairs(tbl) do
        if type(value) == "table" then
            -- Print a message for the nested table
            DEFAULT_CHAT_FRAME:AddMessage(prefix .. tostring(key) .. ": {")
            util.PrintTable(value, indent + 1)  -- Recursive call for nested tables
            DEFAULT_CHAT_FRAME:AddMessage(prefix .. "}")
        else
            -- Print simple key-value pairs
            DEFAULT_CHAT_FRAME:AddMessage(prefix .. tostring(key) .. ": " .. tostring(value))
        end
    end
end


-- Utility: Split a string by spaces
util.Split = function(str)
    local words = {}
    local currentWord = ""
    local i = 1
    while true do
		-- get each char from the string
        local char = string.sub(str, i, i)  
        if char == "" then
			-- reached end of string
            break
        end
		
		-- separate words by spaces
        if char == " " then  
            if currentWord ~= "" then
                table.insert(words, currentWord)
                currentWord = ""
            end
        else
			-- build the current word
            currentWord = currentWord .. char  
        end
		
        i = i + 1
    end

    -- insert the last word if any
    if currentWord ~= "" then
        table.insert(words, currentWord)
    end

    return words
end


-- Utility: SetTimeout
local sleepFrame = CreateFrame("Frame")
sleepFrame:Hide()
util.SetTimeout = function(secs, callback)
	local elapsed = 0
    sleepFrame:SetScript("OnUpdate", function()
        elapsed = elapsed + arg1
        if elapsed >= secs then
            sleepFrame:Hide()
            sleepFrame:SetScript("OnUpdate", nil)
            if callback then callback() end
        end
    end)
    sleepFrame:Show()
end

-- Utility: Hide all Lavender Vibes windows
util.HideAll = function()
	LavenderVibes.Hooks.do_action("hide_all")
end



LavenderVibes.Util = util


lvpt = util.PrintTable