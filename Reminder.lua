local addon, ns = ...

-- A nudge to mark the party when it forms or someone joins. It only ever
-- reminds; marking stays a click per member. Every trigger and output is a
-- setting (Reminder page). It follows the grid's Show rules (Visibility): a
-- reminder that comes due while the grid wouldn't show, or mid-fight, is
-- owed and fires once the grid can show, such as on zoning into a dungeon.

local Reminder = { members = nil, primed = false, pending = nil, lastAt = nil }
ns.Reminder = Reminder

Reminder.DEFAULTS = {
    remind_enabled = true,
    remind_on_join = true,
    remind_on_member = false,
    remind_leader_only = false,
    remind_chat = true,
    remind_screen = true,
    remind_sound = false,
}

local THROTTLE = 10
local RAID_WARNING_SOUND = 8959

local MESSAGES = {
    join = "New party! Mark everyone so they're easy to spot.",
    member = "Someone new joined. Give them a marker.",
    test = "This is what your mark reminder looks like.",
}

local function now() return GetTime and GetTime() or 0 end

local function inCombat() return InCombatLockdown and InCombatLockdown() end

-- GUIDs of everyone in an eligible party, or nil when there isn't one.
local function snapshot()
    if not (ns.isEligibleGroup and ns.isEligibleGroup()) then return nil end
    local set = {}
    for _, member in ipairs(ns.getGroupMembers()) do
        set[UnitGUID(member.unit) or member.fullName] = true
    end
    return set
end

-- Called on world entry: what's already there doesn't count as joining.
function Reminder:Prime()
    self.members = snapshot()
    self.primed = true
end

local function allowed(db)
    if not db.remind_enabled then return false end
    if db.remind_leader_only and UnitIsGroupLeader and not UnitIsGroupLeader("player") then return false end
    return true
end

-- Whether the grid would show now: Never, a hidden grid and its Show rules.
local function gridCanShow(db)
    if db.visibility_mode == "HIDDEN" then return false end
    return not ns.gridConditionsMatch or ns.gridConditionsMatch()
end

function Reminder:Check()
    local db = ns.db
    -- Roster events can arrive before the first world entry; until then
    -- there's no "before" to compare with.
    if not db or not self.primed then return end
    local before, after = self.members, snapshot()
    self.members = after
    if not after then
        self.owed = nil
        return
    end
    local reason
    if not before then
        reason = db.remind_on_join and "join" or nil
    elseif db.remind_on_member then
        for guid in pairs(after) do
            if not before[guid] and guid ~= UnitGUID("player") then reason = "member"; break end
        end
    end
    if not reason or not allowed(db) then return end
    self.owed = reason
    self:Recheck()
end

-- Delivers an owed reminder once nothing is in the way: after combat, on
-- entering a place the grid shows, or when you become leader.
function Reminder:Recheck()
    local db = ns.db
    if not (self.owed and self.members and db) or inCombat() then return end
    if not allowed(db) then self.owed = nil; return end
    if not gridCanShow(db) then return end
    local reason = self.owed
    self.owed = nil
    self:Fire(reason)
end

function Reminder:CombatEnded() self:Recheck() end

function Reminder:Fire(reason, force)
    local db = ns.db
    if not force then
        if self.lastAt and now() - self.lastAt < THROTTLE then return false end
        self.lastAt = now()
    end
    local text = MESSAGES[reason] or MESSAGES.join
    if db.remind_chat then ns.HammerCore.Print(text) end
    if db.remind_screen then
        if RaidNotice_AddMessage and RaidWarningFrame then
            RaidNotice_AddMessage(RaidWarningFrame, "CheckMark: " .. text,
                ChatTypeInfo and ChatTypeInfo.RAID_WARNING or { r = 1, g = 0.82, b = 0 })
        elseif UIErrorsFrame then
            UIErrorsFrame:AddMessage("CheckMark: " .. text, 1, 0.82, 0)
        end
    end
    if db.remind_sound and PlaySound then
        pcall(PlaySound, SOUNDKIT and SOUNDKIT.RAID_WARNING or RAID_WARNING_SOUND, "Master")
    end
    self.lastReason = reason
    return true
end

-- Uses the chosen outputs, so the test shows exactly what a party gets.
function Reminder:Test()
    local db = ns.db
    if not (db.remind_chat or db.remind_screen or db.remind_sound) then
        ns.HammerCore.Print("every reminder output is off, so a reminder would be silent")
        return false
    end
    return self:Fire("test", true)
end
