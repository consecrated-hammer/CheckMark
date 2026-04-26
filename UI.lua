local addon, ns = ...

-- ── Style constants ────────────────────────────────────────────────────────

local COLOR = {
    bg        = { 0.11, 0.11, 0.13, 0.96 },
    titleBg   = { 0.15, 0.15, 0.18, 1.00 },
    border    = { 0.28, 0.28, 0.34, 1.00 },
    text      = { 0.88, 0.88, 0.90, 1.00 },
    subtext   = { 0.58, 0.58, 0.62, 1.00 },
    accent    = { 0.38, 0.68, 0.92, 1.00 },
    btnBg     = { 0.20, 0.20, 0.24, 1.00 },
    btnHover  = { 0.30, 0.30, 0.36, 1.00 },
    btnActive = { 0.32, 0.58, 0.82, 1.00 },
    markerSel = { 0.38, 0.68, 0.92, 0.40 },
    rowAlt    = { 0.14, 0.14, 0.17, 0.60 },
}

local POPUP_W   = 340
local TITLE_H   = 28
local TOGGLE_H  = 30
local ROW_H     = 30
local FOOTER_H  = 40
local MARKER_SZ = 18
local PAD       = 10

local function calcHeight(numRows)
    return TITLE_H + TOGGLE_H + 8 + numRows * ROW_H + 4 + FOOTER_H
end

-- ── Low-level helpers ──────────────────────────────────────────────────────

local function col(r) return r[1], r[2], r[3], r[4] end

local function solidTex(parent, c, layer)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    t:SetColorTexture(col(c))
    return t
end

local function outlineBorder(frame, c)
    c = c or COLOR.border
    local function bar(pt, w, h)
        local t = frame:CreateTexture(nil, "BORDER")
        t:SetColorTexture(col(c))
        t:SetSize(w, h)
        t:SetPoint(pt)
    end
    bar("TOPLEFT",    POPUP_W, 1)
    bar("BOTTOMLEFT", POPUP_W, 1)
    local _, _, _, _, _, h = frame:GetRect() -- may not be set yet; we just need 4 lines
    bar("TOPLEFT",  1, 2000)
    bar("TOPRIGHT", 1, 2000)
end

local function fs(parent, size, str)
    local f = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f:SetFont(f:GetFont(), size or 12, "")
    f:SetText(str or "")
    f:SetTextColor(col(COLOR.text))
    return f
end

local function makeBtn(parent, label, w, h)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w, h)

    local bg = solidTex(b, COLOR.btnBg)
    bg:SetAllPoints()
    b._bg = bg

    local hl = solidTex(b, COLOR.btnHover, "HIGHLIGHT")
    hl:SetAllPoints()

    local txt = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    txt:SetPoint("CENTER")
    txt:SetText(label)
    txt:SetTextColor(col(COLOR.text))
    b._txt = txt

    -- thin border lines
    local function edge(pt, ew, eh)
        local t = b:CreateTexture(nil, "BORDER")
        t:SetColorTexture(col(COLOR.border))
        t:SetSize(ew, eh)
        t:SetPoint(pt)
    end
    edge("TOPLEFT",    w, 1) ; edge("BOTTOMLEFT", w, 1)
    edge("TOPLEFT",    1, h) ; edge("TOPRIGHT",   1, h)

    return b
end

-- ── Marker selector ────────────────────────────────────────────────────────
-- rowCallbacks[rowIndex] is a mutable table; onChange reads from it so we can
-- update the callback without recreating the selector.

local function makeMarkerSelector(parent, rowIndex, rowCallbacks)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize((MARKER_SZ + 2) * 9, MARKER_SZ)

    local selOverlays = {}  -- highlight overlay per button index

    for i = 0, 8 do
        local btn = CreateFrame("Button", nil, f)
        btn:SetSize(MARKER_SZ, MARKER_SZ)
        btn:SetPoint("LEFT", f, "LEFT", i * (MARKER_SZ + 2), 0)

        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        if i == 0 then
            icon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
            icon:SetVertexColor(0.55, 0.55, 0.55)
        else
            icon:SetTexture(ns.MARKER_TEXTURES[i])
        end

        local sel = solidTex(btn, COLOR.markerSel, "OVERLAY")
        sel:SetAllPoints()
        sel:Hide()
        selOverlays[i] = sel

        local hl = solidTex(btn, COLOR.btnHover, "HIGHLIGHT")
        hl:SetAllPoints()

        local idx = i
        btn:SetScript("OnClick", function()
            f:SetMarker(idx)
            local cb = rowCallbacks[rowIndex]
            if cb then cb(idx) end
        end)
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(ns.MARKER_NAMES[idx] or "None", 1, 1, 1)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    function f:SetMarker(idx)
        for j = 0, 8 do
            if selOverlays[j] then
                if j == idx then selOverlays[j]:Show() else selOverlays[j]:Hide() end
            end
        end
    end

    function f:GetMarker()
        for j = 0, 8 do
            if selOverlays[j] and selOverlays[j]:IsShown() then return j end
        end
        return 0
    end

    return f
end

-- ── Player row ─────────────────────────────────────────────────────────────

local function makePlayerRow(parent, rowIndex, rowCallbacks)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(POPUP_W - PAD * 2, ROW_H)

    if rowIndex % 2 == 0 then
        local altBg = solidTex(row, COLOR.rowAlt)
        altBg:SetAllPoints()
    end

    local label = fs(row, 11)
    label:SetPoint("LEFT", row, "LEFT", 4, 0)
    label:SetWidth(88)
    label:SetJustifyH("LEFT")
    row._label = label

    local sub = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sub:SetFont(sub:GetFont(), 10, "")
    sub:SetPoint("LEFT", label, "RIGHT", 2, 0)
    sub:SetWidth(72)
    sub:SetJustifyH("LEFT")
    sub:SetTextColor(col(COLOR.subtext))
    row._sub = sub

    local sel = makeMarkerSelector(row, rowIndex, rowCallbacks)
    sel:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    row._sel = sel

    return row
end

-- ── Mode toggle ────────────────────────────────────────────────────────────

local function makeModeToggle(parent, onToggle)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(POPUP_W - PAD * 2, TOGGLE_H)

    local roleBtn = makeBtn(f, "Role-based", 118, 22)
    roleBtn:SetPoint("LEFT", f, "LEFT", 0, 0)

    local nameBtn = makeBtn(f, "Name-based", 118, 22)
    nameBtn:SetPoint("LEFT", roleBtn, "RIGHT", 4, 0)

    local function activate(mode)
        if mode == "ROLE" then
            roleBtn._bg:SetColorTexture(col(COLOR.btnActive))
            nameBtn._bg:SetColorTexture(col(COLOR.btnBg))
        else
            roleBtn._bg:SetColorTexture(col(COLOR.btnBg))
            nameBtn._bg:SetColorTexture(col(COLOR.btnActive))
        end
        if onToggle then onToggle(mode) end
    end

    roleBtn:SetScript("OnClick", function() activate("ROLE") end)
    nameBtn:SetScript("OnClick", function() activate("NAME") end)

    function f:SetMode(mode) activate(mode) end
    return f
end

-- ── Main popup ─────────────────────────────────────────────────────────────

local popup
local rows         = {}
local rowCallbacks = {}   -- rowCallbacks[i] = function(markerIdx) … end
local currentMembers     = {}
local currentAssignments = {}
local currentMode        = "ROLE"

local function buildPopup()
    popup = CreateFrame("Frame", "CheckMarkPopup", UIParent)
    popup:SetSize(POPUP_W, calcHeight(5))
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
    popup:SetFrameStrata("DIALOG")
    popup:SetMovable(true)
    popup:SetClampedToScreen(true)
    popup:EnableMouse(true)
    popup:Hide()

    -- Background
    local bg = solidTex(popup, COLOR.bg)
    bg:SetAllPoints()

    -- ── Title bar ──────────────────────────────────────────────────────────
    local titleBar = CreateFrame("Frame", nil, popup)
    titleBar:SetPoint("TOPLEFT")
    titleBar:SetPoint("TOPRIGHT")
    titleBar:SetHeight(TITLE_H)
    titleBar:EnableMouse(true)
    titleBar:SetScript("OnMouseDown", function(_, btn)
        if btn == "LeftButton" then popup:StartMoving() end
    end)
    titleBar:SetScript("OnMouseUp", function()
        popup:StopMovingOrSizing()
        if ns.db then
            local pt, _, rpt, x, y = popup:GetPoint(1)
            if pt then
                ns.db.popup_position = { point=pt, relativePoint=rpt, x=x, y=y }
            end
        end
    end)

    local titleBg = solidTex(titleBar, COLOR.titleBg)
    titleBg:SetAllPoints()

    local titleTxt = fs(titleBar, 13, "CheckMark")
    titleTxt:SetPoint("LEFT", titleBar, "LEFT", PAD, 0)
    titleTxt:SetTextColor(col(COLOR.accent))

    local groupInfoTxt = fs(titleBar, 11, "")
    groupInfoTxt:SetPoint("LEFT", titleTxt, "RIGHT", 8, 0)
    groupInfoTxt:SetTextColor(col(COLOR.subtext))
    popup._groupInfo = groupInfoTxt

    local closeBtn = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -2, 0)
    closeBtn:SetScript("OnClick", function() ns.hidePopup() end)

    local div = solidTex(titleBar, COLOR.border, "ARTWORK")
    div:SetHeight(1) ; div:SetPoint("BOTTOMLEFT") ; div:SetPoint("BOTTOMRIGHT")

    -- ── Mode toggle ────────────────────────────────────────────────────────
    local modeToggle = makeModeToggle(popup, function(mode)
        currentMode = mode
        if ns.db then ns.db.last_mode = mode end
        ns.refreshPopup()
    end)
    modeToggle:SetPoint("TOPLEFT", popup, "TOPLEFT", PAD, -(TITLE_H + 4))
    popup._modeToggle = modeToggle

    local div2 = solidTex(popup, COLOR.border, "ARTWORK")
    div2:SetHeight(1)
    div2:SetPoint("TOPLEFT",  popup, "TOPLEFT",  0, -(TITLE_H + TOGGLE_H + 6))
    div2:SetPoint("TOPRIGHT", popup, "TOPRIGHT", 0, -(TITLE_H + TOGGLE_H + 6))

    -- ── Player rows ────────────────────────────────────────────────────────
    for i = 1, 5 do
        local row = makePlayerRow(popup, i, rowCallbacks)
        row:SetPoint("TOPLEFT", popup, "TOPLEFT", PAD,
            -(TITLE_H + TOGGLE_H + 8 + (i - 1) * ROW_H))
        row:Hide()
        rows[i] = row
    end

    -- ── Footer ─────────────────────────────────────────────────────────────
    local div3 = solidTex(popup, COLOR.border, "ARTWORK")
    div3:SetHeight(1)
    div3:SetPoint("BOTTOMLEFT",  popup, "BOTTOMLEFT",  0, FOOTER_H)
    div3:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", 0, FOOTER_H)

    -- Secure Apply / Clear buttons (user must click these directly)
    local applySecure, clearSecure = ns.getSecureButtons()
    applySecure:SetParent(popup)
    applySecure:SetSize(72, 24)
    applySecure:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", PAD, 8)
    applySecure:SetFrameLevel(popup:GetFrameLevel() + 5)
    -- Visual label on top (non-interactive, just text)
    local applyLbl = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    applyLbl:SetText("Apply")
    applyLbl:SetTextColor(col(COLOR.text))
    applyLbl:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", PAD + 24, 16)
    -- Background behind the button (cosmetic)
    local applyBg = solidTex(popup, COLOR.btnBg, "ARTWORK")
    applyBg:SetSize(72, 24)
    applyBg:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", PAD, 8)

    clearSecure:SetParent(popup)
    clearSecure:SetSize(56, 24)
    clearSecure:SetPoint("LEFT", applySecure, "RIGHT", 4, 0)
    clearSecure:SetFrameLevel(popup:GetFrameLevel() + 5)
    local clearBg = solidTex(popup, COLOR.btnBg, "ARTWORK")
    clearBg:SetSize(56, 24)
    clearBg:SetPoint("LEFT", applyBg, "RIGHT", 4, 0)
    local clearLbl = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    clearLbl:SetText("Clear")
    clearLbl:SetTextColor(col(COLOR.text))
    clearLbl:SetPoint("LEFT", applyLbl, "RIGHT", 18, 0)

    -- Save button
    local saveBtn = makeBtn(popup, "Save", 50, 24)
    saveBtn:SetPoint("LEFT", clearBg, "RIGHT", 4, 0)
    saveBtn:SetPoint("BOTTOM", popup, "BOTTOM", 0, 8)
    saveBtn:SetScript("OnClick", function()
        if not ns.db then return end
        for _, m in ipairs(currentMembers) do
            local marker = currentAssignments[m.fullName] or 0
            ns.saveNameTemplate(m.fullName, marker)
        end
        local sig = ns.getGroupSignature()
        local copy = {}
        for k, v in pairs(currentAssignments) do copy[k] = v end
        ns.saveRememberedGroup(sig, currentMode, copy)
        print("|cff62ade3CheckMark:|r Assignments saved.")
    end)

    -- Options button
    local optBtn = makeBtn(popup, "Options", 60, 24)
    optBtn:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -PAD, 8)
    optBtn:SetScript("OnClick", function()
        if ns.showOptions then ns.showOptions() end
    end)

    -- Outer border
    local bT = solidTex(popup, COLOR.border, "BORDER")
    bT:SetHeight(1) ; bT:SetPoint("TOPLEFT") ; bT:SetPoint("TOPRIGHT")
    local bB = solidTex(popup, COLOR.border, "BORDER")
    bB:SetHeight(1) ; bB:SetPoint("BOTTOMLEFT") ; bB:SetPoint("BOTTOMRIGHT")
    local bL = solidTex(popup, COLOR.border, "BORDER")
    bL:SetWidth(1) ; bL:SetPoint("TOPLEFT") ; bL:SetPoint("BOTTOMLEFT")
    local bR = solidTex(popup, COLOR.border, "BORDER")
    bR:SetWidth(1) ; bR:SetPoint("TOPRIGHT") ; bR:SetPoint("BOTTOMRIGHT")
end

-- ── Refresh ────────────────────────────────────────────────────────────────

function ns.refreshPopup()
    if not popup or not popup:IsShown() then return end

    currentMembers    = ns.getGroupMembers()
    currentAssignments = ns.buildDefaultAssignments(currentMode, currentMembers)

    -- Group info
    local zone = GetRealZoneText() or ""
    popup._groupInfo:SetText(
        #currentMembers.." player"..(#currentMembers ~= 1 and "s" or "")
        ..(zone ~= "" and (" \xE2\x80\x94 "..zone) or ""))

    popup._modeToggle:SetMode(currentMode)

    -- Hide all rows
    for _, r in ipairs(rows) do r:Hide() end

    -- Wire row callbacks (mutable so selectors already reference the table)
    for i = 1, 5 do rowCallbacks[i] = nil end

    local numRows = 0

    if currentMode == "ROLE" then
        local slotToMember = ns.assignRoleSlots(currentMembers)
        for i, slot in ipairs(ns.ROLE_SLOTS) do
            local m   = slotToMember[slot]
            local row = rows[i]
            row._label:SetText(ns.ROLE_SLOT_LABELS[slot])
            if m then
                row._sub:SetText(m.name)
                row._sel:SetMarker(currentAssignments[m.fullName] or 0)
                local fullName = m.fullName
                rowCallbacks[i] = function(idx)
                    currentAssignments[fullName] = idx
                    ns.rebuildSecureButtons(currentMembers, currentAssignments)
                end
            else
                row._sub:SetText("\xe2\x80\x94")
                row._sel:SetMarker(0)
            end
            row:Show()
            numRows = i
        end
    else  -- NAME
        for i, m in ipairs(currentMembers) do
            if i > 5 then break end
            local row = rows[i]
            row._label:SetText(m.name)
            local roleLabel = (m.role == "TANK" and "Tank")
                           or (m.role == "HEALER" and "Healer")
                           or (m.role == "DAMAGER" and "DPS")
                           or ""
            row._sub:SetText(roleLabel)
            row._sel:SetMarker(currentAssignments[m.fullName] or 0)
            local fullName = m.fullName
            rowCallbacks[i] = function(idx)
                currentAssignments[fullName] = idx
                ns.rebuildSecureButtons(currentMembers, currentAssignments)
            end
            row:Show()
            numRows = i
        end
    end

    -- Resize popup to fit actual rows
    local h = calcHeight(math.max(numRows, 1))
    popup:SetHeight(h)

    ns.rebuildSecureButtons(currentMembers, currentAssignments)
end

-- ── Show / Hide / Toggle ───────────────────────────────────────────────────

function ns.showPopup()
    if not popup then buildPopup() end

    if ns.db and ns.db.popup_position then
        local p = ns.db.popup_position
        popup:ClearAllPoints()
        popup:SetPoint(p.point or "CENTER", UIParent,
            p.relativePoint or "CENTER", p.x or 0, p.y or 0)
    end

    currentMode = (ns.db and ns.db.last_mode) or "ROLE"
    popup:Show()

    local a, c = ns.getSecureButtons()
    a:Show() ; c:Show()

    ns.refreshPopup()
end

function ns.hidePopup()
    if not popup then return end
    popup:Hide()
    local a, c = ns.getSecureButtons()
    a:Hide() ; c:Hide()
end

function ns.togglePopup()
    if popup and popup:IsShown() then ns.hidePopup() else ns.showPopup() end
end

function ns.onAddonLoaded()
    -- popup is built lazily on first show
end
