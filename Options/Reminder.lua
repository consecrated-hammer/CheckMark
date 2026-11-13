local addon, ns = ...
local HC, O = ns.HammerCore, ns.Options

-- Shared settings. Each dependency gets its own section so hiding it reflows
-- the page and search can focus the switch which makes it available.
local WINDOW_KEYS = { remind_window = true, remind_close_done = true, remind_timeout = true,
    remind_timeout_seconds = true, remind_window_size = true }
local function build(panel, window)
    local db, flow = ns.db, O.Flow(panel)
    local function section(fill, visible, parent)
        local frame = O.Section(panel, 1, parent)
        local bottom, result = fill(frame, -4)
        flow:Add(frame, -O.Flush(frame, bottom) + 4, visible)
        return result
    end
    local function check(frame, y, label, hint, key)
        return O.Check(frame, label, hint, y, function() return db[key] end,
            function(value) db[key] = value end)
    end
    local function timed(label, hint, key, sliderLabel, secondsKey, low, high, visible, parent)
        local toggle = section(function(frame, y)
            local row; row, y = check(frame, y, label, hint, key)
            return y, row
        end, visible, parent)
        section(function(frame, y)
            _, y = O.Slider(frame, sliderLabel, "How long to wait, in seconds.", y, low, high, 1,
                function() return db[secondsKey] end, function(value) db[secondsKey] = value end,
                function(value) return value .. " s" end)
            return y
        end, function() return (not visible or visible()) and db[key] end, toggle)
    end
    if window then
        local master = section(function(frame, y)
            _, y = O.Header(frame, "Marking window (shared)", y)
            local row; row, y = check(frame, y, "Show the marking window",
                "Open a card for each member when a reminder fires. Click each card to mark them. Manual opening from the minimap remains available.", "remind_window")
            return y, row
        end)
        local function enabled() return db.remind_window end
        section(function(frame, y)
            _, y = O.Dropdown(frame, "Window size", "Size of the member cards.", y,
                ns.MarkWindow.SIZE_VALUES, ns.MarkWindow.SIZE_LABELS,
                function() return db.remind_window_size end, function(value)
                    db.remind_window_size = value
                    if ns.MarkWindow:IsShown() then ns.MarkWindow:Refresh() end
                end)
            _, y = check(frame, y, "Close when all clicked", "Close once you have clicked every card.", "remind_close_done")
            return y
        end, enabled, master)
        timed("Close after a while", "Close the window automatically after this time.", "remind_timeout",
            "Seconds open", "remind_timeout_seconds", 5, 60, enabled, master)
    else
        local master = section(function(frame, y)
            _, y = O.Header(frame, "Party reminder (shared)", y)
            local row; row, y = check(frame, y, "Remind me to mark", "Enable automatic reminder triggers. Test reminder still works when this is off.", "remind_enabled")
            return y, row
        end)
        local function enabled() return db.remind_enabled end
        section(function(frame, y)
            _, y = O.Header(frame, "When", y)
            for _, spec in ipairs({
                { "When I join a party", "Remind when you join or form a party.", "remind_on_join" },
                { "When someone joins", "Remind when a new player joins your party.", "remind_on_member" },
                { "Only as party leader", "Stay quiet unless you lead the party.", "remind_leader_only" },
                { "Quiet if someone else marks", "Skip the reminder when another CheckMark user is already marking.", "remind_quiet_others" },
            }) do _, y = check(frame, y, spec[1], spec[2], spec[3]) end
            _, y = O.Text(frame, "Reminders only fire when the grid would show (Visibility).", y)
            _, y = O.Header(frame, "Timing", y)
            return y
        end, enabled, master)
        timed("Wait after joining", "Each new joiner restarts the wait.", "remind_join_wait",
            "Seconds after joining", "remind_join_seconds", 1, 10, enabled, master)
        timed("Wait after combat", "A reminder held during combat waits so you can loot first. This replaces the joining wait.", "remind_combat_wait",
            "Seconds after combat", "remind_combat_seconds", 1, 15, enabled, master)
        -- Outputs stay available for testing even while automatic reminders are off.
        section(function(frame, y)
            _, y = O.Header(frame, "How to remind me", y)
            for _, spec in ipairs({
                { "Chat message", "Print the reminder in chat.", "remind_chat" },
                { "On-screen message", "Show a message like a raid warning.", "remind_screen" },
                { "Reminder sound", "Play the raid warning sound. Marker sounds have their own Sounds page.", "remind_sound" },
            }) do _, y = check(frame, y, spec[1], spec[2], spec[3]) end
            _, y = O.SettingLink(frame, y, "Marking window settings", "Reminder", "Show the marking window")
            return y
        end)
    end
    section(function(frame, y)
        _, y = O.ActionButton(frame, y, window and "Test marking window" or "Test reminder", function() ns.Reminder:Test() end,
            "Test your chosen outputs, even with reminders off. The enabled marking window uses a sample party.", "primary")
        _, y = O.PageReset(frame, y, function()
            for key, value in pairs(ns.Reminder.DEFAULTS) do
                if (WINDOW_KEYS[key] == true) == window then db[key] = value end
            end
        end, window and "Reset marking window" or "Reset reminder")
        return y
    end)
    return flow:Layout()
end
HC.Settings:NewPage({ name = "Reminder", title = "Reminder", group = "main", profileScope = false,
    description = "Choose when to be reminded, how it appears and how the marking window behaves.",
    tabs = {
        { name = "When and how", build = function(panel) return build(panel, false) end, columns = 1 },
        { name = "Marking window", build = function(panel) return build(panel, true) end, columns = 1 },
    },
})
