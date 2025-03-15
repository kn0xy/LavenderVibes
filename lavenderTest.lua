-- Table to hold settings
MyAddonSettings = {
    CheckboxValue = false,
    SliderValue = 50,
}

-- Function to open the settings window
function MyAddon_OpenSettings()
    --LavenderSettingsFrameCheckbox:SetChecked(MyAddonSettings.CheckboxValue)
    --LavenderSettingsFrameSlider:SetValue(MyAddonSettings.SliderValue)
    LavenderSettingsFrame:Show()
end

-- Function to save the settings
function MyAddon_SaveSettings()
    --MyAddonSettings.CheckboxValue = MyAddonSettingsFrameCheckbox:GetChecked()
    --MyAddonSettings.SliderValue = MyAddonSettingsFrameSlider:GetValue()
    print("Settings saved!")
end

-- Slash command to open the settings window
SLASH_MYADDON1 = "/myaddon"
SlashCmdList["MYADDON"] = MyAddon_OpenSettings
LavenderSettingsFrame:Show()