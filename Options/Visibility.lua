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

    _, y = O.Text(panel, "Grid rules save in the active profile. Minimap, update and settings-window options below are shared.", y)
    _, y = O.Header(panel, "Grid (per profile)", y, "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6")
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
        { label = "Show when any of these match", heading = true },
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

    _, y = O.PageReset(panel, y, function()
        db.visibility_mode = "ALWAYS"
        db.visibility = {}
        db.panel_hidden = false
        refreshVisibility()
    end, "Reset grid visibility")
    return y
end

-- Position is part of the grid layout, separate from visibility rules.
function ns.BuildGridPosition(panel)
    local O, db = ns.Options, ns.db
    local flow = O.Flow(panel)
    local function updateHandle() if ns.updateHandle then ns.updateHandle() end end
    local frame = O.Section(panel, 1)
    local y = -8
    local master
    _, y = O.Header(frame, "Grid position (per profile)", y)
    master, y = O.Check(frame, "Show drag handle", "Drag to move the grid; right-click for settings.", y,
        function() return db.show_handle ~= false end,
        function(value) db.show_handle = value; updateHandle() end)
    flow:Add(frame, -y + 4)
    local position = O.Section(panel, 1, master)
    y = -4
    local values, labels = {}, {}
    for _, entry in ipairs(HANDLE_POSITIONS) do
        values[#values + 1], labels[#labels + 1] = entry.value, entry.label
    end
    _, y = O.Dropdown(position, "Handle position", "Which edge of the grid holds the drag handle.", y, values, labels,
        function() return db.handle_position end,
        function(value) db.handle_position = value; updateHandle() end)
    flow:Add(position, -y + 4, function() return db.show_handle ~= false end)
    local actions = O.Section(panel, 1)
    y = -4
    _, y = O.ActionButton(actions, y, "Re-centre grid", function() HC.Commands:Dispatch("reset position") end,
        "Move only the grid to the centre. Keeps the handle settings.")
    _, y = O.PageReset(actions, y, function()
        db.show_handle, db.handle_position = true, "TOP"
        HC.Commands:Dispatch("reset position")
        updateHandle()
    end, "Reset grid position")
    flow:Add(actions, -y + 4)
    return flow:Layout()
end
