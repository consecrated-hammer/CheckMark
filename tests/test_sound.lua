local function equal(actual, expected, label)
    if actual ~= expected then error(("%s: expected %s, got %s"):format(label, tostring(expected), tostring(actual))) end
end

local played = {}
PlaySound = function(id, channel)
    played[#played + 1] = { id = id, channel = channel }
    return true
end

local ns = { db = { marker_sound_enabled = true, marker_sound_id = 416, marker_sound_random = true } }
assert(loadfile("Sound.lua"))("CheckMark", ns)
ns.initializeMarkerSoundSettings()

equal(#ns.MARKER_SOUNDS, 22, "Retail sees every Retail and shared sound")
equal(ns.MARKER_SOUNDS[1].id, 416, "murloc aggro remains first in catalogue order")
equal(ns.MARKER_SOUNDS[22].id, 10049, "heroism cast is catalogued")
equal(#ns.getSelectedMarkerSounds(), 22, "legacy random mode migrates to the full catalogue")
equal(ns.db.marker_sound_mode, "RANDOM", "legacy random mode migrates to random playback")

ns.random = function(maximum) equal(maximum, 22, "random mode sees selected sounds only"); return 22 end
equal(ns.playMarkerSound(), true, "random sound plays")
equal(played[#played].id, 10049, "random selection uses selected catalogue entry")
equal(played[#played].channel, "Master", "sound uses the master channel")

ns.db.marker_sound_ids = { [11965] = true, [888] = true }
ns.db.marker_sound_mode = "SEQUENTIAL"
equal(ns.playMarkerSound(), true, "first sequential sound plays")
equal(played[#played].id, 11965, "sequential playback starts at first selected sound")
equal(ns.playMarkerSound(), true, "second sequential sound plays")
equal(played[#played].id, 888, "sequential playback advances through selected sounds")
equal(ns.playMarkerSound(), true, "sequential playback loops")
equal(played[#played].id, 11965, "sequential playback loops to first selected sound")

equal(ns.playMarkerSound(true), true, "sequential preview plays")
equal(played[#played].id, 11965, "sequential preview starts at first selected sound")
equal(ns.playMarkerSound(), true, "live sequence continues after preview")
equal(played[#played].id, 888, "preview does not advance the live sequence")
ns.resetMarkerSoundSequence()
equal(ns.playMarkerSound(), true, "reset sequence plays")
equal(played[#played].id, 11965, "reset sequence starts from the first selected sound")

equal(ns.setMarkerSoundSelected(11965, false), true, "one of two sounds can be removed")
equal(ns.setMarkerSoundSelected(888, false), false, "last selected sound cannot be removed")
equal(#ns.getSelectedMarkerSounds(), 1, "one selected sound remains valid")

ns.db.marker_sound_enabled = false
equal(ns.playMarkerSound(), false, "disabled sound does not play")
equal(ns.playMarkerSound(true), true, "preview plays while disabled")

local legacySingle = { db = { marker_sound_enabled = true, marker_sound_id = 888, marker_sound_random = false } }
assert(loadfile("Sound.lua"))("CheckMark", legacySingle)
legacySingle.initializeMarkerSoundSettings()
equal(#legacySingle.getSelectedMarkerSounds(), 1, "legacy single sound selection is retained")
equal(legacySingle.getSelectedMarkerSounds()[1].id, 888, "legacy selected sound is retained")
equal(legacySingle.db.marker_sound_mode, "SEQUENTIAL", "legacy non-random mode becomes sequential")

print("CheckMark sound tests passed")

-- Select all and Deselect all.
ns.selectAllMarkerSounds(false)
equal(#ns.getSelectedMarkerSounds(), 1, "deselect all keeps one sound")
ns.selectAllMarkerSounds(true)
equal(#ns.getSelectedMarkerSounds(), 22, "select all ticks every sound")

-- WoW Forever only sees sounds it has.
C_AddOns = { GetAddOnMetadata = function(_, key) return key == "X-CheckMark-Target" and "Camelot" or nil end }
local forever = { db = { marker_sound_enabled = true } }
assert(loadfile("Sound.lua"))("CheckMark", forever)
forever.initializeMarkerSoundSettings()
equal(#forever.MARKER_SOUNDS, 12, "Forever sees shared sounds only")
for _, sound in ipairs(forever.MARKER_SOUNDS) do
    equal(sound.only, nil, "no Retail-only sound on Forever: " .. sound.name)
end
C_AddOns = nil
print("CheckMark sound catalogue tests passed")
