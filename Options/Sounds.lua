local addonName, ns = ...
local HC = ns.HammerCore
local O = ns.Options

local function soundItems()
    local items = {}
    -- Only sounds this client has: the catalogue is already per client, and
    -- anything Find missing sounds found missing stays out of the list.
    for _, sound in ipairs(ns.MARKER_SOUNDS) do
        local id, name = sound.id, sound.name
        if not ns.isMarkerSoundMissing(id) then items[#items + 1] = {
            label = name,
            get = function() return ns.isMarkerSoundSelected(id) end,
            set = function(selected) ns.setMarkerSoundSelected(id, selected) end,
        } end
    end
    return items
end

local function selectedSummary()
    local sounds = ns.getSelectedMarkerSounds()
    if #sounds == 1 then return sounds[1].name end
    return tostring(#sounds) .. " sounds selected"
end

HC.Settings:NewPage({
    name = "Sounds",
    title = "Sounds",
    group = "main", profileScope = false,
    description = "A sound when you click a marker onto someone.",
}, function(panel, y)
    local flow = O.Flow(panel)
    local root = panel
    panel = O.Section(root, 1)
    local heading
    heading, y = O.Header(panel, "Marker sound", y, "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2")
    local master
    master, y = O.Check(panel, "Play marker sounds",
        "Plays when you click a marker onto someone.",
        y, function() return ns.db.marker_sound_enabled ~= false end,
        function(value) ns.db.marker_sound_enabled = value end)

    flow:Add(panel, -y + 4)
    panel = O.Section(root, 1, master); y = -4
    _, y = O.MultiSelect(panel, "Available sounds",
        "Select the sounds available to both playback modes. At least one sound always remains selected.",
        y, { items = soundItems(), summary = selectedSummary,
            -- Deselect all keeps one sound: the pool is never empty.
            bulk = function(selected) ns.selectAllMarkerSounds(selected) end }, 264)


    _, y = O.Dropdown(panel, "Playback", "Random chooses from selected sounds. Sequential follows the selected sounds in catalogue order.",
        y, { "RANDOM", "SEQUENTIAL" }, { "Random", "Sequential" },
        function() return ns.db.marker_sound_mode end,
        function(value) ns.db.marker_sound_mode = value end)

    flow:Add(panel, -y + 4, function() return ns.db.marker_sound_enabled ~= false end)
    panel = O.Section(root, 1); y = -4
    _, y = O.ActionButton(panel, y, "Test sound", function() if ns.playMarkerSound then ns.playMarkerSound(true) end end,
        "Previews from the selected pool using the current playback mode, even if marker sounds are disabled.", "primary")

    local check
    check, y = O.ActionButton(panel, y, "Find missing sounds", function() HC.Commands:Dispatch("sounds") end,
        "Play each sound for an instant to find any this client lacks. Missing sounds are skipped.")
    local result = O.FontString(panel, "GameFontHighlightSmall", "muted")
    result:SetPoint("LEFT", check, "RIGHT", 12, 0)
    HC.UI.OnRefresh(panel, function() result:SetText(ns.markerSoundCheckSummary()) end)
    result:SetText(ns.markerSoundCheckSummary())


    _, y = O.PageReset(panel, y, function()
        ns.db.marker_sound_enabled = true
        ns.db.marker_sound_ids = nil
        ns.db.marker_sound_mode = "RANDOM"
        ns.initializeMarkerSoundSettings()
        if ns.resetMarkerSoundSequence then ns.resetMarkerSoundSequence() end
    end, "Reset sounds")
    flow:Add(panel, -y + 4)
    return flow:Layout()
end)
