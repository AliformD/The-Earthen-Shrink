-- The Earthen Shrink: the main window
--
-- Uses the game's own "portrait frame" (the same metal frame, round portrait
-- and red close button as the Group Finder). Like the Group Finder, the
-- sections are big buttons down the left side, each with a round WoW icon.

local _, ns = ...
local W = ns.Widgets
local UI = {}
ns.UI = UI
ns.Tabs = ns.Tabs or {}

UI.SIDEBAR_W = 178
UI.CONTENT_W = 692                                  -- width every tab builds its page for
UI.WIDTH = UI.SIDEBAR_W + UI.CONTENT_W + 40
UI.HEIGHT = 530                                    -- leaves every page 426 tall, same as before

-- The app's own icon (also used in the AddOn list and the round portrait).
UI.APP_ICON = "Interface\\Icons\\Spell_Nature_Lightning"

-- icon = a normal WoW icon file, so it looks like the game's own buttons.
local TAB_ORDER = {
    { id = "weapon",  title = "Weapon Buffs", head = "Weapon Buffs",     icon = "Interface\\Icons\\Spell_Nature_Cyclone" },
    { id = "spells",  title = "Spells",       head = "Damage Per Mana",  icon = "Interface\\Icons\\Spell_Nature_ChainLightning" },
    { id = "healing", title = "Healing",      head = "Healing Per Mana", icon = "Interface\\Icons\\Spell_Nature_MagicImmunity" },
    { id = "totems",  title = "Totems",       head = "Totems",           icon = "Interface\\Icons\\Spell_Nature_ManaRegenTotem" },
    { id = "simlab",  title = "Sim Lab",      head = "Sim Lab",          icon = "Interface\\Icons\\INV_Misc_Gear_01" },
    { id = "coef",    title = "SP Test",      head = "Spell Power Test", icon = "Interface\\Icons\\Trade_Alchemy" },
    { id = "inspect", title = "Inspect",      head = "Inspect",          icon = "Interface\\Icons\\INV_Misc_Spyglass_03" },
}

local frame, current

---------------------------------------------------------------------------
-- One button on the left side: round icon in a bronze ring, gold name
---------------------------------------------------------------------------

local ICON = 34

local function sideButton(parent, t, i)
    local b = W.Create("Button", nil, parent, { "BackdropTemplate" })
    b:SetSize(UI.SIDEBAR_W - 8, 52)
    b:SetPoint("TOPLEFT", 4, -4 - (i - 1) * 56)
    if b.SetBackdrop then
        b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        b:SetBackdropColor(0.07, 0.08, 0.11, 0.95)
        b:SetBackdropBorderColor(0.2, 0.22, 0.27, 1)
    end

    -- Blue glow when this section is open (same blue as a picked list row).
    b.selected = b:CreateTexture(nil, "BACKGROUND", nil, 2)
    b.selected:SetPoint("TOPLEFT", 1, -1)
    b.selected:SetPoint("BOTTOMRIGHT", -1, 1)
    b.selected:SetColorTexture(0.2, 0.46, 0.8, 0.45)
    b.selected:Hide()
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetPoint("TOPLEFT", 1, -1)
    hl:SetPoint("BOTTOMRIGHT", -1, 1)
    hl:SetColorTexture(1, 1, 1, 0.07)

    -- The icon, cut into a circle.
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(ICON, ICON)
    b.icon:SetPoint("LEFT", 12, 0)
    b.icon:SetTexture(t.icon)
    if not (b.icon.SetMask and pcall(b.icon.SetMask, b.icon, "Interface\\CharacterFrame\\TempPortraitAlphaMask")) then
        b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
    -- The bronze ring that minimap buttons use. The ring sits off-centre in
    -- its picture, so it's placed from the icon's centre (same sizes as the
    -- minimap-button library most addons use, just scaled up).
    b.ring = b:CreateTexture(nil, "OVERLAY")
    b.ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    b.ring:SetSize(ICON * 50 / 18, ICON * 50 / 18)
    b.ring:SetPoint("TOPLEFT", b.icon, "CENTER", -ICON * 15.5 / 18, ICON * 15.5 / 18)

    b.label = W.Text(b, "GameFontNormal", 14, "LEFT")
    b.label:SetPoint("LEFT", b.icon, "RIGHT", 14, 0)
    b.label:SetPoint("RIGHT", -6, 0)
    b.label:SetText(t.title)

    function b:SetSelected(on)
        self.selected:SetShown(on)
        if on then self.label:SetTextColor(1, 1, 1) else self.label:SetTextColor(1, 0.82, 0) end
    end
    b:SetScript("OnClick", function() UI.Show(t.id) end)
    return b
end

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
    -- The app's icon in the round portrait (top left).
    if frame.SetPortraitToAsset then pcall(frame.SetPortraitToAsset, frame, UI.APP_ICON)
    elseif frame.portrait and SetPortraitToTexture then SetPortraitToTexture(frame.portrait, UI.APP_ICON) end

    -- Dark background behind everything, then a darker strip for the sidebar.
    local bg = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    bg:SetPoint("TOPLEFT", 8, -60)
    bg:SetPoint("BOTTOMRIGHT", -6, 6)
    bg:SetColorTexture(0.04, 0.06, 0.08, 0.95)

    local side = CreateFrame("Frame", nil, frame)
    side:SetPoint("TOPLEFT", 10, -62)
    side:SetPoint("BOTTOMLEFT", 10, 8)
    side:SetWidth(UI.SIDEBAR_W)
    local sbg = side:CreateTexture(nil, "BACKGROUND", nil, 2)
    sbg:SetAllPoints()
    sbg:SetColorTexture(0.02, 0.03, 0.04, 0.9)
    local edge = side:CreateTexture(nil, "BORDER")
    edge:SetPoint("TOPRIGHT"); edge:SetPoint("BOTTOMRIGHT"); edge:SetWidth(1)
    edge:SetColorTexture(0.25, 0.27, 0.32, 1)
    frame.side = side

    -- Gold heading over the page, like "DUNGEONS & RAIDS" in the Group Finder.
    local left = UI.SIDEBAR_W + 24
    frame.head = W.Text(frame, "GameFontNormalLarge", 16, "LEFT")
    frame.head:SetPoint("TOPLEFT", left, -68)
    local rule = frame:CreateTexture(nil, "ARTWORK")
    rule:SetPoint("TOPLEFT", left, -88)
    rule:SetPoint("TOPRIGHT", -14, -88)
    rule:SetHeight(1)
    rule:SetColorTexture(1, 0.82, 0, 0.25)

    frame.pages = {}
    frame.buttons = {}
    for i, t in ipairs(TAB_ORDER) do
        local page = CreateFrame("Frame", nil, frame)
        page:SetPoint("TOPLEFT", left, -94)
        page:SetPoint("BOTTOMRIGHT", -12, 10)
        page:Hide()
        frame.pages[t.id] = page
        if ns.Tabs[t.id] then ns.Tabs[t.id].Build(page) end
        frame.buttons[t.id] = sideButton(side, t, i)
    end

    -- Version, bottom of the sidebar.
    local ver = W.Text(side, "GameFontDisableSmall", nil, "CENTER")
    ver:SetPoint("BOTTOM", 0, 6)
    ver:SetText("v" .. ns.VERSION .. "  ·  /es")

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
    for _, t in ipairs(TAB_ORDER) do
        local on = t.id == current
        frame.pages[t.id]:SetShown(on)
        frame.buttons[t.id]:SetSelected(on)
        if on then frame.head:SetText(t.head:upper()) end
    end
    frame:Show()
    UI.Update()
end

-- True when the window is open on this section.
function UI.IsShowing(id)
    return frame and frame:IsShown() and current == id or false
end

function UI.Toggle()
    if frame and frame:IsShown() then frame:Hide() else UI.Show() end
end
