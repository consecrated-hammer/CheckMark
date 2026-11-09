local addon, ns = ...
local HC = ns.HammerCore
local O = HC.UI

-- When CheckMark nudges you to mark the party, and how.

local ICON = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1"
local HOW_ICON = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2"

HC.Settings:NewPage({
    name = "Reminder",
    title = "Reminder",
    group = "main",
    description = "A nudge to mark your party when it forms.",
}, function(panel, y)
    local db = ns.db
    local function check(label, hint, key)
        local row
        row, y = O.Check(panel, label, hint, y,
            function() return db[key] end,
            function(value) db[key] = value end)
        return row
    end

    _, y = O.Header(panel, "When", y, ICON)
    check("Remind me to mark", "Turn the mark reminder on or off.", "remind_enabled")
    local rows = {
        check("When I join a party", "Remind when you join or form a party.", "remind_on_join"),
        check("When someone joins", "Remind when a new player joins your party.", "remind_on_member"),
        check("Only as party leader", "Stay quiet unless you lead the party.", "remind_leader_only"),
    }

    _, y = O.Text(panel, "Follows the grid's Show rules on Visibility, so it waits until the grid can show.", y)
    _, y = O.Header(panel, "How", y, HOW_ICON)
    rows[#rows + 1] = check("Chat message", "Print the reminder in chat.", "remind_chat")
    rows[#rows + 1] = check("On-screen message", "Show the reminder in the middle of the screen, like a raid warning.", "remind_screen")
    rows[#rows + 1] = check("Sound", "Play the raid warning sound.", "remind_sound")

    O.OnRefresh(panel, function()
        for _, row in ipairs(rows) do O.SetEnabled(row.hcCheckbox, db.remind_enabled) end
    end)

    _, y = O.ActionButton(panel, y, "Test reminder", function() ns.Reminder:Test() end,
        "Show the reminder now, with the outputs chosen above.")
    _, y = O.PageReset(panel, y, function()
        for key, value in pairs(ns.Reminder.DEFAULTS) do db[key] = value end
    end, "Reset reminder")
    return y
end)
