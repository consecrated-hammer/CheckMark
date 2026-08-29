local addonName, ns = ...
local O = ns.Options

local function section(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(560, 1)
    frame.salveRefresh = parent.salveRefresh
    frame.salveRefreshAll = parent.salveRefreshAll
    return frame
end
local function refreshGrid() if ns.refreshPopup then ns.refreshPopup() end end

O.NewPage({ name = "CheckMark", title = "Panel", group = "CORE", description = "Shape the compact five-player pre-pull marker grid." }, function(panel)
    local db = ns.db
    local preview = panel.salveCreatePinned(164, 560)
    local py = -8
    _, py = O.Header(preview, "Preview", py)
    local stage = CreateFrame("Frame", nil, preview, "BackdropTemplate")
    stage:SetPoint("TOPLEFT", 16, py); stage:SetSize(528, 120)
    stage:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    stage:SetBackdropColor(unpack(O.theme.rail)); stage:SetBackdropBorderColor(unpack(O.theme.edge))
    local label = stage:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    label:SetPoint("TOPLEFT", 10, -8); label:SetText("LIVE PREVIEW"); label:SetTextColor(unpack(O.theme.muted))
    local fit = stage:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    fit:SetPoint("TOPRIGHT", -10, -8); fit:SetTextColor(unpack(O.theme.muted))
    local markers, names, cells = { 8, 3, 6, 4, 5 }, { "Tank", "Healer", "DPS 1", "DPS 2", "DPS 3" }, {}
    for i = 1, 5 do
        local cell = CreateFrame("Frame", nil, stage, "BackdropTemplate")
        cell:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        cell.icon = cell:CreateTexture(nil, "ARTWORK"); cell.name = cell:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        cells[i] = cell
    end
    local function renderPreview()
        local w, h = math.max(14, db.cell_width or 20), math.max(14, db.cell_height or 20)
        local gap, columns = math.max(0, db.cell_spacing or 1), math.max(1, math.min(5, db.cell_columns or 5))
        local rows, gridW = math.ceil(5 / columns), math.min(5, columns) * w + math.max(0, math.min(5, columns) - 1) * gap
        local gridH = rows * h + math.max(0, rows - 1) * gap
        local scale = math.min(1, 496 / gridW, 70 / gridH)
        local shownW, shownH, shownGap = w * scale, h * scale, gap * scale
        local left, top = -(gridW * scale) / 2, (gridH * scale) / 2 - 5
        fit:SetText(scale < 1 and "SCALED TO FIT" or "")
        for i, cell in ipairs(cells) do
            local n, col, row = i - 1, (i - 1) % columns, math.floor((i - 1) / columns)
            cell:ClearAllPoints(); cell:SetSize(shownW, shownH); cell:SetPoint("TOPLEFT", stage, "CENTER", left + col * (shownW + shownGap), top - row * (shownH + shownGap))
            cell:SetBackdropColor(unpack(O.theme.content)); cell:SetBackdropBorderColor(unpack(O.theme.edge)); cell.icon:ClearAllPoints(); cell.name:ClearAllPoints()
            local iconSize = math.max(10, math.floor((db.icon_size or 20) * scale + 0.5))
            if db.show_cell_names then
                cell.icon:SetSize(iconSize, iconSize); cell.icon:SetPoint("LEFT", 2, 0); cell.name:SetPoint("LEFT", cell.icon, "RIGHT", 4, 0); cell.name:SetPoint("RIGHT", -3, 0); cell.name:SetJustifyH("LEFT"); cell.name:SetText(names[i])
            else cell.icon:SetSize(iconSize, iconSize); cell.icon:SetPoint("CENTER"); cell.name:SetText("") end
            cell.icon:SetTexture(ns.MARKER_TEXTURES[markers[i]])
        end
    end
    preview.salveRefresh[#preview.salveRefresh + 1] = renderPreview; renderPreview()

    local presets = section(panel); local presetY = -8
    _, presetY = O.Header(presets, "Presets", presetY)
    local specs = { { "Compact", "20px cells\nno names", 20, 20, 20, 5, 1, false }, { "Named", "105px cells\nnames on", 105, 20, 20, 5, 1, true }, { "Oversized", "130×55px cells\n48px icons", 130, 55, 48, 5, 1, true } }
    for i, spec in ipairs(specs) do
        local button = O.SelectButton(presets, 174, 58)
        button:SetPoint("TOPLEFT", 16 + (i - 1) * 180, presetY - 4); button:SetText(spec[1])
        button.Text:ClearAllPoints(); button.Text:SetPoint("TOPLEFT", 10, -7); button.Text:SetPoint("RIGHT", -10, 0); button.Text:SetJustifyH("LEFT")
        local note = button:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        note:SetPoint("TOPLEFT", button.Text, "BOTTOMLEFT", 0, -2); note:SetText(spec[2]); note:SetTextColor(unpack(O.theme.muted)); note:SetJustifyH("LEFT")
        button:SetScript("OnClick", function() db.cell_width, db.cell_height, db.icon_size, db.cell_columns, db.cell_spacing, db.show_cell_names = spec[3], spec[4], spec[5], spec[6], spec[7], spec[8]; refreshGrid(); presets.salveRefreshAll() end)
        O.AttachHint(button, spec[1], "Apply this grid shape.")
    end
    local presetsHeight = -presetY + 70
    local grid = section(panel); local gy = -8; _, gy = O.Header(grid, "Grid", gy)
    _, gy = O.Slider(grid, "Cells per row", "How many assignment cells appear before the next line starts.", gy, 1, 5, 1, function() return db.cell_columns end, function(v) db.cell_columns = v; refreshGrid() end)
    _, gy = O.Slider(grid, "Spacing", "Gap between cells, in pixels.", gy, 0, 12, 1, function() return db.cell_spacing end, function(v) db.cell_spacing = v; refreshGrid() end)
    local size = section(panel); local sy = -8; _, sy = O.Header(size, "Cell size", sy)
    _, sy = O.Slider(size, "Width", "Use 95 or more to make room for a member name.", sy, 14, 160, 1, function() return db.cell_width end, function(v) db.cell_width = v; refreshGrid() end)
    _, sy = O.Slider(size, "Height", "Height of each compact assignment cell.", sy, 14, 80, 1, function() return db.cell_height end, function(v) db.cell_height = v; refreshGrid() end)
    _, sy = O.Slider(size, "Icon size", "Marker icon size stays independent from the cell width and height.", sy, 10, 48, 1, function() return db.icon_size end, function(v) db.icon_size = v; refreshGrid() end)
    local contents = section(panel); local cy = -8; _, cy = O.Header(contents, "Cell contents", cy)
    _, cy = O.Check(contents, "Unit names", "Show the party member name beside the marker. Use wider cells for this.", cy, function() return db.show_cell_names end, function(v) db.show_cell_names = v; refreshGrid() end)
    local y = -8
    for _, item in ipairs({ { presets, presetsHeight }, { grid, -gy + 4 }, { size, -sy + 4 }, { contents, -cy + 4 } }) do item[1]:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, y); item[1]:SetHeight(item[2]); y = y - item[2] - 8 end
    return y
end)
