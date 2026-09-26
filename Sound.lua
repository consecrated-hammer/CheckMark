local addonName, ns = ...

-- The catalogue is the only place a built-in sound is defined. The options
-- page and both playback modes derive their choices from this ordered list.
ns.MARKER_SOUNDS = {
    { id = 416, name = "Murloc Aggro" },
    { id = 11965, name = "A Horseman Laugh" },
    { id = 888, name = "Level Up" },
    { id = 618, name = "Quest Added" },
    { id = 12891, name = "Achievement Gained" },
    { id = 13833, name = "Achievement Menu Close" },
    { id = 17318, name = "Dungeon Ready" },
    { id = 114685, name = "Tyrande Greetings" },
    { id = 114684, name = "Tyrande Farewells" },
    { id = 14377, name = "Yogg-Saron Whisper" },
    { id = 339645, name = "Lightcalled Hearthstone Cast" },
    { id = 339647, name = "Lightcalled Hearthstone Paper Cast" },
    { id = 120, name = "Loot Window Coin" },
    { id = 1264, name = "Loot Window Open Empty" },
    { id = 10049, name = "Heroism Cast" },
}

local lastSequentialSoundID

local function findSound(id)
    for _, sound in ipairs(ns.MARKER_SOUNDS) do
        if sound.id == id then return sound end
    end
end

local function allSoundIDs()
    local selected = {}
    for _, sound in ipairs(ns.MARKER_SOUNDS) do selected[sound.id] = true end
    return selected
end

function ns.initializeMarkerSoundSettings()
    local db = ns.db
    if not db then return end

    -- v1.0.1-dev2 had a single selected ID and a boolean random flag. Preserve
    -- a deliberate single-sound setting; old random mode meant every sound was
    -- eligible, so migrate it to the full catalogue.
    if type(db.marker_sound_ids) ~= "table" then
        if db.marker_sound_random == false then
            local oldSound = findSound(tonumber(db.marker_sound_id)) or ns.MARKER_SOUNDS[1]
            db.marker_sound_ids = { [oldSound.id] = true }
        else
            db.marker_sound_ids = allSoundIDs()
        end
    end
    if db.marker_sound_mode ~= "RANDOM" and db.marker_sound_mode ~= "SEQUENTIAL" then
        db.marker_sound_mode = db.marker_sound_random == false and "SEQUENTIAL" or "RANDOM"
    end
    db.marker_sound_id, db.marker_sound_random = nil, nil

    -- A stale or hand-edited saved-variable table should never leave the addon
    -- silently configured with no sound pool.
    local hasSelected = false
    for _, sound in ipairs(ns.MARKER_SOUNDS) do
        if db.marker_sound_ids[sound.id] then hasSelected = true; break end
    end
    if not hasSelected then db.marker_sound_ids = allSoundIDs() end
end

-- Forever's sound library is not Retail's.  A sound kit the client lacks
-- makes PlaySound report that it will not play.  The check plays each sound
-- for an instant and stops it at once; the result is saved per client,
-- because each client keeps its own saved variables.
function ns.isMarkerSoundMissing(id)
    return ns.db and type(ns.db.missing_sound_ids) == "table" and ns.db.missing_sound_ids[id] == true or false
end

function ns.checkMarkerSounds()
    if type(PlaySound) ~= "function" or not ns.db then return nil, "sound is unavailable" end
    local missing, playable = {}, 0
    for _, sound in ipairs(ns.MARKER_SOUNDS) do
        local ok, willPlay, handle = pcall(PlaySound, sound.id, "Master", false)
        if ok and willPlay then
            playable = playable + 1
            if handle and type(StopSound) == "function" then pcall(StopSound, handle, 0) end
        else
            missing[#missing + 1] = sound
        end
    end
    -- Nothing playing at all means game sound is off, not that every kit is
    -- missing; keep the previous result rather than record a false one.
    if playable == 0 then return nil, "no sound played; turn game sound on and check again" end
    ns.db.missing_sound_ids = {}
    for _, sound in ipairs(missing) do ns.db.missing_sound_ids[sound.id] = true end
    return missing
end

function ns.markerSoundCheckSummary()
    local missing = {}
    for _, sound in ipairs(ns.MARKER_SOUNDS) do
        if ns.isMarkerSoundMissing(sound.id) then missing[#missing + 1] = sound.name end
    end
    if type(ns.db and ns.db.missing_sound_ids) ~= "table" then return "Not checked on this client" end
    if #missing == 0 then return "All " .. #ns.MARKER_SOUNDS .. " sounds play on this client" end
    return #missing .. " missing: " .. table.concat(missing, ", ")
end

-- Selected sounds this client can play.  If every selected sound is
-- missing, fall back to any sound that plays rather than fall silent.
function ns.getSelectedMarkerSounds()
    local selected = {}
    if not ns.db then return selected end
    for _, sound in ipairs(ns.MARKER_SOUNDS) do
        if ns.db.marker_sound_ids and ns.db.marker_sound_ids[sound.id] and not ns.isMarkerSoundMissing(sound.id) then
            selected[#selected + 1] = sound
        end
    end
    if #selected == 0 then
        for _, sound in ipairs(ns.MARKER_SOUNDS) do
            if not ns.isMarkerSoundMissing(sound.id) then selected[#selected + 1] = sound end
        end
    end
    return selected
end

function ns.isMarkerSoundSelected(id)
    return ns.db and ns.db.marker_sound_ids and ns.db.marker_sound_ids[id] == true
end

function ns.setMarkerSoundSelected(id, selected)
    if not ns.db or not findSound(id) then return false end
    ns.db.marker_sound_ids = ns.db.marker_sound_ids or allSoundIDs()
    if not selected and ns.isMarkerSoundSelected(id) and #ns.getSelectedMarkerSounds() <= 1 then
        return false
    end
    ns.db.marker_sound_ids[id] = selected and true or nil
    return true
end

local function nextSequentialSound(sounds)
    local nextIndex = 1
    for index, sound in ipairs(sounds) do
        if sound.id == lastSequentialSoundID then
            nextIndex = index % #sounds + 1
            break
        end
    end
    local sound = sounds[nextIndex]
    lastSequentialSoundID = sound.id
    return sound
end

function ns.resetMarkerSoundSequence()
    lastSequentialSoundID = nil
end

function ns.playMarkerSound(preview)
    if not ns.db or (not preview and ns.db.marker_sound_enabled == false) then return false end
    if type(PlaySound) ~= "function" then return false end

    local sounds = ns.getSelectedMarkerSounds()
    if #sounds == 0 then return false end
    local sound
    if ns.db.marker_sound_mode == "SEQUENTIAL" then
        -- Testing must not consume the next live marker cue. It previews the
        -- first selected sound, while real marker clicks advance the sequence.
        sound = preview and sounds[1] or nextSequentialSound(sounds)
    else
        -- Tests can supply ns.random without replacing the game's RNG.
        local choose = ns.random or math.random
        sound = sounds[choose(#sounds)]
    end
    return pcall(PlaySound, sound.id, "Master")
end
