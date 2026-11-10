local addonName, ns = ...
local HC = ns.HammerCore
local O = HC.UI

-- HammerCore builds the Profiles page; CheckMark says what a profile saves.
HC.Profiles:NewPage({
    description = "World, Delve and Dungeon, switching as you go. Each has its own marker rules.",
    extra = function(frame, y)
        _, y = O.Header(frame, "What a profile saves", y)
        _, y = O.Text(frame, "Who goes first, role markers, fill order, and the grid's position, size and Show rules.", y)
        _, y = O.Text(frame, "Regulars, learned markers, the reminder and the marking window are the same in every profile.", y)
        _, y = O.SettingLink(frame, y, "Who goes first", "Markers", "Who goes first")
        return y
    end,
})
