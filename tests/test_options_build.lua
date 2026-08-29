local function equal(actual, expected, label)
    if actual ~= expected then error(label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual)) end
end

local named = {}
local methods = {}
local function object(name)
    local value = { name = name, scripts = {}, shown = true }
    setmetatable(value, { __index = function(self, key)
        if methods[key] then return methods[key] end
        return function() end
    end })
    if name then named[name] = value end
    return value
end

function methods:CreateFontString() return object() end
function methods:CreateTexture() return object() end
function methods:SetScript(name, callback) self.scripts[name] = callback end
function methods:HookScript(name, callback) self.scripts[name] = callback end
function methods:SetText(value) self.text = value end
function methods:SetShown(value) self.shown = value and true or false end
function methods:Show() self.shown = true end
function methods:Hide() self.shown = false end
function methods:IsShown() return self.shown end
function methods:SetChecked(value) self.checked = value end
function methods:GetChecked() return self.checked end
function methods:GetVerticalScrollRange() return 0 end
function methods:GetVerticalScroll() return 0 end
function methods:GetID() return self.name end

for _, name in ipairs({
    "SetSize", "SetPoint", "ClearAllPoints", "SetWidth", "SetHeight", "SetOrientation",
    "SetMinMaxValues", "SetValueStep", "SetObeyStepOnDrag", "SetValue", "SetTextColor",
    "SetJustifyH", "SetJustifyV", "SetTexture", "SetColorTexture", "SetAllPoints",
    "SetFrameStrata", "SetFrameLevel", "SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor",
    "EnableMouse", "EnableMouseWheel", "SetScrollChild", "SetVerticalScroll", "SetEnabled",
    "SetClampedToScreen", "SetMovable", "RegisterForDrag", "Raise", "StartMoving", "StopMovingOrSizing",
}) do methods[name] = function() end end

CreateFrame = function(_, name) return object(name) end
UIParent = object("UIParent")
GameTooltip = { SetOwner = function() end, SetText = function() end, AddLine = function() end, Show = function() end, Hide = function() end, IsOwned = function() return false end }
InterfaceOptions_AddCategory = function() end

local ns = {
    db = {
        settingsPoint = { "CENTER", "CENTER", 0, 0 }, visibility_mode = "ALWAYS", panel_hidden = false, hide_minimap = false, show_handle = true, handle_position = "TOP",
        popup_position = nil, cell_width = 20, cell_height = 20, icon_size = 20, cell_columns = 5, cell_spacing = 1,
        show_cell_names = false, template_mode = "PARTY", auto_template_mode = false,
        role_template = { TANK = 8, HEALER = 3, DPS1 = 0, DPS2 = 0, DPS3 = 0 },
        raid_role_template = { TANK1 = 8, TANK2 = 7, TANK3 = 6, HEALER1 = 5, HEALER2 = 4, HEALER3 = 3, HEALER4 = 2, HEALER5 = 1 },
    },
    ROLE_SLOTS = { "TANK", "HEALER", "DPS1", "DPS2", "DPS3" },
    PARTY_ROLE_SLOTS = { "TANK", "HEALER", "DPS1", "DPS2", "DPS3" },
    RAID_ROLE_SLOTS = { "TANK1", "TANK2", "TANK3", "HEALER1", "HEALER2", "HEALER3", "HEALER4", "HEALER5" },
    ROLE_SLOT_LABELS = { TANK = "Tank", HEALER = "Healer", DPS1 = "DPS 1", DPS2 = "DPS 2", DPS3 = "DPS 3" },
    MARKER_TEXTURES = { [1] = "star", [2] = "circle", [3] = "diamond", [4] = "triangle", [5] = "moon", [6] = "square", [7] = "cross", [8] = "skull" },
    getVersion = function() return "0.2.0-test" end,
    refreshPopup = function() end, applyVisibility = function() end, updateHandle = function() end, refreshMinimapButton = function() end,
    hidePopup = function() end, showPopup = function() end, notify = function() end,
}

assert(loadfile("Options/Shared.lua"))("CheckMark", ns)
for _, path in ipairs({ "Options/CheckMark.lua", "Options/Markers.lua", "Options/Visibility.lua", "Options/Commands.lua", "Options/About.lua" }) do
    assert(loadfile(path))("CheckMark", ns)
end
ns.Options.BuildAll()
equal(ns.Options.window.name, "CheckMarkSettingsFrame", "Salve-style movable settings window is constructed")
local pageCount = 0
for _ in pairs(ns.Options.pages) do pageCount = pageCount + 1 end
equal(pageCount, 5, "five CheckMark-specific pages are constructed")
ns.OpenOptions("Markers")
equal(ns.Options.selectedPage, "Markers", "requested page opens")
equal(ns.Options.window.shown, true, "settings window opens")
ns.Options.ShowPage("unknown")
equal(ns.Options.selectedPage, "CheckMark", "unknown page falls back to Panel")
print("CheckMark options build tests passed")
