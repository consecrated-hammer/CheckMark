package.path = "./tests/hammercore/?.lua;" .. package.path
local wow = require("wow")

-- 1.4.0: markers follow people, the marking window, timing, sharing,
-- profiles and the one-time update for existing players.

local function equal(actual, expected, label)
    if actual ~= expected then
        error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

local party, timers, combat, clock

local function installClient(forever)
    party = { player = { name = "Kevin", realm = "Realm", role = "NONE" } }
    timers, combat, clock = {}, false, 100
    RegisterStateDriver = function() end
    UnregisterStateDriver = function() end
    IsInInstance = function() return false, "none" end
    IsInRaid = function() return false end
    IsInGroup = function() return party.party1 ~= nil end
    UnitExists = function(unit) return party[unit] ~= nil end
    UnitGUID = function(unit) return party[unit] and ("Player-" .. party[unit].name .. (party[unit].surname or "") .. "-" .. (party[unit].realm or "Realm")) end
    UnitName = function(unit)
        local who = party[unit]
        if not who then return nil end
        if forever then return who.name, who.surname end
        return who.name, who.realm ~= "Realm" and who.realm or nil
    end
    GetUnitName = nil
    UnitClass = function() return "Paladin", "PALADIN" end
    UnitGroupRolesAssigned = function(unit) return party[unit] and party[unit].role or "NONE" end
    UnitIsGroupLeader = function() return true end
    GetRealmName = function() return "Realm" end
    GetBuildInfo = function() return "12.1.0", "1", "", 120100 end
    GetTime = function() return clock end
    PlaySound = function() return true end
    InCombatLockdown = function() return combat end
    C_Timer = { After = function(seconds, fn) timers[#timers + 1] = { seconds = seconds, fn = fn } end }
    UIErrorsFrame = { AddMessage = function() end }
    BNGetInfo = function() return 1, "Kevin#1111" end
    BNGetNumFriends = function() return 2 end
    C_BattleNet = {
        GetFriendAccountInfo = function(index)
            local friends = {
                { battleTag = "Bianca#2222", gameAccountInfo = { playerGuid = "Player-Thornwyn-Realm", characterName = "Thornwyn" } },
                { battleTag = "Sarah#3333", gameAccountInfo = { playerGuid = "Player-Lumi-Realm", characterName = "Lumi" } },
            }
            return friends[index]
        end,
    }
end

-- Runs every pending timer (and any they start); returns the waits seen.
local function flush()
    local waits = {}
    while #timers > 0 do
        local timer = table.remove(timers, 1)
        waits[#waits + 1] = timer.seconds
        timer.fn()
    end
    return waits
end

local function waited(waits, seconds)
    for _, value in ipairs(waits) do if value == seconds then return true end end
    return false
end

local function loadAddon(tocName, saved)
    local forever = tocName:find("Camelot") ~= nil
    wow.Install({ CheckMark = { Version = "1.4.0-dev1", ["X-CheckMark-Target"] = forever and "Camelot" or nil } })
    installClient(forever)
    CheckMarkDB = saved
    local ns = {}
    for line in io.lines(tocName) do
        local entry = line:gsub("\r", ""):gsub("\\", "/")
        if entry:match("%.xml$") then
            wow.LoadHammerCore(entry:match("^(.*)/[^/]+$"), "CheckMark", ns)
        elseif entry:match("%.lua$") then
            assert(loadfile(entry))("CheckMark", ns)
        end
    end
    local core = _G.CheckMarkCore
    core.scripts.OnEvent(core, "ADDON_LOADED", "CheckMark")
    flush()
    return ns, core
end

local function markers(plan)
    local names = {}
    for _, slot in ipairs(plan) do names[#names + 1] = ns_marker_name(slot.marker) end
    return table.concat(names, ",")
end
function ns_marker_name(marker)
    return ({ [0] = "None", "Star", "Circle", "Diamond", "Triangle", "Moon", "Square", "Cross", "Skull" })[marker]
end

-- Who gets what ---------------------------------------------------------------

do
    local ns = loadAddon("CheckMark.toc", {})
    local A = ns.Assign
    equal(ns.HammerCore.Profiles:Active(), "World", "a fresh install starts in World")
    equal(ns.db.hcProfiles.auto.mode, "AUTO", "profiles switch on their own by default")

    -- A role-less world party of five, nobody known: the fill order.
    party.party1 = { name = "Thornwyn", realm = "Realm" }
    party.party2 = { name = "Lumi", realm = "Realm" }
    party.party3 = { name = "Grimbar", realm = "Realm" }
    party.party4 = { name = "Velaxi", realm = "Realm" }
    ns.Identity:RefreshFriends()
    equal(markers(A.Current()), "Star,Circle,Triangle,Moon,Square", "everyone in a world party of five gets a marker")

    -- The usual crew: Bianca and Kevin pinned, Sarah learned.
    local members = ns.getGroupMembers()
    A.Pin(members[1], 6)                -- Kevin: Square
    A.Pin(members[2], 3)                -- Bianca (Thornwyn): Diamond
    A.Learn(members[3], 1)              -- Sarah (Lumi): Star
    equal(ns.db.regulars["bnet:Bianca#2222"].marker, 3, "a Battle.net friend is pinned by BattleTag")
    equal(markers(A.Current()), "Square,Diamond,Star,Circle,Triangle", "world: regulars first, randoms fill")

    -- Party order and the leader don't matter.
    party.party1, party.party2 = party.party2, party.party1
    equal(markers(A.Current()), "Square,Star,Diamond,Circle,Triangle", "markers follow people, not slots")

    -- Bianca on an alt still gets Diamond.
    party.party2 = { name = "Brightleaf", realm = "Realm" }
    C_BattleNet.GetFriendAccountInfo = function(index)
        return ({ { battleTag = "Bianca#2222", gameAccountInfo = { playerGuid = "Player-Brightleaf-Realm" } },
            { battleTag = "Sarah#3333", gameAccountInfo = { playerGuid = "Player-Lumi-Realm" } } })[index]
    end
    ns.Identity:RefreshFriends()
    equal(A.Current()[3].marker, 3, "a regular keeps their marker on an alt")
    equal(A.Current()[3].source, "pinned", "the alt matches the pinned account")

    -- Dungeon: roles first. Kevin heals, a rando tanks.
    party.party2 = { name = "Thornwyn", realm = "Realm", role = "DAMAGER" }
    party.player.role = "HEALER"
    party.party3 = { name = "Grimbar", realm = "Realm", role = "TANK" }
    ns.db.marker_rules = "ROLES_REGULARS"
    local plan = A.Current()
    equal(markers(plan), "Diamond,Star,Circle,Skull,Triangle", "dungeon: healer and tank first, then regulars, then fill")
    equal(plan[3].wanted, 3, "Bianca's Diamond went to the healer")
    equal(plan[1].source, "healer", "Kevin heals with the healer's marker")
    ns.db.marker_rules = "REGULARS_ROLES"
    party.player.role = "NONE"

    -- A pick in the window wins for this party and is learned.
    A.Pick(ns.getGroupMembers()[5], 7)
    equal(A.Current()[5].marker, 7, "a picked marker wins")
    A.ClearPicks()
    equal(A.Current()[5].source, "learned", "a picked marker is learned for next time")
    A.ForgetLearned()
    equal(ns.db.regulars["bnet:Kevin#1111"].pinned, true, "forgetting learned keeps pins")
    equal(A.Current()[5].source, "fill", "learned markers are forgotten")

    -- Real clicks learn, except role markers.
    party.party3.role = "TANK"
    ns.db.marker_rules = "ROLES_REGULARS"
    for _, slot in ipairs(A.Current()) do A.Marked(slot) end
    local learned = 0
    for _, entry in pairs(ns.db.regulars) do if not entry.pinned then learned = learned + 1 end end
    equal(learned, 2, "clicks learn people, not the tank's role marker")
end

-- Names ------------------------------------------------------------------------------

do
    local ns = loadAddon("CheckMark_Camelot.toc", {})
    party.party1 = { name = "Bob", surname = "Smith" }
    party.party2 = { name = "Bob", surname = "Jones" }
    party.party3 = { name = "Ada", surname = "Lovelace" }
    local members = ns.Identity.Label(ns.getGroupMembers())
    equal(members[2].key, "char:bobsmith-realm", "a Forever surname is part of the name, not the realm")
    equal(members[2].label, "Bob Smith", "two Bobs show their surnames")
    equal(members[3].label, "Bob Jones", "the other Bob too")
    equal(members[4].label, "Ada", "everyone else shows a first name")
    equal(members[2].key ~= members[3].key, true, "two Bobs are two people")

    ns = loadAddon("CheckMark.toc", {})
    party.party1 = { name = "Bob", realm = "Frostmourne" }
    party.party2 = { name = "Bob", realm = "Nagrand" }
    members = ns.Identity.Label(ns.getGroupMembers())
    equal(members[2].label, "Bob-Frostmourne", "Retail adds the realm only when names clash")
    equal(members[1].label, "Kevin", "your own name stays short")
end

-- Updating from 1.3 ------------------------------------------------------------------

do
    local ns = loadAddon("CheckMark.toc", { remind_screen = true, remind_on_member = false,
        role_template = { TANK = 8, HEALER = 3, DPS1 = 6, DPS2 = 0, DPS3 = 5 } })
    equal(ns.db.remind_screen, false, "the on-screen message is switched off once")
    equal(ns.db.remind_on_member, true, "newcomer reminders are switched on once")
    equal(ns.db.fill_order[1], 6, "old DPS markers lead the fill order")
    equal(ns.db.fill_order[2], 5, "in their old order")
    equal(#ns.db.fill_order, 8, "the fill order holds each marker once")
    equal(ns.db.role_template.DPS1, nil, "DPS slots are gone")
    local P = ns.HammerCore.Profiles
    equal(P:Exists("World") and P:Exists("Delve") and P:Exists("Dungeon"), true, "the starter profiles exist")
    equal(P:Data().list.Dungeon.marker_rules, "ROLES_REGULARS", "Dungeon puts roles first")
    equal(P:Data().list.World.role_template.TANK, 8, "your tank marker carries into every profile")
    ns.db.remind_screen = true
    ns = loadAddon("CheckMark.toc", CheckMarkDB)
    equal(ns.db.remind_screen, true, "the update only happens once")
end

-- Timing and the window ---------------------------------------------------------------

do
    local ns, core = loadAddon("CheckMark.toc", {})
    local W = ns.MarkWindow
    local function fire(event, ...) core.scripts.OnEvent(core, event, ...) end
    fire("PLAYER_ENTERING_WORLD"); flush()

    party.party1 = { name = "Thornwyn", realm = "Realm" }
    fire("GROUP_ROSTER_UPDATE")
    equal(W:IsShown(), false, "the window waits after someone joins")
    local waits = flush()
    equal(waited(waits, 2), true, "it waits 2 seconds by default")
    equal(W:IsShown(), true, "then opens")
    equal(#W.plan, 2, "with a card for each member")
    equal(W.cards[2]:GetAttribute("marker1"), 2, "each card is a secure marker button")
    equal(W.cards[2]:GetAttribute("unit1"), "party1", "aimed at that member")

    -- Clicking every card closes it.
    for index = 1, 2 do W.cards[index].scripts.PostClick(W.cards[index], "LeftButton") end
    equal(W:AllClicked(), true, "every card clicked")
    flush()
    equal(W:IsShown(), false, "it closes once you've clicked everyone")

    -- Someone joins mid-fight: one window after combat, after the loot wait.
    clock = clock + 60
    combat = true
    party.party2 = { name = "Lumi", realm = "Realm" }
    fire("GROUP_ROSTER_UPDATE"); flush()
    equal(W:IsShown(), false, "nothing in combat")
    combat = false
    fire("PLAYER_REGEN_ENABLED")
    waits = flush()
    equal(waited(waits, 3), true, "it waits 3 seconds after combat")
    equal(W:IsShown(), true, "then opens with the newcomer")

    -- Combat closes it before you've clicked everyone: it comes back.
    W.cards[1].scripts.PostClick(W.cards[1], "LeftButton")
    W.window:Hide()
    equal(W.interrupted, true, "combat interrupted it")
    fire("PLAYER_REGEN_ENABLED")
    flush()
    equal(W:IsShown(), true, "it comes back after combat")
    equal(W.cards[1].tick:IsShown(), true, "with your ticks kept")

    -- Turning the waits off delivers at once.
    W:Close()
    ns.db.remind_join_wait = false
    party.party1, party.party2 = nil, nil
    fire("GROUP_ROSTER_UPDATE"); flush()
    clock = clock + 60
    party.party1 = { name = "Grimbar", realm = "Realm" }
    fire("GROUP_ROSTER_UPDATE")
    waits = flush()
    equal(waited(waits, 2), false, "no join wait when it's off")
    equal(W:IsShown(), true, "the window opens straight away")
    W:Close()

    -- Test shows a sample party that can't mark.
    ns.Reminder:Test()
    equal(W.test, true, "test opens a sample window")
    equal(W.cards[1]:GetAttribute("type1"), nil, "sample cards can't mark")
    W:Close()
end

-- Party sharing ------------------------------------------------------------------------

do
    local ns, core = loadAddon("CheckMark.toc", {})
    local function fire(event, ...) core.scripts.OnEvent(core, event, ...) end
    fire("PLAYER_ENTERING_WORLD"); flush()
    local sent = {}
    C_ChatInfo.RegisterAddonMessagePrefix = function() return true end
    C_ChatInfo.SendAddonMessage = function(prefix, text, channel) sent[#sent + 1] = { prefix, text, channel } end
    party.party1 = { name = "Thornwyn", realm = "Realm" }
    party.party2 = { name = "Lumi", realm = "Realm" }
    local plan = ns.Assign.Current()
    ns.Assign.Marked(plan[2])
    equal(sent[1] and sent[1][2], "1:M:Player-Kevin-Realm:Player-Thornwyn-Realm:2:fill", "a click is shared with the party")
    equal(sent[1][3], "PARTY", "on the party channel")

    -- Sarah's CheckMark marks Bianca with Diamond.
    fire("CHAT_MSG_ADDON", "CheckMark", "1:M:Player-Lumi-Realm:Player-Thornwyn-Realm:3", "PARTY", "Lumi-Realm")
    flush()
    equal(ns.db.regulars["bnet:Bianca#2222"].marker, 3, "learned from the party, by BattleTag")
    equal(ns.Share:OtherMarker().name, "Lumi", "you know who's marking")

    -- So a reminder stays quiet.
    party.party3 = { name = "Grimbar", realm = "Realm" }
    fire("GROUP_ROSTER_UPDATE"); flush()
    equal(ns.MarkWindow:IsShown(), false, "no window while someone else is marking")

    ns.db.share_party = false
    sent = {}
    ns.Assign.Marked(plan[2])
    equal(#sent, 0, "sharing can be turned off")
end

-- Review fixes ------------------------------------------------------------------------

do
    local ns, core = loadAddon("CheckMark.toc", {})
    local A, W = ns.Assign, ns.MarkWindow
    local function fire(event, ...) core.scripts.OnEvent(core, event, ...) end
    fire("PLAYER_ENTERING_WORLD"); flush()

    -- A role marker from someone else's CheckMark isn't learned.
    party.party1 = { name = "Grimbar", realm = "Realm", role = "TANK" }
    party.party2 = { name = "Lumi", realm = "Realm" }
    fire("CHAT_MSG_ADDON", "CheckMark", "1:M:Player-Lumi-Realm:Player-Grimbar-Realm:8:tank", "PARTY", "Lumi-Realm")
    equal(ns.db.regulars["char:grimbar-realm"], nil, "a shared tank marker isn't learned")
    fire("CHAT_MSG_ADDON", "CheckMark", "1:M:Player-Lumi-Realm:Player-Grimbar-Realm:8", "PARTY", "Lumi-Realm")
    equal(ns.db.regulars["char:grimbar-realm"], nil, "nor one that looks like their role's marker")
    fire("CHAT_MSG_ADDON", "CheckMark", "1:M:Player-Lumi-Realm:Player-Grimbar-Realm:5:fill", "PARTY", "Lumi-Realm")
    equal(ns.db.regulars["char:grimbar-realm"].marker, 5, "other shared markers are learned")

    -- A learned random doesn't take the tank's Skull.
    party.party2 = { name = "Velaxi", realm = "Realm", role = "DAMAGER" }
    A.Learn(ns.getGroupMembers()[3], 8)
    ns.db.marker_rules = "REGULARS_ROLES"
    local plan = A.Current()
    equal(plan[2].marker, 8, "the tank keeps Skull")
    equal(plan[3].wanted, 8, "the learned random wanted it")
    equal(plan[3].source, "fill", "and takes the fill order instead")

    -- A pinned regular still beats roles in the world rules.
    A.Pin(ns.getGroupMembers()[3], 8)
    equal(A.Current()[3].source, "pinned", "a pin outranks the tank's role")
    A.Unpin(ns.getGroupMembers()[3])
    A.ForgetLearned()

    -- Combat closes the window, a newcomer arrives, the reminder is throttled:
    -- the window still comes back.
    W:Open("Test")
    W.window:Hide()
    equal(W.interrupted, true, "combat closed it")
    fire("PLAYER_REGEN_ENABLED")
    party.party3 = { name = "Pip", realm = "Realm" }
    ns.Reminder.lastAt = clock
    fire("GROUP_ROSTER_UPDATE")
    flush()
    equal(W:IsShown(), true, "a throttled reminder doesn't strand the window")

    -- A tick holds only for the marker you clicked.
    local card = W.cards[2]
    card.scripts.PostClick(card, "LeftButton")
    equal(card.tick:IsShown(), true, "clicked card ticks")
    ns.db.role_template.TANK = 7
    W:Refresh()
    equal(W.cards[2].tick:IsShown(), false, "a changed marker un-ticks")
    W:Close()
    W:Close()
    equal(W.closing ~= true, true, "closing a closed window leaves no stale flag")

    -- A hidden name still gets a card.
    UnitName = function(unit) if unit == "party1" then return nil end return party[unit] and party[unit].name end
    local members = ns.getGroupMembers()
    equal(members[2].label or members[2].first, "Party 1", "a hidden name shows as its party slot")
    A.Learn(members[2], 4)
    equal(ns.db.regulars["unit:party1"], nil, "a hidden name is never learned")
end

-- Regulars has its own tab and refreshes after edits without losing that tab.
for _, toc in ipairs({ "CheckMark.toc", "CheckMark_Camelot.toc" }) do
    local ns = loadAddon(toc, {})
    local settings, A = ns.HammerCore.Settings, ns.Assign
    settings:Show("Markers", "People")
    local page = settings.pages.Markers
    equal(table.concat(page.tabs, ","), "Assignments,People", toc .. ": marker tabs")
    equal(page.selectedTab, "People", toc .. ": People selected")
    local body = page.bodies.People.content
    equal(#body.regularRows, 0, toc .. ": empty list allocates no rows")
    assert(page.bodies.Assignments.hcRows["Who goes first"], "assignment rules stay on Assignments")
    assert(page.bodies.People.hcRows["Add a Battle.net friend"], "friend picker lives on People")
    equal(settings:Search("Add a Battle.net friend")[1].tab, "People", toc .. ": search finds the new tab")
    A.PinTag("Bianca#2222", 3, "Thornwyn")
    party.party1 = { name = "Visitor", realm = "Realm" }
    A.Learn(ns.getGroupMembers()[2], 5)
    settings:Select("Markers", "People")
    equal(body.regularRows[1]:IsShown(), true, toc .. ": new entries appear")
    equal(body.regularRows[2]:IsShown(), true, toc .. ": pinned and learned entries")
    equal(settings:Search("Bianca")[1].tab, "People", toc .. ": search finds a regular")
    local forget = assert(wow.FindButton("Forget learned"))
    forget.scripts.OnClick(forget)
    local dialog = ns.HammerCore.Dialog
    equal(#A.List(), 2, toc .. ": forget waits for confirmation")
    equal(dialog.current.text, "Forget 1 learned person? Pinned people stay.", toc .. ": confirmation names learned count and preserves pins")
    wow.Click(dialog.frame.cancel)
    equal(#A.List(), 2, toc .. ": cancel preserves learned people")
    forget.scripts.OnClick(forget)
    wow.Click(dialog.frame.accept)
    equal(page.selectedTab, "People", toc .. ": edits keep the People tab")
    equal(#A.List(), 1, toc .. ": forget learned preserves pinned regulars")
    equal(body.regularRows[2]:IsShown(), false, toc .. ": removed entry is hidden")
    ns.db.regulars.badMarker = { marker = "not a marker", pinned = false }
    ns.db.regulars.badEntry = "malformed"
    ns.db.regulars.badPinned = { marker = nil, pinned = true }
    equal(A.LearnedCount(), 2, toc .. ": hidden malformed entries count toward forgetting")
    forget.scripts.OnClick(forget)
    equal(dialog.current.text, "Forget 2 learned people? Pinned people stay.", toc .. ": confirmation matches the deletion predicate")
    wow.Click(dialog.frame.accept)
    equal(ns.db.regulars.badMarker, nil, toc .. ": malformed unpinned marker is forgotten")
    equal(ns.db.regulars.badEntry, nil, toc .. ": malformed entry is forgotten")
    assert(ns.db.regulars.badPinned, "malformed pinned entry stays")
    forget.scripts.OnClick(forget)
    equal(dialog:IsShown(), false, toc .. ": empty learned list needs no confirmation")

    assert(body.regularRows[1].Title.text:find("Bianca", 1, true), "remaining row is rebound to its regular")
    body.regularRows[1].remove.scripts.OnClick(body.regularRows[1].remove)
    equal(#A.List(), 0, toc .. ": remove targets the rebound row")
    equal(body.regularRows[1]:IsShown(), false, toc .. ": last removed row disappears")
    equal(#settings:Search("Bianca"), 0, toc .. ": removed names leave search")
    equal(page.selectedTab, "People", toc .. ": remove keeps the tab")
    settings:Select("Markers", "Assignments")
    equal(page.selectedTab, "Assignments", toc .. ": assignments remain accessible")
end

-- Only pinned newcomers can trigger the optional crew-only reminder.
local pinnedChecks=0
local function pinnedEqual(a,b,label)pinnedChecks=pinnedChecks+1;equal(a,b,label)end
for _,toc in ipairs({"CheckMark.toc","CheckMark_Camelot.toc"})do
    local ns,core=loadAddon(toc,{schema=2,remind_pinned_only=true,remind_chat=false})
    local R,W,A=ns.Reminder,ns.MarkWindow,ns.Assign
    local function fire(event)core.scripts.OnEvent(core,event)end
    fire("PLAYER_ENTERING_WORLD");flush()
    pinnedEqual(ns.db.remind_pinned_only,true,toc..": saved pinned-only preference preserved")
    A.Pin(ns.getGroupMembers()[1],6)
    party.party1={name="Visitor",realm="Realm"}
    fire("GROUP_ROSTER_UPDATE");flush()
    pinnedEqual(W:IsShown(),false,toc..": forming party with random does not alert, even when self is pinned")
    party.party2={name="Lumi",realm="Realm"}
    A.Learn(ns.getGroupMembers()[3],4)
    fire("GROUP_ROSTER_UPDATE");flush()
    pinnedEqual(W:IsShown(),false,toc..": a learned marker alone is not a pin")
    A.PinTag("Bianca#2222",3,"Thornwyn")
    party.party3={name="Thornwyn",realm="Realm"}
    fire("GROUP_ROSTER_UPDATE");flush()
    pinnedEqual(W:IsShown(),true,toc..": pinned newcomer opens marking window")
    pinnedEqual(#W.plan,4,toc..": qualifying reminder still includes whole party")
    W:Close();clock=clock+11
    party.party4={name="Random",realm="Realm"}
    fire("GROUP_ROSTER_UPDATE");flush()
    pinnedEqual(W:IsShown(),false,toc..": existing pinned member does not let a random newcomer trigger popup")
    party.party3=nil;R:Check()
    party.party3={name="Thornwyn",realm="Realm"};R:Check()
    pinnedEqual(R.owed~=nil,true,toc..": pinned arrival queues normal join wait")
    party.party3=nil;R:Check();flush()
    pinnedEqual(W:IsShown(),false,toc..": pinned member leaving before timer cancels popup")
    pinnedEqual(R.owed,nil,toc..": stale pinned reminder cleared")
    combat=true;party.party3={name="Thornwyn",realm="Realm"};R:Check()
    pinnedEqual(R.owed~=nil,true,toc..": pinned arrival held through combat")
    party.party3=nil;R:Check();combat=false;fire("PLAYER_REGEN_ENABLED");flush()
    pinnedEqual(W:IsShown(),false,toc..": departed pin does not pop up after combat")
    party.party3={name="Thornwyn",realm="Realm"};R:Check()
    for _,member in ipairs(ns.getGroupMembers())do if member.unit=="party3"then A.Unpin(member)end end
    flush();pinnedEqual(W:IsShown(),false,toc..": removing pin before delivery cancels popup")
    party.party3=nil;R:Check()
    -- A friend on an alt still matches the account-level pin.
    A.PinTag("Bianca#2222",3,"Thornwyn")
    C_BattleNet.GetFriendAccountInfo=function()return {battleTag="Bianca#2222",gameAccountInfo={playerGuid="Player-Brightleaf-Realm"}}end
    party.party3={name="Brightleaf",realm="Realm"};ns.Identity:RefreshFriends();clock=clock+11
    R:Check();flush()
    pinnedEqual(W:IsShown(),true,toc..": Battle.net-linked pinned alt triggers reminder")
    W:Close();party.party3=nil;R:Check();flush()
    R:Test();pinnedEqual(W:IsShown(),true,toc..": manual test bypasses pinned-only filter")
    W:Close();W:Open();pinnedEqual(W:IsShown(),true,toc..": manual mark-party opening bypasses filter")
    W:Close()
    local settings=ns.HammerCore.Settings
    settings:Show("Reminder","When and how")
    local found=false
    for _,result in ipairs(settings:Search("Pinned members only"))do
        if result.label=="Pinned members only" and result.tab=="When and how"then found=true end
    end
    pinnedEqual(found,true,toc..": pinned filter searchable on Reminder tab")
    -- Joining a pre-existing crew counts as a join, not just a later arrival.
    party.party1,party.party2,party.party3,party.party4=nil,nil,nil,nil;R:Check()
    party.party1={name="Brightleaf",realm="Realm"};clock=clock+11;R:Check();flush()
    pinnedEqual(W:IsShown(),true,toc..": joining party containing a pinned member triggers reminder")
    W:Close()
    ns.db.remind_pinned_only=false;clock=clock+11
    party.party2={name="Stranger",realm="Realm"};R:Check();flush()
    pinnedEqual(W:IsShown(),true,toc..": turning filter off restores random newcomer reminders")
    W:Close()
    ns.db.remind_pinned_only=true;ns.db.remind_on_member=false
    party.party1,party.party2,party.party3,party.party4=nil,nil,nil,nil;R:Check()
    -- A delayed Battle.net identity must keep the original party-join trigger.
    C_BattleNet.GetFriendAccountInfo=function()return nil end
    ns.Identity:RefreshFriends()
    party.party1={name="Latealt",realm="Realm"};clock=clock+11
    R:Check();flush()
    pinnedEqual(W:IsShown(),false,toc..": unresolved account does not trigger early")
    C_BattleNet.GetFriendAccountInfo=function()return {battleTag="Bianca#2222",gameAccountInfo={playerGuid="Player-Latealt-Realm"}}end
    fire("BN_FRIEND_INFO_CHANGED");flush()
    pinnedEqual(W:IsShown(),true,toc..": delayed account resolution preserves join-only trigger")
    W:Close();party.party1=nil;R:Check()
    -- The initial roster may not have a name or GUID yet.
    party.party1={name="Thornwyn",realm="Realm"};clock=clock+11
    local oldName,oldGUID=UnitName,UnitGUID
    UnitName=function(unit)if unit=="party1"then return nil end;return oldName(unit)end
    UnitGUID=function(unit)if unit=="party1"then return nil end;return oldGUID(unit)end
    R:Check()
    UnitName,UnitGUID=oldName,oldGUID
    R:Check();flush()
    pinnedEqual(W:IsShown(),true,toc..": resolving anonymous roster preserves join-only trigger")
    W:Close();party.party1=nil;R:Check()
    party.party1={name="Lateexpired",realm="Realm"};R:Check();flush()
    clock=clock+6
    C_BattleNet.GetFriendAccountInfo=function()return {battleTag="Bianca#2222",gameAccountInfo={playerGuid="Player-Lateexpired-Realm"}}end
    fire("BN_FRIEND_INFO_CHANGED");flush()
    pinnedEqual(W:IsShown(),false,toc..": identity refresh cannot alert for an established random")
    W:Close();party.party1=nil;R:Check()
    ns.db.remind_on_member=true
    party.party1={name="Thornwyn",realm="Realm"};clock=clock+11
    local stableGUID=UnitGUID
    UnitGUID=function(unit)if unit=="party1"then return nil end;return stableGUID(unit)end
    A.Pin(ns.getGroupMembers()[2],3)
    R:Check()
    pinnedEqual(R.owed~=nil,true,toc..": named pin queues before GUID is available")
    UnitGUID=stableGUID
    R:Check();flush()
    pinnedEqual(W:IsShown(),true,toc..": GUID resolving during delay preserves queued pin")
    W:Close();clock=clock+11;R:Check();flush()
    pinnedEqual(W:IsShown(),false,toc..": resolved established pin does not retrigger")
    party.party1=nil;R:Check()
    party.party1={name="Thornwyn",realm="Realm"}
    local readableName=UnitName
    UnitName=function(unit)if unit=="party1"then return nil end;return readableName(unit)end
    UnitGUID=function(unit)if unit=="party1"then return nil end;return stableGUID(unit)end
    R:Check();clock=clock+6;R:Check()
    UnitName,UnitGUID=readableName,stableGUID
    R:Check();flush()
    pinnedEqual(W:IsShown(),false,toc..": established anonymous member resolving does not retrigger")
    local fresh=loadAddon(toc,{schema=2})
    pinnedEqual(fresh.db.remind_pinned_only,false,toc..": new filter defaults off for compatibility")
end
io.write("Pinned join reminders: "..pinnedChecks.." checks passed\n")

io.write("marking tests passed\n")
