local addonName, ns = ...
local O = ns.Options

local function soundItems()
    local items = {}
    for _, sound in ipairs(ns.MARKER_SOUNDS) do
        local id, name = sound.id, sound.name
        items[#items + 1] = {
            label = name,
            get = function() return ns.isMarkerSoundSelected(id) end,
            set = function(selected) ns.setMarkerSoundSelected(id, selected) end,
        }
    end
    return items
end

local function selectedSummary()
    local sounds = ns.getSelectedMarkerSounds()
    if #sounds == 1 then return sounds[1].name end
    return tostring(#sounds) .. " sounds selected"
end

O.NewPage({
    name = "Sounds",
    title = "Sounds",
    group = "CORE",
    description = "Choose the optional sound played after applying a prepared marker.",
}, function(panel, y)
    local heading
    heading, y = O.Header(panel, "Marker sound", y)
    _, y = O.Check(panel, "Play a sound when applying a marker",
        "Enabled by default. The sound plays after a left-click submits a prepared marker action.",
        y, function() return ns.db.marker_sound_enabled ~= false end,
        function(value) ns.db.marker_sound_enabled = value end)

    _, y = O.MultiSelect(panel, "Sounds",
        "Select the sounds available to both playback modes. At least one sound always remains selected.",
        y, { items = soundItems(), summary = selectedSummary }, 264)

    _, y = O.MultiSelect(panel, "Playback", "Random chooses from selected sounds. Sequential follows the selected sounds in catalogue order.", y, {
        items = {
            { label = "Random", radio = true, get = function() return ns.db.marker_sound_mode == "RANDOM" end, set = function() ns.db.marker_sound_mode = "RANDOM" end },
            { label = "Sequential", radio = true, get = function() return ns.db.marker_sound_mode == "SEQUENTIAL" end, set = function() ns.db.marker_sound_mode = "SEQUENTIAL" end },
        },
        summary = function() return ns.db.marker_sound_mode == "SEQUENTIAL" and "Sequential" or "Random" end,
    }, 264)

    local test = O.Button(panel, 150, 22, "primary")
    test:SetPoint("TOPLEFT", 16, y - 4)
    test:SetText("Test sound")
    O.AttachHint(test, "Test sound", "Previews from the selected pool using the current playback mode, even if marker sounds are disabled.")
    test:SetScript("OnClick", function() if ns.playMarkerSound then ns.playMarkerSound(true) end end)
    y = y - 40

    _, y = O.PageReset(panel, y, function()
        ns.db.marker_sound_enabled = true
        ns.db.marker_sound_ids = nil
        ns.db.marker_sound_mode = "RANDOM"
        ns.initializeMarkerSoundSettings()
        if ns.resetMarkerSoundSequence then ns.resetMarkerSoundSequence() end
    end, "Reset sounds")
    return y
end)
