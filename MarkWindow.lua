local addon, ns = ...

-- The "notice me" window the reminder opens: a quip and one big card per
-- party member, side by side. Each card is its own secure raid-target
-- button, like a grid cell: one click marks that person. The game hides
-- party markers from addons, so a ticked card means "you clicked it", never
-- "they're marked".
--
-- Combat: a secure state handler hides the window as combat starts (Lua
-- can't touch protected frames then). If you hadn't clicked everyone, the
-- reminder reopens it after combat with your ticks kept.

local MarkWindow = { cards = {}, clicked = {}, token = 0 }
ns.MarkWindow = MarkWindow

local MAX = 5
local CARD_W, CARD_H, GAP, PAD, HEADER = 100, 132, 8, 16, 36
local MIN_WIDTH = 440
MarkWindow.SIZES = { SMALL = 0.85, MEDIUM = 1, LARGE = 1.2 }
MarkWindow.SIZE_VALUES = { "SMALL", "MEDIUM", "LARGE" }
MarkWindow.SIZE_LABELS = { "Small", "Medium", "Large" }

local SAMPLE = {
    { first = "Brakka", role = "TANK" }, { first = "Seliora", role = "HEALER" },
    { first = "Tamsin", role = "DAMAGER" }, { first = "Oduu", role = "DAMAGER" }, { first = "Pip", role = "DAMAGER" },
}

local function inCombat() return InCombatLockdown and InCombatLockdown() end
local function markerName(marker) return ns.MARKER_NAMES[marker] or "None" end

local function sampleMembers()
    local members = {}
    for index, sample in ipairs(SAMPLE) do
        members[index] = { unit = "sample" .. index, first = sample.first, full = sample.first, label = sample.first,
            role = sample.role, key = "sample:" .. sample.first:lower(), fullName = "sample:" .. sample.first, sample = true }
    end
    return members
end

MarkWindow.SampleMembers = sampleMembers

-- Card -----------------------------------------------------------------------------

local function slotKey(slot) return slot and ns.Assign.KeyFor(slot.member) end

local function cardTooltip(card)
    local slot = card.slot
    if not slot then return end
    local member = slot.member
    GameTooltip:SetOwner(card, "ANCHOR_TOP")
    GameTooltip:SetText(member.full or member.label or "?", 1, 0.82, 0)
    local tag = member.tag or ns.Identity.TagFor(member.guid)
    if tag then GameTooltip:AddLine("Battle.net friend: " .. tag, 0.55, 0.78, 1) end
    if slot.marker > 0 then
        GameTooltip:AddLine(markerName(slot.marker) .. " (" .. ns.Assign.SOURCE_LABELS[slot.source] .. ")", 1, 1, 1)
    end
    if slot.wanted and slot.wanted ~= slot.marker then
        GameTooltip:AddLine(markerName(slot.wanted) .. " was taken by someone else.", 0.85, 0.85, 0.85)
    end
    if slot.marker > 0 and MarkWindow.clicked[slotKey(slot)] == slot.marker then GameTooltip:AddLine("Clicked", 0.4, 0.9, 0.4) end
    if slot.marker > 0 then
        GameTooltip:AddLine("Click: mark with " .. markerName(slot.marker), 0.85, 0.85, 0.85)
        GameTooltip:AddLine("Right-click: clear their marker", 0.85, 0.85, 0.85)
    end
    GameTooltip:AddLine("Click the icon to choose another marker", 0.85, 0.85, 0.85)
    GameTooltip:Show()
end

local picker

local function openPicker(card)
    local HC = ns.HammerCore
    local T = HC.Theme
    if not picker then
        picker = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        picker:SetSize(170, 8 * 26 + 10)
        picker:SetFrameStrata("FULLSCREEN_DIALOG")
        picker:SetClampedToScreen(true)
        T.Surface(picker, "menu", "menuEdge")
        picker.items = {}
        for marker = 1, 8 do
            local item = CreateFrame("Button", nil, picker, "BackdropTemplate")
            item:SetSize(160, 24)
            item:SetPoint("TOPLEFT", 5, -5 - (marker - 1) * 26)
            T.Surface(item, "rail")
            local icon = item:CreateTexture(nil, "ARTWORK")
            icon:SetSize(18, 18); icon:SetPoint("LEFT", 6, 0); icon:SetTexture(ns.MARKER_TEXTURES[marker])
            local label = item:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            label:SetPoint("LEFT", 30, 0); label:SetText(markerName(marker))
            item.note = item:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
            item.note:SetPoint("RIGHT", -6, 0)
            item:SetScript("OnClick", function()
                picker:Hide()
                MarkWindow:Choose(picker.slot, marker)
            end)
            item:HookScript("OnEnter", function() item:SetBackdropColor(T.Unpack("menuActive")) end)
            item:HookScript("OnLeave", function() item:SetBackdropColor(T.Unpack("rail")) end)
            picker.items[marker] = item
        end
        picker:SetScript("OnUpdate", function(self)
            if not self:IsMouseOver() and IsMouseButtonDown and IsMouseButtonDown("LeftButton") then self:Hide() end
        end)
        picker:Hide()
    end
    picker.slot = card.slot
    local owners = {}
    for _, other in ipairs(MarkWindow.plan or {}) do
        if other ~= card.slot and other.marker > 0 then owners[other.marker] = other.member.label end
    end
    for marker, item in ipairs(picker.items) do item.note:SetText(owners[marker] or "") end
    picker:ClearAllPoints()
    picker:SetPoint("TOP", card.icon, "BOTTOM", 0, -4)
    picker:Show()
end

local function makeCard(parent, index)
    local HC = ns.HammerCore
    local T, UI = HC.Theme, HC.UI
    local card = CreateFrame("Button", "CheckMarkMarkCard" .. index, parent, "SecureActionButtonTemplate,BackdropTemplate")
    card:SetSize(CARD_W, CARD_H)
    card:SetAttribute("useOnKeyDown", false)
    card:RegisterForClicks("AnyUp")
    T.Surface(card, "rail", "edge")
    card.glow = T.Fill(card:CreateTexture(nil, "BORDER"), "accent")
    card.glow:SetAllPoints(); card.glow:SetAlpha(0.12); card.glow:Hide()

    card.icon = card:CreateTexture(nil, "ARTWORK")
    card.icon:SetSize(44, 44)
    card.icon:SetPoint("TOP", 0, -18)
    -- The icon is its own (insecure) button: it opens the marker picker.
    card.iconButton = CreateFrame("Button", nil, card)
    card.iconButton:SetAllPoints(card.icon)
    card.iconButton:SetFrameLevel(card:GetFrameLevel() + 3)
    card.iconButton:SetScript("OnClick", function() openPicker(card) end)
    card.iconButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(card.iconButton, "ANCHOR_TOP")
        GameTooltip:SetText("Choose a marker")
        GameTooltip:AddLine("CheckMark remembers what you pick for " .. ((card.slot and card.slot.member.label) or "them") .. ".", 0.85, 0.85, 0.85, true)
        GameTooltip:Show()
    end)
    card.iconButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    card.pin = CreateFrame("Button", nil, card)
    card.pin:SetSize(18, 18)
    card.pin:SetPoint("TOPRIGHT", -4, -4)
    card.pin:SetFrameLevel(card:GetFrameLevel() + 3)
    card.pin.tex = card.pin:CreateTexture(nil, "ARTWORK")
    card.pin.tex:SetAllPoints()
    card.pin.tex:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    card.pin:SetScript("OnClick", function() MarkWindow:TogglePin(card.slot) end)
    card.pin:SetScript("OnEnter", function()
        local slot = card.slot
        if not slot then return end
        GameTooltip:SetOwner(card.pin, "ANCHOR_TOP")
        local name = slot.member.label or "them"
        if ns.Assign.IsPinned(slot.member) then
            GameTooltip:SetText("Pinned")
            GameTooltip:AddLine("Click to unpin " .. name .. ".", 0.85, 0.85, 0.85)
        else
            GameTooltip:SetText("Pin " .. name)
            local account = slot.member.tag or ns.Identity.TagFor(slot.member.guid)
            GameTooltip:AddLine("Always give " .. name .. " " .. markerName(slot.marker)
                .. (account and " on any of their characters." or "."), 0.85, 0.85, 0.85, true)
        end
        GameTooltip:Show()
    end)
    card.pin:SetScript("OnLeave", function() GameTooltip:Hide() end)

    card.tick = card:CreateTexture(nil, "OVERLAY")
    card.tick:SetSize(18, 18)
    card.tick:SetPoint("TOPLEFT", 4, -4)
    card.tick:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")

    card.name = T.Font(UI.FontString(card, "GameFontNormal", "text"), 13)
    card.name:SetPoint("TOP", card.icon, "BOTTOM", 0, -8)
    card.name:SetWidth(CARD_W - 8)
    card.marker = UI.FontString(card, "GameFontHighlightSmall", "text")
    card.marker:SetPoint("TOP", card.name, "BOTTOM", 0, -4)
    card.source = UI.FontString(card, "GameFontHighlightSmall", "muted")
    card.source:SetPoint("TOP", card.marker, "BOTTOM", 0, -2)

    card:HookScript("PostClick", function(self, button) MarkWindow:Clicked(self, button) end)
    card:HookScript("OnEnter", function(self) self.glow:Show(); cardTooltip(self) end)
    card:HookScript("OnLeave", function(self) self.glow:Hide(); GameTooltip:Hide() end)
    return card
end

local function paintCard(card, slot)
    local T = ns.HammerCore.Theme
    card.slot = slot
    local member = slot.member
    card.name:SetText(member.label or member.first or "?")
    if slot.marker > 0 then
        card.icon:SetTexture(ns.MARKER_TEXTURES[slot.marker]); card.icon:SetVertexColor(1, 1, 1, 1)
        card.marker:SetText(markerName(slot.marker))
    else
        card.icon:SetTexture("Interface\\Buttons\\UI-PlusButton-UP"); card.icon:SetVertexColor(0.6, 0.6, 0.6, 1)
        card.marker:SetText("No marker")
    end
    card.source:SetText(ns.Assign.SOURCE_LABELS[slot.source] or "")
    -- Ticked only for the marker you clicked: a profile switch that changes
    -- someone's marker un-ticks them.
    local clicked = slot.marker > 0 and MarkWindow.clicked[slotKey(slot)] == slot.marker
    card.tick:SetShown(clicked)
    card:SetAlpha(clicked and 0.5 or 1)
    local pinned = ns.Assign.IsPinned(member)
    card.pin.tex:SetAlpha(pinned and 1 or 0.25)
    if card.SetBackdropBorderColor then card:SetBackdropBorderColor(T.Unpack(pinned and "accent" or "edge")) end
end

-- Window ---------------------------------------------------------------------------

function MarkWindow:Create()
    if self.window then return self.window end
    local HC = ns.HammerCore
    local UI, T = HC.UI, HC.Theme
    local win = CreateFrame("Frame", "CheckMarkMarkWindow", UIParent, "BackdropTemplate,SecureHandlerStateTemplate")
    win:SetFrameStrata("DIALOG")
    win:SetToplevel(true)
    win:SetClampedToScreen(true)
    win:SetMovable(true)
    win:EnableMouse(true)
    T.Surface(win, "outer", "edge")
    win:Hide()
    -- Combat closes it from the secure side; Lua reopens it afterwards.
    win:SetAttribute("_onstate-combat", [[ if newstate == "on" then self:Hide() end ]])
    if RegisterStateDriver then RegisterStateDriver(win, "combat", "[combat] on; off") end
    win:SetScript("OnHide", function()
        if picker then picker:Hide() end
        if not MarkWindow.closing and not MarkWindow.test and not MarkWindow:AllClicked() then
            MarkWindow.interrupted = true
        end
        MarkWindow.closing = nil
    end)

    local bar = CreateFrame("Frame", nil, win)
    bar:SetPoint("TOPLEFT", 1, -1)
    bar:SetPoint("TOPRIGHT", -1, -1)
    bar:SetHeight(HEADER)
    T.Fill(bar:CreateTexture(nil, "BACKGROUND"), "header"):SetAllPoints()
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function() if not inCombat() then win:StartMoving() end end)
    bar:SetScript("OnDragStop", function()
        if inCombat() then return end
        win:StopMovingOrSizing()
        local from, _, to, x, y = win:GetPoint()
        ns.db.mark_window_point = { from, to, x, y }
    end)
    local title = T.Font(UI.FontString(bar, "GameFontNormalLarge", "text"), 15)
    title:SetPoint("LEFT", PAD, 0)
    title:SetText("CheckMark")
    local close = UI.CloseButton(bar, function() MarkWindow:Close() end, 22)
    close:SetPoint("RIGHT", -8, 0)

    local quip = T.Font(UI.FontString(win, "GameFontNormalLarge", "accent"), 16)
    quip:SetPoint("TOPLEFT", PAD, -(HEADER + 14))
    quip:SetPoint("TOPRIGHT", -PAD, -(HEADER + 14))
    quip:SetJustifyH("CENTER")
    local status = UI.FontString(win, "GameFontHighlightSmall", "muted")
    status:SetPoint("TOP", quip, "BOTTOM", 0, -6)

    local cards = CreateFrame("Frame", nil, win)
    cards:SetPoint("TOP", 0, -(HEADER + 64))
    for index = 1, MAX do self.cards[index] = makeCard(cards, index) end

    local hint = UI.FontString(win, "GameFontHighlightSmall", "muted")
    hint:SetPoint("TOP", cards, "BOTTOM", 0, -10)
    hint:SetText("Click a card to mark · Right-click clears · Click the icon to change")

    local later = UI.Button(win, 84, 24)
    later:SetPoint("BOTTOMRIGHT", -PAD, 12)
    later:SetText("Later")
    later:SetScript("OnClick", function() MarkWindow:Close() end)
    UI.AttachHint(later, "Later", "Close this window. The grid is still there when you're ready.")

    local profile = UI.FontString(win, "GameFontHighlightSmall", "muted")
    profile:SetPoint("BOTTOMLEFT", PAD, 18)
    local link = UI.Link(win, "Change markers", function()
        HC.Settings:Focus("Markers", "Who goes first")
    end)
    link:SetPoint("LEFT", profile, "RIGHT", 10, 0)

    self.window = win
    self.parts = { quip = quip, status = status, cards = cards, hint = hint, profile = profile, link = link }
    self:Place()
    return win
end

function MarkWindow:Place()
    local win, point = self.window, ns.db.mark_window_point
    win:ClearAllPoints()
    if type(point) == "table" and point[1] then
        win:SetPoint(point[1], UIParent, point[2], point[3], point[4])
    else
        win:SetPoint("CENTER", UIParent, "CENTER", 0, 140)
    end
end

function MarkWindow:IsShown() return self.window and self.window:IsShown() or false end

function MarkWindow:AllClicked()
    local any = false
    for _, slot in ipairs(self.plan or {}) do
        if slot.marker > 0 then
            any = true
            if self.clicked[slotKey(slot)] ~= slot.marker then return false end
        end
    end
    return any
end

function MarkWindow:Members()
    if self.test then return sampleMembers() end
    return ns.getGroupMembers()
end

function MarkWindow:Refresh()
    if not self.window then return end
    local parts = self.parts
    local members = ns.Identity.Label(self:Members())
    self.plan = ns.Assign.Plan(members)
    local count = math.min(MAX, #self.plan)
    local width = count * CARD_W + math.max(0, count - 1) * GAP
    parts.cards:SetSize(math.max(1, width), CARD_H)
    for index, card in ipairs(self.cards) do
        local slot = self.plan[index]
        if slot and index <= count then
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT", parts.cards, "TOPLEFT", (index - 1) * (CARD_W + GAP), 0)
            paintCard(card, slot)
            card:Show()
        else
            card.slot = nil
            card:Hide()
        end
    end
    if not self.test then
        if not inCombat() then
            local bound = {}
            for index = 1, count do bound[index] = self.plan[index].member end
            ns.bindMarkerCells(self.cards, bound, ns.Assign.Markers(self.plan))
        end
    end
    parts.quip:SetText(self.quip or "")
    local other = ns.Share and ns.Share:OtherMarker()
    if self.test then
        parts.status:SetText("A sample party. These cards can't mark anyone.")
    elseif other then
        parts.status:SetText(other.name .. "'s marked this party.")
    else
        parts.status:SetText("")
    end
    local active = ns.HammerCore.Profiles.enabled and ns.HammerCore.Profiles:Active()
    parts.profile:SetText(active and (active .. " profile ·") or "")
    self.window:SetSize(math.max(MIN_WIDTH, width + PAD * 2), HEADER + 64 + CARD_H + 76)
    self.window:SetScale(self.SIZES[ns.db.remind_window_size] or 1)
end

function MarkWindow:StartTimeout()
    self.token = self.token + 1
    local token = self.token
    if ns.db.remind_timeout and C_Timer and C_Timer.After then
        C_Timer.After(tonumber(ns.db.remind_timeout_seconds) or 20, function()
            if MarkWindow.token == token and MarkWindow:IsShown() then MarkWindow:Close() end
        end)
    end
end

-- Opens for a new reminder; returns whether it showed.
function MarkWindow:Open(quip)
    if inCombat() or not (ns.isEligibleGroup and ns.isEligibleGroup()) then return false end
    self:Create()
    self.test, self.interrupted, self.quip = false, false, quip
    self.clicked = {}
    self:Refresh()
    if self.window.Raise then self.window:Raise() end
    self.window:Show()
    self:StartTimeout()
    return true
end

-- Back after combat, ticks kept.
function MarkWindow:Reopen()
    if not self.interrupted or inCombat() then return false end
    self.interrupted = false
    if not (ns.isEligibleGroup and ns.isEligibleGroup()) then return false end
    self:Create()
    self:Refresh()
    if self:AllClicked() then return false end
    self.window:Show()
    self:StartTimeout()
    return true
end

function MarkWindow:Test(quip)
    if inCombat() then return false end
    self:Create()
    self.test, self.interrupted, self.quip = true, false, quip
    self.clicked = {}
    for _, card in ipairs(self.cards) do
        for _, key in ipairs({ "type1", "unit1", "marker1", "action1", "type2", "unit2", "action2" }) do
            card:SetAttribute(key, nil)
        end
    end
    self:Refresh()
    self.window:Show()
    self:StartTimeout()
    return true
end

function MarkWindow:Close()
    if not self.window or inCombat() then return end
    if not self.window:IsShown() then self.interrupted = false; return end
    self.closing, self.interrupted = true, false
    if picker then picker:Hide() end
    self.window:Hide()
end

function MarkWindow:Clicked(card, button)
    local slot = card.slot
    if not slot then return end
    local key = slotKey(slot)
    if button == "RightButton" then
        if key then self.clicked[key] = nil end
    elseif slot.marker > 0 then
        if key then self.clicked[key] = slot.marker end
        if ns.playMarkerSound then ns.playMarkerSound() end
        if not self.test then ns.Assign.Marked(slot) end
    else
        return
    end
    paintCard(card, slot)
    if self:AllClicked() and ns.db.remind_close_done ~= false and C_Timer and C_Timer.After then
        local token = self.token
        C_Timer.After(0.6, function()
            if MarkWindow.token == token and MarkWindow:IsShown() and MarkWindow:AllClicked() then MarkWindow:Close() end
        end)
    end
end

function MarkWindow:Choose(slot, marker)
    if not slot or inCombat() then return end
    if self.test then
        ns.Assign.picked[slotKey(slot)] = marker
    else
        ns.Assign.Pick(slot.member, marker)
    end
    self.clicked[slotKey(slot)] = nil
    self:Refresh()
    if ns.refreshPopup then ns.refreshPopup() end
end

function MarkWindow:TogglePin(slot)
    if not slot or slot.marker <= 0 then return end
    if self.test then return ns.HammerCore.Print("pins work on a real party, not the sample") end
    if ns.Assign.IsPinned(slot.member) then ns.Assign.Unpin(slot.member) else ns.Assign.Pin(slot.member, slot.marker) end
    self:Refresh()
    if ns.HammerCore.Settings:IsShown() then ns.HammerCore.Settings:Select(ns.HammerCore.Settings.selected) end
end

-- The party changed while the window is open.
function MarkWindow:RosterChanged()
    if not self:IsShown() or self.test or inCombat() then return end
    if not (ns.isEligibleGroup and ns.isEligibleGroup()) then self:Close(); return end
    self:Refresh()
end

function MarkWindow:OthersMarking()
    if self:IsShown() and not inCombat() then self:Refresh() end
end
