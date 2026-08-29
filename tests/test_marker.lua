local function equal(actual, expected, label)
    if actual ~= expected then error(("%s: expected %s, got %s"):format(label, tostring(expected), tostring(actual))) end
end

local combat = false
InCombatLockdown = function() return combat end

local function cell()
    local result = { attributes = {} }
    function result:SetAttribute(key, value) self.attributes[key] = value end
    function result:Enable() self.enabled = true end
    function result:Disable() self.enabled = false end
    return result
end

local ns = {}
assert(loadfile("Marker.lua"))("CheckMark", ns)

local cells = { cell(), cell(), cell() }
local members = {
    { unit = "player", fullName = "Player-Realm" },
    { unit = "party1", fullName = "Tank-Realm" },
    { unit = "party2", fullName = "Healer-Realm" },
}
local assignments = { ["Player-Realm"] = 0, ["Tank-Realm"] = 8, ["Healer-Realm"] = 3 }

equal(ns.bindMarkerCells(cells, members, assignments), true, "cells bind out of combat")
equal(cells[1].enabled, true, "unplanned player cell remains clickable for settings")
equal(cells[1].attributes.type1, nil, "unplanned player cell has no secure action")
equal(cells[2].attributes.type1, "raidtarget", "tank cell uses native secure action")
equal(cells[2].attributes.unit1, "party1", "left click targets party token")
equal(cells[2].attributes.marker1, 8, "left click uses skull")
equal(cells[2].attributes.action1, "set", "left click sets rather than toggles")
equal(cells[2].attributes.type2, "raidtarget", "right click uses native secure action")
equal(cells[2].attributes.unit2, "party1", "right click targets the same party token")
equal(cells[2].attributes.action2, "clear", "right click clears any marker")
equal(cells[3].attributes.marker1, 3, "healer left click uses diamond")

combat = true
equal(ns.bindMarkerCells(cells, members, assignments), false, "combat defers cell rebinding")
equal(ns.pendingMarkerRebuild, true, "combat marks a pending rebind")
combat = false
equal(ns.rebuildPendingRowSecureButtons(), true, "pending cell rebind resumes after combat")

print("CheckMark marker cell tests passed")
