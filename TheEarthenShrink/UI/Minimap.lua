-- The Earthen Shrink: the round button on the edge of the minimap
--
-- Left-click opens or closes the window (same as typing /es).
-- Right-click opens a small options menu (lock it in place, or hide it).
-- Drag it with the left mouse button to slide it around the minimap.
-- Where it sits is saved, so it stays there after you log out.
--
-- Most addons use a shared library for this button. We don't use any
-- libraries, so this file does the same job by itself.

local _, ns = ...
local MM = {}
ns.Minimap = MM

local DEFAULT_ANGLE = 200   -- degrees around the minimap. 0 = right side, 90 = top
local button, menu

-- Our part of the saved settings: { angle = number, hide = bool, lock = bool }
local function settings()
    local db = ns.db()
    if type(db.minimap) ~= "table" then db.minimap = {} end
    local m = db.minimap
    if type(m.angle) ~= "number" then m.angle = DEFAULT_ANGLE end
    return m
end

---------------------------------------------------------------------------
-- Position: the button sits on a circle around the minimap's centre.
-- The angle is like the hand of a clock (but in degrees, counter-clockwise).
---------------------------------------------------------------------------

local function place()
    local r = math.rad(settings().angle)
    local radius = (Minimap:GetWidth() or 140) / 2 + 5
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(r) * radius, math.sin(r) * radius)
end

-- Runs every frame while you drag: turns the mouse position into an angle.
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
local function followMouse()
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    if not (mx and px and scale) then return end
    px, py = px / scale, py / scale
    settings().angle = math.deg(atan2(py - my, px - mx)) % 360
    place()
end

---------------------------------------------------------------------------
-- The right-click menu (a small dark box with three rows)
---------------------------------------------------------------------------

local function menuRow(parent, i, text, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(176, 20)
    b:SetPoint("TOPLEFT", 8, -26 - (i - 1) * 20)
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.1)
    b.check = b:CreateTexture(nil, "ARTWORK")
    b.check:SetSize(14, 14)
    b.check:SetPoint("LEFT", 2, 0)
    b.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    b.check:Hide()
    b.label = b:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    b.label:SetPoint("LEFT", 20, 0)
    b.label:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

local function buildMenu()
    menu = CreateFrame("Frame", "TheEarthenShrinkMinimapMenu", UIParent, "BackdropTemplate")
    menu:SetSize(192, 92)
    menu:SetFrameStrata("DIALOG")
    menu:SetClampedToScreen(true)
    if menu.SetBackdrop then
        menu:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        menu:SetBackdropColor(0.05, 0.06, 0.08, 0.95)
        menu:SetBackdropBorderColor(0.45, 0.38, 0.2, 1)
    end
    menu:Hide()
    -- Escape closes it, like the game's own menus.
    table.insert(UISpecialFrames, "TheEarthenShrinkMinimapMenu")

    local title = menu:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOPLEFT", 10, -8)
    title:SetText("The Earthen Shrink")

    menu.lock = menuRow(menu, 1, "Lock button in place", function()
        local m = settings()
        m.lock = not m.lock
        MM.UpdateMenu()
    end)
    menuRow(menu, 2, "Hide minimap button", function()
        menu:Hide()
        MM.SetHidden(true)
    end)
    menuRow(menu, 3, "Close", function() menu:Hide() end)
end

function MM.UpdateMenu()
    if menu then menu.lock.check:SetShown(settings().lock and true or false) end
end

local function toggleMenu()
    if not menu then buildMenu() end
    if menu:IsShown() then menu:Hide() return end
    MM.UpdateMenu()
    menu:ClearAllPoints()
    menu:SetPoint("TOPRIGHT", button, "BOTTOMLEFT", 4, 4)
    menu:Show()
    GameTooltip:Hide()
end

---------------------------------------------------------------------------
-- The button itself
---------------------------------------------------------------------------

-- short = true for the compartment list, where only clicking works.
local function showTooltip(self, short)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("The Earthen Shrink |cff9d9d9dv" .. ns.VERSION .. "|r")
    GameTooltip:AddLine("|cffffd100" .. (short and "Click" or "Left-click") .. ":|r open or close", 1, 1, 1)
    if short then GameTooltip:Show() return end
    GameTooltip:AddLine("|cffffd100Right-click:|r options", 1, 1, 1)
    if not settings().lock then
        GameTooltip:AddLine("|cffffd100Drag:|r move around the minimap", 1, 1, 1)
    end
    GameTooltip:Show()
end

local function build()
    button = CreateFrame("Button", "TheEarthenShrinkMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- Same pieces (and sizes) as the minimap buttons of most other addons:
    -- a dark round background, the icon, and the bronze ring on top.
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetSize(24, 24)
    bg:SetPoint("TOPLEFT", 7, -5)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(ns.UI.APP_ICON)
    icon:SetSize(18, 18)
    icon:SetPoint("TOPLEFT", 7, -6)
    icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    if icon.SetMask then pcall(icon.SetMask, icon, "Interface\\CharacterFrame\\TempPortraitAlphaMask") end
    button.icon = icon

    local ring = button:CreateTexture(nil, "OVERLAY")
    ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    ring:SetSize(50, 50)
    ring:SetPoint("TOPLEFT")

    -- Pressing the button nudges the icon down a little, like a real button.
    button:SetScript("OnMouseDown", function() icon:SetPoint("TOPLEFT", 8, -7) end)
    button:SetScript("OnMouseUp", function() icon:SetPoint("TOPLEFT", 7, -6) end)

    button:SetScript("OnClick", function(self, which)
        if which == "RightButton" then
            toggleMenu()
        else
            if menu then menu:Hide() end
            ns.UI.Toggle()
        end
    end)
    button:SetScript("OnEnter", function(self) showTooltip(self) end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    button:SetScript("OnDragStart", function(self)
        if settings().lock then return end
        GameTooltip:Hide()
        self:SetScript("OnUpdate", followMouse)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        icon:SetPoint("TOPLEFT", 7, -6)
    end)

    place()
end

---------------------------------------------------------------------------
-- Show / hide, and the /es minimap command
---------------------------------------------------------------------------

function MM.SetHidden(hide)
    settings().hide = hide and true or false
    if not button then return end
    button:SetShown(not hide)
    if hide then
        ns.say("minimap button hidden. Type |cffffd100/es minimap|r to bring it back.")
    end
end

-- /es minimap         show or hide the button
-- /es minimap reset   put it back in its first spot and unlock it
function MM.Slash(arg)
    if not button then ns.say("there's no minimap on this screen, so no button.") return end
    local m = settings()
    if arg == "reset" then
        m.angle, m.lock = DEFAULT_ANGLE, false
        place()
        MM.SetHidden(false)
        ns.say("minimap button moved back to its first spot.")
    else
        MM.SetHidden(not m.hide)
        if not m.hide then ns.say("minimap button shown.") end
    end
end

function MM.Button() return button end

ns.on("ADDON_LOADED", function(name)
    if name ~= "TheEarthenShrink" or button then return end
    if not Minimap then return end
    build()
    button:SetShown(not settings().hide)
end)

---------------------------------------------------------------------------
-- The game's "addon compartment": the little dropdown of addons near the
-- minimap. The .toc file names these functions, and the game calls them.
-- 🔶 The TOC wiki says Forever has this list. Not seen in game yet.
---------------------------------------------------------------------------

function TheEarthenShrink_OnCompartmentClick()
    ns.UI.Toggle()
end

function TheEarthenShrink_OnCompartmentEnter(_, frame)
    if not frame then return end
    showTooltip(frame, true)
end

function TheEarthenShrink_OnCompartmentLeave()
    GameTooltip:Hide()
end
