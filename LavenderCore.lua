-- Define addon version
local lavender_version = "0.3.1"

-- Initialize internal hooks and actions system
local function initHooks()

    -- Table to store all hooks and their associated actions
    local hooks = {}

    -- Function to add an action to a hook
    local function add_action(hook_name, callback, priority)
        -- Check if callback is valid
        if type(callback) ~= "function" then
            error("add_action: callback must be a function")
            return
        end

        -- Create the hook table if it doesn't exist
        if not hooks[hook_name] then
            hooks[hook_name] = {}
        end

        -- Default priority to 10 if not specified
        priority = priority or 10

        -- Insert the callback into the hook's list with priority
        table.insert(hooks[hook_name], { callback = callback, priority = priority })

        -- Sort actions by priority (lower priority numbers run first)
        table.sort(hooks[hook_name], function(a, b)
            return a.priority < b.priority
        end)
    end

    -- Function to trigger all actions for a hook
    local function do_action(hook_name, ...)
		local args = arg
		
        -- Check if the hook has registered actions
        if hooks[hook_name] then
            -- Loop through each action in the hook and execute its callback
            for _, action in ipairs(hooks[hook_name]) do
                action.callback(unpack(args))
            end
        end
    end

    -- Function to remove an action from a hook
    local function remove_action(hook_name, callback)
        if hooks[hook_name] then
            for i, action in ipairs(hooks[hook_name]) do
                if action.callback == callback then
                    table.remove(hooks[hook_name], i)
                    break
                end
            end
        end
    end

    -- Return the hook functions in a table
    local lavenderHooks = {
        ["hooks"] = hooks,
        ["add_action"] = add_action,
        ["do_action"] = do_action,
        ["remove_action"] = remove_action
    }

    return lavenderHooks
end


-- Utility: Check if key exists in table
local function keyExists(tbl, key)
	return tbl[key] ~= nil
end



-- Initialize module slash commands registrar
local function initCommands()
	
	local commands = {
		["commands"] = {},
		["helptext"] = {},
		["has_subs"] = {}
	}
	
	commands.Add = function(cmd, callback, helpTxt, subs)
		commands.commands[cmd] = callback
		commands.helptext[cmd] = helpTxt
		if subs then commands.has_subs[cmd] = true end
	end
	
	commands.onEvent = function(cmd, args)
		if(keyExists(commands.commands, cmd) == true) then
			commands.commands[cmd](args);
			return true
		end
		return false
	end

	return commands
end


-- Initialize message throttling handler
local function initThrottle()
	local function initFrame()
		local frame = CreateFrame("Frame")
		frame:Hide()
		return frame
	end

	local function init_throttle(throttle)
		-- Process the message queue
		throttle.Frame:SetScript("OnUpdate", function()
			local throttleInterval = 0.1
			throttle.TimeSinceLastUpdate = throttle.TimeSinceLastUpdate + arg1
			if throttle.TimeSinceLastUpdate >= throttleInterval then
				throttle.TimeSinceLastUpdate = 0
				local messageData = table.remove(throttle.Queue, 1)
				if not messageData then
					throttle.Count = 0
					throttle.Frame:Hide()
				else
					throttle.Count = throttle.Count - 1
					SendChatMessage(messageData.msg, messageData.type)
				end
					
				-- hide the frame when the queue is empty
				if throttle.Count == 0 then throttle.Frame:Hide() end
			end
		end)

		-- When the frame is shown, reset the update timer
		throttle.Frame:SetScript("OnShow", function()
			throttle.TimeSinceLastUpdate = 0
		end)

		-- Accept incoming messages
		throttle.Add = function(message, channel)
			table.insert(throttle.Queue, {msg = message, type = channel})
			throttle.Count = throttle.Count + 1
			throttle.Frame:Show()
		end

		return throttle
	end

	return init_throttle({
		Frame = initFrame(),
		TimeSinceLastUpdate = 0,
		Count = 0,
		Queue = {}
	});
end


-- Initialize Options
if(LavenderOptions == nil) then
	LavenderOptions = {
		module_MinimapButton_enabled = true
	}
end



-- Initialize global object
LavenderVibes = {
	["MainFrame"] = CreateFrame("Frame"),
	["Hooks"]     = initHooks(),
	["Commands"]  = initCommands(),
	["Throttle"]  = initThrottle(),
	["Config"]    = {},
	["Modules"]   = {},
	["Util"]	  = {},
	["Session"]   = 0,
}



-- Handle slash commands
local function LavenderCommands(msg, editbox)
	local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
	
	-- /lv
	if not cmd then

		LavenderPrint("Lavender Vibes v" .. lavender_version)
		local ctbc = LavenderVibes.Util.ColorTextByClass

		local function helpCommand(cmd, desc)
			LavenderPrint("  " .. ctbc("/lv "..cmd, "Mage") .. " - " .. desc)
		end

		local function helpSubcommand(cmd)
			local str = ""
			local spaces = string.len(cmd) + 9
			local sub = ctbc("/lv "..cmd.." ?", "Druid")
			local suf = ctbc(" for additional commands.", "Rogue")
			local dash = "|cffffffff- |r"
			for i=1,spaces do
				str = str .. " "
			end
			str = str .. dash .. sub .. suf
			LavenderPrint(str, "Priest")
		end

		-- Display help text
		helpCommand("config", "Show the options window.")
		helpCommand("session", "Output the current session elapsed time.")
		for hCmd,hTxt in pairs(LavenderVibes.Commands.helptext) do
			helpCommand(hCmd, hTxt)
			if(keyExists(LavenderVibes.Commands.has_subs, hCmd)) then
				helpSubcommand(hCmd)
			end
		end
	

	-- /lv config
	elseif(cmd == "config") then
		if LavenderVibes.Config:IsShown() then
			LavenderVibes.Config:Hide()
		else
			LavenderVibes.Config:LoadOptions()
		end
	
	
	-- /lv test
	elseif(cmd == "test") then
	
		LavenderTestFrame:Show()
    
	
	-- /lv session
    elseif cmd == "session" then
		
		local sessionTime = LavenderVibes.Util.SecondsToString(LavenderVibes.Session)
		LavenderPrint("Session Time: |r" .. sessionTime)

	else 
		local result = LavenderVibes.Commands.onEvent(cmd, args)
		if not result == true then
			LavenderPrint("Unrecognized command: " .. cmd)
		end
	
	end
end
SLASH_LAVENDER1 = "/lv"
SLASH_LAVENDER2 = "/lavender"
SLASH_LAVENDER3 = "/vibes"
SLASH_LAVENDER4 = "/dreams"
SlashCmdList["LAVENDER"] = LavenderCommands




-- Load all enabled modules
local function loadModules()
	for _, module in ipairs(LavenderVibes.Modules) do
		local enabled = LavenderOptions["module_"..module.."_enabled"]
		if(enabled == true) then
			LavenderVibes.Hooks.do_action("load_module_" .. module)
		end
	end

end
LavenderVibes.Hooks.add_action("core_ready", loadModules)


local function initSession()
	local last_end = LavenderOptions.last_session_end or 0
	local gap = time() - last_end
	if(gap > 600) then
		LavenderOptions.current_session_start = time()
		LavenderPrint("New session started")
	end
	LavenderVibes.Session = time() - LavenderOptions.current_session_start
end


-- Fire once when player UI loads
local function handle_events()

	if(event == "VARIABLES_LOADED") then
		LavenderPrint("Variables loaded")
		lvpt(LavenderOptions)
		
	end

	if(event == "PLAYER_LOGIN") then
		
		-- Get available modules
		LavenderVibes.Hooks.do_action("modules_available")

		-- Initialize the configuration/options window
		LavenderVibes.Config:Init()
		
		-- Initialize session
		initSession()
		
		-- Trigger the loading of enabled modules
		LavenderVibes.Hooks.do_action("core_ready")

	elseif(event == "PLAYER_LOGOUT") then
		LavenderOptions.last_session_end = time()
	end
end


-- Initialize MainFrame
LavenderVibes.MainFrame:RegisterEvent("PLAYER_LOGIN");
LavenderVibes.MainFrame:RegisterEvent("PLAYER_LOGOUT");
LavenderVibes.MainFrame:SetScript("OnEvent", handle_events)
