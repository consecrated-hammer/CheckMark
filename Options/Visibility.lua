local addonName, ns = ...
local O = ns.Options

local HANDLE_POSITIONS = {
    { value = "LEFT", label = "Left" }, { value = "TOPLEFT", label = "Top left" },
    { value = "TOP", label = "Top centre" }, { value = "TOPRIGHT", label = "Top right" },
    { value = "RIGHT", label = "Right" }, { value = "BOTTOMRIGHT", label = "Bottom right" },
    { value = "BOTTOM", label = "Bottom centre" }, { value = "BOTTOMLEFT", label = "Bottom left" },
}

O.NewPage({
    name = "Visibility",
    title = "Visibility",
    group = "CORE",
    description = "Choose when CheckMark is visible and where its handle sits.",
}, function(panel, y)
    local db = ns.db
    local function refreshVisibility()
        if ns.applyVisibility then ns.applyVisibility() end
    end

    local heading
    heading, y = O.Header(panel, "Display", y)
    local displayItems = {
        { label = "Always", radio = true,
            get = function() return db.visibility_mode ~= "HIDDEN" end,
            set = function() db.visibility_mode = "ALWAYS"; refreshVisibility() end },
        { label = "Never", radio = true,
            get = function() return db.visibility_mode == "HIDDEN" end,
            set = function() db.visibility_mode = "HIDDEN"; refreshVisibility() end },
    }
    _, y = O.MultiSelect(panel, "Show",
        "Always shows CheckMark for an eligible party outside combat. Combat is deliberately not an available condition.", y,
        { items = displayItems, summary = function() return db.visibility_mode == "HIDDEN" and "Never" or "Always" end }, 264)

    heading, y = O.Header(panel, "Position", y)
    _, y = O.Check(panel, "Show drag handle",
        "Drag the gold handle to move CheckMark. Right-click it for settings.", y,
        function() return db.show_handle ~= false end,
        function(value) db.show_handle = value; if ns.updateHandle then ns.updateHandle() end end)

    local handleItems = {}
    for _, entry in ipairs(HANDLE_POSITIONS) do
        local position = entry.value
        handleItems[#handleItems + 1] = {
            label = entry.label, radio = true,
            get = function() return db.handle_position == position end,
            set = function() db.handle_position = position; if ns.updateHandle then ns.updateHandle() end end,
        }
    end
    _, y = O.MultiSelect(panel, "Handle position", "Choose which edge of the grid holds the drag handle.", y,
        { items = handleItems, summary = function()
            for _, entry in ipairs(HANDLE_POSITIONS) do
                if db.handle_position == entry.value then return entry.label end
            end
            return "Top centre"
        end }, 264)
    local resetPosition = O.Button(panel, 180, 22)
    resetPosition:SetPoint("TOPLEFT", 16, y - 4)
    resetPosition:SetText("Reset grid position")
    O.AttachHint(resetPosition, "Reset grid position", "Move CheckMark back to the centre of the screen.")
    resetPosition:SetScript("OnClick", function()
        db.popup_position = nil
        if ns.hidePopup then ns.hidePopup() end
        if ns.showPopup then ns.showPopup() end
    end)
    y = y - 42

    heading, y = O.Header(panel, "Other", y)
    _, y = O.Check(panel, "Show minimap button",
        "Left-click opens the grid. Right-click opens settings. Drag it around the minimap to move it.", y,
        function() return not db.hide_minimap end,
        function(value) db.hide_minimap = not value; if ns.refreshMinimapButton then ns.refreshMinimapButton() end end)

    y = y - 8
    heading, y = O.Header(panel, "Reset", y)
    local reset
    reset, y = O.PageReset(panel, y, function()
        db.visibility_mode = "ALWAYS"
        db.panel_hidden = false
        db.show_handle = true
        db.handle_position = "TOP"
        db.hide_minimap = false
        db.minimap_angle = 225
        db.popup_position = nil
        if ns.updateHandle then ns.updateHandle() end
        if ns.refreshMinimapButton then ns.refreshMinimapButton() end
        refreshVisibility()
    end, "Reset Visibility")
    return y
end)
