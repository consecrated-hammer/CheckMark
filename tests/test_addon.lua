package.path = "./tests/hammercore/?.lua;" .. package.path
local wow = require("wow")

local function equal(actual, expected, label)
    if actual ~= expected then
        error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

-- Client APIs CheckMark uses beyond the HammerCore harness, as plain stubs.
local function installClient()
    RegisterStateDriver, UnregisterStateDriver = function() end, function() end
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
        "CheckMark,Markers,Sounds,Visibility,Theme,Commands,Troubleshooting,About", toc .. ": rail order")
    local failures = {}
    for name, err in pairs(HC.Settings.errors) do failures[#failures + 1] = name .. ": " .. err end
    equal(table.concat(failures, "; "), "", toc .. ": every settings page builds")
    for _, spec in ipairs(HC.Settings.order) do
        HC.Settings:Show(spec.name)
        equal(HC.Settings.selected, spec.name, toc .. ": " .. spec.name .. " opens")
    end

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
        if wow.Plain(line) == "  Left-click a cell - Apply that role's marker" then sawAction = true end
    end
    equal(sawAction, true, toc .. ": grid actions are listed in help")

    for _, old in ipairs({ "options", "reset", "loadmsg on", "diagnostics" }) do
        SlashCmdList.CHECKMARK(old)
        equal(wow.LastPrint(), "CheckMark: unknown command. Type /checkmark help for the list.",
            toc .. ": old command '" .. old .. "' is removed")
    end
end

io.write("addon tests passed\n")
