local addonName, ns = ...
local HC = ns.HammerCore
local O, T = HC.UI, HC.Theme

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
    -- HammerCore's select draws the chevron; make room for the marker icon.
    button.Text:ClearAllPoints()
    button.Text:SetPoint("LEFT", 34, 0)
    button.Text:SetPoint("RIGHT", -26, 0)
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
        if panel.hcRefreshAll then panel.hcRefreshAll() end
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
        T.Surface(menu, "menu", "menuEdge")
        for index, marker in ipairs(MARKERS) do
            local item = CreateFrame("Button", nil, menu, "BackdropTemplate")
            item:SetSize(178, 26)
            item:SetPoint("TOPLEFT", 5, -5 - (index - 1) * 28)
            T.Surface(item, "rail")
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
                item:SetBackdropColor(T.Unpack((active or hovered) and "menuActive" or "rail"))
                T.Text(text, active and "text" or "muted")
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
                    item.allocation:SetTextColor(T.Unpack("selected"))
                else
                    item.allocation:SetTextColor(T.Unpack("muted"))
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
    panel.hcRefresh[#panel.hcRefresh + 1] = render
    render()
    return row, y - 38
end

HC.Settings:NewPage({
    name = "Markers",
    title = "Markers",
    group = "main",
    description = "Choose the marker each role's cell prepares.",
}, function(panel, y)
    local db = ns.db
    _, y = O.Header(panel, "Party assignments", y)
    _, y = O.Text(panel, "Markers stay unique: assigning one to a role removes it from another.", y)
    for _, slot in ipairs(ns.ROLE_SLOTS) do
        _, y = markerDropdown(panel, slot, y, db.role_template, ns.ROLE_SLOTS)
    end
    _, y = O.PageReset(panel, y - 8, function()
        db.role_template = { TANK = 8, HEALER = 3, DPS1 = 0, DPS2 = 0, DPS3 = 0 }
        refreshGrid()
    end, "Reset markers")
    return y
end)
