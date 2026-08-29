local addonName, ns = ...
local O = ns.Options

local MARKERS = { 0, 1, 2, 3, 4, 5, 6, 7, 8 }
local MARKER_LABELS = { "None", "Star", "Circle", "Diamond", "Triangle", "Moon", "Square", "Cross", "Skull" }

local function refreshGrid()
    if ns.refreshPopup then ns.refreshPopup() end
end

local function markerDropdown(panel, slot, y, template, slots)
    local db = ns.db
    local row = O.Row(panel, y, 34, ns.ROLE_SLOT_LABELS[slot],
        "Choose this role's marker. Selecting an icon already used elsewhere removes it from that role.")
    local button = O.SelectButton(row, 188, 28)
    button:SetPoint("LEFT", row, "LEFT", 128, 0)
    button.Text:ClearAllPoints()
    button.Text:SetPoint("LEFT", 34, 0)
    button.Text:SetPoint("RIGHT", -26, 0)
    button.Text:SetJustifyH("LEFT")
    -- Match Salve's own select affordance: a pair of texture strokes makes
    -- this read as a dropdown rather than a wide action button.
    local arrowLeft = button:CreateTexture(nil, "OVERLAY")
    arrowLeft:SetSize(7, 1); arrowLeft:SetPoint("RIGHT", -13, 2)
    arrowLeft:SetColorTexture(unpack(O.theme.muted))
    if arrowLeft.SetRotation then arrowLeft:SetRotation(-0.75) end
    local arrowRight = button:CreateTexture(nil, "OVERLAY")
    arrowRight:SetSize(7, 1); arrowRight:SetPoint("RIGHT", -8, 2)
    arrowRight:SetColorTexture(unpack(O.theme.muted))
    if arrowRight.SetRotation then arrowRight:SetRotation(0.75) end
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetPoint("LEFT", 8, 0)

    local function select(marker)
        if marker > 0 then
            for _, other in ipairs(slots) do
                if other ~= slot and template[other] == marker then template[other] = 0 end
            end
        end
        template[slot] = marker
        refreshGrid()
        if panel.salveRefreshAll then panel.salveRefreshAll() end
    end
    local function render()
        local marker = template[slot] or 0
        button:SetText(MARKER_LABELS[marker + 1])
        if marker > 0 then
            icon:SetTexture(ns.MARKER_TEXTURES[marker]); icon:Show()
        else
            icon:Hide()
        end
    end

    local menu
    local menuItems = {}
    local function allocatedTo(marker)
        if marker == 0 then return nil end
        for _, other in ipairs(slots) do
            if template[other] == marker then
                return ns.ROLE_SLOT_LABELS[other]
            end
        end
    end
    local function ensureMenu()
        if menu then return end
        menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        menu:SetSize(188, #MARKERS * 28 + 10)
        menu:SetFrameStrata("FULLSCREEN_DIALOG")
        menu:SetFrameLevel(200)
        menu:SetClampedToScreen(true)
        menu:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        menu:SetBackdropColor(0.020, 0.027, 0.039, 1)
        menu:SetBackdropBorderColor(unpack(O.theme.menuEdge))
        for index, marker in ipairs(MARKERS) do
            local item = CreateFrame("Button", nil, menu, "BackdropTemplate")
            item:SetSize(178, 26)
            item:SetPoint("TOPLEFT", 5, -5 - (index - 1) * 28)
            item:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
            local itemIcon = item:CreateTexture(nil, "ARTWORK")
            itemIcon:SetSize(18, 18); itemIcon:SetPoint("LEFT", 8, 0)
            if marker > 0 then itemIcon:SetTexture(ns.MARKER_TEXTURES[marker]) else itemIcon:Hide() end
            local text = item:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            text:SetPoint("LEFT", 34, 0); text:SetPoint("RIGHT", -62, 0); text:SetText(MARKER_LABELS[index])
            text:SetJustifyH("LEFT")
            local allocation = item:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
            allocation:SetPoint("RIGHT", -7, 0)
            allocation:SetWidth(53)
            allocation:SetJustifyH("RIGHT")
            local function paint(active, hovered)
                item:SetBackdropColor(unpack((active or hovered) and O.theme.menuActive or O.theme.rail))
                text:SetTextColor(active and 1 or O.theme.muted[1], active and 1 or O.theme.muted[2], active and 1 or O.theme.muted[3])
            end
            item.marker = marker
            item.allocation = allocation
            item.paint = paint
            menuItems[#menuItems + 1] = item
            item:SetScript("OnClick", function() select(marker); menu:Hide() end)
            item:HookScript("OnEnter", function() paint((template[slot] or 0) == marker, true) end)
            item:HookScript("OnLeave", function() paint((template[slot] or 0) == marker, false) end)
            item:HookScript("OnShow", function() paint((template[slot] or 0) == marker, false) end)
        end
        function menu:RefreshAllocations()
            for _, item in ipairs(menuItems) do
                local role = allocatedTo(item.marker)
                item.allocation:SetText(role or "")
                if role == ns.ROLE_SLOT_LABELS[slot] then
                    item.allocation:SetTextColor(unpack(O.theme.selected))
                else
                    item.allocation:SetTextColor(unpack(O.theme.muted))
                end
                item.paint((template[slot] or 0) == item.marker, false)
            end
        end
        -- A marker choice is only committed by selecting an item.  Clicking
        -- back into the settings page dismisses this lightweight menu.
        menu:SetScript("OnUpdate", function(self)
            if not self:IsMouseOver() and not button:IsMouseOver()
                and IsMouseButtonDown and IsMouseButtonDown("LeftButton") then
                self:Hide()
            end
        end)
        menu:Hide()
    end
    button:SetScript("OnClick", function(self)
        ensureMenu()
        if menu:IsShown() then menu:Hide(); return end
        menu:RefreshAllocations()
        menu:ClearAllPoints(); menu:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -5); menu:Show()
    end)
    O.AttachHint(button, ns.ROLE_SLOT_LABELS[slot], "Choose a marker. Markers remain unique across the role template.")
    panel.salveRefresh[#panel.salveRefresh + 1] = render
    render()
    return row, y - 38
end

O.NewPage({
    name = "Markers",
    title = "Markers",
    group = "CORE",
    description = "Choose the role marker CheckMark prepares on each compact cell.",
}, function(panel, y)
    local db = ns.db
    local heading
    heading, y = O.Header(panel, "Role template", y)
    local tabs = {}
    local sections = {}
    local selectedTemplate = db.template_mode or "PARTY"
    local function showTemplate(mode)
        selectedTemplate = mode
        for key, section in pairs(sections) do section:SetShown(key == mode) end
        for key, tab in pairs(tabs) do
            local active = key == mode
            tab:SetBackdropColor(unpack(active and O.theme.menuActive or O.theme.raised))
            tab:SetBackdropBorderColor(unpack(active and O.theme.selected or O.theme.edge))
            tab.Text:SetTextColor(active and 1 or O.theme.muted[1], active and 1 or O.theme.muted[2], active and 1 or O.theme.muted[3])
        end
    end
    for index, spec in ipairs({}) do
        local tab = O.SelectButton(panel, 128, 28)
        tab:SetPoint("TOPLEFT", 16 + (index - 1) * 136, y - 4)
        tab:SetText(spec[2])
        tab:SetScript("OnClick", function() showTemplate(spec[1]) end)
        O.AttachHint(tab, spec[2], spec[1] == "PARTY" and "Configure the five-player Tank, Healer and DPS template." or "Configure up to three tanks and five healers, one marker each.")
        tabs[spec[1]] = tab
    end
    y = y - 8

    local function makeSection(mode)
        local section = CreateFrame("Frame", nil, panel)
        section:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, y)
        section:SetSize(560, 1)
        section.salveRefresh = panel.salveRefresh
        section.salveRefreshAll = panel.salveRefreshAll
        sections[mode] = section
        return section
    end
    local party = makeSection("PARTY")
    local partyY = -8
    heading, partyY = O.Header(party, "Party assignments", partyY)
    local note = party:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    note:SetPoint("TOPLEFT", 16, partyY + 4); note:SetWidth(530); note:SetJustifyH("LEFT")
    note:SetText("Markers stay unique. Assigning one to a role removes it from another role.")
    note:SetTextColor(unpack(O.theme.muted)); partyY = partyY - 28
    for _, slot in ipairs(ns.PARTY_ROLE_SLOTS) do _, partyY = markerDropdown(party, slot, partyY, db.role_template, ns.PARTY_ROLE_SLOTS) end
    partyY = partyY - 8
    local reset
    reset, partyY = O.PageReset(party, partyY, function()
        db.role_template = { TANK = 8, HEALER = 3, DPS1 = 0, DPS2 = 0, DPS3 = 0 }; refreshGrid()
    end, "Reset party markers")
    party:SetHeight(-partyY + 8)

    local raid = makeSection("RAID")
    local raidY = -8
    heading, raidY = O.Header(raid, "Raid assignments", raidY)
    local raidNote = raid:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    raidNote:SetPoint("TOPLEFT", 16, raidY + 4); raidNote:SetWidth(530); raidNote:SetJustifyH("LEFT")
    raidNote:SetText("Uses all eight target markers: up to three tanks, then up to five healers, in roster order.")
    raidNote:SetTextColor(unpack(O.theme.muted)); raidY = raidY - 28
    for _, slot in ipairs(ns.RAID_ROLE_SLOTS) do _, raidY = markerDropdown(raid, slot, raidY, db.raid_role_template, ns.RAID_ROLE_SLOTS) end
    raidY = raidY - 8
    reset, raidY = O.PageReset(raid, raidY, function()
        db.raid_role_template = { TANK1 = 8, TANK2 = 7, TANK3 = 6, HEALER1 = 5, HEALER2 = 4, HEALER3 = 3, HEALER4 = 2, HEALER5 = 1 }; refreshGrid()
    end, "Reset raid markers")
    raid:SetHeight(-raidY + 8)
    panel.salveRefresh[#panel.salveRefresh + 1] = function() showTemplate(selectedTemplate) end
    showTemplate(selectedTemplate)
    return y - math.max(-partyY, -raidY) - 8
end)
