local addon, ns = ...

-- Record whether saved data was available at Lua load, then ensure event
-- handlers always have a table to read.
ns.savedVariablesAtLuaLoad = type(CheckMarkDB) == "table"
if type(CheckMarkDB) ~= "table" then CheckMarkDB = {} end

local core = CreateFrame("Frame", addon.."Core")
ns.core = core

-- ── Constants ──────────────────────────────────────────────────────────────

ns.MARKER_NAMES = {
    [0] = "None",
    [1] = "Star",
    [2] = "Circle",
    [3] = "Diamond",
    [4] = "Triangle",
    [5] = "Moon",
    [6] = "Square",
    [7] = "Cross",
    [8] = "Skull",
}

ns.MARKER_TEXTURES = {}
for i = 1, 8 do
    ns.MARKER_TEXTURES[i] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_"..i
end
ns.MARKER_TEXTURES[0] = nil  -- no icon for "none"

function ns.getVersion()
    local getMetadata = C_AddOns and C_AddOns.GetAddOnMetadata
    local version = getMetadata and getMetadata(addon, "Version")
    if not version and GetAddOnMetadata then version = GetAddOnMetadata(addon, "Version") end
    return version or "development"
end

-- Chat output, settings, commands and the minimap button come from
-- HammerCore (Libs/HammerCore); see Setup.lua.
function ns.notify(msg)
    ns.HammerCore.Print(msg)
    if UIErrorsFrame then
        UIErrorsFrame:AddMessage("CheckMark: "..tostring(msg or ""), 1, 0.82, 0)
    end
end

-- Role markers: everyone else takes the fill order (Templates.lua).
ns.ROLE_SLOTS = { "TANK", "HEALER" }
ns.ROLE_SLOT_LABELS = {
    TANK   = "Tank",
    HEALER = "Healer",
}

-- ── DB defaults ────────────────────────────────────────────────────────────

local DEFAULT_DB = {
    visibility_mode         = "ALWAYS",
    panel_hidden            = false,
    popup_position          = nil,
    show_handle             = true,
    handle_position         = "TOP",
    cell_width              = 20,
    cell_height             = 20,
    icon_size               = 20,
    cell_columns            = 5,
    cell_spacing            = 1,
    show_cell_names         = false,
    marker_sound_enabled    = true,
    visibility              = {},
    role_template = {
        TANK   = 8,  -- Skull
        HEALER = 3,  -- Diamond
    },
    fill_order              = { 1, 2, 4, 5, 6, 7, 8, 3 },
    marker_rules            = "REGULARS_ROLES",
    regulars                = {},
    learn_mine              = true,
    share_party             = true,
    learn_party             = true,
}

ns.DEFAULT_DB = DEFAULT_DB

-- Saved-data version. 2 is 1.4.0: markers follow people, and the marking
-- window takes over from the on-screen message.
local SCHEMA = 2

local function copyValue(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = copyValue(child) end
    return result
end

local function initDB()
    local d = CheckMarkDB
    local existing = next(d) ~= nil

    for k, v in pairs(DEFAULT_DB) do
        if d[k] == nil then
            d[k] = copyValue(v)
        end
    end
    for _, module in ipairs({ ns.Reminder, ns.Preview }) do
        for k, v in pairs(module.DEFAULTS or {}) do
            if d[k] == nil then d[k] = v end
        end
    end

    if existing and (tonumber(d.schema) or 1) < SCHEMA then
        -- Once, for players updating to 1.4.0: the window replaces the
        -- on-screen message, newcomers now get a reminder, and DPS markers
        -- you'd set lead the new fill order.
        d.remind_screen, d.remind_on_member = false, true
        local fill = {}
        for _, slot in ipairs({ "DPS1", "DPS2", "DPS3" }) do
            local marker = tonumber(d.role_template and d.role_template[slot])
            if marker and marker > 0 then fill[#fill + 1] = marker end
        end
        for _, marker in ipairs(DEFAULT_DB.fill_order) do fill[#fill + 1] = marker end
        d.fill_order = fill
    end
    d.schema = SCHEMA
    if type(d.role_template) ~= "table" then d.role_template = copyValue(DEFAULT_DB.role_template) end
    for _, slot in ipairs(ns.ROLE_SLOTS) do
        if d.role_template[slot] == nil then d.role_template[slot] = 0 end
    end
    d.role_template.DPS1, d.role_template.DPS2, d.role_template.DPS3 = nil, nil, nil
    ns.db = d
    -- Profiles (World, Delve, Dungeon) switch on their own by default.
    if type(d.hcProfiles) ~= "table" then d.hcProfiles = { auto = { mode = "AUTO" } } end
    d.fill_order = ns.Assign.FillOrder(d.fill_order)
    local profiles = ns.HammerCore and ns.HammerCore.Profiles
    if profiles and profiles.enabled then profiles:Ready() end
    -- Keys from early development builds.
    d.last_mode, d.name_templates, d.remembered_groups = nil, nil, nil
    d.popup_on_group_change, d.popup_on_instance_enter = nil, nil
    d.raid_role_template, d.template_mode, d.auto_template_mode, d.panel_settings = nil, nil, nil, nil
end

-- ── Group helpers ──────────────────────────────────────────────────────────

-- One entry per member: Identity.Unit's fields (unit, guid, first, full,
-- realm, key, fullName) plus name, role and classFile.
function ns.getGroupMembers()
    local members = {}
    local seen = {}

    local function addUnit(unit)
        local member = ns.Identity.Unit(unit)
        if not member then return end
        local id = member.guid or member.key
        if seen[id] then return end
        seen[id] = true
        local role = UnitGroupRolesAssigned and UnitGroupRolesAssigned(unit)
        member.role = ns.Identity.Readable(role) and role or "NONE"
        member.name = member.first
        member.classFile = select(2, UnitClass(unit)) or "WARRIOR"
        table.insert(members, member)
    end

    addUnit("player")
    for i = 1, 4 do addUnit("party"..i) end

    return members
end

function ns.isEligibleGroup()
    if IsInRaid() then return false end
    local members = ns.getGroupMembers()
    return #members >= 2 and #members <= 5
end

-- Sorted full-name signature uniquely identifying the current group composition
function ns.getGroupSignature(members)
    members = members or ns.getGroupMembers()
    local names = {}
    for _, m in ipairs(members) do table.insert(names, m.fullName) end
    table.sort(names)
    return table.concat(names, "|")
end

-- ── Event handling ─────────────────────────────────────────────────────────

local pendingMarkerRebuild = false
ns.pendingMarkerRebuild = false  -- read by Marker.lua

-- A party forms in a burst of roster events; check once it settles.
local reminderQueued = false
local function queueReminder()
    if not ns.Reminder or reminderQueued then return end
    reminderQueued = true
    C_Timer.After(0.3, function()
        reminderQueued = false
        ns.Reminder:Check()
    end)
end

local friendsQueued = false
local function refreshFriends()
    if friendsQueued then return end
    friendsQueued = true
    C_Timer.After(0.5, function()
        friendsQueued = false
        ns.Identity:RefreshFriends()
    end)
end

local function onGroupChanged()
    if not ns.db then return end
    refreshFriends()
    queueReminder()
    if ns.MarkWindow then ns.MarkWindow:RosterChanged() end
    -- The grid owns its visibility through a secure state driver.  Do not try
    -- to show or hide secure children during combat.
    if ns.applyVisibility then ns.applyVisibility() end
    if InCombatLockdown and InCombatLockdown() then return end
    if not ns.isEligibleGroup() then
        if ns.hidePopup then ns.hidePopup() end
        return
    end
    if ns.showPopup then ns.showPopup() end
end

core:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName ~= addon then return end
        initDB()
        ns.Share:Register()
        ns.Identity:RefreshFriends()
        if ns.initializeMarkerSoundSettings then ns.initializeMarkerSoundSettings() end
        ns.HammerCore:Start()

    elseif event == "GROUP_ROSTER_UPDATE" then
        onGroupChanged()

    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Group unit tokens are reliable on the next frame on both login and
        -- reload, so use the same visibility rule for every world entry.
        C_Timer.After(0.2, function()
            if ns.Reminder then ns.Reminder:Prime() end
            onGroupChanged()
            if ns.Reminder then ns.Reminder:Recheck() end
        end)

    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "PARTY_LEADER_CHANGED" then
        if ns.applyVisibility then ns.applyVisibility() end
        if ns.Reminder then ns.Reminder:Recheck() end

    elseif event == "ROLE_CHANGED_INFORM" or event == "PLAYER_ROLES_ASSIGNED" then
        if ns.refreshPopup then ns.refreshPopup() end
        if ns.MarkWindow then ns.MarkWindow:RosterChanged() end

    elseif event == "CHAT_MSG_ADDON" then
        ns.Share:Receive(...)

    elseif event == "BN_FRIEND_INFO_CHANGED" or event == "BN_FRIEND_LIST_SIZE_CHANGED" then
        refreshFriends()

    elseif event == "PLAYER_REGEN_ENABLED" then
        if ns.Reminder then ns.Reminder:CombatEnded() end
        if ns.pendingMarkerRebuild then
            ns.pendingMarkerRebuild = false
            if ns.rebuildSecureButtons then ns.rebuildSecureButtons() end
            if ns.rebuildPendingRowSecureButtons then ns.rebuildPendingRowSecureButtons() end
        end
        if ns.applyVisibility then ns.applyVisibility() end
        if ns.refreshPopup then ns.refreshPopup() end
    end
end)

core:RegisterEvent("ADDON_LOADED")
core:RegisterEvent("GROUP_ROSTER_UPDATE")
core:RegisterEvent("PLAYER_ENTERING_WORLD")
core:RegisterEvent("PLAYER_REGEN_ENABLED")
pcall(core.RegisterEvent, core, "ROLE_CHANGED_INFORM")
pcall(core.RegisterEvent, core, "PLAYER_ROLES_ASSIGNED")
-- Party sharing and Battle.net friends.
pcall(core.RegisterEvent, core, "CHAT_MSG_ADDON")
pcall(core.RegisterEvent, core, "BN_FRIEND_INFO_CHANGED")
pcall(core.RegisterEvent, core, "BN_FRIEND_LIST_SIZE_CHANGED")
-- Show conditions depend on where you are and who leads.
pcall(core.RegisterEvent, core, "ZONE_CHANGED_NEW_AREA")
pcall(core.RegisterEvent, core, "PARTY_LEADER_CHANGED")
