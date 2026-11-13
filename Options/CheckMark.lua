local addonName, ns = ...
local HC = ns.HammerCore
local O, T = ns.Options, HC.Theme

-- Section headings wear the raid markers.
local ICONS = { presets = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1", grid = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6", size = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3", contents = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4" }

-- columns: 2 lays the section's settings out two to a row.
local section = O.Section
local function refreshGrid() if ns.refreshPopup then ns.refreshPopup() end end

HC.Settings:NewPage({ name = "CheckMark", title = "Grid", group = "main", description = "Shape the compact five-player marker grid.",
    headerAction = ns.LivePreviewAction,
    tabs = { { name = "Layout", build = function(panel)
    local db = ns.db
    local presets = section(panel); local presetY = -8
    _, presetY = O.Header(presets, "Presets", presetY, ICONS.presets)
    local specs = { { "Compact", "Icons only", 20, 20, 20, 5, 1, false }, { "Named", "Icons and names", 105, 20, 20, 5, 1, true }, { "Oversized", "Large, with names", 130, 55, 48, 5, 1, true } }
    for i, spec in ipairs(specs) do
        local presetWidth = math.floor((O.CONTENT_WIDTH - 12) / 3)
        local button = O.Button(presets, presetWidth, 58)
        button:SetPoint("TOPLEFT", O.PAD + (i - 1) * (presetWidth + 6), presetY - 4); button:SetText(spec[1])
        button.Text:ClearAllPoints(); button.Text:SetPoint("TOPLEFT", 10, -7); button.Text:SetPoint("RIGHT", -10, 0); button.Text:SetJustifyH("LEFT")
        local note = button:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
        note:SetPoint("TOPLEFT", button.Text, "BOTTOMLEFT", 0, -2); note:SetText(spec[2]); note:SetTextColor(T.Unpack("muted")); note:SetJustifyH("LEFT")
        button:SetScript("OnClick", function() db.cell_width, db.cell_height, db.icon_size, db.cell_columns, db.cell_spacing, db.show_cell_names = spec[3], spec[4], spec[5], spec[6], spec[7], spec[8]; refreshGrid(); presets.hcRefreshAll() end)
        O.AttachHint(button, spec[1], "Apply this grid layout preset. Saved per profile.")
        O.RegisterRow(presets, button, spec[1])
    end
    local presetsHeight = -presetY + 70
    local grid = section(panel, 2); local gy = -8; _, gy = O.Header(grid, "Grid", gy, ICONS.grid)
    _, gy = O.Slider(grid, "Cells per row", "How many assignment cells appear before the next line starts.", gy, 1, 5, 1, function() return db.cell_columns end, function(v) db.cell_columns = v; refreshGrid() end)
    _, gy = O.Slider(grid, "Spacing", "Gap between cells, in pixels.", gy, 0, 12, 1, function() return db.cell_spacing end, function(v) db.cell_spacing = v; refreshGrid() end)
    gy = O.Flush(grid, gy)
    local size = section(panel, 2); local sy = -8; _, sy = O.Header(size, "Cell size", sy, ICONS.size)
    _, sy = O.Slider(size, "Width", "Use 95 or more to make room for a member name.", sy, 14, 160, 1, function() return db.cell_width end, function(v) db.cell_width = v; refreshGrid() end)
    _, sy = O.Slider(size, "Height", "Height of each compact assignment cell.", sy, 14, 80, 1, function() return db.cell_height end, function(v) db.cell_height = v; refreshGrid() end)
    _, sy = O.Slider(size, "Icon size", "Marker icon size stays independent from the cell width and height.", sy, 10, 48, 1, function() return db.icon_size end, function(v) db.icon_size = v; refreshGrid() end)
    sy = O.Flush(size, sy)
    local contents = section(panel, 2); local cy = -8; _, cy = O.Header(contents, "Cell contents", cy, ICONS.contents)
    _, cy = O.Check(contents, "Player names", "Show the party member name beside the marker. Use wider cells for this.", cy, function() return db.show_cell_names end, function(v) db.show_cell_names = v; refreshGrid() end)
    cy = O.Flush(contents, cy)
    local y = -8
    for _, item in ipairs({ { presets, presetsHeight }, { grid, -gy + 4 }, { size, -sy + 4 }, { contents, -cy + 4 } }) do item[1]:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, y); item[1]:SetHeight(item[2]); y = y - item[2] - 8 end
    _, y = O.PageReset(panel, y, function()
        for _, key in ipairs({ "cell_width", "cell_height", "icon_size", "cell_columns", "cell_spacing", "show_cell_names" }) do
            ns.db[key] = ns.DEFAULT_DB[key]
        end
        refreshGrid()
    end, "Reset grid layout")
    return y
end }, { name = "Position", build = function(panel) return ns.BuildGridPosition(panel) end } },
})
