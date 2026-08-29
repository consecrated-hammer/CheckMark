local addon, ns = ...

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

function ns.notify(msg)
    print("|cffffd200CheckMark:|r "..tostring(msg or ""))
    if UIErrorsFrame then
        UIErrorsFrame:AddMessage("CheckMark: "..tostring(msg or ""), 1, 0.82, 0)
    end
end

ns.ROLE_SLOTS = { "TANK", "HEALER", "DPS1", "DPS2", "DPS3" }
-- Compatibility aliases for saved UI fragments from earlier development
-- builds; CheckMark now exposes only this five-player role template.
ns.PARTY_ROLE_SLOTS = ns.ROLE_SLOTS
ns.RAID_ROLE_SLOTS = {}
ns.ROLE_SLOT_LABELS = {
    TANK   = "Tank",
    HEALER = "Healer",
    DPS1   = "DPS 1",
    DPS2   = "DPS 2",
    DPS3   = "DPS 3",
}

-- ── DB defaults ────────────────────────────────────────────────────────────

local DEFAULT_DB = {
    visibility_mode         = "ALWAYS",
    panel_hidden            = false,
    popup_position          = nil,
    show_handle             = true,
    handle_position         = "TOP",
    minimap_angle           = 225,
    hide_minimap            = false,
    cell_width              = 20,
    cell_height             = 20,
    icon_size               = 20,
    cell_columns            = 5,
    cell_spacing            = 1,
    show_cell_names         = false,
    role_template = {
        TANK   = 8,  -- Skull
        HEALER = 3,  -- Diamond
        DPS1   = 0,
        DPS2   = 0,
        DPS3   = 0,
    },
}

local function copyValue(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = copyValue(child) end
    return result
end

local function copyDefaults(dest)
    for k in pairs(dest) do dest[k] = nil end
    for k, v in pairs(DEFAULT_DB) do
        dest[k] = copyValue(v)
    end
end

local function initDB()
    if type(CheckMarkDB) ~= "table" then CheckMarkDB = nil end
    CheckMarkDB = CheckMarkDB or {}
    local d = CheckMarkDB

    for k, v in pairs(DEFAULT_DB) do
        if d[k] == nil then
            d[k] = copyValue(v)
        end
    end

    -- Fill any missing party role slots.
    for _, slot in ipairs(ns.ROLE_SLOTS) do
        if d.role_template[slot] == nil then
            d.role_template[slot] = 0
        end
    end
    ns.db = d
    -- Saved-party planning is intentionally deferred; keep the saved-variable
    -- surface focused on reusable role presets for now.
    d.last_mode, d.name_templates, d.remembered_groups = nil, nil, nil
    d.popup_on_group_change, d.popup_on_instance_enter = nil, nil
    d.raid_role_template, d.template_mode, d.auto_template_mode, d.panel_settings = nil, nil, nil, nil
end

function ns.resetDB()
    CheckMarkDB = {}
    copyDefaults(CheckMarkDB)
    ns.db = CheckMarkDB
    if ns.refreshOptions then ns.refreshOptions() end
    if ns.refreshPopup then ns.refreshPopup() end
    if ns.applyVisibility then ns.applyVisibility() end
end

-- ── Group helpers ──────────────────────────────────────────────────────────

-- Returns {unit, name, realm, fullName, role, classFile} for each member.
function ns.getGroupMembers()
    local members = {}
    local seen = {}

    local function addUnit(unit)
        if not UnitExists(unit) then return end
        local guid = UnitGUID(unit)
        if guid and seen[guid] then return end
        local name, realm = UnitName(unit)
        if not name then return end
        if guid then seen[guid] = true end
        if not realm or realm == "" then realm = GetRealmName() end
        table.insert(members, {
            unit       = unit,
            name       = name,
            realm      = realm,
            fullName   = name.."-"..realm,
            role       = UnitGroupRolesAssigned(unit) or "NONE",
            classFile  = select(2, UnitClass(unit)) or "WARRIOR",
        })
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

local function onGroupChanged()
    if not ns.db then return end
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
        if ns.Options and ns.Options.EnsureBuilt then ns.Options.EnsureBuilt() end
        if ns.onAddonLoaded then ns.onAddonLoaded() end
        if ns.createMinimapButton then ns.createMinimapButton() end

    elseif event == "GROUP_ROSTER_UPDATE" then
        onGroupChanged()

    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Group unit tokens are reliable on the next frame on both login and
        -- reload, so use the same visibility rule for every world entry.
        C_Timer.After(0.2, onGroupChanged)

    elseif event == "ROLE_CHANGED_INFORM" then
        if ns.refreshPopup then ns.refreshPopup() end

    elseif event == "PLAYER_REGEN_DISABLED" then
        -- The secure visibility driver hides the grid at combat start.
        if ns.refreshMinimapButton then ns.refreshMinimapButton() end

    elseif event == "PLAYER_REGEN_ENABLED" then
        if ns.pendingMarkerRebuild then
            ns.pendingMarkerRebuild = false
            if ns.rebuildSecureButtons then ns.rebuildSecureButtons() end
            if ns.rebuildPendingRowSecureButtons then ns.rebuildPendingRowSecureButtons() end
        end
        if ns.applyVisibility then ns.applyVisibility() end
        if ns.refreshPopup then ns.refreshPopup() end
        if ns.refreshMinimapButton then ns.refreshMinimapButton() end
    end
end)

core:RegisterEvent("ADDON_LOADED")
core:RegisterEvent("GROUP_ROSTER_UPDATE")
core:RegisterEvent("PLAYER_ENTERING_WORLD")
core:RegisterEvent("PLAYER_REGEN_DISABLED")
core:RegisterEvent("PLAYER_REGEN_ENABLED")
pcall(core.RegisterEvent, core, "ROLE_CHANGED_INFORM")

-- ── Slash commands ─────────────────────────────────────────────────────────

SLASH_CHECKMARK1 = "/checkmark"
SLASH_CHECKMARK2 = "/cm"
SlashCmdList["CHECKMARK"] = function(msg)
    msg = (msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "options" or msg == "opt" then
        if ns.showOptions then ns.showOptions()
        else print("CheckMark: options panel not ready.") end
    elseif msg == "reset" then
        ns.resetDB()
        ns.notify("Settings reset.")
    else
        if ns.togglePopup then ns.togglePopup()
        else print("CheckMark: UI not ready.") end
    end
end
