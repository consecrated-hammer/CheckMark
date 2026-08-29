local addon, ns = ...

local T = ns.Theme
local frame, markerPicker, aboutFrame
local refreshers = {}

local function text(parent, value, size, colour)
    local label = ns.makeText(parent, size or 12, colour or T.text)
    label:SetText(value)
    return label
end

local function section(parent, label, y)
    local title = text(parent, label:upper(), 10, T.muted)
    title:SetPoint("TOPLEFT", 18, y)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(unpack(T.edge)); line:SetHeight(1)
    line:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6); line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -18, y - 18)
    return y - 32
end

local function checkbox(parent, label, hint, y, get, set)
    local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    row:SetSize(444, 28); row:SetPoint("TOPLEFT", 18, y); ns.applySurface(row, T.content, T.edge)
    local check = row:CreateTexture(nil, "ARTWORK"); check:SetSize(14, 14); check:SetPoint("LEFT", 8, 0); check:SetColorTexture(unpack(T.selected))
    local title = text(row, label, 11); title:SetPoint("LEFT", check, "RIGHT", 8, 0)
    row:SetScript("OnClick", function() set(not get()); check:SetShown(get()) end)
    ns.attachHint(row, label, hint)
    refreshers[#refreshers + 1] = function() check:SetShown(get()) end
    check:SetShown(get())
    return y - 34
end

local function visibilityChoice(parent, label, hint, y, mode)
    local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    row:SetSize(444, 28); row:SetPoint("TOPLEFT", 18, y)
    local dot = row:CreateTexture(nil, "ARTWORK"); dot:SetSize(12, 12); dot:SetPoint("LEFT", 9, 0)
    local title = text(row, label, 11); title:SetPoint("LEFT", dot, "RIGHT", 9, 0)
    local function render()
        local selected = ns.db.visibility_mode == mode
        ns.applySurface(row, selected and T.raised or T.content, selected and T.selected or T.edge)
        dot:SetColorTexture(unpack(selected and T.selected or T.muted))
    end
    row:SetScript("OnClick", function()
        ns.db.visibility_mode = mode
        if ns.applyVisibility then ns.applyVisibility() end
        if ns.refreshPopup then ns.refreshPopup() end
        ns.refreshOptions()
    end)
    ns.attachHint(row, label, hint)
    refreshers[#refreshers + 1] = render; render()
    return y - 34
end

local function buildMarkerPicker()
    markerPicker = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    markerPicker:SetSize(328, 50); ns.applySurface(markerPicker, T.rail, T.selected); markerPicker:SetFrameLevel(frame:GetFrameLevel() + 10); markerPicker:Hide()
    markerPicker.title = text(markerPicker, "CHOOSE MARKER", 10, T.muted); markerPicker.title:SetPoint("TOPLEFT", 9, -5)
    for marker = 0, 8 do
        local button = CreateFrame("Button", nil, markerPicker, "BackdropTemplate")
        button:SetSize(30, 24); button:SetPoint("BOTTOMLEFT", 9 + marker * 35, 6); ns.applySurface(button, T.raised, T.edge)
        local icon = button:CreateTexture(nil, "ARTWORK"); icon:SetPoint("CENTER"); icon:SetSize(18, 18)
        if marker == 0 then icon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up"); icon:SetVertexColor(unpack(T.muted)) else icon:SetTexture(ns.MARKER_TEXTURES[marker]) end
        local chosen = marker
        button:SetScript("OnClick", function()
            if markerPicker.set then markerPicker.set(chosen) end
            markerPicker:Hide()
        end)
    end
end

local function roleRow(parent, slot, y)
    local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    row:SetSize(444, 36); row:SetPoint("TOPLEFT", 18, y); ns.applySurface(row, T.content, T.edge)
    local label = text(row, ns.ROLE_SLOT_LABELS[slot], 12); label:SetPoint("LEFT", 10, 0)
    local button = CreateFrame("Button", nil, row, "BackdropTemplate")
    button:SetSize(110, 26); button:SetPoint("RIGHT", -5, 0); ns.applySurface(button, T.raised, T.edge)
    local icon = button:CreateTexture(nil, "ARTWORK"); icon:SetSize(18, 18); icon:SetPoint("LEFT", 8, 0)
    local value = text(button, "", 11, T.text); value:SetPoint("LEFT", icon, "RIGHT", 7, 0)
    local function render()
        local marker = ns.db and ns.db.role_template[slot] or 0
        if marker > 0 then icon:SetTexture(ns.MARKER_TEXTURES[marker]); icon:SetVertexColor(1, 1, 1, 1); value:SetText(ns.MARKER_NAMES[marker])
        else icon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up"); icon:SetVertexColor(unpack(T.muted)); value:SetText("None") end
    end
    button:SetScript("OnClick", function()
        if not markerPicker then buildMarkerPicker() end
        markerPicker.set = function(marker)
            if marker > 0 then
                for _, other in ipairs(ns.ROLE_SLOTS) do if other ~= slot and ns.db.role_template[other] == marker then ns.db.role_template[other] = 0 end end
            end
            ns.db.role_template[slot] = marker
            ns.refreshOptions()
            if ns.refreshPopup then ns.refreshPopup() end
        end
        markerPicker.title:SetText("CHOOSE " .. ns.ROLE_SLOT_LABELS[slot]:upper() .. " MARKER")
        markerPicker:ClearAllPoints(); markerPicker:SetPoint("TOPRIGHT", row, "BOTTOMRIGHT", 0, -2); markerPicker:Show(); markerPicker:Raise()
    end)
    refreshers[#refreshers + 1] = render; render()
    return y - 40
end

local function displayPreset(parent, label, hint, x, y, spec)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(216, 28); button:SetPoint("TOPLEFT", x, y); ns.styleButton(button)
    local title = text(button, label, 11, T.text); title:SetPoint("LEFT", 9, 0)
    button:SetScript("OnClick", function()
        ns.db.cell_width, ns.db.cell_height = spec.width, spec.height
        ns.db.cell_columns, ns.db.cell_spacing = spec.columns, spec.spacing
        ns.db.show_cell_names = spec.names
        if ns.refreshPopup then ns.refreshPopup() end
    end)
    ns.attachHint(button, label, hint)
end

local function buildOptions()
    frame = CreateFrame("Frame", "CheckMarkOptions", UIParent, "BackdropTemplate")
    frame:SetSize(480, 620); frame:SetPoint("CENTER", UIParent, "CENTER", 190, 50); frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetMovable(true); frame:SetClampedToScreen(true); frame:EnableMouse(true); ns.applySurface(frame, T.outer, T.edge); frame:Hide()
    local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    header:SetPoint("TOPLEFT", 1, -1); header:SetPoint("TOPRIGHT", -1, -1); header:SetHeight(36); header:EnableMouse(true); ns.applySurface(header, T.rail, T.edge)
    header:SetScript("OnMouseDown", function(_, mouse) if mouse == "LeftButton" then frame:StartMoving() end end)
    header:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() end)
    local title = text(header, "CheckMark settings", 14); title:SetPoint("LEFT", 14, 0)
    local close = CreateFrame("Button", nil, header); close:SetSize(24, 24); close:SetPoint("RIGHT", -6, 0)
    local x = text(close, "×", 16, T.muted); x:SetAllPoints(); x:SetJustifyH("CENTER"); close:SetScript("OnClick", function() frame:Hide() end)
    local y = -54
    y = section(frame, "Display", y)
    displayPreset(frame, "Compact", "Same compact grid geometry as Salve: 20px square cells, five across, one-pixel gaps and no names.", 18, y, { width = 20, height = 20, columns = 5, spacing = 1, names = false })
    displayPreset(frame, "Named", "Salve's named layout: 95px-wide cells, five across, with member names visible.", 246, y, { width = 95, height = 20, columns = 5, spacing = 1, names = true })
    y = y - 40
    y = section(frame, "Visibility", y)
    y = visibilityChoice(frame, "Always outside combat", "Show CheckMark whenever you are in a two-to-five player party. The secure grid hides as combat begins.", y, "ALWAYS")
    y = visibilityChoice(frame, "Hidden", "Keep the grid hidden. The minimap button and slash command still open Settings.", y, "HIDDEN")
    y = y - 8; y = section(frame, "Minimap", y)
    y = checkbox(frame, "Show minimap button", "Show the minimap launcher for opening CheckMark.", y, function() return not ns.db.hide_minimap end, function(v) ns.db.hide_minimap = not v; if ns.refreshMinimapButton then ns.refreshMinimapButton() end end)
    y = y - 8; y = section(frame, "Role template", y)
    for _, slot in ipairs(ns.ROLE_SLOTS) do y = roleRow(frame, slot, y) end
    local reset = CreateFrame("Button", nil, frame, "BackdropTemplate"); reset:SetSize(130, 24); reset:SetPoint("BOTTOMRIGHT", -18, 16); ns.styleButton(reset)
    local resetText = text(reset, "Reset saved data", 10, T.muted); resetText:SetAllPoints(); resetText:SetJustifyH("CENTER")
    reset:SetScript("OnClick", function()
        StaticPopupDialogs["CHECKMARK_RESET"] = { text = "Reset all CheckMark settings and saved templates?", button1 = "Reset", button2 = "Cancel", OnAccept = function() ns.resetDB(); ns.refreshOptions() end, timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3 }
        StaticPopup_Show("CHECKMARK_RESET")
    end)
    local about = CreateFrame("Button", nil, frame, "BackdropTemplate"); about:SetSize(62, 24); about:SetPoint("BOTTOMLEFT", 18, 16); ns.styleButton(about)
    local aboutText = text(about, "About", 10, T.muted); aboutText:SetAllPoints(); aboutText:SetJustifyH("CENTER")
    about:SetScript("OnClick", function() if ns.showAbout then ns.showAbout() end end)
end

local function buildAbout()
    aboutFrame = CreateFrame("Frame", "CheckMarkAbout", UIParent, "BackdropTemplate")
    aboutFrame:SetSize(480, 330); aboutFrame:SetPoint("CENTER", UIParent, "CENTER", 190, 50); aboutFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    aboutFrame:SetMovable(true); aboutFrame:SetClampedToScreen(true); aboutFrame:EnableMouse(true); ns.applySurface(aboutFrame, T.outer, T.edge); aboutFrame:Hide()
    local header = CreateFrame("Frame", nil, aboutFrame, "BackdropTemplate")
    header:SetPoint("TOPLEFT", 1, -1); header:SetPoint("TOPRIGHT", -1, -1); header:SetHeight(36); header:EnableMouse(true); ns.applySurface(header, T.rail, T.edge)
    header:SetScript("OnMouseDown", function(_, mouse) if mouse == "LeftButton" then aboutFrame:StartMoving() end end)
    header:SetScript("OnMouseUp", function() aboutFrame:StopMovingOrSizing() end)
    local icon = header:CreateTexture(nil, "ARTWORK"); icon:SetSize(22, 22); icon:SetPoint("LEFT", 10, 0); icon:SetTexture(ns.MARKER_TEXTURES[8])
    local title = text(header, "CheckMark", 14); title:SetPoint("LEFT", icon, "RIGHT", 7, 0)
    local close = CreateFrame("Button", nil, header); close:SetSize(24, 24); close:SetPoint("RIGHT", -6, 0)
    local x = text(close, "×", 16, T.muted); x:SetAllPoints(); x:SetJustifyH("CENTER"); close:SetScript("OnClick", function() aboutFrame:Hide() end)
    local version = text(header, "v" .. ns.getVersion(), 10, T.muted); version:SetPoint("RIGHT", close, "LEFT", -6, 0)

    local function paragraph(label, value, y)
        local heading = text(aboutFrame, label:upper(), 10, T.muted); heading:SetPoint("TOPLEFT", 18, y)
        local body = text(aboutFrame, value, 12, T.text); body:SetPoint("TOPLEFT", 18, y - 18); body:SetPoint("TOPRIGHT", -18, y - 18); body:SetJustifyH("LEFT"); body:SetJustifyV("TOP"); body:SetWordWrap(true)
    end
    paragraph("Pre-pull marker preparation", "CheckMark gives a small party one clear role-marker plan. Configure Tank, Healer and DPS presets, then click the matching compact cell before the pull.", -58)
    paragraph("Planned, not observed", "Each compact cell shows your configured marker and gives you one click to apply it. CheckMark does not guess whether another player has added, removed or changed a marker.", -135)
    paragraph("Before combat", "Open it from the minimap button or the group prompt, finish the visible preparation list, then click the required compact cells before the pull.", -222)
end

function ns.refreshOptions()
    for _, refresh in ipairs(refreshers) do refresh() end
end

function ns.showOptions()
    if not frame then buildOptions() end
    if aboutFrame then aboutFrame:Hide() end
    ns.refreshOptions(); frame:Show(); frame:Raise()
end
function ns.hideOptions() if frame then frame:Hide() end end

function ns.showAbout()
    if not aboutFrame then buildAbout() end
    if frame then frame:Hide() end
    aboutFrame:Show(); aboutFrame:Raise()
end
function ns.hideAbout() if aboutFrame then aboutFrame:Hide() end end
