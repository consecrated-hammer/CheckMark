local addon, ns = ...

-- The live preview: CheckMark's grid at actual size in its own window, with
-- a sample party, like Salve's. It opens from the header button on pages
-- that change the grid, stays open while you change pages, and redraws as
-- settings change. Its cells are plain frames: nothing here can mark.

local Preview = {}
ns.Preview = Preview

local WINDOW_MIN_WIDTH, WINDOW_PAD, WINDOW_HEADER, WINDOW_CONTROLS = 360, 16, 40, 80
local HANDLE_ROOM = 14
local MAX_MEMBERS = 5
-- Sample party in role order, so each gets that role's marker.
local SAMPLE = {
    { name = "Brakka", slot = "TANK" }, { name = "Seliora", slot = "HEALER" },
    { name = "Tamsin", slot = "DPS1" }, { name = "Oduu", slot = "DPS2" }, { name = "Pip", slot = "DPS3" },
}

Preview.DEFAULTS = {
    preview_window_open = false,
    preview_window_on_top = true,
    preview_members = 5,
}

local function switch(parent, label, hint)
    local HC = ns.HammerCore
    local control = HC.UI.Switch(parent)
    control:SetSize(170, 26)
    control.Text:SetText(label)
    HC.UI.AttachHint(control, label, hint)
    return control
end

function Preview:Create()
    if self.window then return self.window end
    local HC = ns.HammerCore
    local UI, T = HC.UI, HC.Theme

    local win = CreateFrame("Frame", "CheckMarkLivePreview", UIParent, "BackdropTemplate")
    win:SetFrameStrata("DIALOG")
    win:SetToplevel(true)
    win:SetClampedToScreen(true)
    win:SetMovable(true)
    win:EnableMouse(true)
    T.Surface(win, "outer", "edge")
    win:Hide()
    local point = ns.db.preview_window_point
    if type(point) == "table" and point[1] then
        win:SetPoint(point[1], UIParent, point[2], point[3], point[4])
    else
        win:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 40, -120)
    end

    local bar = CreateFrame("Frame", nil, win)
    bar:SetPoint("TOPLEFT", 1, -1)
    bar:SetPoint("TOPRIGHT", -1, -1)
    bar:SetHeight(WINDOW_HEADER)
    T.Fill(bar:CreateTexture(nil, "BACKGROUND"), "header"):SetAllPoints()
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function() win:StartMoving() end)
    bar:SetScript("OnDragStop", function()
        win:StopMovingOrSizing()
        local from, _, to, x, y = win:GetPoint()
        ns.db.preview_window_point = { from, to, x, y }
    end)
    local title = T.Font(UI.FontString(bar, "GameFontNormalLarge", "text"), 16)
    title:SetPoint("LEFT", WINDOW_PAD, 0)
    title:SetText("Live preview")
    local close = UI.CloseButton(bar, function() Preview:Hide() end, 24)
    close:SetPoint("RIGHT", -8, 0)

    local controls = CreateFrame("Frame", nil, win)
    controls:SetPoint("TOPLEFT", 0, -WINDOW_HEADER)
    controls:SetPoint("TOPRIGHT", 0, -WINDOW_HEADER)
    controls:SetHeight(WINDOW_CONTROLS)

    -- Party size, - n +.
    local members = CreateFrame("Frame", nil, controls)
    members:SetSize(170, 26)
    members:SetPoint("TOPLEFT", WINDOW_PAD, -8)
    local membersLabel = UI.FontString(members, "GameFontHighlight", "text")
    membersLabel:SetPoint("LEFT")
    membersLabel:SetText("Party")
    local minus = UI.Button(members, 26, 24)
    minus:SetPoint("LEFT", membersLabel, "RIGHT", 12, 0)
    minus:SetText("-")
    local count = UI.FontString(members, "GameFontHighlight", "text")
    count:SetPoint("LEFT", minus, "RIGHT", 6, 0)
    count:SetWidth(26)
    count:SetJustifyH("CENTER")
    local plus = UI.Button(members, 26, 24)
    plus:SetPoint("LEFT", count, "RIGHT", 6, 0)
    plus:SetText("+")
    UI.AttachHint(minus, "Smaller party", "Preview fewer members.")
    UI.AttachHint(plus, "Bigger party", "Preview more members.")

    local openWith = switch(controls, "Open with settings", "Open this window whenever CheckMark's settings open.")
    openWith:SetPoint("TOPLEFT", controls, "TOP", 4, -8)
    local inFront = switch(controls, "Keep in front", "Keep this window above the settings window. Off, whichever you click comes to the front.")
    inFront:SetPoint("TOPLEFT", controls, "TOP", 4, -40)

    local note = UI.FontString(win, "GameFontHighlightSmall", "muted")
    note:SetPoint("TOPLEFT", WINDOW_PAD, -(WINDOW_HEADER + WINDOW_CONTROLS))
    note:SetPoint("RIGHT", -WINDOW_PAD, 0)
    note:SetJustifyH("LEFT")

    local viewport = CreateFrame("Frame", nil, win)
    viewport:SetPoint("TOPLEFT", WINDOW_PAD, -(WINDOW_HEADER + WINDOW_CONTROLS + 22))
    T.Fill(viewport:CreateTexture(nil, "BACKGROUND"), "rail"):SetAllPoints()
    if viewport.SetClipsChildren then viewport:SetClipsChildren(true) end

    local grid = CreateFrame("Frame", nil, viewport)
    grid:EnableMouse(false)
    local cells = {}
    for i = 1, MAX_MEMBERS do
        local cell = CreateFrame("Frame", nil, grid)
        ns.Grid.DressCell(cell)
        cell:Hide()
        cells[i] = cell
    end
    -- The drag handle, drawn as the grid draws it.
    local handle = CreateFrame("Frame", nil, grid)
    handle:SetSize(10, 10)
    local fill = handle:CreateTexture(nil, "ARTWORK")
    fill:SetAllPoints()
    fill:SetColorTexture(0.58, 0.43, 0.22, 0.85)
    local edge = handle:CreateTexture(nil, "BACKGROUND")
    edge:SetPoint("TOPLEFT", -1, 1)
    edge:SetPoint("BOTTOMRIGHT", 1, -1)
    edge:SetColorTexture(0, 0, 0, 0.9)

    self.window = win
    self.parts = { viewport = viewport, grid = grid, cells = cells, handle = handle, note = note,
        count = count, openWith = openWith, inFront = inFront }

    local function size(delta)
        local current = tonumber(ns.db.preview_members) or MAX_MEMBERS
        ns.db.preview_members = math.max(2, math.min(MAX_MEMBERS, current + delta))
        Preview:Refresh()
    end
    minus:SetScript("OnClick", function() size(-1) end)
    plus:SetScript("OnClick", function() size(1) end)
    openWith:SetScript("OnClick", function()
        ns.db.preview_window_open = not ns.db.preview_window_open
        Preview:Refresh()
    end)
    inFront:SetScript("OnClick", function()
        ns.db.preview_window_on_top = not ns.db.preview_window_on_top
        Preview:ApplyLayer()
        Preview:Refresh()
    end)
    return win
end

-- Keep in front: one layer above the settings window (DIALOG).
function Preview:ApplyLayer()
    if not self.window then return end
    self.window:SetFrameStrata(ns.db.preview_window_on_top ~= false and "FULLSCREEN" or "DIALOG")
    if self.window.Raise then self.window:Raise() end
end

function Preview:IsShown()
    return self.window and self.window:IsShown() or false
end

function Preview:Show()
    self:Create()
    self.window:Show()
    self:ApplyLayer()
    self:Refresh()
    local HC = ns.HammerCore
    if HC.Settings.RefreshHeaderAction then HC.Settings:RefreshHeaderAction() end
end

function Preview:Hide()
    if self.window then self.window:Hide() end
    local HC = ns.HammerCore
    if HC and HC.Settings and HC.Settings.RefreshHeaderAction then HC.Settings:RefreshHeaderAction() end
end

function Preview:Toggle()
    if self:IsShown() then self:Hide() else self:Show() end
end

function Preview:Refresh()
    local parts = self.parts
    if not (parts and self.window:IsShown()) then return end
    local db = ns.db
    local count = math.max(2, math.min(MAX_MEMBERS, tonumber(db.preview_members) or MAX_MEMBERS))
    parts.count:SetText(tostring(count))
    parts.openWith:SetChecked(db.preview_window_open == true)
    parts.inFront:SetChecked(db.preview_window_on_top ~= false)

    local layout = ns.Grid.Layout(count)
    parts.grid:SetSize(layout.frameWidth, layout.frameHeight)
    for i, cell in ipairs(parts.cells) do
        local sample = SAMPLE[i]
        if i <= count then
            local n = i - 1
            local col, row = n % layout.columns, math.floor(n / layout.columns)
            cell:SetSize(layout.width, layout.height)
            cell:ClearAllPoints()
            cell:SetPoint("TOPLEFT", parts.grid, "TOPLEFT", col * (layout.width + layout.spacing),
                -row * (layout.height + layout.spacing))
            ns.Grid.PaintCell(cell, ns.getRoleMarker(sample.slot), sample.name)
            cell:Show()
        else
            cell:Hide()
        end
    end

    local handleShown = db.show_handle ~= false
    parts.handle:SetShown(handleShown)
    if handleShown then
        local p = ns.Grid.HandlePoints[db.handle_position] or ns.Grid.HandlePoints.TOP
        parts.handle:ClearAllPoints()
        parts.handle:SetPoint(p[1], parts.grid, p[2], p[3], p[4])
    end

    -- Actual size, unless the grid is bigger than most of the screen.
    local room = handleShown and HANDLE_ROOM * 2 or 0
    local naturalWidth, naturalHeight = layout.frameWidth + room, layout.frameHeight + room
    local screenWidth = UIParent.GetWidth and UIParent:GetWidth() or 0
    local screenHeight = UIParent.GetHeight and UIParent:GetHeight() or 0
    local fit = 1
    if screenWidth > 0 and screenHeight > 0 then
        fit = math.min(1, (screenWidth * 0.8) / math.max(1, naturalWidth), (screenHeight * 0.7) / math.max(1, naturalHeight))
    end
    local innerWidth = math.max(WINDOW_MIN_WIDTH - WINDOW_PAD * 2, naturalWidth * fit + 24)
    local innerHeight = math.max(80, naturalHeight * fit + 24)
    parts.viewport:SetSize(innerWidth, innerHeight)
    parts.grid:SetScale(fit)
    parts.grid:ClearAllPoints()
    parts.grid:SetPoint("CENTER", parts.viewport, "CENTER", 0, 0)
    self.window:SetSize(innerWidth + WINDOW_PAD * 2, WINDOW_HEADER + WINDOW_CONTROLS + 22 + innerHeight + WINDOW_PAD)
    parts.note:SetText(fit < 1 and ("Scaled to %d%% to fit your screen."):format(math.floor(fit * 100 + 0.5))
        or ("Actual size, %d members. Markers follow the Markers page."):format(count))
end

-- Redraw whenever the grid or its handle would.
local refreshPopup, updateHandle = ns.refreshPopup, ns.updateHandle
function ns.refreshPopup(...)
    refreshPopup(...)
    Preview:Refresh()
end
function ns.updateHandle(...)
    updateHandle(...)
    Preview:Refresh()
end
