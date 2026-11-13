local addonName, ns = ...
local HC = ns.HammerCore

ns.Options = setmetatable({}, { __index = HC.UI })

-- Sections share their page's refresh list and search index.
function ns.Options.Section(parent, columns, parentRow)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(HC.UI.CONTENT_WIDTH + HC.UI.PAD * 2, 1)
    frame.hcColumns = columns or 2
    frame.hcRefresh, frame.hcRefreshAll = parent.hcRefresh, parent.hcRefreshAll
    frame.hcHeaderOwner = parent.hcHeaderOwner or parent
    frame.hcParentRow = parentRow
    return frame
end

-- Hidden dependent sections leave no gap and keep a searchable parent.
function ns.Options.Flow(panel)
    local flow = { entries = {}, y = -8 }
    function flow:Add(frame, height, visible, parentRow)
        if parentRow then frame.hcParentRow = parentRow end
        self.entries[#self.entries + 1] = { frame = frame, height = height, visible = visible }
    end
    function flow:Layout()
        local y = -8
        for _, entry in ipairs(self.entries) do
            local shown = not entry.visible or entry.visible()
            entry.frame:SetShown(shown)
            if shown then
                entry.frame:ClearAllPoints()
                entry.frame:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, y)
                local height = type(entry.height) == "function" and entry.height() or entry.height
                entry.frame:SetHeight(height)
                y = y - height
            end
        end
        self.y = y - 8
        if panel.hcSetBottom then panel.hcSetBottom(self.y) end
        return self.y
    end
    panel.hcRefresh[#panel.hcRefresh + 1] = function() flow:Layout() end
    return flow
end

-- Declares CheckMark to HammerCore: commands, grid actions, the minimap
-- menu, status, diagnostics and About content.

-- The header button on pages whose settings change how the grid looks.
ns.LivePreviewAction = {
    text = function() return ns.Preview:IsShown() and "Hide live preview" or "Show live preview" end,
    onClick = function() ns.Preview:Toggle() end,
    hint = "An actual-size preview of the grid with a sample party, in its own window. Drag it anywhere; it stays open while you change pages.",
}

local quips = {
    "All marked up. Try not to make it a personality.",
    "A skull for the tank. Classic for a reason.",
    "Markers applied. Your party is now at least easy to find.",
    "One click per person. That is the whole CheckMark thesis.",
    "The raid icons have been asked politely to behave.",
    "No targets were inspected in the making of this assignment.",
    "CheckMark: because 'you are the triangle' is an actionable plan.",
    "Eight icons, zero prophecy. Just a tidy little roster.",
    "The marker grid is compact. Your responsibilities remain enormous.",
    "Marker admin complete. Now comes the part with the dragons.",
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


-- Extras under HammerCore's settings and Profiles items on the minimap
-- right-click. Marking needs a click per person, so "Mark the party" opens
-- the marking window; solo, it previews it with a sample party.
function ns.minimapMenu()
    local combat = InCombatLockdown and InCombatLockdown() or false
    local party = ns.isEligibleGroup and ns.isEligibleGroup() or false
    return {
        { text = party and "Mark the party" or "Preview marking window", disabled = combat,
            func = function()
                if party then ns.MarkWindow:Open() else ns.MarkWindow:Test() end
            end },
        { text = "Show grid", checked = ns.isPopupShown and ns.isPopupShown() or false, disabled = combat,
            func = function() if ns.togglePopup then ns.togglePopup() end end },
        { text = "Mark reminder", checked = ns.db.remind_enabled and true or false,
            func = function()
                ns.db.remind_enabled = not ns.db.remind_enabled
                HC.Print("mark reminder " .. (ns.db.remind_enabled and "on" or "off"))
                if HC.Settings:IsShown() then HC.Settings:Select(HC.Settings.selected) end
            end },
    }
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
    { version = "1.4.0", date = "2026-11-10", items = {
        { title = "Mark your party", text = "When your party forms, a big window pops up with everyone's marker. Click each person to mark them.",
            page = "Reminder" },
        { title = "Markers follow people", text = "Pin someone to a marker and they keep it on any of their characters if they're a Battle.net friend.",
            page = "Markers" },
        { title = "It learns", text = "CheckMark remembers the markers you pick, and party members running CheckMark share theirs. Manage pinned and learned people on Markers > Regulars.",
            page = "Markers", tab = "Regulars" },
        { title = "World, Delve, Dungeon", text = "Profiles switch automatically, so dungeons can go by role and the open world by who's who.",
            page = "Profiles" },
        { title = "Good timing", text = "Reminders wait a couple of seconds after someone joins, and a few after combat so you can loot first.",
            kind = "improved", page = "Reminder" },
        { title = "Minimap menu", text = "Right-click the minimap button to mark the party, show the grid or switch the reminder.",
            kind = "improved", page = "Visibility" },
        { title = "Settings search", text = "Type in the box at the top of settings to jump straight to any setting.",
            kind = "improved" },
    } },
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
        menu = function() return ns.minimapMenu() end,
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

HC.Commands:AddAction({ section = "Grid", usage = "Left-click a cell", help = "Apply that person's marker" })
HC.Commands:AddAction({ section = "Grid", usage = "Right-click a cell", help = "Remove the marker from that member" })
HC.Commands:AddAction({ section = "Grid", usage = "Left-click an empty cell", help = "Open Markers settings" })
HC.Commands:AddAction({ section = "Marking window", usage = "Click a card", help = "Mark that person" })
HC.Commands:AddAction({ section = "Marking window", usage = "Click a card's icon", help = "Choose another marker; CheckMark remembers it" })
HC.Commands:AddAction({ section = "Marking window", usage = "Click a card's pin", help = "Always give that person this marker" })

-- Profiles: World, Delve and Dungeon, switching on their own. A profile
-- saves who goes first, the role markers and fill order, and the grid's
-- position, size and Show rules. Regulars, the reminder and the window are
-- the same in every profile.
HC.Profiles:Setup({
    groups = {
        { key = "markers", label = "Markers", keys = { "marker_rules", "role_template", "fill_order" } },
        { key = "position", label = "Position", keys = { "popup_position", "show_handle", "handle_position" } },
        { key = "grid", label = "Grid and size",
            keys = { "cell_width", "cell_height", "icon_size", "cell_columns", "cell_spacing", "show_cell_names" } },
        { key = "visibility", label = "Visibility", keys = { "visibility_mode", "visibility" } },
    },
    defaults = function() return ns.DEFAULT_DB end,
    seed = {
        { name = "World", values = { marker_rules = "REGULARS_ROLES" } },
        { name = "Delve", values = { marker_rules = "REGULARS_ROLES" } },
        { name = "Dungeon", values = { marker_rules = "ROLES_REGULARS" } },
    },
    active = "World",
    rules = {
        { profile = "Dungeon", instance = { PARTY = true }, source = "GROUP", min = 1, max = 40 },
        { profile = "Delve", instance = { SCENARIO = true }, source = "GROUP", min = 1, max = 40 },
        { profile = "World", source = "GROUP", min = 1, max = 40 },
    },
    unsafe = function() return InCombatLockdown and InCombatLockdown() end,
    apply = function()
        if ns.placePopup then ns.placePopup() end
        if ns.updateHandle then ns.updateHandle() end
        if ns.refreshPopup then ns.refreshPopup() end
        if ns.applyVisibility then ns.applyVisibility() end
        if ns.MarkWindow and ns.MarkWindow:IsShown() then ns.MarkWindow:Refresh() end
        if ns.Preview then ns.Preview:Refresh() end
    end,
})

-- /checkmark whois: everything behind who gets which marker, to copy.
-- It names people, so it isn't part of the diagnostics report.
local function whois()
    local Identity = ns.Identity
    Identity:RefreshFriends()
    local inside, kind = false, "none"
    if IsInInstance then inside, kind = IsInInstance() end
    local lines = {
        "Client: " .. (Identity.IsForever() and "WoW Forever" or "Retail"),
        "Where: " .. (inside and tostring(kind) or "open world"),
        "Profile: " .. tostring(HC.Profiles:Active() or "none"),
        "Who goes first: " .. tostring(ns.db.marker_rules),
        "Your BattleTag readable: " .. yesNo(Identity.selfTag ~= nil),
        "Friends list readable: " .. yesNo(Identity.friendsReadable) .. " (" .. #Identity.friends .. " friends)",
        "Party messages: " .. (ns.Share.registered and "registered" or "not registered")
            .. (ns.Share.lastSendOk == nil and "" or (", last send " .. (ns.Share.lastSendOk and "ok" or "failed"))),
        "",
    }
    local members = Identity.Label(ns.getGroupMembers())
    for _, slot in ipairs(ns.Assign.Plan(members)) do
        local member = slot.member
        local tag = Identity.TagFor(member.guid)
        lines[#lines + 1] = ("%s: %s (%s), role %s, GUID %s, %s"):format(member.label or "?",
            ns.MARKER_NAMES[slot.marker] or "None", ns.Assign.SOURCE_LABELS[slot.source] or "?", tostring(member.role),
            member.guid and "readable" or "hidden", tag and ("Battle.net " .. tag) or ("character " .. tostring(member.key)))
    end
    if #members == 0 then lines[#lines + 1] = "Not in a party." end
    HC.Copy:Show("CheckMark whois", table.concat(lines, "\n"), "Press Ctrl+C to copy, then paste it to Claude.")
end

HC.Commands:Add({ name = "whois", section = "Diagnostics", help = "Explain who gets which marker, and why",
    run = whois })
HC.Commands:AddAction({ section = "Grid", usage = "Drag the handle", help = "Move the grid; right-click it for settings" })
