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

-- Ordered role slots for role-based mode
ns.ROLE_SLOTS    = { "TANK", "HEALER", "DPS1", "DPS2", "DPS3" }
ns.ROLE_SLOT_LABELS = {
    TANK   = "Tank",
    HEALER = "Healer",
    DPS1   = "DPS 1",
    DPS2   = "DPS 2",
    DPS3   = "DPS 3",
}

-- ── DB defaults ────────────────────────────────────────────────────────────

local DEFAULT_DB = {
    popup_on_group_change   = true,
    popup_on_instance_enter = true,
    last_mode               = "ROLE",  -- "ROLE" or "NAME"
    popup_position          = nil,
    role_template = {
        TANK   = 8,  -- Skull
        HEALER = 3,  -- Diamond
        DPS1   = 0,
        DPS2   = 0,
        DPS3   = 0,
    },
    name_templates    = {},
    remembered_groups = {},
}

local function initDB()
    if type(CheckMarkDB) ~= "table" then CheckMarkDB = nil end
    CheckMarkDB = CheckMarkDB or {}
    local d = CheckMarkDB

    for k, v in pairs(DEFAULT_DB) do
        if d[k] == nil then
            if type(v) == "table" then
                d[k] = {}
                for kk, vv in pairs(v) do d[k][kk] = vv end
            else
                d[k] = v
            end
        end
    end

    -- Fill any missing role slots
    for _, slot in ipairs(ns.ROLE_SLOTS) do
        if d.role_template[slot] == nil then
            d.role_template[slot] = 0
        end
    end

    ns.db = d
end

-- ── Group helpers ──────────────────────────────────────────────────────────

-- Returns {unit, name, realm, fullName, targetName, role, classFile} for each member.
-- Player is always first; party1..party4 follow in party order.
function ns.getGroupMembers()
    local members = {}

    local function addUnit(unit)
        if not UnitExists(unit) then return end
        local name, realm = UnitName(unit)
        if not name then return end
        if not realm or realm == "" then realm = GetRealmName() end
        -- targetName: used in /targetexact — include realm only if cross-realm
        local _, localRealm = UnitName("player")
        local targetName = name
        if realm ~= GetRealmName() then
            targetName = name.."-"..realm
        end
        table.insert(members, {
            unit       = unit,
            name       = name,
            realm      = realm,
            fullName   = name.."-"..realm,
            targetName = targetName,
            role       = UnitGroupRolesAssigned(unit) or "NONE",
            classFile  = select(2, UnitClass(unit)) or "WARRIOR",
        })
    end

    addUnit("player")
    if IsInGroup() and not IsInRaid() then
        for i = 1, 4 do addUnit("party"..i) end
    end

    return members
end

function ns.isEligibleGroup()
    if IsInRaid() then return false end
    local members = ns.getGroupMembers()
    return #members >= 2 and #members <= 5
end

-- Sorted full-name signature uniquely identifying the current group composition
function ns.getGroupSignature()
    local members = ns.getGroupMembers()
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
    if not ns.db.popup_on_group_change then return end
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
        if ns.onAddonLoaded then ns.onAddonLoaded() end

    elseif event == "GROUP_ROSTER_UPDATE" then
        onGroupChanged()

    elseif event == "PLAYER_ENTERING_WORLD" then
        local isLogin, isReload = ...
        -- Suppress the initial login/reload fire; only catch actual zone transitions
        if isLogin or isReload then return end
        if ns.db and ns.db.popup_on_instance_enter then
            C_Timer.After(1.5, function()
                if ns.isEligibleGroup() and ns.showPopup then
                    ns.showPopup()
                end
            end)
        end

    elseif event == "ROLE_CHANGED_INFORM" then
        if ns.refreshPopup then ns.refreshPopup() end

    elseif event == "PLAYER_REGEN_ENABLED" then
        if ns.pendingMarkerRebuild then
            ns.pendingMarkerRebuild = false
            if ns.rebuildSecureButtons then ns.rebuildSecureButtons() end
        end
    end
end)

core:RegisterEvent("ADDON_LOADED")
core:RegisterEvent("GROUP_ROSTER_UPDATE")
core:RegisterEvent("PLAYER_ENTERING_WORLD")
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
        CheckMarkDB = nil
        ReloadUI()
    else
        if ns.togglePopup then ns.togglePopup()
        else print("CheckMark: UI not ready.") end
    end
end
