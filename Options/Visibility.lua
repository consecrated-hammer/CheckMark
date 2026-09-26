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
    local function updateHandle()
        if ns.updateHandle then ns.updateHandle() end
    end

    _, y = O.Header(panel, "Grid", y)
    _, y = O.MultiSelect(panel, "Show",
        "Always shows CheckMark for an eligible party outside combat. Combat is deliberately not a condition.", y, {
            items = {
                { label = "Always", radio = true,
                    get = function() return db.visibility_mode ~= "HIDDEN" end,
                    set = function() db.visibility_mode = "ALWAYS"; refreshVisibility() end },
                { label = "Never", radio = true,
                    get = function() return db.visibility_mode == "HIDDEN" end,
                    set = function() db.visibility_mode = "HIDDEN"; refreshVisibility() end },
            },
            summary = function() return db.visibility_mode == "HIDDEN" and "Never" or "Always" end,
        }, 264)

    _, y = O.Header(panel, "Position", y)
    _, y = O.Check(panel, "Show drag handle", "Drag the handle to move CheckMark. Right-click it for settings.", y,
        function() return db.show_handle ~= false end,
        function(value) db.show_handle = value; updateHandle() end)
    local values, labels = {}, {}
    for _, entry in ipairs(HANDLE_POSITIONS) do
        values[#values + 1], labels[#labels + 1] = entry.value, entry.label
    end
    _, y = O.Dropdown(panel, "Handle position", "Which edge of the grid holds the drag handle.", y, values, labels,
        function() return db.handle_position end,
        function(value) db.handle_position = value; updateHandle() end)
    local resetPosition = O.Button(panel, 180, 22)
    resetPosition:SetPoint("TOPLEFT", O.PAD, y - 4)
    resetPosition:SetText("Reset grid position")
    O.AttachHint(resetPosition, "Reset grid position", "Move CheckMark back to the centre of the screen.")
    resetPosition:SetScript("OnClick", function() HC.Commands:Dispatch("reset position") end)
    y = y - 38

    _, y = O.PageReset(panel, y, function()
        db.visibility_mode = "ALWAYS"
        db.panel_hidden = false
        db.show_handle = true
        db.handle_position = "TOP"
        db.popup_position = nil
        local state = HC.State()
        state.startupMessage, state.minimap, state.minimapAngle = true, true, 225
        HC.Minimap:Update()
        updateHandle()
        refreshVisibility()
    end, "Reset visibility")
    return y
end
