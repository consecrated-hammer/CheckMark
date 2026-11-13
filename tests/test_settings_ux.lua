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
    local ns = { testRows = {} }
    for line in io.lines(tocName) do
        local entry = line:gsub("\r", ""):gsub("\\", "/")
        if entry:match("%.xml$") then
            wow.LoadHammerCore(entry:match("^(.*)/[^/]+$"), "CheckMark", ns)
            local UI = ns.HammerCore.UI
            local register, makeRow, action = UI.RegisterRow, UI.Row, UI.ActionButton
            UI.RegisterRow = function(parent, row, label)
                local text = type(label) == "function" and label() or label
                local owner = parent.hcHeaderOwner or parent
                local previous = owner.hcRows and owner.hcRows[text]
                assert(not previous or previous == row, "duplicate setting label: " .. tostring(text))
                return register(parent, row, label)
            end
            UI.Row = function(...)
                local row = makeRow(...); ns.testRows[#ns.testRows + 1] = row; return row
            end
            UI.ActionButton = function(...)
                local row, y = action(...); ns.testRows[#ns.testRows + 1] = row; return row, y
            end

        elseif entry:match("%.lua$") then
            assert(loadfile(entry))("CheckMark", ns)
        end
    end
    local core = _G.CheckMarkCore
    core.scripts.OnEvent(core, "ADDON_LOADED", "CheckMark")
    return ns
end


for _, toc in ipairs({ "CheckMark.toc", "CheckMark_Camelot.toc" }) do
    local ns = loadAddon(toc, { schema = 2, marker_rules = "ROLES_REGULARS", remind_enabled = false,
        remind_join_seconds = 9, remind_window_size = "LARGE", learn_mine = false,
        marker_sound_enabled = false })
    local HC, db = ns.HammerCore, ns.db
    HC.Settings:Show("CheckMark")
    equal(db.remind_join_seconds, 9, "existing timing survives")
    equal(db.remind_window_size, "LARGE", "existing window size survives")
    equal(db.learn_mine, false, "existing learning choice survives")
    equal(db.schema, 2, "SavedVariables schema is unchanged")
    local indexed = {}
    for _, page in pairs(HC.Settings.pages) do
        for _, body in pairs(page.bodies) do
            for _, row in pairs(body.hcRows or {}) do indexed[row] = true end
        end
    end
    for _, row in ipairs(ns.testRows) do assert(indexed[row], "control missing from page search index") end
    for _, label in ipairs({ "Compact", "Named", "Oversized" }) do
        assert(HC.Settings:Focus("CheckMark", label, "Layout"), "preset indexed")
    end
    local function rows(page, tab)
        return HC.Settings.pages[page].bodies[tab or page].hcRows
    end
    local function refresh(page, tab) HC.Settings:Select(page, tab) end
    local function click(page, tab, label)
        refresh(page, tab)
        local row = assert(rows(page, tab)[label], label)
        wow.Click(row.hcCheckbox or row)
        if label:match("^Reset ") then
            assert(HC.Dialog:IsShown(), label .. " asks for confirmation")
            equal(HC.Dialog.current.title, label, "confirmation names its reset")
            wow.Click(HC.Dialog.frame.accept)
        end
    end
    -- Scope metadata follows the real profile storage contract in Setup.lua.
    local profileKeys = {}
    for _, group in ipairs(HC.Profiles.spec.groups) do
        for _, key in ipairs(group.keys) do profileKeys[key] = true end
    end
    local mapped = {
        { "CheckMark", "Layout", {
            Compact = "cell_width", Named = "cell_width", Oversized = "cell_width",
            ["Cells per row"] = "cell_columns", Spacing = "cell_spacing", Width = "cell_width",
            Height = "cell_height", ["Icon size"] = "icon_size", ["Player names"] = "show_cell_names",
            ["Reset grid layout"] = "cell_width",
        } },
        { "CheckMark", "Position", {
            ["Show drag handle"] = "show_handle", ["Handle position"] = "handle_position",
            ["Re-centre grid"] = "popup_position", ["Reset grid position"] = "popup_position",
        } },
        { "Markers", "Assignments", {
            ["Mark the party"] = false, ["Who goes first"] = "marker_rules", Tank = "role_template",
            Healer = "role_template", ["Fill order"] = "fill_order", ["Reset assignments"] = "marker_rules",
        } },
        { "Visibility", nil, { ["Show grid"] = "visibility_mode", ["Reset grid visibility"] = false } },
    }
    local function checkScope(row, expected, label)
        equal(row.hcSettingScope, expected, label .. " storage scope")
        if expected == "profile" then
            assert(row.hcScopeIcon and row.hcScopeIcon:IsShown(), label .. " has a profile icon")
        else
            assert(not row.hcScopeIcon or not row.hcScopeIcon:IsShown(), label .. " has no profile icon")
        end
    end
    for _, item in ipairs(mapped) do
        local page, tab, bindings = item[1], item[2], item[3]
        local body = HC.Settings.pages[page].bodies[tab or page]
        assert(body.hcScopeLegend, page .. "/" .. tostring(tab) .. " has one scope legend")
        for label in pairs(bindings) do assert(body.hcRows[label], "scope target remains searchable: " .. label) end
        for label, row in pairs(body.hcRows) do
            local key = bindings[label]
            if key then assert(profileKeys[key], label .. " maps to a declared profile key") end
            checkScope(row, key and "profile" or "shared", label)
        end
    end
    for _, pageTab in ipairs({ { "Markers", "People" }, { "Reminder", "When and how" },
        { "Reminder", "Marking window" }, { "Sounds", "Sounds" } }) do
        local body = HC.Settings.pages[pageTab[1]].bodies[pageTab[2]]
        assert(not body.hcScopeLegend, "shared-only tabs need no repeated legend")
        for label, row in pairs(body.hcRows) do checkScope(row, "shared", label) end
    end
    assert(not profileKeys.panel_hidden, "manual grid hide is a shared setting")
    assert(rows("Visibility")["Reset grid visibility"].hcHint:find("shared manual Hide grid", 1, true),
        "mixed visibility reset explains its shared effect")
    for _, label in ipairs({ "Compact", "Named", "Oversized" }) do
        local preset = rows("CheckMark", "Layout")[label]
        local _, textX = preset.Text:GetPoint()
        local _, _, _, glyphX = preset.hcScopeMarker:GetPoint()
        assert(glyphX + preset.hcScopeMarker:GetWidth() <= textX, label .. " reserves a clear glyph gutter")
        equal(preset:GetWidth(), math.floor((HC.UI.CONTENT_WIDTH - 12) / 3), "preset width remains unchanged")
    end
    local expectedOrders = {
        REGULARS_ROLES = "Order: party picks, pinned people, tank and healer, learned people, fill order.",
        ROLES_REGULARS = "Order: party picks, tank and healer, pinned people, learned people, fill order.",
        REGULARS = "Order: party picks, pinned people, learned people, fill order.",
        ROLES = "Order: party picks, tank and healer, fill order.",
        FILL = "Order: party picks, fill order.",
    }
    for rule, text in pairs(expectedOrders) do
        db.marker_rules = rule
        refresh("Markers", "Assignments")
        local short = text:gsub("^Order: party picks", "Your picks"):gsub("tank and healer", "tank/healer")
            :gsub("learned people", "learned"):gsub(", ", " > ")
        equal(HC.Settings.pages.Markers.bodies.Assignments.content.assignmentOrder:GetText(), short,
            "visible order follows " .. rule)
        assert(#short <= 64, "order stays concise; native text width still needs client acceptance")
    end
    local reminder = rows("Reminder", "When and how")
    local seconds = reminder["Seconds after joining"]
    equal(HC.Settings:Focus("Reminder", "Seconds after joining", "When and how"), reminder["Remind me to mark"], "disabled reminder focuses master")
    db.remind_enabled = true; db.remind_join_wait = false
    refresh("Reminder", "When and how")
    equal(HC.Settings:Focus("Reminder", "Seconds after joining", "When and how"), reminder["Wait after joining"], "disabled timing focuses wait switch")
    local height = HC.Settings.pages.Reminder.bodies["When and how"].content:GetHeight()
    click("Reminder", "When and how", "Wait after joining")
    assert(seconds:GetParent():IsShown(), "joining slider appears")
    assert(HC.Settings.pages.Reminder.bodies["When and how"].content:GetHeight() > height, "timing reflows page")
    assert(reminder["Seconds after combat"]:GetParent():IsShown(), "independent combat slider stays shown")
    db.remind_window = false; db.remind_timeout = false
    local window = rows("Reminder", "Marking window")
    equal(HC.Settings:Focus("Reminder", "Seconds open", "Marking window"), window["Show the marking window"], "nested hidden window seconds focuses master")
    db.remind_window = true
    equal(HC.Settings:Focus("Reminder", "Seconds open", "Marking window"), window["Close after a while"], "window timeout focuses switch")
    db.remind_join_seconds = 9
    click("Reminder", "Marking window", "Reset marking window")
    equal(db.remind_join_seconds, 9, "window reset preserves timing")
    db.remind_window_size = "LARGE"
    click("Reminder", "When and how", "Reset reminder")
    equal(db.remind_window_size, "LARGE", "reminder reset preserves window")
    equal(db.remind_join_seconds, 2, "reminder reset restores timing")
    local sounds = rows("Sounds")
    equal(HC.Settings:Focus("Sounds", "Available sounds"), sounds["Play marker sounds"], "disabled sounds focus master")
    equal(HC.Settings:Focus("Sounds", "Find missing sounds"), sounds["Find missing sounds"], "sound diagnosis remains available")
    equal(HC.Settings:Focus("Sounds", "Test sound"), sounds["Test sound"], "sound test remains available")
    local playback
    for _, frame in ipairs(wow.frames) do
        if frame:GetParent() == sounds.Playback and rawget(frame, "Text") then playback = frame end
    end
    assert(playback, "standard Playback dropdown exists")
    for _, value in ipairs({ "INVALID", false, "SEQUENTIAL" }) do
        db.marker_sound_mode = value or nil
        refresh("Sounds")
        equal(playback:GetText(), value == "SEQUENTIAL" and "Sequential" or "Random", "Playback defaults invalid or nil to Random")
    end
    local _, _, testY = sounds["Test sound"]:GetPoint()
    local _, _, findY = sounds["Find missing sounds"]:GetPoint()
    assert(testY > findY, "sound test comes before diagnosis")

    db.show_handle = false
    local position = rows("CheckMark", "Position")
    equal(HC.Settings:Focus("CheckMark", "Handle position", "Position"), position["Show drag handle"], "hidden handle position focuses switch")
    db.popup_position = { "TOPLEFT", "TOPLEFT", 50, -60 }
    HC.State().minimap = false; HC.State().startupMessage = false
    db.panel_hidden = true
    click("Visibility", nil, "Reset grid visibility")
    equal(db.panel_hidden, false, "mixed visibility reset still clears shared manual hiding")
    equal(db.popup_position[3], 50, "visibility reset preserves position")
    equal(db.show_handle, false, "visibility reset preserves handle")
    equal(HC.State().minimap, false, "visibility reset preserves minimap")
    equal(HC.State().startupMessage, false, "visibility reset preserves updates")
    db.cell_width = 121; db.remind_sound = true
    click("CheckMark", "Position", "Reset grid position")
    equal(db.popup_position, nil, "position reset centres grid")
    equal(db.show_handle, true, "position reset restores handle")
    equal(db.cell_width, 121, "position reset preserves layout")
    equal(db.remind_sound, true, "position reset preserves reminders")
    -- Profile transitions save their own grid/assignment settings and keep
    -- global reminder, learning and sound choices unchanged.
    HC.Profiles:Switch("World", "manual")
    db.cell_width, db.marker_rules, db.remind_join_seconds = 119, "FILL", 8
    HC.Profiles:Switch("Dungeon", "manual")
    equal(db.marker_rules, "ROLES_REGULARS", "Dungeon keeps seeded precedence")
    equal(db.remind_join_seconds, 8, "reminder is shared on profile switch")
    db.cell_width = 77
    HC.Profiles:Switch("World", "manual")
    equal(db.cell_width, 119, "World restores its grid width")
    equal(db.marker_rules, "FILL", "World restores its precedence")
    equal(db.remind_join_seconds, 8, "profile restore preserves shared timing")
    local refreshedRules
    local refreshPopup = ns.refreshPopup
    ns.refreshPopup = function(...) refreshedRules = db.marker_rules; return refreshPopup(...) end
    click("Markers", "Assignments", "Reset assignments")
    ns.refreshPopup = refreshPopup
    equal(refreshedRules, ns.DEFAULT_DB.marker_rules, "assignment displays refresh after precedence resets")
    assert(HC.Pages.visibility.profileScope ~= false, "mixed visibility page retains profile badge")
    equal(db.marker_rules, ns.DEFAULT_DB.marker_rules, "assignment reset includes precedence")
    equal(db.cell_width, 119, "assignment reset preserves grid")
    -- Every person remains editable and searchable beyond the old 20-row cap.
    for index = 1, 27 do ns.Assign.PinTag("Person" .. index .. "#1234", index % 8 + 1) end
    refresh("Markers", "People")
    local body = HC.Settings.pages.Markers.bodies.People.content
    equal(#body.regularRows, 27, "all regulars get rows")
    for _, row in ipairs(body.regularRows) do checkScope(row, "shared", "dynamic person") end
    local controls = HC.Settings.pages.Markers.bodies.People.hcRows["Add a Battle.net friend"]:GetParent()
    local _, _, _, _, controlsTop = controls:GetPoint()
    local _, _, _, _, listTop = body.regularRows[1]:GetParent():GetPoint()
    assert(controlsTop > listTop, "learning and Add controls stay above a long People list")

    assert(#HC.Settings:Search("Person27") > 0, "last regular is searchable")
    ns.Assign.Forget("bnet:Person27#1234")
    equal(#HC.Settings:Search("Person27"), 0, "removed regular leaves no search result")
    equal(body.regularRows[27]:IsShown(), false, "removed row hides")
    -- Construction and search at both supported window scales. Pixel clipping
    -- and native scrolling still need a real client.
    for _, scale in ipairs({ 0.7, 1.3 }) do
        HC.State().settingsScale = scale; HC.Settings:ApplyScale()
        for name, page in pairs(HC.Settings.pages) do
            for tab, body in pairs(page.bodies) do
                refresh(name, tab)
                for label in pairs(body.hcRows or {}) do
                    local found = false
                    for _, result in ipairs(HC.Settings:Search(label, 10000)) do
                        if result.page == name and result.tab == tab and result.label == label then found = true end
                    end
                    assert(found, "search missing " .. name .. "/" .. tab .. "/" .. label)
                    assert(HC.Settings:Focus(name, label, tab), "cannot focus " .. label)
                end
            end
        end
    end
    equal(next(HC.Settings.errors), nil, "all pages and tabs construct")
end
io.write("settings UX tests passed on Retail and Forever at 0.7 and 1.3 scales\n")
