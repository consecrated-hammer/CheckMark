local addon, ns = ...

-- ── Style (reuse UI constants via ns where possible) ──────────────────────

local COLOR_OPT = {
    bg      = { 0.11, 0.11, 0.13, 0.96 },
    titleBg = { 0.15, 0.15, 0.18, 1.00 },
    border  = { 0.28, 0.28, 0.34, 1.00 },
    text    = { 0.88, 0.88, 0.90, 1.00 },
    subtext = { 0.58, 0.58, 0.62, 1.00 },
    accent  = { 0.38, 0.68, 0.92, 1.00 },
    btnBg   = { 0.20, 0.20, 0.24, 1.00 },
    btnHov  = { 0.30, 0.30, 0.36, 1.00 },
    marSel  = { 0.38, 0.68, 0.92, 0.40 },
    check   = { 0.38, 0.68, 0.92, 1.00 },
}

local OW, OH = 360, 400
local TH, PAD = 28, 10
local MSIZ = 18

local function c(r) return r[1], r[2], r[3], r[4] end

local function solidTex(parent, col, layer)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    t:SetColorTexture(c(col))
    return t
end

local function oFs(parent, size, str)
    local f = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f:SetFont(f:GetFont(), size or 12, "")
    f:SetText(str or "")
    f:SetTextColor(c(COLOR_OPT.text))
    return f
end

local function oBtn(parent, label, w, h)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w, h)
    local bg = solidTex(b, COLOR_OPT.btnBg)
    bg:SetAllPoints() ; b._bg = bg
    local hl = solidTex(b, COLOR_OPT.btnHov, "HIGHLIGHT")
    hl:SetAllPoints()
    local txt = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    txt:SetPoint("CENTER") ; txt:SetText(label) ; txt:SetTextColor(c(COLOR_OPT.text))
    b._txt = txt
    local function edge(pt, ew, eh)
        local t = b:CreateTexture(nil, "BORDER")
        t:SetColorTexture(c(COLOR_OPT.border))
        t:SetSize(ew, eh) ; t:SetPoint(pt)
    end
    edge("TOPLEFT", w, 1) ; edge("BOTTOMLEFT", w, 1)
    edge("TOPLEFT", 1, h) ; edge("TOPRIGHT",   1, h)
    return b
end

-- ── Checkbox row ──────────────────────────────────────────────────────────

local function makeCheckRow(parent, label, getter, setter)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(OW - PAD * 2, 22)

    local cb = CreateFrame("Button", nil, row)
    cb:SetSize(16, 16)
    cb:SetPoint("LEFT", row, "LEFT", 0, 0)

    local bg = solidTex(cb, COLOR_OPT.btnBg)
    bg:SetAllPoints()
    local hl = solidTex(cb, COLOR_OPT.btnHov, "HIGHLIGHT")
    hl:SetAllPoints()
    local border = solidTex(cb, COLOR_OPT.border, "BORDER")
    border:SetSize(16, 16) ; border:SetAllPoints()

    local check = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    check:SetFont(check:GetFont(), 13, "OUTLINE")
    check:SetPoint("CENTER")
    check:SetText("")

    local function refresh()
        if getter and getter() then
            check:SetText("|cff62ade3\xE2\x9C\x93|r")
        else
            check:SetText("")
        end
    end

    cb:SetScript("OnClick", function()
        if setter then setter(not (getter and getter())) end
        refresh()
    end)

    local lbl = oFs(row, 11, label)
    lbl:SetPoint("LEFT", cb, "RIGHT", 6, 0)

    refresh()
    row._refresh = refresh
    return row
end

-- ── Marker selector (mini) ─────────────────────────────────────────────────

local function makeSlotRow(parent, slotLabel, getMarker, setMarker)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(OW - PAD * 2, 24)

    local lbl = oFs(row, 11, slotLabel)
    lbl:SetPoint("LEFT", row, "LEFT", 0, 0)
    lbl:SetWidth(60)
    lbl:SetJustifyH("LEFT")

    local selOverlays = {}
    for i = 0, 8 do
        local btn = CreateFrame("Button", nil, row)
        btn:SetSize(MSIZ, MSIZ)
        btn:SetPoint("LEFT", row, "LEFT", 66 + i * (MSIZ + 2), 0)

        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        if i == 0 then
            icon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
            icon:SetVertexColor(0.55, 0.55, 0.55)
        else
            icon:SetTexture(ns.MARKER_TEXTURES[i])
        end

        local sel = solidTex(btn, COLOR_OPT.marSel, "OVERLAY")
        sel:SetAllPoints() ; sel:Hide()
        selOverlays[i] = sel

        local hl = solidTex(btn, COLOR_OPT.btnHov, "HIGHLIGHT")
        hl:SetAllPoints()

        local idx = i
        btn:SetScript("OnClick", function()
            for j = 0, 8 do
                if selOverlays[j] then
                    if j == idx then selOverlays[j]:Show() else selOverlays[j]:Hide() end
                end
            end
            if setMarker then setMarker(idx) end
        end)
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(ns.MARKER_NAMES[idx] or "None", 1, 1, 1)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    -- Set initial selection
    local cur = getMarker and getMarker() or 0
    if selOverlays[cur] then selOverlays[cur]:Show() end

    function row:Refresh()
        local v = getMarker and getMarker() or 0
        for j = 0, 8 do
            if selOverlays[j] then
                if j == v then selOverlays[j]:Show() else selOverlays[j]:Hide() end
            end
        end
    end

    return row
end

-- ── Options panel ─────────────────────────────────────────────────────────

local optPanel
local checkRows = {}
local slotRows  = {}

local function buildOptions()
    optPanel = CreateFrame("Frame", "CheckMarkOptions", UIParent)
    optPanel:SetSize(OW, OH)
    optPanel:SetPoint("CENTER", UIParent, "CENTER", 200, 80)
    optPanel:SetFrameStrata("DIALOG")
    optPanel:SetMovable(true)
    optPanel:SetClampedToScreen(true)
    optPanel:EnableMouse(true)
    optPanel:Hide()

    local bg = solidTex(optPanel, COLOR_OPT.bg)
    bg:SetAllPoints()

    -- Title bar
    local titleBar = CreateFrame("Frame", nil, optPanel)
    titleBar:SetPoint("TOPLEFT") ; titleBar:SetPoint("TOPRIGHT") ; titleBar:SetHeight(TH)
    titleBar:EnableMouse(true)
    titleBar:SetScript("OnMouseDown", function(_, btn)
        if btn == "LeftButton" then optPanel:StartMoving() end
    end)
    titleBar:SetScript("OnMouseUp", function() optPanel:StopMovingOrSizing() end)

    local tBg = solidTex(titleBar, COLOR_OPT.titleBg) ; tBg:SetAllPoints()
    local tTxt = oFs(titleBar, 13, "CheckMark \xe2\x80\x94 Options")
    tTxt:SetPoint("LEFT", titleBar, "LEFT", PAD, 0)
    tTxt:SetTextColor(c(COLOR_OPT.accent))

    local closeBtn = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -2, 0)
    closeBtn:SetScript("OnClick", function() optPanel:Hide() end)

    local div = solidTex(titleBar, COLOR_OPT.border, "ARTWORK")
    div:SetHeight(1) ; div:SetPoint("BOTTOMLEFT") ; div:SetPoint("BOTTOMRIGHT")

    -- Scrollable content area
    local scroll = CreateFrame("ScrollFrame", nil, optPanel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     optPanel, "TOPLEFT",     PAD,    -(TH + 4))
    scroll:SetPoint("BOTTOMRIGHT", optPanel, "BOTTOMRIGHT", -PAD-18, PAD)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(OW - PAD * 2 - 18, 1)
    scroll:SetScrollChild(content)

    local yOff = 0
    local function section(label)
        local h = oFs(content, 11, label)
        h:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOff)
        h:SetTextColor(c(COLOR_OPT.accent))
        yOff = yOff + 18
        local div2 = content:CreateTexture(nil, "ARTWORK")
        div2:SetColorTexture(c(COLOR_OPT.border))
        div2:SetHeight(1)
        div2:SetPoint("TOPLEFT",  content, "TOPLEFT",  0, -yOff)
        div2:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -yOff)
        yOff = yOff + 6
    end

    local function addCheck(label, getter, setter)
        local row = makeCheckRow(content, label, getter, setter)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOff)
        yOff = yOff + 26
        table.insert(checkRows, row)
        return row
    end

    local function addSlot(slotKey, slotLabel)
        local function getM() return ns.db and ns.db.role_template[slotKey] or 0 end
        local function setM(v)
            if ns.db then ns.db.role_template[slotKey] = v end
        end
        local row = makeSlotRow(content, slotLabel, getM, setM)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOff)
        yOff = yOff + 28
        table.insert(slotRows, row)
        return row
    end

    -- ── Trigger settings ──────────────────────────────────────────────────
    section("Popup Triggers")
    addCheck("Show popup when group changes", function()
        return ns.db and ns.db.popup_on_group_change
    end, function(v)
        if ns.db then ns.db.popup_on_group_change = v end
    end)
    addCheck("Show popup when entering a dungeon or delve", function()
        return ns.db and ns.db.popup_on_instance_enter
    end, function(v)
        if ns.db then ns.db.popup_on_instance_enter = v end
    end)

    yOff = yOff + 8

    -- ── Role template ──────────────────────────────────────────────────────
    section("Role Template (defaults for Role-based mode)")
    for _, slot in ipairs(ns.ROLE_SLOTS) do
        addSlot(slot, ns.ROLE_SLOT_LABELS[slot])
    end

    yOff = yOff + 8

    -- ── Reset ──────────────────────────────────────────────────────────────
    section("Data")
    local resetBtn = oBtn(content, "Reset all settings and remembered groups", OW - PAD * 2 - 18, 24)
    resetBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOff)
    resetBtn:SetScript("OnClick", function()
        StaticPopupDialogs["CHECKMARK_RESET"] = {
            text          = "Reset all CheckMark settings?  This cannot be undone.",
            button1       = "Reset",
            button2       = "Cancel",
            OnAccept      = function()
                CheckMarkDB = nil
                ReloadUI()
            end,
            timeout       = 0,
            whileDead     = true,
            hideOnEscape  = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("CHECKMARK_RESET")
    end)
    yOff = yOff + 32

    content:SetHeight(yOff + PAD)

    -- Outer border
    local bT = solidTex(optPanel, COLOR_OPT.border, "BORDER")
    bT:SetHeight(1) ; bT:SetPoint("TOPLEFT") ; bT:SetPoint("TOPRIGHT")
    local bB = solidTex(optPanel, COLOR_OPT.border, "BORDER")
    bB:SetHeight(1) ; bB:SetPoint("BOTTOMLEFT") ; bB:SetPoint("BOTTOMRIGHT")
    local bL = solidTex(optPanel, COLOR_OPT.border, "BORDER")
    bL:SetWidth(1) ; bL:SetPoint("TOPLEFT") ; bL:SetPoint("BOTTOMLEFT")
    local bR = solidTex(optPanel, COLOR_OPT.border, "BORDER")
    bR:SetWidth(1) ; bR:SetPoint("TOPRIGHT") ; bR:SetPoint("BOTTOMRIGHT")
end

function ns.showOptions()
    if not optPanel then buildOptions() end
    -- Refresh slot rows to reflect current DB values
    for _, row in ipairs(slotRows) do
        if row.Refresh then row:Refresh() end
    end
    for _, row in ipairs(checkRows) do
        if row._refresh then row._refresh() end
    end
    optPanel:Show()
end

function ns.hideOptions()
    if optPanel then optPanel:Hide() end
end
