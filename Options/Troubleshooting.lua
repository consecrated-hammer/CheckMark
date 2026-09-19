local addonName, ns = ...
local O = ns.Options

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
        "CheckMark diagnostics",
        "Version: " .. tostring(ns.getVersion and ns.getVersion() or metadata("Version") or "unknown"),
        "Interface: " .. tostring(interface or "unknown"),
        "Target: " .. tostring(metadata("X-CheckMark-Target") or "Retail"),
        "Database at Lua load: " .. (ns.savedVariablesAtLuaLoad and "loaded" or "absent"),
        "Database active: " .. (type(ns.db) == "table" and "ready" or "unavailable"),
        "Group: " .. (IsInRaid() and "raid" or ns.isEligibleGroup and ns.isEligibleGroup() and "eligible party" or "solo or unsupported party"),
        "Combat lockdown: " .. yesNo(InCombatLockdown and InCombatLockdown()),
        "Panel hidden: " .. yesNo(db.panel_hidden),
        "Visibility mode: " .. tostring(db.visibility_mode or "unknown"),
        "Marker sound: " .. yesNo(db.marker_sound_enabled),
        "Minimap hidden: " .. yesNo(db.hide_minimap),
        "Minimap stored angle: " .. tostring(db.minimap_angle or "none"),
        "Minimap button: " .. (button and "created" or "not created"),
        "Minimap visible: " .. (button and yesNo(button:IsShown()) or "not created"),
        "Minimap point: " .. framePoint(button),
        "Minimap size/scale: " .. string.format("%.1f x %.1f / %.3f", Minimap:GetWidth() or 0, Minimap:GetHeight() or 0, Minimap:GetEffectiveScale() or 0),
        "Report privacy: no character names, assignments or marker history included.",
    }
    return table.concat(lines, "\n")
end

ns.BuildDiagnosticReport = buildReport

local dialog
function ns.ShowDiagnosticReport()
    if not dialog then
        dialog = CreateFrame("Frame", "CheckMarkCopyReport", UIParent, "BackdropTemplate")
        dialog:SetSize(640, 360); dialog:SetPoint("CENTER"); dialog:SetFrameStrata("FULLSCREEN_DIALOG")
        dialog:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 })
        dialog:SetBackdropColor(0.035, 0.035, 0.04, 0.98); dialog:SetBackdropBorderColor(0.58, 0.43, 0.22, 1); dialog:EnableMouse(true)
        local title = dialog:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); title:SetPoint("TOPLEFT", 18, -16); title:SetText("Copy CheckMark report")
        local help = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); help:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5); help:SetText("Press Ctrl+C, then Escape.")
        local scroll = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT", 18, -66); scroll:SetPoint("BOTTOMRIGHT", -38, 44)
        local edit = CreateFrame("EditBox", nil, scroll); edit:SetMultiLine(true); edit:SetAutoFocus(false); edit:SetFontObject(ChatFontNormal); edit:SetWidth(565); edit:SetHeight(800); edit:SetTextInsets(4, 4, 4, 4); edit:SetScript("OnEscapePressed", function() dialog:Hide() end); scroll:SetScrollChild(edit); dialog.edit = edit
        local close = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate"); close:SetSize(90, 22); close:SetPoint("BOTTOMRIGHT", -18, 14); close:SetText("Close"); close:SetScript("OnClick", function() dialog:Hide() end)
    end
    dialog.edit:SetText(buildReport()); dialog:Show(); dialog.edit:SetFocus(); dialog.edit:HighlightText()
end

O.NewPage({ name = "Troubleshooting", title = "Troubleshooting", group = "REFERENCE", description = "Copy a safe diagnostic report for support." }, function(panel, y)
    local heading; heading, y = O.Header(panel, "Diagnostics", y)
    local note = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall"); note:SetPoint("TOPLEFT", 16, y); note:SetWidth(530); note:SetJustifyH("LEFT")
    note:SetText("The report captures client, saved-setting, marker-panel and minimap state. It intentionally excludes character names and assignments.")
    y = y - 48
    local copy = O.Button(panel, 140, 24, "primary"); copy:SetPoint("TOPLEFT", 16, y); copy:SetText("Copy report"); O.AttachHint(copy, "Copy report", "Open a selectable report you can paste into a bug report."); copy:SetScript("OnClick", ns.ShowDiagnosticReport)
    return y - 42
end)
