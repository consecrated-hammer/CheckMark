package.path = "./tests/hammercore/?.lua;" .. package.path
local wow = require("wow")

local function equal(actual, expected, label)
    if actual ~= expected then
        error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

-- Client APIs CheckMark uses beyond the HammerCore harness, as plain stubs.
local function installClient()
    lastDriver = nil
    RegisterStateDriver = function(_, _, rule) lastDriver = rule end
    UnregisterStateDriver = function() end
    instanceKind = nil
    IsInInstance = function() return instanceKind ~= nil, instanceKind or "none" end
    IsInRaid, IsInGroup = function() return false end, function() return false end
    UnitExists = function(unit) return unit == "player" end
    UnitGUID = function(unit) return "guid-" .. tostring(unit) end
    UnitName = function() return "Tester" end
    UnitClass = function() return "Paladin", "PALADIN" end
    UnitGroupRolesAssigned = function() return "NONE" end
    GetRealmName = function() return "Realm" end
    GetBuildInfo = function() return "12.1.0", "1", "", 120100 end
    PlaySound = function() return true end
    C_Timer = { After = function() end }
    UIErrorsFrame = { AddMessage = function() end }
end

local function loadAddon(tocName, saved)
    local camelot = tocName:find("Camelot") and "Camelot" or nil
    wow.Install({ CheckMark = { Version = "1.1.8-dev1", ["X-CheckMark-Target"] = camelot } })
    installClient()
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
    return ns
end

for _, toc in ipairs({ "CheckMark.toc", "CheckMark_Camelot.toc" }) do
    local ns = loadAddon(toc, { show_startup_message = true, hide_minimap = true, minimap_angle = 70,
        settingsPoint = { "TOPLEFT", "TOPLEFT", 12, -12 }, visibility_mode = "ALWAYS" })
    local HC = ns.HammerCore
    equal(wow.LastPrint(), "CheckMark v1.1.8-dev1 loaded - type /checkmark for settings, /checkmark help for commands",
        toc .. ": standard login message")
    equal(HC.State().minimap, false, toc .. ": a hidden minimap stays hidden")
    equal(CheckMarkDB.hide_minimap, nil, toc .. ": the old inverted key is removed")
    equal(HC.State().minimapAngle, 70, toc .. ": minimap position is kept")
    equal(HC.State().settingsPoint[3], 12, toc .. ": settings position is kept")
    equal(HC.Minimap.button:GetName(), "CheckMarkMinimapButton", toc .. ": minimap button keeps its name")
    equal(SLASH_CHECKMARK2, "/cm", toc .. ": /cm is registered")

    SlashCmdList.CHECKMARK("")
    equal(HC.Settings:IsShown(), true, toc .. ": the bare command opens settings")
    local names = {}
    for _, spec in ipairs(HC.Settings.order) do names[#names + 1] = spec.name end
    equal(table.concat(names, ","),
        "CheckMark,Markers,Reminder,Sounds,Visibility,Profiles,What's new,Commands,Troubleshooting,About", toc .. ": rail order")
    local failures = {}
    for name, err in pairs(HC.Settings.errors) do failures[#failures + 1] = name .. ": " .. err end
    equal(table.concat(failures, "; "), "", toc .. ": every settings page builds")
    for _, spec in ipairs(HC.Settings.order) do
        HC.Settings:Show(spec.name)
        equal(HC.Settings.selected, spec.name, toc .. ": " .. spec.name .. " opens")
    end

    -- The live preview opens from the header and follows settings.
    HC.Settings:Show("CheckMark")
    equal(HC.Settings.headerAction:GetText(), "Show live preview", toc .. ": Panel offers the live preview")
    wow.Click(HC.Settings.headerAction)
    equal(ns.Preview:IsShown(), true, toc .. ": the header opens the preview")
    equal(ns.Preview.dock:IsAttached(), false, toc .. ": opening preview does not auto-attach")
    equal(HC.spec.previewDock, true, toc .. ": snapping preference is advertised")
    equal(HC.spec.profileColumns, 2, toc .. ": profile control groups request two columns")
    equal(HC.Settings.headerAction:GetText(), "Hide live preview", toc .. ": the header button follows it")
    equal(ns.Preview.parts.cells[1]:IsShown(), true, toc .. ": the preview draws sample cells")
    ns.db.preview_members = 3; ns.Preview:Refresh()
    equal(ns.Preview.parts.cells[4]:IsShown(), false, toc .. ": party size changes the preview")
    ns.db.cell_width = 105; ns.refreshPopup()
    equal(ns.Preview.parts.cells[1]:GetWidth(), 105, toc .. ": settings changes redraw the preview")
    HC.Settings:Hide()
    equal(ns.Preview:IsShown(), false, toc .. ": closing settings closes the preview")
    ns.db.preview_window_open = true
    HC.Settings:Show()
    equal(ns.Preview:IsShown(), true, toc .. ": Open with settings reopens it")
    ns.db.preview_window_open, ns.db.cell_width = false, 20

    SlashCmdList.CHECKMARK("lock")
    equal(ns.db.show_handle, false, toc .. ": lock hides the handle")
    SlashCmdList.CHECKMARK("unlock")
    equal(ns.db.show_handle, true, toc .. ": unlock shows it")
    ns.db.popup_position = { "TOP", "TOP", 1, 1 }
    SlashCmdList.CHECKMARK("reset position")
    equal(ns.db.popup_position, nil, toc .. ": reset position clears the grid position")
    SlashCmdList.CHECKMARK("toggle")
    equal(wow.LastPrint(), "CheckMark: Form a two-to-five player party to prepare markers.",
        toc .. ": toggle reaches the grid")
    SlashCmdList.CHECKMARK("version")
    equal(wow.LastPrint():find(toc:find("Camelot") and "(WoW Forever)" or "(Retail)", 1, true) ~= nil,
        true, toc .. ": version names the client")
    SlashCmdList.CHECKMARK("debug")
    equal(HC.Copy.frame.edit:GetText():find("Visibility mode: ALWAYS", 1, true) ~= nil, true,
        toc .. ": debug includes CheckMark's report")

    wow.printed = {}
    SlashCmdList.CHECKMARK("help")
    local sawAction = false
    for _, line in ipairs(wow.printed) do
        if wow.Plain(line) == "  Left-click a cell - Apply that person's marker" then sawAction = true end
    end
    equal(sawAction, true, toc .. ": grid actions are listed in help")

    -- The sound check finds kits this client lacks and playback skips them.
    PlaySound = function(id) return id ~= 878 and id ~= 880, 1 end
    SlashCmdList.CHECKMARK("sounds")
    equal(wow.LastPrint(), toc:find("Camelot") and "CheckMark: 1 missing: Party Invite" or "CheckMark: 2 missing: Quest Complete, Party Invite",
        toc .. ": the sound check names missing sounds")
    for _, sound in ipairs(ns.getSelectedMarkerSounds()) do
        equal(sound.id ~= 878 and sound.id ~= 880, true, toc .. ": missing sounds are not played")
    end
    PlaySound = function() return false end
    SlashCmdList.CHECKMARK("sounds")
    equal(wow.LastPrint(), "CheckMark: no sound played; turn game sound on and check again",
        toc .. ": sound off is not mistaken for missing sounds")
    equal(ns.isMarkerSoundMissing(416), false, toc .. ": a failed check keeps the previous result")
    PlaySound = function() return true end

    for _, old in ipairs({ "options", "reset", "loadmsg on", "diagnostics" }) do
        SlashCmdList.CHECKMARK(old)
        equal(wow.LastPrint(), "CheckMark: unknown command. Type /checkmark help for the list.",
            toc .. ": old command '" .. old .. "' is removed")
    end
end

-- Every page also builds under HammerCore's Classic theme.
for _, toc in ipairs({ "CheckMark.toc", "CheckMark_Camelot.toc" }) do
    local ns = loadAddon(toc, { hammerCore = { theme = "classic" } })
    local HC = ns.HammerCore
    -- Classic is switched off for players until it is reworked; keep it building.
    HC.Theme.registry.classic.available = true
    equal(HC.Theme.IsClassic(), true, toc .. ": classic theme is active")
    HC.Settings:Show()
    local failures = {}
    for name, err in pairs(HC.Settings.errors) do failures[#failures + 1] = name .. ": " .. err end
    equal(table.concat(failures, "; "), "", toc .. ": every settings page builds in classic")
    for _, spec in ipairs(HC.Settings.order) do
        HC.Settings:Show(spec.name)
        equal(HC.Settings.selected, spec.name, toc .. ": " .. spec.name .. " opens in classic")
    end
end

-- Mark reminder: joining a party nudges once; triggers and outputs follow settings.
do
    local ns = loadAddon("CheckMark.toc", {})
    local core, clock = _G.CheckMarkCore, 100
    GetTime = function() return clock end
    C_Timer = { After = function(_, fn) fn() end }
    local combat = false
    InCombatLockdown = function() return combat end
    local members = { player = true }
    UnitExists = function(unit) return members[unit] == true end
    IsInGroup = function() return members.party1 == true end
    local leader = true
    UnitIsGroupLeader = function() return leader end
    local function fire(event) core.scripts.OnEvent(core, event) end
    -- "join" and "member" match any line from that reminder's pool.
    local function said(text)
        local pool = ns.Reminder.MESSAGES[text] or { text }
        for _, line in ipairs(wow.printed) do
            for _, wanted in ipairs(pool) do
                if wow.Plain(line):find(wanted, 1, true) then return true end
            end
        end
        return false
    end
    local function roster() wow.printed = {}; fire("GROUP_ROSTER_UPDATE") end

    fire("PLAYER_ENTERING_WORLD")
    members.party1 = true
    roster()
    equal(said("join"), true, "joining a party reminds")
    equal(ns.MarkWindow:IsShown(), true, "joining a party opens the marking window")
    ns.MarkWindow:Close()
    members.party2 = true; clock = clock + 60
    roster()
    equal(said("member"), true, "a newcomer reminds by default")
    members.party3 = true
    roster()
    equal(said("member"), false, "reminders are throttled")
    ns.db.remind_on_member = false
    members.party4 = true; clock = clock + 60
    roster()
    equal(said("member"), false, "the newcomer reminder can be turned off")
    ns.db.remind_on_member = true

    members.party1, members.party2, members.party3, members.party4 = nil, nil, nil, nil
    roster()
    combat = true; members.party1 = true; clock = clock + 60
    roster()
    equal(said("join"), false, "never in combat")
    combat = false; wow.printed = {}
    fire("PLAYER_REGEN_ENABLED")
    equal(said("join"), true, "a reminder due in combat waits for it to end")

    members.party1 = nil; roster()
    leader = false; members.party1 = true; clock = clock + 60
    roster()
    equal(said("join"), true, "leader-only is off by default")
    members.party1 = nil; roster()
    ns.db.remind_leader_only = true; members.party1 = true; clock = clock + 60
    roster()
    equal(said("join"), false, "leader-only stays quiet for others")
    ns.db.remind_leader_only, leader = false, true

    -- Show rules: a reminder waits until the grid can show.
    members.party1 = nil; roster()
    ns.db.visibility.dungeon = true; members.party1 = true; clock = clock + 60
    roster()
    equal(said("join"), false, "the grid's Show rules hold the reminder back")
    instanceKind = "party"; wow.printed = {}
    fire("ZONE_CHANGED_NEW_AREA")
    equal(said("join"), true, "zoning in where the grid shows delivers it")
    wow.printed = {}
    fire("ZONE_CHANGED_NEW_AREA")
    equal(said("join"), false, "an owed reminder is delivered once")
    ns.db.visibility.dungeon, instanceKind = nil, nil

    members.party1 = nil; roster()
    ns.db.remind_enabled = false; members.party1 = true; clock = clock + 60
    roster()
    equal(said("join"), false, "the reminder can be turned off")
    ns.db.remind_enabled = true

    -- Reloading inside a party isn't joining one.
    ns = loadAddon("CheckMark.toc", {})
    GetTime = function() return clock end
    C_Timer = { After = function(_, fn) fn() end }
    UnitExists = function(unit) return members[unit] == true end
    IsInGroup = function() return true end
    core = _G.CheckMarkCore
    wow.printed = {}
    core.scripts.OnEvent(core, "PLAYER_ENTERING_WORLD")
    core.scripts.OnEvent(core, "GROUP_ROSTER_UPDATE")
    equal(said("join"), false, "a reload in a party stays quiet")

    ns.db.remind_chat, ns.db.remind_screen, ns.db.remind_sound, ns.db.remind_window = false, false, false, false
    wow.printed = {}
    ns.Reminder:Test()
    equal(said("every reminder output is off"), true, "test explains a silent setup")
    ns.db.remind_chat = true
    wow.printed = {}
    ns.Reminder:Test()
    equal(said("This is what your mark reminder looks like."), true, "test uses the chosen outputs")
end

-- Show conditions: none means always; ticked ones must match.
do
    local ns = loadAddon("CheckMark.toc", {})
    UnitExists = function(unit) return unit == "player" or unit == "party1" end
    IsInGroup = function() return true end
    UnitIsGroupLeader = function() return false end
    ns.showPopup()
    equal(lastDriver, "[combat] hide; [group:party] show; hide", "no conditions: shows in the party")
    ns.db.visibility.dungeon = true
    ns.applyVisibility()
    equal(lastDriver, "hide", "dungeon only: hidden in the open world")
    equal(ns.gridVisibilitySummary(), "In a dungeon", "summary names the condition")
    instanceKind = "party"
    ns.applyVisibility()
    equal(lastDriver, "[combat] hide; [group:party] show; hide", "dungeon only: shown in a dungeon")
    instanceKind = nil
    ns.db.visibility.leader = true
    UnitIsGroupLeader = function() return true end
    ns.applyVisibility()
    equal(lastDriver, "[combat] hide; [group:party] show; hide", "any ticked rule is enough")
    ns.db.visibility_mode = "HIDDEN"
    ns.applyVisibility()
    equal(lastDriver, "hide", "Never wins")
end

-- Minimap right-click: HammerCore's menu with CheckMark's extras.
do
    local ns = loadAddon("CheckMark.toc", nil)
    local HC = ns.HammerCore
    equal(HC.Minimap.RightClickMode(), "menu", "the minimap right-click opens the menu")
    local function find(text)
        for _, item in ipairs(HC.Minimap:MenuItems()) do
            if item.text == text then return item end
        end
    end
    local solo = find("Preview marking window")
    equal(solo ~= nil, true, "solo, the menu previews the marking window")
    solo.func()
    equal(ns.MarkWindow:IsShown(), true, "the preview opens")
    equal(ns.MarkWindow.test, true, "solo, it's the sample party")
    ns.MarkWindow:Close()
    local reminder = find("Mark reminder")
    equal(reminder.checked, true, "the reminder starts on")
    reminder.func()
    equal(ns.db.remind_enabled, false, "the menu turns the reminder off")
    equal(find("Mark reminder").checked, false, "and shows it off")
    equal(find("Show grid") ~= nil, true, "the grid toggle is there")
    InCombatLockdown = function() return true end
    equal(find("Preview marking window").disabled, true, "no marking window in combat")
    InCombatLockdown = function() return false end
    IsInGroup = function() return true end
    UnitExists = function(unit) return unit == "player" or unit == "party1" end
    local party = find("Mark the party")
    equal(party ~= nil, true, "in a party, the menu marks it")
    party.func()
    equal(ns.MarkWindow:IsShown(), true, "the marking window opens")
    equal(ns.MarkWindow.test, false, "for the real party")
end

io.write("addon tests passed\n")
