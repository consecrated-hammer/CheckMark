local addonName, ns = ...
local HC = ns.HammerCore
local O = HC.UI

-- HammerCore's Visibility page supplies the startup message and minimap
-- button; this adds when the grid shows and where its handle sits.

local HANDLE_POSITIONS = {
    { value = "LEFT", label = "Left" }, { value = "TOPLEFT", label = "Top left" },
    { value = "TOP", label = "Top centre" }, { value = "TOPRIGHT", label = "Top right" },
    { value = "RIGHT", label = "Right" }, { value = "BOTTOMRIGHT", label = "Bottom right" },
    { value = "BOTTOM", label = "Bottom centre" }, { value = "BOTTOMLEFT", label = "Bottom left" },
}

HC.Settings:AddVisibility()
HC.spec.visibility = function(panel, y)
    local db = ns.db
    local function refreshVisibility()
        if ns.applyVisibility then ns.applyVisibility() end
    end

    O.SetScope(panel, "profile")
    _, y = O.ScopeLegend(panel, y)
    _, y = O.Header(panel, "Grid", y, "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6")
    local function setBase(mode)
        db.visibility_mode = mode
        db.visibility = {}
        refreshVisibility()
    end
    local items = {
        { label = "Always", radio = true,
            get = function() return db.visibility_mode ~= "HIDDEN" and not ns.hasGridConditions() end,
            set = function() setBase("ALWAYS") end },
        { label = "Never", radio = true,
            get = function() return db.visibility_mode == "HIDDEN" end,
            set = function() setBase("HIDDEN") end },
        { label = "Or when any of these match", heading = true },
    }
    for _, condition in ipairs(ns.GRID_CONDITIONS) do
        local key = condition.key
        items[#items + 1] = {
            label = condition.label,
            get = function() return db.visibility_mode ~= "HIDDEN" and db.visibility[key] == true end,
            set = function(value)
                db.visibility_mode = "ALWAYS"
                db.visibility[key] = value or nil
                refreshVisibility()
            end,
        }
    end
    _, y = O.MultiSelect(panel, "Show grid",
        "Choose Always or Never, or tick several rules; any matching rule shows the grid. It's only ever in a party of two to five, and always hides in combat.",
        y, { items = items, summary = ns.gridVisibilitySummary }, 264)

    -- This action also clears the shared manual hide flag, so it is mixed
    -- scope and deliberately has no profile-only glyph.
    O.SetScope(panel, "shared")
    local reset
    reset, y = O.PageReset(panel, y, function()
        db.visibility_mode = "ALWAYS"
        db.visibility = {}
        db.panel_hidden = false
        refreshVisibility()
    end, "Reset grid visibility")
    reset.hcHint = "Reset this profile's grid show rules and clear the shared manual Hide grid toggle. Minimap, update and window preferences stay."
    -- HammerCore appends shared minimap, update and window preferences here.
    O.SetScope(panel, "shared")
    return y
end

-- Position is part of the grid layout, separate from visibility rules.
function ns.BuildGridPosition(panel)
    local O, db = ns.Options, ns.db
    O.SetScope(panel, "profile")
    local flow = O.Flow(panel)
    local legend = O.Section(panel, 1)
    local _, legendY = O.ScopeLegend(legend, -4)
    flow:Add(legend, -legendY + 4)
    local function updateHandle() if ns.updateHandle then ns.updateHandle() end end
    local frame = O.Section(panel, 2)
    local y = -8
    local master
    _, y = O.Header(frame, "Grid position", y)
    master, y = O.Check(frame, "Show drag handle", "Drag to move the grid; right-click for settings.", y,
        function() return db.show_handle ~= false end,
        function(value) db.show_handle = value; updateHandle() end)
    local position = frame
    local values, labels = {}, {}
    for _, entry in ipairs(HANDLE_POSITIONS) do
        values[#values + 1], labels[#labels + 1] = entry.value, entry.label
    end
    local handleRow
    handleRow, y = O.Dropdown(position, "Handle position", "Which edge of the grid holds the drag handle.", y, values, labels,
        function() return db.handle_position end,
        function(value) db.handle_position = value; updateHandle() end)
    handleRow.hcParentRow = master
    local function showPosition() handleRow:SetShown(db.show_handle ~= false) end
    O.OnRefresh(position, showPosition); showPosition()
    flow:Add(position, -O.Flush(position, y) + 4)
    local actions = O.Section(panel, 2)
    y = -4
    _, y = O.ActionButton(actions, y, "Re-centre grid", function() HC.Commands:Dispatch("reset position") end,
        "Move only the grid to the centre. Keeps the handle settings.")
    _, y = O.PageReset(actions, y, function()
        db.show_handle, db.handle_position = true, "TOP"
        HC.Commands:Dispatch("reset position")
        updateHandle()
    end, "Reset grid position")
    flow:Add(actions, -O.Flush(actions, y) + 4)
    return flow:Layout()
end
