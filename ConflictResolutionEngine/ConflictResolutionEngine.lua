-- Conflict Resolution Engine (CRE) - A lightweight dice roller addon for World of Warcraft
-- Version: 1.6.0
-- Author: Ridrith

local addonName = "ConflictResolutionEngine"
local CRE = {}

-- Addon communication prefix
local ADDON_PREFIX = "CRE"

-- Color codes for different roll results
local colors = {
    critical = "|cFFFF0000",  -- Red for critical failures/successes
    success = "|cFF00FF00",   -- Green for good rolls
    normal = "|cFFFFFF00",    -- Yellow for normal rolls
    poor = "|cFFFF8000",      -- Orange for poor rolls
    attribute = "|cFF00FFFF", -- Cyan for attribute values
    total = "|cFFFFFFFF",     -- White for totals
    addon = "|cFF9482C9",     -- Purple for addon messages
    dice = "|cFFFFD700",      -- Gold for dice type
    player = "|cFF00BFFF",    -- Deep sky blue for player name
    math = "|cFFFFA500",      -- Orange for math operators
    health = "|cFFFF4444",    -- Red for health
    defense = "|cFF4444FF",   -- Blue for defense
    profile = "|cFFFF69B4",   -- Hot pink for profile messages
    reset = "|r"
}

-- Print function with addon prefix (defined early)
local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage(colors.addon .. "[CRE]" .. colors.reset .. " " .. message)
end

-- Attribute names for display (updated order with new attributes)
local attributeNames = {
    might = "Might",
    finesse = "Finesse", 
    endurance = "Endurance",
    insight = "Insight",
    resolve = "Resolve",
    presence = "Presence",
    faith = "Faith",
    magic = "Magic",
    luck = "Luck"
}

-- Attribute order for UI display
local attributeOrder = {"might", "finesse", "endurance", "insight", "resolve", "presence", "faith", "magic", "luck"}

-- Common dice types
local commonDice = {4, 6, 8, 10, 12, 20, 100}

-- Default profile settings
local defaultProfile = {
    attributes = {
        might = 0,
        finesse = 0,
        endurance = 0,
        insight = 0,
        resolve = 0,
        presence = 0,
        faith = 0,
        magic = 0,
        luck = 0
    },
    character = {
        strikes = 0,
        maxStrikes = 0,
        damageReduction = 0
    }
}

-- Default global settings
local defaultSettings = {
    profiles = {},
    currentProfile = "",
    ui = {
        selectedDice = 20,
        windowPosition = {}
    }
}

-- Get current character profile key
local function GetCurrentProfileKey()
    local name = UnitName("player")
    local realm = GetRealmName()
    return name .. "-" .. realm
end

-- Get current profile data
local function GetCurrentProfile()
    local profileKey = GetCurrentProfileKey()
    if not ConflictResolutionEngineDB.profiles[profileKey] then
        ConflictResolutionEngineDB.profiles[profileKey] = {
            attributes = {},
            character = {}
        }
        -- Copy default values
        for attr, value in pairs(defaultProfile.attributes) do
            ConflictResolutionEngineDB.profiles[profileKey].attributes[attr] = value
        end
        for field, value in pairs(defaultProfile.character) do
            ConflictResolutionEngineDB.profiles[profileKey].character[field] = value
        end
        Print("Created new profile for " .. colors.profile .. UnitName("player") .. colors.reset)
    end
    return ConflictResolutionEngineDB.profiles[profileKey]
end

-- Initialize saved variables with defaults
local function InitializeSavedVariables()
    if not ConflictResolutionEngineDB then
        ConflictResolutionEngineDB = {}
    end
    
    if not ConflictResolutionEngineDB.profiles then
        ConflictResolutionEngineDB.profiles = {}
    end
    
    if not ConflictResolutionEngineDB.ui then
        ConflictResolutionEngineDB.ui = {}
    end
    
    -- Set current profile
    ConflictResolutionEngineDB.currentProfile = GetCurrentProfileKey()
    
    -- Migrate old data if it exists
    if ConflictResolutionEngineDB.attributes or ConflictResolutionEngineDB.character then
        local profileKey = GetCurrentProfileKey()
        if not ConflictResolutionEngineDB.profiles[profileKey] then
            ConflictResolutionEngineDB.profiles[profileKey] = {
                attributes = ConflictResolutionEngineDB.attributes or {},
                character = ConflictResolutionEngineDB.character or {}
            }
            Print("Migrated existing data to profile system for " .. colors.profile .. UnitName("player") .. colors.reset)
        end
        -- Clean up old data
        ConflictResolutionEngineDB.attributes = nil
        ConflictResolutionEngineDB.character = nil
    end
    
    -- Ensure current profile exists and is valid
    local currentProfile = GetCurrentProfile()
    
    -- Ensure all attributes exist
    for attr, defaultValue in pairs(defaultProfile.attributes) do
        if currentProfile.attributes[attr] == nil then
            currentProfile.attributes[attr] = defaultValue
        end
    end
    
    -- Ensure character data exists
    for field, defaultValue in pairs(defaultProfile.character) do
        if currentProfile.character[field] == nil then
            currentProfile.character[field] = defaultValue
        end
    end
    
    -- Ensure UI settings exist
    for setting, defaultValue in pairs(defaultSettings.ui) do
        if ConflictResolutionEngineDB.ui[setting] == nil then
            ConflictResolutionEngineDB.ui[setting] = defaultValue
        end
    end
end

-- Main frame for event handling
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")

-- UI Variables
local mainFrame = nil
local attributeButtons = {}
local diceButtons = {}
local selectedDiceButton = nil
local characterUI = {}
local uiCreated = false

-- Custom random function using WoW's secure random
local function SecureRandom(min, max)
    return math.random(min, max)
end

-- Register addon communication
local function RegisterAddonComms()
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)
    else
        RegisterAddonMessagePrefix(ADDON_PREFIX)
    end
end

-- Send addon message to party
local function SendAddonMessage(message)
    if IsInGroup() then
        if C_ChatInfo and C_ChatInfo.SendAddonMessage then
            C_ChatInfo.SendAddonMessage(ADDON_PREFIX, message, "PARTY")
        else
            SendAddonMessage(ADDON_PREFIX, message, "PARTY")
        end
    end
end

-- Handle incoming addon messages
local function HandleAddonMessage(prefix, message, channel, sender)
    if prefix == ADDON_PREFIX and sender ~= UnitName("player") then
        -- Parse the roll message
        local diceType, roll, attribute, attributeValue, total = string.match(message, "(%d+);(%d+);([^;]*);(%d*);(%d*)")
        
        if diceType and roll then
            local formattedMessage = FormatReceivedRoll(sender, tonumber(diceType), tonumber(roll), attribute, tonumber(attributeValue), tonumber(total))
            Print(formattedMessage)
        end
    end
end

-- Format received roll for display
function FormatReceivedRoll(sender, diceType, roll, attribute, attributeValue, total)
    local message = ""
    
    if attribute and attribute ~= "" and attributeValue and attributeValue > 0 then
        -- Roll with attribute
        message = string.format("%s%s%s rolled %sD%d%s: %s%d%s + %s%s %d%s = %s%d%s",
            colors.player, sender, colors.reset,
            colors.dice, diceType, colors.reset,
            CRE:GetRollColor(roll, diceType), roll, colors.reset,
            colors.attribute, attributeNames[attribute], attributeValue, colors.reset,
            CRE:GetTotalColor(total, diceType + attributeValue), total, colors.reset)
    else
        -- Plain roll
        message = string.format("%s%s%s rolled %sD%d%s: %s%d%s",
            colors.player, sender, colors.reset,
            colors.dice, diceType, colors.reset,
            CRE:GetRollColor(roll, diceType), roll, colors.reset)
    end
    
    return message
end

-- Create styled button with subtle hover effects
local function CreateStyledButton(parent, width, height, text, template)
    local button = CreateFrame("Button", nil, parent, template or "UIPanelButtonTemplate")
    button:SetSize(width, height)
    button:SetText(text)
    button:SetNormalFontObject("GameFontNormal")
    button:SetHighlightFontObject("GameFontNormal")
    button:SetDisabledFontObject("GameFontDisable")
    
    button:SetScript("OnEnter", function(self)
        self:SetAlpha(0.85)
    end)
    button:SetScript("OnLeave", function(self)
        self:SetAlpha(1.0)
    end)
    
    return button
end

-- Create section header
local function CreateSectionHeader(parent, text, yOffset)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOP", parent, "TOP", 0, yOffset)
    header:SetText(text)
    header:SetTextColor(0.8, 0.8, 1, 1)
    
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOP", header, "BOTTOM", 0, -2)
    line:SetSize(parent:GetWidth() - 40, 1)
    line:SetColorTexture(0.5, 0.5, 0.7, 0.8)
    
    return header, line
end

-- Create attribute row (more compact)
local function CreateAttributeRow(parent, attr, displayName, yOffset)
    local rowFrame = CreateFrame("Frame", nil, parent)
    rowFrame:SetSize(370, 28)
    rowFrame:SetPoint("TOP", parent, "TOP", 0, yOffset)
    
    local bg = rowFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(rowFrame)
    bg:SetColorTexture(0.1, 0.1, 0.15, 0.3)
    
    local nameLabel = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("LEFT", rowFrame, "LEFT", 12, 0)
    nameLabel:SetText(displayName)
    nameLabel:SetSize(80, 20)
    nameLabel:SetJustifyH("LEFT")
    nameLabel:SetTextColor(0.9, 0.9, 0.9, 1)
    
    local valueFrame = CreateFrame("Frame", nil, rowFrame)
    valueFrame:SetSize(28, 18)
    valueFrame:SetPoint("LEFT", nameLabel, "RIGHT", 8, 0)
    
    local valueBg = valueFrame:CreateTexture(nil, "BACKGROUND")
    valueBg:SetAllPoints(valueFrame)
    valueBg:SetColorTexture(0.2, 0.2, 0.3, 0.8)
    
    local valueLabel = valueFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    valueLabel:SetPoint("CENTER", valueFrame, "CENTER", 0, 0)
    valueLabel:SetText(GetCurrentProfile().attributes[attr])
    valueLabel:SetTextColor(0, 1, 1, 1)
    
    local decreaseBtn = CreateStyledButton(rowFrame, 24, 18, "–")
    decreaseBtn:SetPoint("LEFT", valueFrame, "RIGHT", 6, 0)
    decreaseBtn:SetScript("OnClick", function()
        local profile = GetCurrentProfile()
        local current = profile.attributes[attr]
        if current > 0 then
            profile.attributes[attr] = current - 1
            valueLabel:SetText(profile.attributes[attr])
        end
    end)
    
    local increaseBtn = CreateStyledButton(rowFrame, 24, 18, "+")
    increaseBtn:SetPoint("LEFT", decreaseBtn, "RIGHT", 2, 0)
    increaseBtn:SetScript("OnClick", function()
        local profile = GetCurrentProfile()
        local current = profile.attributes[attr]
        if current < 10 then
            profile.attributes[attr] = current + 1
            valueLabel:SetText(profile.attributes[attr])
        end
    end)
    
    local rollBtn = CreateStyledButton(rowFrame, 50, 18, "Roll")
    rollBtn:SetPoint("LEFT", increaseBtn, "RIGHT", 12, 0)
    rollBtn:SetScript("OnClick", function()
        CRE:RollDice(ConflictResolutionEngineDB.ui.selectedDice, attr)
    end)
    
    local plainRollBtn = CreateStyledButton(rowFrame, 50, 18, "Plain")
    plainRollBtn:SetPoint("LEFT", rollBtn, "RIGHT", 2, 0)
    plainRollBtn:SetScript("OnClick", function()
        CRE:RollDice(ConflictResolutionEngineDB.ui.selectedDice, nil)
    end)
    
    return {
        frame = rowFrame,
        valueLabel = valueLabel,
        rollBtn = rollBtn,
        plainRollBtn = plainRollBtn
    }
end

-- Create character stats section (updated for Strikes and DR)
local function CreateCharacterStats(parent, yOffset)
    local statsFrame = CreateFrame("Frame", nil, parent)
    statsFrame:SetSize(380, 60)
    statsFrame:SetPoint("TOP", parent, "TOP", 0, yOffset)
    
    local bg = statsFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(statsFrame)
    bg:SetColorTexture(0.08, 0.08, 0.12, 0.6)
    
    local profile = GetCurrentProfile()
    
    -- Strikes section
    local strikesLabel = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    strikesLabel:SetPoint("TOPLEFT", statsFrame, "TOPLEFT", 15, -12)
    strikesLabel:SetText("Strikes:")
    strikesLabel:SetTextColor(1, 0.4, 0.4, 1)
    
    local strikesInput = CreateFrame("EditBox", nil, statsFrame, "InputBoxTemplate")
    strikesInput:SetSize(35, 18)
    strikesInput:SetPoint("LEFT", strikesLabel, "RIGHT", 8, 0)
    strikesInput:SetAutoFocus(false)
    strikesInput:SetText(profile.character.strikes)
    strikesInput:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText()) or 0
        GetCurrentProfile().character.strikes = value
        self:ClearFocus()
    end)
    
    local slashLabel = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    slashLabel:SetPoint("LEFT", strikesInput, "RIGHT", 3, 0)
    slashLabel:SetText("/")
    slashLabel:SetTextColor(0.8, 0.8, 0.8, 1)
    
    local maxStrikesInput = CreateFrame("EditBox", nil, statsFrame, "InputBoxTemplate")
    maxStrikesInput:SetSize(35, 18)
    maxStrikesInput:SetPoint("LEFT", slashLabel, "RIGHT", 3, 0)
    maxStrikesInput:SetAutoFocus(false)
    maxStrikesInput:SetText(profile.character.maxStrikes)
    maxStrikesInput:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText()) or 0
        GetCurrentProfile().character.maxStrikes = value
        self:ClearFocus()
    end)
    
    -- +/- buttons for strikes
    local strikesDecBtn = CreateStyledButton(statsFrame, 20, 18, "-")
    strikesDecBtn:SetPoint("LEFT", maxStrikesInput, "RIGHT", 8, 0)
    strikesDecBtn:SetScript("OnClick", function()
        local profile = GetCurrentProfile()
        local current = profile.character.strikes
        if current > 0 then
            profile.character.strikes = current - 1
            strikesInput:SetText(profile.character.strikes)
        end
    end)
    
    local strikesIncBtn = CreateStyledButton(statsFrame, 20, 18, "+")
    strikesIncBtn:SetPoint("LEFT", strikesDecBtn, "RIGHT", 2, 0)
    strikesIncBtn:SetScript("OnClick", function()
        local profile = GetCurrentProfile()
        profile.character.strikes = profile.character.strikes + 1
        strikesInput:SetText(profile.character.strikes)
    end)
    
    -- DR (Damage Reduction) section
    local drLabel = statsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    drLabel:SetPoint("TOPLEFT", statsFrame, "TOPLEFT", 15, -35)
    drLabel:SetText("DR:")
    drLabel:SetTextColor(0.4, 0.4, 1, 1)
    
    local drInput = CreateFrame("EditBox", nil, statsFrame, "InputBoxTemplate")
    drInput:SetSize(40, 18)
    drInput:SetPoint("LEFT", drLabel, "RIGHT", 8, 0)
    drInput:SetAutoFocus(false)
    drInput:SetText(profile.character.damageReduction)
    drInput:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText()) or 0
        GetCurrentProfile().character.damageReduction = value
        self:ClearFocus()
    end)
    
    -- +1/-1 buttons for DR
    local drDecBtn = CreateStyledButton(statsFrame, 20, 18, "-")
    drDecBtn:SetPoint("LEFT", drInput, "RIGHT", 6, 0)
    drDecBtn:SetScript("OnClick", function()
        local profile = GetCurrentProfile()
        local current = profile.character.damageReduction
        if current > 0 then
            profile.character.damageReduction = current - 1
            drInput:SetText(profile.character.damageReduction)
        end
    end)
    
    local drIncBtn = CreateStyledButton(statsFrame, 20, 18, "+")
    drIncBtn:SetPoint("LEFT", drDecBtn, "RIGHT", 2, 0)
    drIncBtn:SetScript("OnClick", function()
        local profile = GetCurrentProfile()
        profile.character.damageReduction = profile.character.damageReduction + 1
        drInput:SetText(profile.character.damageReduction)
    end)
    
    characterUI.strikesInput = strikesInput
    characterUI.maxStrikesInput = maxStrikesInput
    characterUI.drInput = drInput
    
    return statsFrame
end

-- Create profile info section
local function CreateProfileInfo(parent, yOffset)
    local profileFrame = CreateFrame("Frame", nil, parent)
    profileFrame:SetSize(380, 35)
    profileFrame:SetPoint("TOP", parent, "TOP", 0, yOffset)
    
    local profileBg = profileFrame:CreateTexture(nil, "BACKGROUND")
    profileBg:SetAllPoints(profileFrame)
    profileBg:SetColorTexture(0.15, 0.1, 0.2, 0.8)
    
    local profileLabel = profileFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    profileLabel:SetPoint("CENTER", profileFrame, "CENTER", 0, 5)
    profileLabel:SetText("Character Profile")
    profileLabel:SetTextColor(1, 0.7, 1, 1)
    
    local characterName = profileFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    characterName:SetPoint("CENTER", profileFrame, "CENTER", 0, -8)
    characterName:SetText(colors.profile .. UnitName("player") .. colors.reset)
    
    return profileFrame
end

-- Refresh UI with current profile data
local function RefreshUIWithProfile()
    if not uiCreated then return end
    
    local profile = GetCurrentProfile()
    
    -- Update attribute values
    for attr, button in pairs(attributeButtons) do
        if button and button.valueLabel then
            button.valueLabel:SetText(profile.attributes[attr])
        end
    end
    
    -- Update character stats
    if characterUI.strikesInput then
        characterUI.strikesInput:SetText(profile.character.strikes)
    end
    if characterUI.maxStrikesInput then
        characterUI.maxStrikesInput:SetText(profile.character.maxStrikes)
    end
    if characterUI.drInput then
        characterUI.drInput:SetText(profile.character.damageReduction)
    end
end

-- Create the main UI frame (fixed spacing)
local function CreateMainFrame()
    if mainFrame or uiCreated then 
        Print("UI already created!")
        return 
    end
    
    Print("Creating UI...")
    
    InitializeSavedVariables()
    
    -- Main frame (increased height to prevent clipping)
    mainFrame = CreateFrame("Frame", "CREMainFrame", UIParent, "BasicFrameTemplateWithInset")
    mainFrame:SetSize(420, 660) -- Increased height for profile section
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    mainFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    mainFrame:SetFrameStrata("MEDIUM")
    mainFrame:SetToplevel(true)
    mainFrame:Hide()
    
    -- Enhanced background
    local bg = mainFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 4, -4)
    bg:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -4, 4)
    bg:SetColorTexture(0.05, 0.05, 0.1, 0.95)
    
    -- Title
    mainFrame.title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    mainFrame.title:SetPoint("CENTER", mainFrame.TitleBg, "CENTER", 5, 0)
    mainFrame.title:SetText("Conflict Resolution Engine")
    mainFrame.title:SetTextColor(1, 1, 1, 1)
    
    -- Version info
    local versionLabel = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    versionLabel:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -35, -8)
    versionLabel:SetText("v1.6.0")
    versionLabel:SetTextColor(0.6, 0.6, 0.6, 1)
    
    -- Close button
    if mainFrame.CloseButton then
        mainFrame.CloseButton:SetScript("OnClick", function()
            mainFrame:Hide()
        end)
    end
    
    -- Profile info section
    local profileFrame = CreateProfileInfo(mainFrame, -35)
    
    -- Selected dice display
    local diceDisplayFrame = CreateFrame("Frame", nil, mainFrame)
    diceDisplayFrame:SetSize(380, 35)
    diceDisplayFrame:SetPoint("TOP", profileFrame, "BOTTOM", 0, -5)
    
    local diceBg = diceDisplayFrame:CreateTexture(nil, "BACKGROUND")
    diceBg:SetAllPoints(diceDisplayFrame)
    diceBg:SetColorTexture(0.1, 0.1, 0.2, 0.8)
    
    mainFrame.diceLabel = diceDisplayFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    mainFrame.diceLabel:SetPoint("CENTER", diceDisplayFrame, "CENTER", 0, 0)
    mainFrame.diceLabel:SetText("Selected Dice: D" .. ConflictResolutionEngineDB.ui.selectedDice)
    mainFrame.diceLabel:SetTextColor(1, 0.8, 0, 1)
    
    -- Dice selection section (compact)
    local diceFrame = CreateFrame("Frame", nil, mainFrame)
    diceFrame:SetPoint("TOP", diceDisplayFrame, "BOTTOM", 0, -10)
    diceFrame:SetSize(380, 80)
    
    local diceHeader, diceLine = CreateSectionHeader(diceFrame, "Dice Selection", -5)
    
    -- Dice buttons (compact)
    diceButtons = {}
    local buttonWidth = 42
    local buttonHeight = 25
    local spacing = 3
    local startX = -(((buttonWidth + spacing) * #commonDice - spacing) / 2) + (buttonWidth / 2)
    
    for i, dice in ipairs(commonDice) do
        local button = CreateStyledButton(diceFrame, buttonWidth, buttonHeight, "D" .. dice)
        button:SetPoint("TOP", diceFrame, "TOP", startX + ((buttonWidth + spacing) * (i - 1)), -28)
        button:SetScript("OnClick", function()
            ConflictResolutionEngineDB.ui.selectedDice = dice
            mainFrame.diceLabel:SetText("Selected Dice: D" .. dice)
            UpdateDiceButtonHighlight(button)
            Print("Selected D" .. dice)
        end)
        table.insert(diceButtons, button)
        
        if dice == ConflictResolutionEngineDB.ui.selectedDice then
            selectedDiceButton = button
        end
    end
    
    -- Custom dice input (compact)
    local customDiceFrame = CreateFrame("Frame", nil, mainFrame)
    customDiceFrame:SetPoint("TOP", diceFrame, "BOTTOM", 0, -5)
    customDiceFrame:SetSize(380, 30)
    
    local customBg = customDiceFrame:CreateTexture(nil, "BACKGROUND")
    customBg:SetAllPoints(customDiceFrame)
    customBg:SetColorTexture(0.08, 0.08, 0.12, 0.6)
    
    local customLabel = customDiceFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    customLabel:SetPoint("LEFT", customDiceFrame, "LEFT", 15, 0)
    customLabel:SetText("Custom Dice:")
    customLabel:SetTextColor(0.9, 0.9, 0.9, 1)
    
    local customInput = CreateFrame("EditBox", "CRECustomInput", customDiceFrame, "InputBoxTemplate")
    customInput:SetSize(55, 22)
    customInput:SetPoint("LEFT", customLabel, "RIGHT", 8, 0)
    customInput:SetAutoFocus(false)
    customInput:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText())
        if value and value >= 2 and value <= 100 then
            ConflictResolutionEngineDB.ui.selectedDice = value
            mainFrame.diceLabel:SetText("Selected Dice: D" .. value)
            UpdateDiceButtonHighlight(nil)
            Print("Selected custom D" .. value)
        else
            Print("Invalid dice value. Must be between 2 and 100.")
        end
        self:ClearFocus()
    end)
    
    local customButton = CreateStyledButton(customDiceFrame, 45, 22, "Set")
    customButton:SetPoint("LEFT", customInput, "RIGHT", 4, 0)
    customButton:SetScript("OnClick", function()
        local value = tonumber(customInput:GetText())
        if value and value >= 2 and value <= 100 then
            ConflictResolutionEngineDB.ui.selectedDice = value
            mainFrame.diceLabel:SetText("Selected Dice: D" .. value)
            UpdateDiceButtonHighlight(nil)
            Print("Selected custom D" .. value)
        else
            Print("Invalid dice value. Must be between 2 and 100.")
        end
    end)
    
    -- Character stats section
    local statsFrame = CreateCharacterStats(mainFrame, -245)
    
    -- Attributes section (with proper spacing)
    local attributesFrame = CreateFrame("Frame", nil, mainFrame)
    attributesFrame:SetPoint("TOP", statsFrame, "BOTTOM", 0, -10)
    attributesFrame:SetSize(380, 280)
    
    local attrHeader, attrLine = CreateSectionHeader(attributesFrame, "Attributes", -5)
    
    -- Create attribute rows (with proper spacing)
    local yOffset = -30
    attributeButtons = {}
    
    for i, attr in ipairs(attributeOrder) do
        local displayName = attributeNames[attr]
        local buttons = CreateAttributeRow(attributesFrame, attr, displayName, yOffset)
        attributeButtons[attr] = buttons
        yOffset = yOffset - 30
    end
    
    -- Main roll button (positioned with enough clearance)
    local mainRollBtn = CreateStyledButton(mainFrame, 120, 30, "Roll Selected Dice")
    mainRollBtn:SetPoint("BOTTOM", mainFrame, "BOTTOM", 0, 20)
    mainRollBtn:SetNormalFontObject("GameFontNormalLarge")
    mainRollBtn:SetHighlightFontObject("GameFontNormalLarge")
    mainRollBtn:SetScript("OnClick", function()
        CRE:RollDice(ConflictResolutionEngineDB.ui.selectedDice, nil)
    end)
    
    -- Update initial dice button highlight
    UpdateDiceButtonHighlight(selectedDiceButton)
    
    -- Refresh UI with current profile
    RefreshUIWithProfile()
    
    uiCreated = true
    Print("UI created successfully for " .. colors.profile .. UnitName("player") .. colors.reset)
end

-- Update dice button highlighting
function UpdateDiceButtonHighlight(selectedButton)
    if not diceButtons then return end
    
    for _, button in ipairs(diceButtons) do
        if button == selectedButton then
            button:SetNormalFontObject("GameFontHighlight")
            if not button.border then
                button.border = CreateFrame("Frame", nil, button)
                button.border:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2)
                button.border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
                button.border:SetFrameLevel(button:GetFrameLevel() - 1)
                
                local borderTex = button.border:CreateTexture(nil, "BACKGROUND")
                borderTex:SetAllPoints(button.border)
                borderTex:SetColorTexture(1, 0.8, 0, 0.4)
                
                local inner = CreateFrame("Frame", nil, button.border)
                inner:SetPoint("TOPLEFT", button.border, "TOPLEFT", 1, -1)
                inner:SetPoint("BOTTOMRIGHT", button.border, "BOTTOMRIGHT", -1, 1)
                
                local innerTex = inner:CreateTexture(nil, "ARTWORK")
                innerTex:SetAllPoints(inner)
                innerTex:SetColorTexture(0.05, 0.05, 0.1, 1)
                
                button.borderFrame = button.border
            end
            button.border:Show()
        else
            button:SetNormalFontObject("GameFontNormal")
            if button.border then
                button.border:Hide()
            end
        end
    end
    selectedDiceButton = selectedButton
end

-- Event handler
eventFrame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4, arg5)
    if event == "ADDON_LOADED" and arg1 == addonName then
        Print("Addon loaded, initializing saved variables...")
        InitializeSavedVariables()
        RegisterAddonComms()
        
        -- Register slash commands
        SLASH_CRE1 = "/cre"
        SlashCmdList["CRE"] = function(msg)
            CRE:HandleSlashCommand(msg)
        end
        
        SLASH_CREROLL1 = "/creroll"
        SLASH_CREROLL2 = "/roll"
        SlashCmdList["CREROLL"] = function(msg)
            CRE:HandleRollCommand(msg)
        end
        
    elseif event == "PLAYER_LOGIN" then
        Print("Player login event fired")
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        Print("Player entering world event fired")
        if not uiCreated then
            CreateMainFrame()
        end
        
    elseif event == "CHAT_MSG_ADDON" then
        HandleAddonMessage(arg1, arg2, arg3, arg4)
    end
end)

function CRE:HandleSlashCommand(input)
    local args = {}
    for arg in input:gmatch("%S+") do
        table.insert(args, arg:lower())
    end
    
    if not args[1] or args[1] == "help" then
        self:ShowHelp()
    elseif args[1] == "show" or args[1] == "ui" then
        if not uiCreated then
            Print("Creating UI...")
            CreateMainFrame()
        end
        if mainFrame then
            mainFrame:Show()
            RefreshUIWithProfile()
            Print("UI window shown")
        else
            Print("UI creation failed!")
        end
    elseif args[1] == "hide" then
        if mainFrame then
            mainFrame:Hide()
            Print("UI window hidden")
        end
    elseif args[1] == "debug" then
        Print("Debug info:")
        Print("uiCreated: " .. tostring(uiCreated))
        Print("mainFrame exists: " .. tostring(mainFrame ~= nil))
        Print("ConflictResolutionEngineDB exists: " .. tostring(ConflictResolutionEngineDB ~= nil))
        Print("Current profile: " .. colors.profile .. GetCurrentProfileKey() .. colors.reset)
        if ConflictResolutionEngineDB then
            local profileCount = 0
            for _ in pairs(ConflictResolutionEngineDB.profiles) do
                profileCount = profileCount + 1
            end
            Print("Total profiles: " .. tostring(profileCount))
            if ConflictResolutionEngineDB.ui then
                Print("Selected dice: " .. tostring(ConflictResolutionEngineDB.ui.selectedDice))
            end
            local profile = GetCurrentProfile()
            if profile.character then
                Print("Strikes: " .. tostring(profile.character.strikes) .. "/" .. tostring(profile.character.maxStrikes))
                Print("DR: " .. tostring(profile.character.damageReduction))
            end
        end
        if mainFrame then
            Print("mainFrame visible: " .. tostring(mainFrame:IsVisible()))
        end
    elseif args[1] == "profiles" then
        self:ShowProfiles()
    elseif args[1] == "set" then
        self:SetAttribute(args[2], tonumber(args[3]))
    elseif args[1] == "get" then
        self:GetAttribute(args[2])
    elseif args[1] == "reset" then
        self:ResetAttributes()
    elseif args[1] == "version" then
        Print("Version 1.6.0")
    elseif args[1] == "test" then
        self:TestRoll()
    else
        Print("Unknown command. Use /cre help for available commands.")
    end
end

function CRE:ShowProfiles()
    Print("Available character profiles:")
    for profileKey, profile in pairs(ConflictResolutionEngineDB.profiles) do
        local current = (profileKey == GetCurrentProfileKey()) and " " .. colors.profile .. "(Current)" .. colors.reset or ""
        Print("  " .. colors.player .. profileKey .. colors.reset .. current)
    end
end

function CRE:TestRoll()
    Print("Testing random number generation...")
    for i = 1, 5 do
        local roll = SecureRandom(1, 20)
        Print("Test roll " .. i .. ": " .. roll)
    end
end

function CRE:HandleRollCommand(input)
    local diceType, attribute = self:ParseRollCommand(input)
    if diceType then
        self:RollDice(diceType, attribute)
    else
        Print("Invalid roll command. Use format: /roll d20 might or /roll d6")
    end
end

function CRE:ParseRollCommand(input)
    if not input or input == "" then
        return 20, nil
    end
    
    local parts = {}
    for part in input:gmatch("%S+") do
        table.insert(parts, part:lower())
    end
    
    local diceType = nil
    local attribute = nil
    
    -- Parse dice type
    if parts[1] then
        local diceMatch = parts[1]:match("d(%d+)")
        if diceMatch then
            diceType = tonumber(diceMatch)
            if diceType < 2 or diceType > 100 then
                Print("Dice type must be between D2 and D100.")
                return nil, nil
            end
        else
            diceType = tonumber(parts[1])
            if not diceType or diceType < 2 or diceType > 100 then
                Print("Invalid dice type. Use D2 to D100.")
                return nil, nil
            end
        end
    end
    
    -- Parse attribute
    if parts[2] and GetCurrentProfile().attributes[parts[2]] then
        attribute = parts[2]
    end
    
    return diceType, attribute
end

function CRE:RollDice(diceType, attribute)
    if not IsInGroup() then
        Print("You must be in a party to use the dice roller.")
        return
    end
    
    local diceRoll = SecureRandom(1, diceType)
    local attributeValue = 0
    local total = diceRoll
    
    if attribute then
        attributeValue = GetCurrentProfile().attributes[attribute] or 0
        total = diceRoll + attributeValue
    end
    
    local message = string.format("%d;%d;%s;%d;%d", 
        diceType, 
        diceRoll, 
        attribute or "", 
        attributeValue, 
        total)
    
    SendAddonMessage(message)
    
    local localMessage = self:FormatLocalRoll(diceType, diceRoll, attribute, attributeValue, total)
    Print(localMessage)
end

function CRE:FormatLocalRoll(diceType, diceRoll, attribute, attributeValue, total)
    local message = ""
    
    if attribute and attributeValue > 0 then
        message = string.format("You rolled %sD%d%s: %s%d%s + %s%s %d%s = %s%d%s",
            colors.dice, diceType, colors.reset,
            self:GetRollColor(diceRoll, diceType), diceRoll, colors.reset,
            colors.attribute, attributeNames[attribute], attributeValue, colors.reset,
            self:GetTotalColor(total, diceType + attributeValue), total, colors.reset)
    else
        message = string.format("You rolled %sD%d%s: %s%d%s",
            colors.dice, diceType, colors.reset,
            self:GetRollColor(diceRoll, diceType), diceRoll, colors.reset)
    end
    
    return message
end

function CRE:GetRollColor(roll, diceType)
    local percentage = roll / diceType
    
    if roll == 1 then
        return colors.critical
    elseif roll == diceType then
        return colors.success
    elseif percentage >= 0.8 then
        return colors.success
    elseif percentage >= 0.6 then
        return colors.normal
    elseif percentage >= 0.4 then
        return colors.poor
    else
        return colors.critical
    end
end

function CRE:GetTotalColor(total, maxPossible)
    local percentage = total / maxPossible
    
    if percentage >= 0.8 then
        return colors.success
    elseif percentage >= 0.6 then
        return colors.normal
    elseif percentage >= 0.4 then
        return colors.poor
    else
        return colors.critical
    end
end

function CRE:SetAttribute(attributeName, value)
    if not attributeName then
        Print("Please specify an attribute name.")
        return
    end
    
    local profile = GetCurrentProfile()
    if not profile.attributes[attributeName] then
        Print("Invalid attribute. Valid attributes: " .. table.concat(attributeOrder, ", "))
        return
    end
    
    if not value or value < 0 or value > 10 then
        Print("Attribute value must be between 0 and 10.")
        return
    end
    
    profile.attributes[attributeName] = value
    Print(string.format("%s set to %d", attributeNames[attributeName], value))
    
    if attributeButtons[attributeName] then
        attributeButtons[attributeName].valueLabel:SetText(value)
    end
end

function CRE:GetAttribute(attributeName)
    if not attributeName then
        self:ShowAllAttributes()
        return
    end
    
    local profile = GetCurrentProfile()
    if not profile.attributes[attributeName] then
        Print("Invalid attribute name.")
        return
    end
    
    local value = profile.attributes[attributeName]
    Print(string.format("%s: %d", attributeNames[attributeName], value))
end

function CRE:ShowAllAttributes()
    Print("Current Attributes for " .. colors.profile .. UnitName("player") .. colors.reset .. ":")
    local profile = GetCurrentProfile()
    for _, attr in ipairs(attributeOrder) do
        local value = profile.attributes[attr]
        Print(string.format("  %s: %d", attributeNames[attr], value))
    end
end

function CRE:ResetAttributes()
    local profile = GetCurrentProfile()
    for attr, _ in pairs(profile.attributes) do
        profile.attributes[attr] = 0
    end
    Print("All attributes reset to 0 for " .. colors.profile .. UnitName("player") .. colors.reset)
    
    for attr, button in pairs(attributeButtons) do
        if button and button.valueLabel then
            button.valueLabel:SetText("0")
        end
    end
end

function CRE:ShowHelp()
    Print("Conflict Resolution Engine Commands:")
    Print(colors.normal .. "/cre show" .. colors.reset .. " - Show the UI window")
    Print(colors.normal .. "/cre hide" .. colors.reset .. " - Hide the UI window")
    Print(colors.normal .. "/cre debug" .. colors.reset .. " - Show debug information")
    Print(colors.normal .. "/cre profiles" .. colors.reset .. " - List all character profiles")
    Print(colors.normal .. "/cre set <attribute> <value>" .. colors.reset .. " - Set attribute (0-10)")
    Print(colors.normal .. "/cre get <attribute>" .. colors.reset .. " - Get attribute value")
    Print(colors.normal .. "/cre reset" .. colors.reset .. " - Reset all attributes to 0")
    Print(colors.normal .. "/cre test" .. colors.reset .. " - Test random number generation")
    Print(colors.normal .. "/roll d20 might" .. colors.reset .. " - Roll D20 + Might attribute")
    Print(colors.normal .. "/roll d6" .. colors.reset .. " - Roll D6 without attribute")
    Print(colors.normal .. "/creroll d100 luck" .. colors.reset .. " - Alternative roll command")
    Print("")
    Print("Attributes: " .. colors.attribute .. table.concat(attributeOrder, ", ") .. colors.reset)
    Print("Dice range: " .. colors.success .. "D2 to D100" .. colors.reset)
    Print("Current profile: " .. colors.profile .. UnitName("player") .. colors.reset)
    Print("Note: " .. colors.normal .. "Each character has their own profile with separate attributes and stats!" .. colors.reset)
end