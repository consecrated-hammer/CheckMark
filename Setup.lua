local addonName, ns = ...
local HC = ns.HammerCore

-- Declares CheckMark to HammerCore: commands, grid actions, the minimap
-- right-click, status, diagnostics and About content.

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
