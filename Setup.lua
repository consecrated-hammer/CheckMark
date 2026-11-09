local addonName, ns = ...
local HC = ns.HammerCore

-- Declares CheckMark to HammerCore: commands, grid actions, the minimap
-- right-click, status, diagnostics and About content.

-- The header button on pages whose settings change how the grid looks.
ns.LivePreviewAction = {
    text = function() return ns.Preview:IsShown() and "Hide live preview" or "Show live preview" end,
    onClick = function() ns.Preview:Toggle() end,
    hint = "An actual-size preview of the grid with a sample party, in its own window. Drag it anywhere; it stays open while you change pages.",
}

local quips = {
    "All marked up. Try not to make it a personality.",
    "A skull for the tank. Classic for a reason.",
    "Markers applied. The pull is now at least emotionally prepared.",
    "One click per person. That is the whole CheckMark thesis.",
    "The raid icons have been asked politely to behave.",
    "No targets were inspected in the making of this assignment.",
    "CheckMark: because 'you are the triangle' is an actionable plan.",
    "Eight icons, zero prophecy. Just a tidy little roster.",
    "The marker grid is compact. Your responsibilities remain enormous.",
    "Pre-pull admin complete. Now comes the part with the dragons.",
}

local function yesNo(value) return value and "yes" or "no" end

local function metadata(key)
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        local value = C_AddOns.GetAddOnMetadata(addonName, key)
        if value ~= nil then return value end
    end
    return GetAddOnMetadata and GetAddOnMetadata(addonName, key)
end

local function framePoint(frame)
    if not frame or not frame.GetPoint then return "not created" end
    local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
    return table.concat({ tostring(point or "?"), tostring(relativeTo and relativeTo:GetName() or "?"),
        tostring(relativePoint or "?"), string.format("%.1f", x or 0), string.format("%.1f", y or 0) }, " ")
end

local function buildReport()
    local interface
    if GetBuildInfo then
        local ok, _, _, _, value = pcall(GetBuildInfo)
        if ok then interface = value end
    end
    local db = ns.db or {}
    local button = _G.CheckMarkMinimapButton
    local lines = {
        "Interface: " .. tostring(interface or "unknown"),
        "Target: " .. tostring(metadata("X-CheckMark-Target") or "Retail"),
        "Database at Lua load: " .. (ns.savedVariablesAtLuaLoad and "loaded" or "absent"),
        "Database active: " .. (type(ns.db) == "table" and "ready" or "unavailable"),
        "Group: " .. (IsInRaid() and "raid" or ns.isEligibleGroup and ns.isEligibleGroup() and "eligible party" or "solo or unsupported party"),
        "Combat lockdown: " .. yesNo(InCombatLockdown and InCombatLockdown()),
        "Panel hidden: " .. yesNo(db.panel_hidden),
        "Visibility mode: " .. tostring(db.visibility_mode or "unknown"),
        "Marker sound: " .. yesNo(db.marker_sound_enabled),
        "Mark reminder: " .. (db.remind_enabled and "on" or "off") .. (ns.Reminder and ns.Reminder.lastReason
            and (", last: " .. ns.Reminder.lastReason) or ""),
        "Sound check: " .. ns.markerSoundCheckSummary(),
        "Minimap button: " .. ((HC.State() or {}).minimap and "shown" or "hidden"),
        "Minimap stored angle: " .. tostring((HC.State() or {}).minimapAngle or "none"),
        "Minimap button: " .. (button and "created" or "not created"),
        "Minimap visible: " .. (button and yesNo(button:IsShown()) or "not created"),
        "Minimap point: " .. framePoint(button),
        "Minimap size/scale: " .. string.format("%.1f x %.1f / %.3f", Minimap:GetWidth() or 0, Minimap:GetHeight() or 0, Minimap:GetEffectiveScale() or 0),
        "Report privacy: no character names, assignments or marker history included.",
    }
    return table.concat(lines, "\n")
end


local function setHandle(shown)
    ns.db.show_handle = shown
    if ns.updateHandle then ns.updateHandle() end
    HC.Print("drag handle " .. (shown and "shown" or "hidden"))
end

-- Highlights for HammerCore's What's new page, newest first. Every
-- CurseForge release gets an entry, fixes included (Kevin, 2026-11-09);
-- HammerCore's tools/whatsnew_check.py fails the release without one. A
-- `page` adds a link to that settings page.
local WHATS_NEW = {
    { version = "1.3.0", date = "2026-11-09", items = {
        { title = "Mark reminder", text = "Join a party and CheckMark nudges you to mark everyone. Choose when and how on the Reminder page, or turn it off.",
            page = "Reminder" },
        { title = "Live preview", text = "Show live preview at the top of Panel and Markers draws your grid at actual size with a sample party, in its own window.",
            kind = "improved", page = "CheckMark" },
        { title = "Show rules", text = "Show the grid only in dungeons, delves, the open world or when you lead. Tick any mix on Visibility.",
            page = "Visibility" },
        { title = "More sounds", text = "New marker sounds, Select all and Deselect all, and each client only lists sounds it can play.",
            kind = "improved", page = "Sounds" },
        { title = "A fresh coat of paint", text = "Settings got a new look: two columns, switches, marker icons on every heading, and this What's new page.",
            kind = "improved" },
        { title = "Support links", text = "CurseForge, Discord and Buy me a coffee sit at the bottom of the settings window. Hide them on Visibility.",
            kind = "improved", page = "Visibility" },
    } },
    -- History: written after the fact for releases from before What's new.
    { version = "1.2.0", date = "2026-09-26", history = true, items = {
        { text = "Check sounds finds marker sounds your client can't play.", page = "Sounds" },
        "A lore quiz, and the same commands and settings layout as every Consecrated Hammer addon.",
    } },
    { version = "1.1.0", date = "2026-09-13", history = true, items = {
        { text = "Marker sounds: pick from the catalogue, random or in order.", page = "Sounds" },
    } },
    { version = "1.0.0", date = "2026-08-29", history = true, items = {
        "Role markers and one cell per party member: click to mark before the pull.",
    } },
}

HC:Init({
    name = "CheckMark",
    command = "checkmark",
    aliases = { "cm" },
    savedVariable = "CheckMarkDB",
    db = function() return ns.db end,
    icon = "Interface\\AddOns\\CheckMark\\Textures\\CheckMark",
    legacy = {
        startupMessage = "show_startup_message",
        minimap = { key = "hide_minimap", invert = true },
        minimapAngle = "minimap_angle",
        settingsPoint = "settingsPoint",
    },
    clientLabel = function()
        return HC.GetMetadata("X-CheckMark-Target") == "Camelot" and "WoW Forever" or "Retail"
    end,
    minimap = {
        icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",
        rightClick = function() if ns.togglePopup then ns.togglePopup() end end,
        rightClickLabel = "show or hide the grid",
    },
    toggle = { help = "Show or hide the marker grid",
        run = function() if ns.togglePopup then ns.togglePopup() end end },
    lock = { help = "Hide the drag handle", run = function() setHandle(false) end },
    unlock = { help = "Show the drag handle", run = function() setHandle(true) end },
    resetPosition = function()
        ns.db.popup_position = nil
        if ns.hidePopup then ns.hidePopup() end
        if ns.showPopup then ns.showPopup() end
    end,
    status = function()
        local db = ns.db or {}
        return table.concat({
            "Group: " .. (IsInRaid() and "raid" or ns.isEligibleGroup and ns.isEligibleGroup() and "eligible party"
                or "solo or unsupported party"),
            "Grid: " .. (db.visibility_mode == "HIDDEN" and "never shown" or "shown outside combat"),
            "Marker sound: " .. (db.marker_sound_enabled and "on" or "off"),
        }, "\n")
    end,
    diagnostics = buildReport,
    onSettingsShown = function()
        if ns.db.preview_window_open then ns.Preview:Show() end
    end,
    onSettingsHidden = function() ns.Preview:Hide() end,
    whatsNew = WHATS_NEW,
    about = {
        note = "CHECKMARKER'S NOTE",
        tips = quips,
        action = "Apply CheckMark",
    },
})

HC.Commands:Add({ name = "sounds", section = "Sounds", help = "Find marker sounds this client lacks",
    run = function()
        local missing, reason = ns.checkMarkerSounds()
        if not missing then return HC.Print(reason) end
        HC.Print(ns.markerSoundCheckSummary())
        if HC.Settings:IsShown() then HC.Settings:Select(HC.Settings.selected) end
    end })

HC.Commands:AddAction({ section = "Grid", usage = "Left-click a cell", help = "Apply that role's marker" })
HC.Commands:AddAction({ section = "Grid", usage = "Right-click a cell", help = "Remove the marker from that member" })
HC.Commands:AddAction({ section = "Grid", usage = "Left-click an empty cell", help = "Open Markers settings" })
HC.Commands:AddAction({ section = "Grid", usage = "Drag the handle", help = "Move the grid; right-click it for settings" })
