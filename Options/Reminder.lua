local addon, ns = ...
local HC = ns.HammerCore
local O = HC.UI

-- When CheckMark nudges you to mark the party, how long it waits, and how.

local ICON = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1"
local TIMING_ICON = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5"
local WINDOW_ICON = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6"
local HOW_ICON = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2"

local function seconds(value) return value .. " s" end

HC.Settings:NewPage({
    name = "Reminder",
    title = "Reminder",
    group = "main",
    description = "A nudge to mark your party when it forms.",
}, function(panel, y)
    local db = ns.db
    local switches, dependants = {}, {}
    local function check(label, hint, key)
        local row
        row, y = O.Check(panel, label, hint, y,
            function() return db[key] end,
            function(value) db[key] = value end)
        switches[#switches + 1] = row
        return row
    end
    -- A switch and, beside it, its seconds slider (hidden while it's off).
    local function timed(label, hint, key, sliderLabel, sliderHint, secondsKey, low, high)
        y = O.Columns(panel, 2, y)
        local top = y
        local row = check(label, hint, key)
        local slider, nextY = O.Slider(panel, sliderLabel, sliderHint, top, low, high, 1,
            function() return db[secondsKey] end, function(value) db[secondsKey] = value end, seconds)
        dependants[#dependants + 1] = { row = slider, key = key }
        y = O.Columns(panel, 1, math.min(y, nextY))
        return row
    end

    _, y = O.Header(panel, "When", y, ICON)
    check("Remind me to mark", "Turn the mark reminder on or off.", "remind_enabled")
    check("When I join a party", "Remind when you join or form a party.", "remind_on_join")
    check("When someone joins", "Remind when a new player joins your party.", "remind_on_member")
    check("Only as party leader", "Stay quiet unless you lead the party.", "remind_leader_only")
    check("Quiet if someone else marks", "Skip the reminder when another CheckMark user in the party is already marking.",
        "remind_quiet_others")
    _, y = O.Text(panel, "Follows the grid's Show rules on Visibility, so it waits until the grid can show.", y)

    _, y = O.Header(panel, "Timing", y, TIMING_ICON)
    timed("Wait after joining", "Wait a moment so everyone's in. Each new joiner restarts the wait.", "remind_join_wait",
        "Seconds after joining", "How long to wait after the last person joins.", "remind_join_seconds", 1, 10)
    timed("Wait after combat", "A reminder held through a fight waits a moment, so you can loot first.", "remind_combat_wait",
        "Seconds after combat", "How long to wait after combat ends.", "remind_combat_seconds", 1, 15)

    _, y = O.Header(panel, "Marking window", y, WINDOW_ICON)
    check("Show the marking window", "Pop up a window with a big card for each member. Click each card to mark them.",
        "remind_window")
    check("Close when all clicked", "Close the window once you've clicked everyone.", "remind_close_done")
    timed("Close after a while", "Close the window on its own after a set time.", "remind_timeout",
        "Seconds open", "How long the window stays open.", "remind_timeout_seconds", 5, 60)
    local size
    size, y = O.Dropdown(panel, "Window size", "How big the marking window is.", y,
        ns.MarkWindow.SIZE_VALUES, ns.MarkWindow.SIZE_LABELS,
        function() return db.remind_window_size end,
        function(value)
            db.remind_window_size = value
            if ns.MarkWindow:IsShown() then ns.MarkWindow:Refresh() end
        end)

    _, y = O.Header(panel, "Also", y, HOW_ICON)
    check("Chat message", "Print the reminder in chat.", "remind_chat")
    check("On-screen message", "Show the reminder in the middle of the screen, like a raid warning.", "remind_screen")
    check("Sound", "Play the raid warning sound.", "remind_sound")

    O.OnRefresh(panel, function()
        for index, row in ipairs(switches) do
            if index > 1 then O.SetEnabled(row.hcCheckbox, db.remind_enabled) end
        end
        for _, item in ipairs(dependants) do item.row:SetShown(db[item.key] == true) end
    end)

    _, y = O.ActionButton(panel, y, "Test reminder", function() ns.Reminder:Test() end,
        "Show the reminder now, with the outputs chosen above. The window shows a sample party.")
    _, y = O.PageReset(panel, y, function()
        for key, value in pairs(ns.Reminder.DEFAULTS) do db[key] = value end
    end, "Reset reminder")
    return y
end)
