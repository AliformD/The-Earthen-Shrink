-- The Earthen Shrink: small reusable UI pieces
--
-- Look: the same as the preview (Group Finder style). Gold names with a grey
-- line under them, numbers on the right, a gold bar for "how good", and the
-- full math in a normal WoW tooltip when you hover a row.

local _, ns = ...
local W = {}
ns.Widgets = W

W.GOLD  = { 1, 0.82, 0 }
W.GREEN = { 0.12, 1, 0 }
W.GREY  = { 0.6, 0.6, 0.6 }
W.WHITE = { 1, 1, 1 }
W.ORANGE = { 1, 0.5, 0 }

local ROW_H = 34

-- Tries a list of templates and uses the first one this client has.
function W.Create(kind, name, parent, templates)
    for _, t in ipairs(templates or {}) do
        local ok, f = pcall(CreateFrame, kind, name, parent, t)
        if ok and f then return f, t end
    end
    return CreateFrame(kind, name, parent)
end

function W.Text(parent, font, size, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    if justify then fs:SetJustifyH(justify) end
    if size then
        local path, _, flags = fs:GetFont()
        if path then fs:SetFont(path, size, flags) end
    end
    return fs
end

function W.Button(parent, text, width)
    local b = W.Create("Button", nil, parent, { "UIPanelButtonTemplate" })
    b:SetSize(width or 120, 22)
    b:SetText(text)
    return b
end

-- A dark box with a dark-blue edge, like the preview's panels.
function W.Panel(parent)
    local f = W.Create("Frame", nil, parent, { "BackdropTemplate" })
    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1,
        })
        f:SetBackdropColor(0.02, 0.03, 0.04, 0.9)
        f:SetBackdropBorderColor(0.15, 0.2, 0.28, 1)
    end
    return f
end

---------------------------------------------------------------------------
-- Chips: the little boxes at the top with one big number each
---------------------------------------------------------------------------

function W.Chips(parent, count, width)
    local chips = {}
    local w = (width - (count - 1) * 6) / count
    for i = 1, count do
        local c = W.Panel(parent)
        c:SetSize(w, 44)
        c:SetPoint("TOPLEFT", (i - 1) * (w + 6), 0)
        c.label = W.Text(c, "GameFontDisableSmall", nil, "LEFT")
        c.label:SetPoint("TOPLEFT", 8, -6)
        c.label:SetPoint("RIGHT", -6, 0)
        c.value = W.Text(c, "GameFontHighlightLarge", nil, "LEFT")
        c.value:SetPoint("BOTTOMLEFT", 8, 6)
        c.value:SetPoint("RIGHT", -6, 0)
        function c:Set(label, value, color)
            self.label:SetText(label or "")
            self.value:SetText(value or "")
            local col = color or W.WHITE
            self.value:SetTextColor(col[1], col[2], col[3])
        end
        chips[i] = c
    end
    return chips
end

---------------------------------------------------------------------------
-- The scrolling list of rows
---------------------------------------------------------------------------
-- columns = { { title = "Mana", width = 50 }, ... } shown on the right side.
-- meterAfter = index of the column to show a gold bar next to (optional).

function W.List(parent, width, height, columns, meterAfter)
    local L = { rows = {}, columns = columns or {}, width = width }
    local box = W.Panel(parent)
    box:SetSize(width, height)
    L.frame = box

    -- Column titles
    local header = CreateFrame("Frame", nil, box)
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetHeight(18)
    local hbg = header:CreateTexture(nil, "BACKGROUND")
    hbg:SetAllPoints()
    hbg:SetColorTexture(0.04, 0.05, 0.07, 1)
    L.headerTitles = {}

    local scroll = W.Create("ScrollFrame", nil, box, { "UIPanelScrollFrameTemplate", "ScrollFrameTemplate" })
    scroll:SetPoint("TOPLEFT", 1, -20)
    scroll:SetPoint("BOTTOMRIGHT", -24, 2)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(width - 26, 10)
    scroll:SetScrollChild(child)
    L.scroll, L.child = scroll, child
    L.innerWidth = width - 26

    -- Lay out columns from the right edge inwards.
    L.colX = {}
    local x = -6
    for i = #L.columns, 1, -1 do
        local col = L.columns[i]
        L.colX[i] = x
        local t = W.Text(header, "GameFontNormalSmall", nil, "RIGHT")
        t:SetPoint("RIGHT", header, "RIGHT", x - 24, 0)  -- -24 lines up with the scrollbar gap
        t:SetWidth(col.width)
        t:SetText(col.title)
        L.headerTitles[i] = t
        x = x - col.width - 6
        if meterAfter == i then x = x - 62 end
    end
    L.meterAfter = meterAfter
    local nameTitle = W.Text(header, "GameFontNormalSmall", nil, "LEFT")
    nameTitle:SetPoint("LEFT", 44, 0)
    L.nameTitle = nameTitle

    function L:SetNameTitle(s) self.nameTitle:SetText(s or "") end

    local function makeRow(i)
        local r = CreateFrame("Button", nil, child)
        r:SetSize(L.innerWidth, ROW_H)
        local line = r:CreateTexture(nil, "BACKGROUND")
        line:SetPoint("BOTTOMLEFT"); line:SetPoint("BOTTOMRIGHT"); line:SetHeight(1)
        line:SetColorTexture(1, 1, 1, 0.05)
        r.stripe = r:CreateTexture(nil, "BACKGROUND")
        r.stripe:SetAllPoints()
        r.stripe:SetColorTexture(1, 1, 1, 0.025)
        r.bg = r:CreateTexture(nil, "BACKGROUND", nil, 1)
        r.bg:SetAllPoints()
        r.bg:SetColorTexture(0.2, 0.46, 0.8, 0.35)
        r.bg:Hide()
        local hl = r:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.07)

        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(26, 26)
        r.icon:SetPoint("LEFT", 8, 0)
        r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        -- small green tick on the icon for the "best" row
        r.badge = r:CreateTexture(nil, "OVERLAY")
        r.badge:SetSize(14, 14)
        r.badge:SetPoint("BOTTOMRIGHT", r.icon, "BOTTOMRIGHT", 4, -3)
        r.badge:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        r.badge:Hide()

        r.name = W.Text(r, "GameFontNormal", nil, "LEFT")
        r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 8, 1)
        r.sub = W.Text(r, "GameFontDisableSmall", nil, "LEFT")
        r.sub:SetPoint("BOTTOMLEFT", r.icon, "BOTTOMRIGHT", 8, -1)

        r.cols = {}
        for c, col in ipairs(L.columns) do
            local t = W.Text(r, "GameFontHighlight", nil, "RIGHT")
            t:SetPoint("RIGHT", r, "RIGHT", L.colX[c], 0)
            t:SetWidth(col.width)
            r.cols[c] = t
        end
        if L.meterAfter then
            local bar = CreateFrame("StatusBar", nil, r)
            bar:SetSize(56, 7)
            bar:SetPoint("RIGHT", r.cols[L.meterAfter], "LEFT", -6, 0)
            bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
            bar:SetStatusBarColor(0.95, 0.75, 0.15)
            bar:SetMinMaxValues(0, 1)
            local bbg = bar:CreateTexture(nil, "BACKGROUND")
            bbg:SetAllPoints()
            bbg:SetColorTexture(0, 0, 0, 1)
            r.meter = bar
        end
        -- Leftmost column limits how wide the name can be.
        local leftCol = L.meterAfter == 1 and r.meter or r.cols[1]
        if leftCol then
            r.name:SetPoint("RIGHT", leftCol, "LEFT", -8, 0)
            r.sub:SetPoint("RIGHT", leftCol, "LEFT", -8, 0)
        end

        -- Section header look (used when a row is a title, not data)
        r.sectionIcon = r:CreateTexture(nil, "ARTWORK")
        r.sectionIcon:SetSize(14, 14)
        r.sectionIcon:SetPoint("LEFT", 8, 0)
        r.sectionIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        r.section = W.Text(r, "GameFontNormalSmall", nil, "LEFT")
        r.section:SetPoint("LEFT", 8, 0)
        r.section:SetTextColor(0.6, 0.6, 0.6)

        r:SetScript("OnEnter", function(self)
            if not self.data or not self.data.tooltip then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            self.data.tooltip(GameTooltip)
            GameTooltip:Show()
        end)
        r:SetScript("OnLeave", function() GameTooltip:Hide() end)
        r:SetScript("OnClick", function(self)
            if self.data and self.data.onClick then self.data.onClick(self.data) end
        end)
        return r
    end

    -- rows = list of { header = "TEXT" } or
    --   { icon, name, sub, cols = {..}, colColors = {..}, meter = 0..1, selected, tooltip = fn(tt) }
    function L:SetRows(rows)
        local y = 0
        for i, data in ipairs(rows) do
            local r = self.rows[i] or makeRow(i)
            self.rows[i] = r
            r.data = data
            r:ClearAllPoints()
            local h = data.header and 20 or ROW_H
            r:SetHeight(h)
            r:SetPoint("TOPLEFT", 0, -y)
            y = y + h
            local isHeader = data.header ~= nil
            r.section:SetText(isHeader and data.header:upper() or "")
            r.section:ClearAllPoints()
            r.section:SetPoint("LEFT", (isHeader and data.headerIcon) and 28 or 8, 0)
            r.sectionIcon:SetShown(isHeader and data.headerIcon ~= nil)
            if isHeader and data.headerIcon then r.sectionIcon:SetTexture(data.headerIcon) end
            r.badge:SetShown(not isHeader and data.badge and true or false)
            r.stripe:SetShown(not isHeader and i % 2 == 0)
            r.icon:SetShown(not isHeader)
            r.name:SetShown(not isHeader)
            r.sub:SetShown(not isHeader)
            if r.meter then r.meter:SetShown(not isHeader and data.meter ~= nil) end
            r.bg:SetShown(data.selected and true or false)
            if not isHeader then
                r.icon:SetTexture(data.icon or 134400)  -- 134400 = question mark icon
                r.name:SetText(data.name or "")
                local nc = data.nameColor or W.GOLD
                r.name:SetTextColor(nc[1], nc[2], nc[3])
                r.sub:SetText(data.sub or "")
                if r.meter and data.meter then
                    r.meter:SetValue(math.max(0, math.min(1, data.meter)))
                    local mc = data.meterColor or { 0.95, 0.75, 0.15 }
                    r.meter:SetStatusBarColor(mc[1], mc[2], mc[3])
                end
                r.icon:SetDesaturated(data.dim and true or false)
                r.icon:SetAlpha(data.dim and 0.6 or 1)
            end
            for c, t in ipairs(r.cols) do
                t:SetText(not isHeader and data.cols and data.cols[c] or "")
                local col = (data.colColors and data.colColors[c]) or (c == #r.cols and W.WHITE or W.GREY)
                t:SetTextColor(col[1], col[2], col[3])
            end
            r:Show()
        end
        for i = #rows + 1, #self.rows do self.rows[i]:Hide() end
        self.child:SetHeight(math.max(10, y))
    end

    return L
end

---------------------------------------------------------------------------
-- Tooltip helpers
---------------------------------------------------------------------------

-- Adds "math" lines to a GameTooltip. Plain strings are shown in a soft
-- yellow; { left, right } pairs are shown as two columns.
function W.AddMath(tt, lines)
    for _, l in ipairs(lines or {}) do
        if l == "" then
            -- skip empty lines
        elseif type(l) == "table" then
            tt:AddDoubleLine(l[1], l[2], 1, 0.82, 0, 1, 1, 1)
        else
            tt:AddLine(l, 0.91, 0.89, 0.78, true)
        end
    end
end

function W.AddNote(tt, text)
    tt:AddLine(" ")
    tt:AddLine(text, 0.6, 0.6, 0.6, true)
end

---------------------------------------------------------------------------
-- Stat slider: a label, the amount you added, and a slider with - and +
---------------------------------------------------------------------------
-- opts = { label, min, max, step, unit = "%" or nil, onChange = fn(value) }
-- The slider starts at 0 (= your real stats). Left of the middle line takes
-- stats away, right adds them. The coloured bar shows how far from 0 you are.

function W.StatSlider(parent, width, opts)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(width, 36)
    row.label = W.Text(row, "GameFontNormal", nil, "LEFT")
    row.label:SetPoint("TOPLEFT", 2, -1)
    row.label:SetText(opts.label)
    row.value = W.Text(row, "GameFontHighlight", nil, "RIGHT")
    row.value:SetPoint("TOPRIGHT", -2, -1)

    local function stepButton(text)
        local b = W.Create("Button", nil, row, { "UIPanelButtonTemplate" })
        b:SetSize(20, 18)
        b:SetText(text)
        return b
    end
    row.minus = stepButton("-")
    row.minus:SetPoint("BOTTOMLEFT", 0, 0)
    row.plus = stepButton("+")
    row.plus:SetPoint("BOTTOMRIGHT", 0, 0)

    local s = CreateFrame("Slider", nil, row)
    s:SetOrientation("HORIZONTAL")
    s:SetHeight(16)
    s:SetPoint("LEFT", row.minus, "RIGHT", 8, 0)
    s:SetPoint("RIGHT", row.plus, "LEFT", -8, 0)
    s:SetMinMaxValues(opts.min, opts.max)
    s:SetValueStep(opts.step or 1)
    if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
    s:EnableMouseWheel(true)
    row.slider = s

    -- Track, the "0" line, and the coloured fill from 0 to the knob.
    local track = s:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("LEFT"); track:SetPoint("RIGHT"); track:SetHeight(6)
    track:SetColorTexture(0, 0, 0, 0.9)
    local zero = s:CreateTexture(nil, "BORDER")
    zero:SetSize(2, 12)
    zero:SetColorTexture(1, 0.82, 0, 0.7)
    local fill = s:CreateTexture(nil, "ARTWORK")
    fill:SetHeight(6)
    fill:Hide()
    -- The knob. The game's own slider knob if this client has it, else a gold block.
    local thumb = s:CreateTexture(nil, "OVERLAY")
    if not (thumb.SetAtlas and thumb:SetAtlas("Minimal_SliderBar_Button")) then
        thumb:SetColorTexture(1, 0.82, 0, 1)
        thumb:SetSize(8, 16)
    else
        thumb:SetSize(20, 20)
    end
    s:SetThumbTexture(thumb)

    local function xOf(v)
        local w = s:GetWidth() or 0
        return (v - opts.min) / (opts.max - opts.min) * w
    end

    local function show(v)
        local unit = opts.unit or ""
        if v > 0 then
            row.value:SetText("|cff1eff00+" .. ns.fmt(v) .. unit .. "|r")
        elseif v < 0 then
            row.value:SetText("|cffff4a3a" .. ns.fmt(v) .. unit .. "|r")
        else
            row.value:SetText("|cff9999990" .. unit .. "|r")
        end
        local w = s:GetWidth() or 0
        if w > 0 then
            zero:ClearAllPoints()
            zero:SetPoint("CENTER", s, "LEFT", xOf(0), 0)
            fill:ClearAllPoints()
            local a, b = xOf(math.min(0, v)), xOf(math.max(0, v))
            fill:SetPoint("LEFT", s, "LEFT", a, 0)
            fill:SetWidth(math.max(1, b - a))
            if v > 0 then fill:SetColorTexture(0.12, 0.8, 0.1, 0.9) else fill:SetColorTexture(0.9, 0.2, 0.15, 0.9) end
            fill:SetShown(v ~= 0)
        end
    end

    local quiet = false   -- true while we move the slider ourselves (no callback)
    s:SetScript("OnValueChanged", function(_, v)
        local step = opts.step or 1
        v = math.floor(v / step + 0.5) * step
        show(v)
        if not quiet and opts.onChange then opts.onChange(v) end
    end)
    s:SetScript("OnSizeChanged", function() show(row:Get()) end)
    s:SetScript("OnMouseWheel", function(_, delta) row:Set(row:Get() + delta * (opts.step or 1), true) end)
    row.minus:SetScript("OnClick", function() row:Set(row:Get() - (opts.step or 1), true) end)
    row.plus:SetScript("OnClick", function() row:Set(row:Get() + (opts.step or 1), true) end)

    function row:Get()
        local step = opts.step or 1
        return math.floor((s:GetValue() or 0) / step + 0.5) * step
    end
    -- notify = true runs onChange (a click); false is for code setting it.
    function row:Set(v, notify)
        v = math.max(opts.min, math.min(opts.max, v))
        quiet = true
        s:SetValue(v)
        quiet = false
        show(v)
        if notify and opts.onChange then opts.onChange(v) end
    end

    if opts.tooltip then
        s:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            opts.tooltip(GameTooltip)
            GameTooltip:Show()
        end)
        s:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    s:SetValue(0)
    show(0)
    return row
end
