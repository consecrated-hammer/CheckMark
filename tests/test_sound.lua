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

equal(#ns.MARKER_SOUNDS, 15, "all supplied marker sounds are catalogued")
equal(ns.MARKER_SOUNDS[1].id, 416, "murloc aggro remains first in catalogue order")
equal(ns.MARKER_SOUNDS[15].id, 10049, "heroism cast is catalogued")
equal(#ns.getSelectedMarkerSounds(), 15, "legacy random mode migrates to the full catalogue")
equal(ns.db.marker_sound_mode, "RANDOM", "legacy random mode migrates to random playback")

ns.random = function(maximum) equal(maximum, 15, "random mode sees selected sounds only"); return 15 end
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
