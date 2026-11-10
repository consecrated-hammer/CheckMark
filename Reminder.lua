local addon, ns = ...

-- A nudge to mark the party when it forms or someone joins. It only ever
-- reminds; marking stays a click per member. Every trigger, wait and output
-- is a setting (Reminder page). It follows the grid's Show rules
-- (Visibility): a reminder that comes due while the grid wouldn't show, or
-- mid-fight, is owed and fires once the grid can show, such as on zoning
-- into a dungeon.
--
-- Timing: a reminder waits a moment after someone joins (each new joiner
-- restarts the wait, so one window has everyone), and a moment after
-- combat so you can loot. The after-combat wait replaces the join wait.

local Reminder = { members = nil, primed = false, lastAt = nil, token = 0 }
ns.Reminder = Reminder

Reminder.DEFAULTS = {
    remind_enabled = true,
    remind_on_join = true,
    remind_on_member = true,
    remind_leader_only = false,
    remind_window = true,
    remind_join_wait = true,
    remind_join_seconds = 2,
    remind_combat_wait = true,
    remind_combat_seconds = 3,
    remind_close_done = true,
    remind_timeout = false,
    remind_timeout_seconds = 20,
    remind_window_size = "MEDIUM",
    remind_quiet_others = true,
    remind_chat = true,
    remind_screen = false,
    remind_sound = false,
}

local THROTTLE = 10
local RAID_WARNING_SOUND = 8959

-- Each reminder picks a line at random, so it doesn't nag in the same words.
local MESSAGES = {
    join = {
        "New party! Hand out the markers.",
        "Fresh party. Time to give everyone a shiny new hat.",
        "A wild party appears! Mark them before they scatter.",
        "New party! Mark them now, thank yourself later.",
        "Party assembled. Markers, please.",
        "New party! Nobody wants to be 'um, them, over there somewhere'.",
        "New party! Skip the 'no, the OTHER one' chat.",
    },
    member = {
        "Someone new joined. They're looking a bit iconless.",
        "Fresh face in the party. They'll want a marker.",
        "New arrival! Don't let them wander about unmarked.",
        "Someone joined. Pop a marker on their head.",
    },
    test = { "This is what your mark reminder looks like." },
}

Reminder.MESSAGES = MESSAGES

local function pick(lines)
    return lines[math.random(#lines)]
end

local function now() return GetTime and GetTime() or 0 end

local function inCombat() return InCombatLockdown and InCombatLockdown() end

-- GUIDs of everyone in an eligible party, or nil when there isn't one.
local function snapshot()
    if not (ns.isEligibleGroup and ns.isEligibleGroup()) then return nil end
    local set = {}
    for _, member in ipairs(ns.getGroupMembers()) do
        set[member.guid or member.fullName] = true
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
        if ns.Assign then ns.Assign.ClearPicks() end
        if ns.Share then ns.Share:Reset() end
        return
    end
    local reason
    if not before then
        reason = db.remind_on_join and "join" or nil
    elseif db.remind_on_member then
        local me = UnitGUID and UnitGUID("player")
        for guid in pairs(after) do
            if not before[guid] and guid ~= me then reason = "member"; break end
        end
    end
    if not reason or not allowed(db) then return end
    -- A party that's still forming stays a "join".
    if self.owed ~= "join" then self.owed = reason end
    self:Schedule("join")
end

-- Waits the join or after-combat time, then delivers. A newer call
-- restarts the wait.
function Reminder:Schedule(kind)
    if inCombat() then return end
    local db = ns.db
    local wait = 0
    if kind == "combat" then
        wait = db.remind_combat_wait and tonumber(db.remind_combat_seconds) or 0
    else
        wait = db.remind_join_wait and tonumber(db.remind_join_seconds) or 0
    end
    self.token = self.token + 1
    local token, held = self.token, kind == "combat"
    if wait > 0 and C_Timer and C_Timer.After then
        C_Timer.After(wait, function()
            if Reminder.token == token then Reminder:Recheck(held) end
        end)
    else
        self:Recheck(held)
    end
end

-- Delivers an owed reminder once nothing is in the way: after combat, on
-- entering a place the grid shows, or when you become leader. A window
-- that combat closed comes back here too.
function Reminder:Recheck(held)
    local db = ns.db
    if not db or inCombat() then return end
    local fired = self:Deliver(held)
    -- Whatever happened to the owed reminder, a window combat closed gets
    -- its chance to come back.
    if not fired and ns.MarkWindow and ns.MarkWindow.interrupted then ns.MarkWindow:Reopen() end
end

function Reminder:Deliver(held)
    local db = ns.db
    if not (self.owed and self.members) then return false end
    if not allowed(db) then self.owed = nil; return false end
    if not gridCanShow(db) then return false end
    if db.remind_quiet_others and ns.Share and ns.Share:OtherMarker() then self.owed = nil; return false end
    local reason = self.owed
    self.owed = nil
    -- One held through combat isn't throttled away.
    return self:Fire(reason, held)
end

function Reminder:CombatEnded()
    if self.owed or (ns.MarkWindow and ns.MarkWindow.interrupted) then self:Schedule("combat") end
end

local function outputs(db)
    return db.remind_window or db.remind_chat or db.remind_screen or db.remind_sound
end

function Reminder:Fire(reason, force, test)
    local db = ns.db
    if not force then
        if self.lastAt and now() - self.lastAt < THROTTLE then return false end
        self.lastAt = now()
    end
    local text = pick(MESSAGES[reason] or MESSAGES.join)
    if db.remind_window and ns.MarkWindow then
        if test then ns.MarkWindow:Test(text) else ns.MarkWindow:Open(text) end
    end
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
-- The window shows a sample party; the waits are skipped.
function Reminder:Test()
    local db = ns.db
    if not outputs(db) then
        ns.HammerCore.Print("every reminder output is off, so a reminder would be silent")
        return false
    end
    return self:Fire("test", true, true)
end
