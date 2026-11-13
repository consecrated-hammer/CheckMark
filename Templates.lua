local addon, ns = ...

-- Who gets which marker. Markers follow people, not party slots:
--
--   1. A marker you picked for someone in this party (the window's icon).
--   2. The profile's rule order, from "Who goes first":
--        Regulars   people you've pinned (by BattleTag for Battle.net
--                   friends, otherwise by character)
--        Roles      the tank's and healer's markers
--   3. Learned markers, when the rules use regulars. They come after roles
--      so a random you once marked doesn't take the tank's Skull.
--   4. Fill order: everyone left gets the next free marker.
--
-- A marker goes to one person only; whoever loses a clash drops to the next
-- rule. Party order and the leader don't matter.

local Assign = { picked = {}, MAX_LEARNED = 200 }
ns.Assign = Assign

Assign.FILL_DEFAULT = { 1, 2, 4, 5, 6, 7, 8, 3 } -- Star, Circle, Triangle, Moon, Square, Cross, Skull, Diamond
Assign.ROLE_DEFAULT = { TANK = 8, HEALER = 3 }

-- "Who goes first" choices; the fill order always comes last.
Assign.RULES = {
    { value = "REGULARS_ROLES", label = "Pinned people, then tank and healer", order = { "REGULARS", "ROLES" } },
    { value = "ROLES_REGULARS", label = "Tank and healer, then pinned people", order = { "ROLES", "REGULARS" } },
    { value = "REGULARS", label = "Pinned people only", order = { "REGULARS" } },
    { value = "ROLES", label = "Tank and healer only", order = { "ROLES" } },
    { value = "FILL", label = "Fill order only", order = {} },
}

Assign.SOURCE_LABELS = {
    picked = "Picked", pinned = "Pinned", learned = "Learned", tank = "Tank", healer = "Healer",
    fill = "Next free", none = "No marker",
}

local function rulesFor(value)
    for _, rule in ipairs(Assign.RULES) do
        if rule.value == value then return rule.order end
    end
    return Assign.RULES[1].order
end

-- A clean fill order: each marker 1-8 once, the saved order first.
function Assign.FillOrder(saved)
    local order, seen = {}, {}
    for _, marker in ipairs(type(saved) == "table" and saved or {}) do
        marker = tonumber(marker)
        if marker and marker >= 1 and marker <= 8 and not seen[marker] then
            order[#order + 1], seen[marker] = marker, true
        end
    end
    for _, marker in ipairs(Assign.FILL_DEFAULT) do
        if not seen[marker] then order[#order + 1], seen[marker] = marker, true end
    end
    return order
end

-- Regulars ---------------------------------------------------------------------

local function regulars()
    ns.db.regulars = type(ns.db.regulars) == "table" and ns.db.regulars or {}
    return ns.db.regulars
end

-- The member's regular entry: pinned or learned; account before character.
-- Returns entry, key.
function Assign.RegularFor(member, pinned)
    local list = regulars()
    for _, key in ipairs(ns.Identity.Keys(member)) do
        local entry = list[key]
        if type(entry) == "table" and (entry.pinned == true) == pinned and tonumber(entry.marker) then
            return entry, key
        end
    end
end

-- The key to save a member under: their BattleTag when we know it.
function Assign.KeyFor(member)
    return ns.Identity.Keys(member)[1]
end

local function describe(member, key)
    if key and key:sub(1, 5) == "bnet:" then return key:sub(6) end
    if not member.full then return member.label or "?" end
    if ns.Identity.IsForever() then return member.full end
    return member.full .. "-" .. (member.realm or "")
end

local function now() return time and time() or 0 end
local function refreshRegulars()
    if ns.RefreshRegularsSearch then ns.RefreshRegularsSearch() end
end

local function trim()
    local list, learned = regulars(), {}
    for key, entry in pairs(list) do
        if type(entry) ~= "table" then list[key] = nil
        elseif not entry.pinned then learned[#learned + 1] = { key = key, at = tonumber(entry.at) or 0 } end
    end
    if #learned <= Assign.MAX_LEARNED then return end
    table.sort(learned, function(a, b) return a.at < b.at end)
    for index = 1, #learned - Assign.MAX_LEARNED do list[learned[index].key] = nil end
end

local function save(member, marker, pinned)
    local key = Assign.KeyFor(member)
    if not key or (member.anonymous and key:sub(1, 5) ~= "bnet:") then return end
    regulars()[key] = { marker = marker, pinned = pinned or nil, label = describe(member, key),
        seen = member.label or member.first, at = now() }
    trim()
    refreshRegulars()
    return key
end

-- Remembers a marker someone got. A pinned person keeps their pin.
function Assign.Learn(member, marker)
    marker = tonumber(marker)
    if not (member and marker and marker >= 1 and marker <= 8) then return end
    if Assign.RegularFor(member, true) then return end
    return save(member, marker, false)
end

function Assign.Pin(member, marker)
    marker = tonumber(marker)
    if not (member and marker and marker >= 1 and marker <= 8) then return end
    -- One entry per person: drop learned entries under any of their keys.
    for _, key in ipairs(ns.Identity.Keys(member)) do regulars()[key] = nil end
    return save(member, marker, true)
end

function Assign.Unpin(member)
    for _, key in ipairs(ns.Identity.Keys(member)) do
        local entry = regulars()[key]
        if type(entry) == "table" and entry.pinned then regulars()[key] = nil end
    end
    refreshRegulars()
end

function Assign.IsPinned(member)
    return Assign.RegularFor(member, true) ~= nil
end

-- Pins an account straight from the friends list.
function Assign.PinTag(tag, marker, character)
    if not (tag and tonumber(marker)) then return end
    regulars()["bnet:" .. tag] = { marker = tonumber(marker), pinned = true, label = tag, seen = character, at = now() }
    refreshRegulars()
end

function Assign.Forget(key) regulars()[key] = nil; refreshRegulars() end

local function forgettable(entry)
    return type(entry) ~= "table" or not entry.pinned
end

function Assign.LearnedCount()
    local count = 0
    for _, entry in pairs(regulars()) do if forgettable(entry) then count = count + 1 end end
    return count
end

function Assign.ForgetLearned()
    for key, entry in pairs(regulars()) do
        if forgettable(entry) then regulars()[key] = nil end
    end
    refreshRegulars()
end

-- Sorted for the Markers page: pinned first by name, then most recent.
function Assign.List()
    local items = {}
    for key, entry in pairs(regulars()) do
        if type(entry) == "table" and tonumber(entry.marker) then
            items[#items + 1] = { key = key, marker = tonumber(entry.marker), pinned = entry.pinned == true,
                label = tostring(entry.label or key), seen = entry.seen, account = key:sub(1, 5) == "bnet:",
                at = tonumber(entry.at) or 0 }
        end
    end
    table.sort(items, function(a, b)
        if a.pinned ~= b.pinned then return a.pinned end
        if a.pinned or a.at == b.at then return a.label:lower() < b.label:lower() end
        return a.at > b.at
    end)
    return items
end

function Assign.SetMarker(key, marker)
    local entry = regulars()[key]
    if type(entry) == "table" and tonumber(marker) then entry.marker = tonumber(marker) end
end

-- This party's picks (the window's marker icon). Cleared when you leave.
function Assign.Pick(member, marker)
    local key = member and Assign.KeyFor(member)
    if not key then return end
    Assign.picked[key] = tonumber(marker)
    if ns.db.learn_mine ~= false then Assign.Learn(member, marker) end
end

function Assign.ClearPicks() Assign.picked = {} end

-- The plan -----------------------------------------------------------------------

-- members: { unit, key, guid, role, ... }. Returns one entry per member, in
-- party order: { member, marker, source, wanted? }.
function Assign.Plan(members)
    local db = ns.db
    local used, plan = {}, {}
    for index, member in ipairs(members) do plan[index] = { member = member, marker = 0, source = "none" } end
    local function give(slot, marker, source)
        marker = tonumber(marker)
        if slot.marker ~= 0 or not marker or marker < 1 or marker > 8 then return false end
        if used[marker] then
            slot.wanted = slot.wanted or marker
            return false
        end
        slot.marker, slot.source, used[marker] = marker, source, true
        return true
    end

    for _, slot in ipairs(plan) do
        local key = Assign.KeyFor(slot.member)
        if key and Assign.picked[key] then give(slot, Assign.picked[key], "picked") end
    end
    local regularsOn = false
    for _, rule in ipairs(rulesFor(db.marker_rules)) do
        if rule == "REGULARS" then
            regularsOn = true
            for _, slot in ipairs(plan) do
                if slot.marker == 0 then
                    local entry = Assign.RegularFor(slot.member, true)
                    if entry then give(slot, entry.marker, "pinned") end
                end
            end
        elseif rule == "ROLES" then
            local template = type(db.role_template) == "table" and db.role_template or Assign.ROLE_DEFAULT
            for _, role in ipairs({ "TANK", "HEALER" }) do
                for _, slot in ipairs(plan) do
                    if slot.marker == 0 and slot.member.role == role then
                        give(slot, template[role], role == "TANK" and "tank" or "healer")
                        break
                    end
                end
            end
        end
    end
    if regularsOn then
        for _, slot in ipairs(plan) do
            if slot.marker == 0 then
                local entry = Assign.RegularFor(slot.member, false)
                if entry then give(slot, entry.marker, "learned") end
            end
        end
    end
    local fill = Assign.FillOrder(db.fill_order)
    for _, slot in ipairs(plan) do
        if slot.marker == 0 then
            for _, marker in ipairs(fill) do
                if not used[marker] then give(slot, marker, "fill"); break end
            end
        end
    end
    return plan
end

-- member.fullName -> marker, for the secure cells.
function Assign.Markers(plan)
    local markers = {}
    for _, slot in ipairs(plan) do markers[slot.member.fullName] = slot.marker end
    return markers
end

-- The current party's plan.
function Assign.Current()
    return Assign.Plan(ns.getGroupMembers())
end

-- After a real click set someone's marker: learn it (unless it came from a
-- role, which says nothing about the person) and tell the party.
function Assign.Marked(slot)
    if not (slot and slot.marker and slot.marker > 0) then return end
    if ns.db.learn_mine ~= false and slot.source ~= "tank" and slot.source ~= "healer" then
        Assign.Learn(slot.member, slot.marker)
    end
    if ns.Share then ns.Share:Send(slot.member, slot.marker, slot.source) end
end
