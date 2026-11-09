local addon, ns = ...

-- The live surface deliberately follows Salve's compact grid: tiny direct
-- action cells, no window chrome, and one small handle for moving/options.

local T = ns.Theme
local panel, handle
local cells, currentMembers, currentAssignments = {}, {}, {}
local MAX_CELLS = 5

local function savePosition()
    local point, _, relativePoint, x, y = panel:GetPoint(1)
    ns.db.popup_position = { point = point, relativePoint = relativePoint, x = x, y = y }
end

local function markerName(marker) return ns.MARKER_NAMES[marker] or "Marker" end
local function roleLabel(member, slots)
    local slot = slots and slots[member.fullName]
    return slot and ns.ROLE_SLOT_LABELS[slot] or "Party member"
end

-- Shared with the live preview window (Preview.lua).
local function layout(count)
    local db = ns.db
    local columns = math.max(1, math.min(MAX_CELLS, tonumber(db.cell_columns) or 5))
    local width, height = math.max(14, tonumber(db.cell_width) or 20), math.max(14, tonumber(db.cell_height) or 20)
    local spacing = math.max(0, tonumber(db.cell_spacing) or 1)
    local across = math.min(math.max(1, count), columns)
    local down = math.ceil(math.max(1, count) / columns)
    return { columns = columns, width = width, height = height, spacing = spacing, across = across, down = down,
        frameWidth = across * width + math.max(0, across - 1) * spacing,
        frameHeight = down * height + math.max(0, down - 1) * spacing }
end

-- A cell's look, for live cells and the preview's plain copies alike.
local function paintCell(cell, marker, memberName)
    cell.name:SetText(ns.db.show_cell_names and memberName or "")
    cell.name:SetFont(cell.name:GetFont(), math.max(8, math.min(11, ns.db.cell_height - 5)), "")
    cell.icon:ClearAllPoints()
    cell.name:ClearAllPoints()
    local iconSize = math.max(10, tonumber(ns.db.icon_size) or 18)
    if ns.db.show_cell_names then
        cell.icon:SetSize(iconSize, iconSize)
        cell.icon:SetPoint("LEFT", cell, "LEFT", 2, 0)
        cell.name:SetPoint("LEFT", cell.icon, "RIGHT", 4, 0)
        cell.name:SetPoint("RIGHT", cell, "RIGHT", -3, 0)
        cell.name:SetJustifyH("LEFT")
    else
        cell.icon:SetSize(iconSize, iconSize)
        cell.icon:SetPoint("CENTER")
    end
    if marker > 0 then
        cell.icon:SetTexture(ns.MARKER_TEXTURES[marker]); cell.icon:SetVertexColor(1, 1, 1, 1)
        cell.border:SetBackdropBorderColor(0.55, 0.55, 0.55, 0.85)
    else
        cell.icon:SetTexture("Interface\\Buttons\\UI-PlusButton-UP"); cell.icon:SetVertexColor(unpack(T.muted))
        cell.border:SetBackdropBorderColor(unpack(T.edge))
    end
    cell.plate:SetVertexColor(0.18, 0.18, 0.18, 1)
end

-- The parts of a cell that draw, on any frame.
local function dressCell(cell)
    cell.plate = cell:CreateTexture(nil, "BACKGROUND"); cell.plate:SetAllPoints(); cell.plate:SetTexture("Interface\\TargetingFrame\\UI-StatusBar"); cell.plate:SetVertexColor(0.18, 0.18, 0.18, 1)
    cell.icon = cell:CreateTexture(nil, "ARTWORK"); cell.icon:SetAllPoints()
    cell.border = CreateFrame("Frame", nil, cell, "BackdropTemplate"); cell.border:SetPoint("TOPLEFT", -1, 1); cell.border:SetPoint("BOTTOMRIGHT", 1, -1); cell.border:SetFrameLevel(cell:GetFrameLevel() + 5); cell.border:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8 }); cell.border:EnableMouse(false)
    cell.name = cell:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); cell.name:SetPoint("TOPLEFT", 3, -1); cell.name:SetPoint("BOTTOMRIGHT", -3, 1); cell.name:SetJustifyH("LEFT"); cell.name:SetJustifyV("MIDDLE")
end

-- Where the handle sits for each Handle position: point, relative point, x, y.
local HANDLE_POINTS = {
    LEFT = { "RIGHT", "LEFT", -1, 0 },
    TOPLEFT = { "BOTTOMLEFT", "TOPLEFT", 0, 1 },
    TOP = { "BOTTOM", "TOP", 0, 1 },
    TOPRIGHT = { "BOTTOMRIGHT", "TOPRIGHT", 0, 1 },
    RIGHT = { "LEFT", "RIGHT", 1, 0 },
    BOTTOMRIGHT = { "TOPRIGHT", "BOTTOMRIGHT", 0, -1 },
    BOTTOM = { "TOP", "BOTTOM", 0, -1 },
    BOTTOMLEFT = { "TOPLEFT", "BOTTOMLEFT", 0, -1 },
}

ns.Grid = { Layout = layout, PaintCell = paintCell, DressCell = dressCell, HandlePoints = HANDLE_POINTS }

local function tooltip(cell)
    GameTooltip:SetOwner(cell, "ANCHOR_RIGHT")
    GameTooltip:SetText(cell.label or "CheckMark", unpack(T.accent))
    if cell.marker and cell.marker > 0 then
        GameTooltip:AddLine(markerName(cell.marker), 1, 1, 1)
        GameTooltip:AddLine("Click: apply " .. markerName(cell.marker), 0.85, 0.85, 0.85)
        GameTooltip:AddLine("Right-click: remove marker", 0.85, 0.85, 0.85)
    else
        GameTooltip:AddLine("No assignment", 0.85, 0.85, 0.85)
        GameTooltip:AddLine("Click: choose a marker", 0.85, 0.85, 0.85)
    end
    GameTooltip:Show()
end

local function makeCell(parent, index)
    local cell = CreateFrame("Button", "CheckMarkCell" .. index, parent, "SecureActionButtonTemplate,BackdropTemplate")
    cell:SetAttribute("useOnKeyDown", false); cell:RegisterForClicks("AnyUp")
    cell:HookScript("PostClick", function(self, button)
        -- The native secure raid-target action has just been submitted.  Keep
        -- feedback on the left-click set action only: right click clears a
        -- marker and an unassigned cell merely opens the marker settings.
        if self.marker and self.marker > 0 and button == "LeftButton" and ns.playMarkerSound then
            ns.playMarkerSound()
        end
        if self.marker == 0 and button == "LeftButton" then ns.HammerCore.Settings:Show("Markers") end
    end)
    cell:HookScript("OnEnter", tooltip); cell:HookScript("OnLeave", function() if GameTooltip:IsOwned(cell) then GameTooltip:Hide() end end)

    dressCell(cell)
    cells[index] = cell
    return cell
end


local function styleCell(cell, member, label)
    local marker = currentAssignments[member.fullName] or 0
    cell.marker = marker
    cell.label = label .. " · " .. member.name
    paintCell(cell, marker, member.name)
end

local function refreshCells()
    local grid = layout(#currentMembers)
    panel:SetSize(grid.frameWidth, grid.frameHeight)
    local _, slots = ns.assignRoleSlots(currentMembers)
    for i = 1, MAX_CELLS do
        local cell, member = cells[i], currentMembers[i]
        if member then
            local n = i - 1; local col, row = n % grid.columns, math.floor(n / grid.columns)
            cell:SetSize(grid.width, grid.height); cell:ClearAllPoints(); cell:SetPoint("TOPLEFT", panel, "TOPLEFT", col * (grid.width + grid.spacing), -row * (grid.height + grid.spacing))
            styleCell(cell, member, roleLabel(member, slots)); cell:Show()
        else cell:Hide() end
    end
    ns.bindMarkerCells(cells, currentMembers, currentAssignments)
    if ns.updateHandle then ns.updateHandle() end
end

local function buildHandle()
    handle = CreateFrame("Button", "CheckMarkHandle", panel)
    handle:SetSize(10, 10); handle:SetFrameLevel(panel:GetFrameLevel() + 20); handle:RegisterForDrag("LeftButton"); handle:EnableMouse(true)
    handle.tex = handle:CreateTexture(nil, "ARTWORK"); handle.tex:SetAllPoints(); handle.tex:SetColorTexture(0.58, 0.43, 0.22, 0.85)
    local edge = handle:CreateTexture(nil, "BACKGROUND"); edge:SetPoint("TOPLEFT", -1, 1); edge:SetPoint("BOTTOMRIGHT", 1, -1); edge:SetColorTexture(0, 0, 0, 0.9)
    handle:SetScript("OnDragStart", function(self) if not InCombatLockdown() then self.dragging = true; panel:StartMoving() end end)
    handle:SetScript("OnDragStop", function(self) if self.dragging and not InCombatLockdown() then self.dragging = nil; panel:StopMovingOrSizing(); savePosition() end end)
    handle:RegisterForClicks("RightButtonUp")
    handle:SetScript("OnClick", function(_, button) if button == "RightButton" then ns.HammerCore.Settings:Toggle() end end)
    handle:HookScript("OnEnter", function(self) self.tex:SetColorTexture(1, 0.82, 0.26, 1); GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText("CheckMark"); GameTooltip:AddLine("Drag: move the grid", 0.85, 0.85, 0.85); GameTooltip:AddLine("Right-click: settings", 0.85, 0.85, 0.85); GameTooltip:Show() end)
    handle:HookScript("OnLeave", function(self) self.tex:SetColorTexture(0.58, 0.43, 0.22, 0.85); GameTooltip:Hide() end)
end

function ns.updateHandle()
    if not handle or (InCombatLockdown and InCombatLockdown()) then return end
    handle:SetShown(ns.db.show_handle ~= false)
    handle:ClearAllPoints()
    local point = HANDLE_POINTS[ns.db.handle_position] or HANDLE_POINTS.TOP
    handle:SetPoint(point[1], panel, point[2], point[3], point[4])
end

local function buildPanel()
    panel = CreateFrame("Frame", "CheckMarkPanel", UIParent)
    -- Like Salve's live panel, the grid stays on the normal UI strata. The
    -- settings window is DIALOG, so it always opens above these action cells.
    panel:SetClampedToScreen(true); panel:SetMovable(true); panel:SetFrameStrata("MEDIUM"); panel:SetPoint("CENTER", UIParent, "CENTER", 250, 80); panel:Hide()
    for i = 1, MAX_CELLS do makeCell(panel, i) end
    buildHandle()
end

function ns.refreshPopup()
    if InCombatLockdown and InCombatLockdown() then return end
    if not panel or not panel:IsShown() then return end
    currentMembers = ns.getTemplateMembers(ns.getGroupMembers())
    currentAssignments = ns.buildDefaultAssignments(currentMembers)
    refreshCells()
end
-- Show conditions, on top of "in a two-to-five player party, out of
-- combat", which always applies. Ticking none means always. They're read
-- out of combat, on zone, leader and roster changes; combat hides the grid
-- regardless.
ns.GRID_CONDITIONS = {
    { key = "dungeon", label = "In a dungeon", test = function()
        local inside, kind = IsInInstance(); return inside and kind == "party" end },
    { key = "delve", label = "In a delve or scenario", test = function()
        local inside, kind = IsInInstance(); return inside and kind == "scenario" end },
    { key = "world", label = "In the open world", test = function() return not IsInInstance() end },
    { key = "leader", label = "As party leader", test = function()
        return UnitIsGroupLeader and UnitIsGroupLeader("player") or false end },
}

function ns.hasGridConditions()
    for _, condition in ipairs(ns.GRID_CONDITIONS) do
        if ns.db.visibility and ns.db.visibility[condition.key] then return true end
    end
    return false
end

function ns.gridConditionsMatch()
    if not ns.hasGridConditions() then return true end
    for _, condition in ipairs(ns.GRID_CONDITIONS) do
        if ns.db.visibility[condition.key] and condition.test() then return true end
    end
    return false
end

function ns.gridVisibilitySummary()
    if ns.db.visibility_mode == "HIDDEN" then return "Never" end
    local labels = {}
    for _, condition in ipairs(ns.GRID_CONDITIONS) do
        if ns.db.visibility and ns.db.visibility[condition.key] then labels[#labels + 1] = condition.label end
    end
    if #labels == 0 then return "Always" end
    if #labels > 2 then return #labels .. " conditions" end
    return table.concat(labels, ", ")
end

function ns.applyVisibility()
    if not panel or (InCombatLockdown and InCombatLockdown()) then return end
    UnregisterStateDriver(panel, "visibility")
    if ns.db.visibility_mode == "HIDDEN" or ns.db.panel_hidden or not ns.isEligibleGroup()
        or not ns.gridConditionsMatch() then
        RegisterStateDriver(panel, "visibility", "hide")
    else
        -- This is deliberately a secure state driver, like Salve's protected
        -- visibility: the action cells vanish exactly as combat begins.
        RegisterStateDriver(panel, "visibility", "[combat] hide; [group:party] show; hide")
    end
end
function ns.showPopup()
    if InCombatLockdown and InCombatLockdown() then ns.notify("CheckMark can't mark in combat. Try again once it's over."); return end
    if not ns.isEligibleGroup() then
        ns.notify("Form a two-to-five player party to prepare markers.")
        return
    end
    if not panel then buildPanel() end
    if ns.db.panel_hidden then ns.applyVisibility(); return end
    if ns.db.popup_position then local p = ns.db.popup_position; panel:ClearAllPoints(); panel:SetPoint(p.point or "CENTER", UIParent, p.relativePoint or "CENTER", p.x or 0, p.y or 0) end
    panel:Show(); ns.refreshPopup(); ns.updateHandle(); ns.applyVisibility()
end
function ns.hidePopup() if panel then panel:Hide() end end
function ns.togglePopup()
    if InCombatLockdown and InCombatLockdown() then
        ns.notify("CheckMark can't mark in combat. Try again once it's over.")
        return
    end
    if ns.db.panel_hidden or not (panel and panel:IsShown()) then
        ns.db.panel_hidden = false
        ns.showPopup()
    else
        ns.db.panel_hidden = true
        ns.applyVisibility()
    end
end
