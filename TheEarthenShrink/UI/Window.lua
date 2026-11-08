-- The Earthen Shrink: the main window
--
-- Uses the game's own "portrait frame" (the same metal frame, round portrait
-- and red close button as the Group Finder), with tabs along the bottom.

local _, ns = ...
local W = ns.Widgets
local UI = {}
ns.UI = UI
ns.Tabs = ns.Tabs or {}

UI.WIDTH, UI.HEIGHT = 720, 500
UI.CONTENT_W = UI.WIDTH - 28

local TAB_ORDER = {
    { id = "weapon",  title = "Weapon Buffs" },
    { id = "spells",  title = "Spell Efficiency" },
    { id = "healing", title = "Healing" },
    { id = "totems",  title = "Totems" },
    { id = "inspect", title = "Inspect" },
}

local frame, current

local function build()
    frame = W.Create("Frame", "TheEarthenShrinkFrame", UIParent,
        { "PortraitFrameTemplate", "ButtonFrameTemplate", "BasicFrameTemplateWithInset" })
    frame:SetSize(UI.WIDTH, UI.HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    -- Escape closes it, like other game windows.
    table.insert(UISpecialFrames, "TheEarthenShrinkFrame")

    if frame.SetTitle then pcall(frame.SetTitle, frame, "The Earthen Shrink")
    elseif frame.TitleText then frame.TitleText:SetText("The Earthen Shrink") end
    -- Lightning Bolt icon in the round portrait.
    if frame.SetPortraitToAsset then pcall(frame.SetPortraitToAsset, frame, "Interface\\Icons\\Spell_Nature_Lightning")
    elseif frame.portrait then SetPortraitToTexture(frame.portrait, "Interface\\Icons\\Spell_Nature_Lightning") end

    -- A dark background behind the content, like the preview.
    local bg = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    bg:SetPoint("TOPLEFT", 8, -60)
    bg:SetPoint("BOTTOMRIGHT", -6, 6)
    bg:SetColorTexture(0.04, 0.06, 0.08, 0.95)

    frame.pages = {}
    frame.tabs = {}
    for i, t in ipairs(TAB_ORDER) do
        local page = CreateFrame("Frame", nil, frame)
        page:SetPoint("TOPLEFT", 14, -64)
        page:SetPoint("BOTTOMRIGHT", -12, 10)
        page:Hide()
        frame.pages[t.id] = page
        if ns.Tabs[t.id] then ns.Tabs[t.id].Build(page) end

        local tab = W.Create("Button", "TheEarthenShrinkFrameTab" .. i, frame, { "PanelTabButtonTemplate", "CharacterFrameTabButtonTemplate" })
        tab:SetID(i)
        tab:SetText(t.title)
        if PanelTemplates_TabResize then pcall(PanelTemplates_TabResize, tab, 0) end
        if i == 1 then tab:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 12, 2)
        else tab:SetPoint("LEFT", frame.tabs[i - 1], "RIGHT", 4, 0) end
        tab:SetScript("OnClick", function() UI.Show(t.id) end)
        frame.tabs[i] = tab
    end
    frame.Tabs = frame.tabs
    if PanelTemplates_SetNumTabs then pcall(PanelTemplates_SetNumTabs, frame, #TAB_ORDER) end

    ns.onRefresh(function()
        if frame:IsShown() then UI.Update() end
    end)
end

function UI.Update()
    if not frame or not current then return end
    if ns.inCombat() then return end   -- numbers are hidden in combat; update after
    local tab = ns.Tabs[current]
    if tab and tab.Update then
        local ok, err = pcall(tab.Update, frame.pages[current])
        if not ok then ns.say("|cffff4a3awindow error:|r " .. tostring(err)) end
    end
end

function UI.Show(id)
    if not frame then build() end
    current = id or current or "weapon"
    for i, t in ipairs(TAB_ORDER) do
        frame.pages[t.id]:SetShown(t.id == current)
        if t.id == current and PanelTemplates_SetTab then pcall(PanelTemplates_SetTab, frame, i) end
    end
    frame:Show()
    UI.Update()
end

function UI.Toggle()
    if frame and frame:IsShown() then frame:Hide() else UI.Show() end
end
