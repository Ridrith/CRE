-- UI.lua — Main GUI frame, tabs, minimap button, dark-fantasy theme
-- Conflict Resolution Engine v2.0
local addonName, ns = ...

local c = ns.colors

-- ─── Theme constants ─────────────────────────────────────────────────────────
local THEME = {
    bgColor     = { r=0.05, g=0.05, b=0.08, a=0.95 },
    borderColor = { r=0.4,  g=0.3,  b=0.1,  a=1 },
    tabActive   = { r=0.15, g=0.12, b=0.04, a=1 },
    tabInactive = { r=0.08, g=0.06, b=0.02, a=1 },
    titleColor  = { r=1,    g=0.82, b=0.2,  a=1 },
    textColor   = { r=0.9,  g=0.85, b=0.7,  a=1 },
    accentColor = { r=0.53, g=0.27, b=0,    a=1 },
}

-- ─── Backdrop helper ─────────────────────────────────────────────────────────
local function SetDarkBackdrop(f, edgeSize)
    edgeSize = edgeSize or 2
    f:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile     = true, tileSize = 16, edgeSize = edgeSize,
        insets   = { left=3, right=3, top=3, bottom=3 },
    })
    f:SetBackdropColor(THEME.bgColor.r, THEME.bgColor.g, THEME.bgColor.b, THEME.bgColor.a)
    f:SetBackdropBorderColor(THEME.borderColor.r, THEME.borderColor.g, THEME.borderColor.b, THEME.borderColor.a)
end
ns.SetDarkBackdrop = SetDarkBackdrop

-- ─── Tab definitions ─────────────────────────────────────────────────────────
local TAB_NAMES = {"Profile", "Dice", "Combat", "Traits", "Reference"}
ns.tabs = {}       -- tab button refs
ns.panels = {}     -- content panel refs
ns.activeTab = 1

-- ─── Main window ─────────────────────────────────────────────────────────────
local mainFrame

local function CreateMainFrame()
    mainFrame = CreateFrame("Frame", "CREMainFrame", UIParent, "BackdropTemplate")
    mainFrame:SetSize(520, 620)
    mainFrame:SetPoint("CENTER", UIParent, "CENTER")
    mainFrame:SetMovable(true)
    mainFrame:SetResizable(true)
    mainFrame:SetResizeBounds(400, 480)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save position
        local point, _, relPoint, x, y = self:GetPoint()
        if ConflictResolutionEngineDB and ConflictResolutionEngineDB.windowPos then
            ConflictResolutionEngineDB.windowPos = {
                point = point, relPoint = relPoint, x = x, y = y
            }
        end
    end)
    mainFrame:Hide()

    -- Backdrop
    SetDarkBackdrop(mainFrame, 3)

    -- Title bar background
    local titleBg = mainFrame:CreateTexture(nil, "BACKGROUND")
    titleBg:SetColorTexture(THEME.accentColor.r, THEME.accentColor.g, THEME.accentColor.b, 0.6)
    titleBg:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 0, 0)
    titleBg:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 0, 0)
    titleBg:SetHeight(28)

    -- Title text
    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", mainFrame, "TOPLEFT", 10, -14)
    title:SetText("|cFFFFD700Conflict Resolution Engine|r  |cFFAAAAAA v2.0|r")
    title:SetFont("Fonts/FRIZQT__.TTF", 13, "OUTLINE")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() mainFrame:Hide() end)

    -- Resize grip
    local resizeBtn = CreateFrame("Button", nil, mainFrame)
    resizeBtn:SetSize(16, 16)
    resizeBtn:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -2, 2)
    resizeBtn:SetNormalTexture("Interface/ChatFrame/UI-ChatIM-SizeGrab")
    resizeBtn:SetScript("OnMouseDown", function() mainFrame:StartSizing("BOTTOMRIGHT") end)
    resizeBtn:SetScript("OnMouseUp",   function()
        mainFrame:StopMovingOrSizing()
    end)

    -- Add to UISpecialFrames so Escape closes it
    table.insert(UISpecialFrames, "CREMainFrame")

    return mainFrame
end

-- ─── Tab bar ─────────────────────────────────────────────────────────────────
local function CreateTabs(parent)
    local tabWidth = 90
    local tabHeight = 26
    local tabY = -28

    for i, name in ipairs(TAB_NAMES) do
        local tab = CreateFrame("Button", "CRETab" .. i, parent, "BackdropTemplate")
        tab:SetSize(tabWidth, tabHeight)
        tab:SetPoint("TOPLEFT", parent, "TOPLEFT", (i - 1) * (tabWidth + 2) + 4, tabY)
        SetDarkBackdrop(tab, 2)

        local label = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("CENTER")
        label:SetText(name)
        label:SetTextColor(THEME.textColor.r, THEME.textColor.g, THEME.textColor.b)
        tab.label = label

        tab:SetScript("OnClick", function()
            ns.ShowTab(i)
        end)

        -- Hover highlight
        tab:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.2, 0.15, 0.05, 1)
        end)
        tab:SetScript("OnLeave", function(self)
            if ns.activeTab == i then
                self:SetBackdropColor(THEME.tabActive.r, THEME.tabActive.g, THEME.tabActive.b, 1)
            else
                self:SetBackdropColor(THEME.tabInactive.r, THEME.tabInactive.g, THEME.tabInactive.b, 1)
            end
        end)

        ns.tabs[i] = tab

        -- Content panel for this tab
        local panel = CreateFrame("Frame", "CREPanel" .. i, parent, "BackdropTemplate")
        panel:SetPoint("TOPLEFT",  parent, "TOPLEFT",  6,  -(28 + tabHeight + 4))
        panel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -6, 6)
        panel:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            tile   = true, tileSize = 16,
        })
        panel:SetBackdropColor(0.03, 0.03, 0.05, 0.8)
        panel:Hide()
        ns.panels[i] = panel
    end
end

-- Show a specific tab
function ns.ShowTab(index)
    ns.activeTab = index
    for i, tab in ipairs(ns.tabs) do
        local isActive = (i == index)
        if isActive then
            tab:SetBackdropColor(THEME.tabActive.r, THEME.tabActive.g, THEME.tabActive.b, 1)
            tab:SetBackdropBorderColor(THEME.titleColor.r, THEME.titleColor.g, THEME.titleColor.b, 1)
            tab.label:SetTextColor(THEME.titleColor.r, THEME.titleColor.g, THEME.titleColor.b)
        else
            tab:SetBackdropColor(THEME.tabInactive.r, THEME.tabInactive.g, THEME.tabInactive.b, 1)
            tab:SetBackdropBorderColor(THEME.borderColor.r, THEME.borderColor.g, THEME.borderColor.b, 1)
            tab.label:SetTextColor(THEME.textColor.r, THEME.textColor.g, THEME.textColor.b)
        end
        ns.panels[i]:SetShown(isActive)
    end
    -- Notify each tab's refresh callback
    local refreshFns = {
        ns.RefreshProfileTab,
        ns.RefreshDiceTab,
        ns.RefreshCombatTab,
        ns.RefreshTraitsTab,
        ns.RefreshReferenceTab,
    }
    if refreshFns[index] then
        refreshFns[index]()
    end
end

-- ─── Toggle / Show / Hide ─────────────────────────────────────────────────────
function ns.ToggleMainWindow()
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        -- Restore saved position
        if ConflictResolutionEngineDB and ConflictResolutionEngineDB.windowPos then
            local pos = ConflictResolutionEngineDB.windowPos
            if pos.point then
                mainFrame:ClearAllPoints()
                mainFrame:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
            end
        end
        mainFrame:Show()
        ns.ShowTab(ns.activeTab)
    end
end

function ns.ShowMainWindow()
    if not mainFrame:IsShown() then ns.ToggleMainWindow() end
end

-- ─── Minimap button ──────────────────────────────────────────────────────────
local minimapBtn

local function CreateMinimapButton()
    minimapBtn = CreateFrame("Button", "CREMinimapButton", Minimap)
    minimapBtn:SetSize(32, 32)
    minimapBtn:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    minimapBtn:SetMovable(true)
    minimapBtn:RegisterForDrag("LeftButton")
    minimapBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    -- Position on minimap using saved angle
    local function UpdateMinimapPos(angle)
        local x = 80 * math.cos(math.rad(angle))
        local y = 80 * math.sin(math.rad(angle))
        minimapBtn:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end

    local angle = 45
    if ConflictResolutionEngineDB and ConflictResolutionEngineDB.settings then
        angle = ConflictResolutionEngineDB.settings.minimapPos or 45
    end
    UpdateMinimapPos(angle)

    -- Drag to reposition
    minimapBtn:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale  = UIParent:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale
            local newAngle = math.deg(math.atan2(cy - my, cx - mx))
            angle = newAngle
            UpdateMinimapPos(newAngle)
        end)
    end)
    minimapBtn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        if ConflictResolutionEngineDB and ConflictResolutionEngineDB.settings then
            ConflictResolutionEngineDB.settings.minimapPos = angle
        end
    end)

    -- Icon
    local icon = minimapBtn:CreateTexture(nil, "BACKGROUND")
    icon:SetAllPoints()
    icon:SetTexture("Interface/ICONS/inv_misc_dice_02")

    -- Border
    local border = minimapBtn:CreateTexture(nil, "OVERLAY")
    border:SetAllPoints()
    border:SetTexture("Interface/Minimap/MiniMap-TrackingBorder")

    -- Tooltip
    minimapBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("|cFFFFD700Conflict Resolution Engine|r")
        GameTooltip:AddLine("Left-click to toggle window", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Drag to reposition", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    minimapBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    minimapBtn:SetScript("OnClick", function(self, btn)
        if btn == "LeftButton" then
            ns.ToggleMainWindow()
        end
    end)

    return minimapBtn
end

-- ─── Init (called from Core.lua after ADDON_LOADED) ──────────────────────────
function ns.OnAddonLoaded()
    CreateMainFrame()
    CreateTabs(mainFrame)
    -- Each UI_*.lua module builds its content into the panels
    if ns.BuildProfileTab    then ns.BuildProfileTab(ns.panels[1])    end
    if ns.BuildDiceTab       then ns.BuildDiceTab(ns.panels[2])       end
    if ns.BuildCombatTab     then ns.BuildCombatTab(ns.panels[3])     end
    if ns.BuildTraitsTab     then ns.BuildTraitsTab(ns.panels[4])     end
    if ns.BuildReferenceTab  then ns.BuildReferenceTab(ns.panels[5])  end

    CreateMinimapButton()
    ns.ShowTab(1)
end

-- ─── Shared UI widget helpers (used by sub-tab files) ────────────────────────

-- Create a styled button
function ns.MakeButton(parent, label, width, height)
    width  = width  or 100
    height = height or 22
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height)
    btn:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 2,
        insets   = { left=2, right=2, top=2, bottom=2 },
    })
    btn:SetBackdropColor(0.15, 0.10, 0.03, 1)
    btn:SetBackdropBorderColor(0.5, 0.35, 0.1, 1)

    local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    txt:SetPoint("CENTER")
    txt:SetText(label)
    txt:SetTextColor(1, 0.85, 0.2)
    btn.txt = txt

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.25, 0.18, 0.06, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.15, 0.10, 0.03, 1)
    end)
    return btn
end

-- Create a styled edit box
function ns.MakeEditBox(parent, width, height, label)
    width  = width  or 120
    height = height or 20
    local eb = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    eb:SetSize(width, height)
    eb:SetAutoFocus(false)
    eb:SetFontObject("GameFontNormalSmall")
    eb:SetTextColor(0.9, 0.85, 0.7)
    eb:SetBackdrop({
        bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile     = true, tileSize = 8, edgeSize = 2,
        insets   = { left=3, right=3, top=2, bottom=2 },
    })
    eb:SetBackdropColor(0.02, 0.02, 0.04, 0.9)
    eb:SetBackdropBorderColor(0.4, 0.3, 0.1, 1)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return eb
end

-- Create a simple scrolling text frame
function ns.MakeScrollFrame(parent, w, h)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetSize(w, h)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(w - 20, h)
    scroll:SetScrollChild(content)

    return scroll, content
end

-- Create a section label
function ns.MakeLabel(parent, text, r, g, b)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetText(text)
    fs:SetTextColor(r or 1, g or 0.82, b or 0.2)
    return fs
end

-- Create a dropdown (uses UIDropDownMenu)
function ns.MakeDropdown(parent, items, currentVal, onChange)
    local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dd:SetWidth(130)

    UIDropDownMenu_SetWidth(dd, 110)
    UIDropDownMenu_SetText(dd, currentVal or items[1])

    UIDropDownMenu_Initialize(dd, function(self, level)
        for _, item in ipairs(items) do
            local info = UIDropDownMenu_CreateInfo()
            info.text    = item
            info.value   = item
            info.checked = (UIDropDownMenu_GetText(dd) == item)
            info.func    = function()
                UIDropDownMenu_SetText(dd, item)
                if onChange then onChange(item) end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    return dd
end
