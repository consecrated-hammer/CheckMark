local addonName, ns = ...
local HC = ns.HammerCore
local O, T = HC.UI, HC.Theme

-- Who gets which marker: who goes first, the role markers and fill order
-- (all per profile), regulars and learning (shared by every profile).

local ICONS = {
    rules = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",
    roles = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3",
    fill = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1",
    regulars = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6",
    learning = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5",
}

local function markerName(marker) return ns.MARKER_NAMES[marker] or "None" end

local function changed()
    if ns.refreshPopup then ns.refreshPopup() end
    if ns.MarkWindow and ns.MarkWindow:IsShown() then ns.MarkWindow:Refresh() end
    if ns.Preview then ns.Preview:Refresh() end
end

-- Refreshes the visible list after regulars change, keeping its selected tab.
local function rebuild()
    changed()
    if HC.Settings:IsShown() and HC.Settings.selected == "Markers" then HC.Settings:Select("Markers") end
end

-- A marker select with icon: get() -> marker, set(marker), note(marker) ->
-- who else has it. none adds a "None" choice.
local function markerSelect(row, width, get, set, note, none)
    local button = O.SelectButton(row, width, 28)
    button:SetPoint("RIGHT", row, "RIGHT", -O.CELL_INSET, 0)
    button.Text:ClearAllPoints()
    button.Text:SetPoint("LEFT", 34, 0)
    button.Text:SetPoint("RIGHT", -26, 0)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetPoint("LEFT", 8, 0)
    local markers = {}
    if none then markers[1] = 0 end
    for marker = 1, 8 do markers[#markers + 1] = marker end

    local function render()
        local marker = get() or 0
        button:SetText(markerName(marker))
        if marker > 0 then icon:SetTexture(ns.MARKER_TEXTURES[marker]); icon:Show() else icon:Hide() end
    end
    local menu
    local function ensureMenu()
        if menu then return end
        menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        menu:SetSize(188, #markers * 28 + 10)
        menu:SetFrameStrata("FULLSCREEN_DIALOG")
        menu:SetFrameLevel(200)
        menu:SetClampedToScreen(true)
        T.Surface(menu, "menu", "menuEdge")
        menu.items = {}
        for index, marker in ipairs(markers) do
            local item = CreateFrame("Button", nil, menu, "BackdropTemplate")
            item:SetSize(178, 26)
            item:SetPoint("TOPLEFT", 5, -5 - (index - 1) * 28)
            T.Surface(item, "rail")
            local itemIcon = item:CreateTexture(nil, "ARTWORK")
            itemIcon:SetSize(18, 18); itemIcon:SetPoint("LEFT", 8, 0)
            if marker > 0 then itemIcon:SetTexture(ns.MARKER_TEXTURES[marker]) else itemIcon:Hide() end
            local text = item:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            text:SetPoint("LEFT", 34, 0); text:SetPoint("RIGHT", -70, 0); text:SetText(markerName(marker))
            text:SetJustifyH("LEFT")
            item.note = item:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
            item.note:SetPoint("RIGHT", -7, 0); item.note:SetWidth(62); item.note:SetJustifyH("RIGHT")
            local function paint(hovered)
                item:SetBackdropColor(T.Unpack(((get() or 0) == marker or hovered) and "menuActive" or "rail"))
            end
            item.paint = paint
            item:SetScript("OnClick", function() menu:Hide(); set(marker); render() end)
            item:HookScript("OnEnter", function() paint(true) end)
            item:HookScript("OnLeave", function() paint(false) end)
            item.marker = marker
            menu.items[index] = item
        end
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
        for _, item in ipairs(menu.items) do
            item.note:SetText(note and note(item.marker) or "")
            item.paint(false)
        end
        menu:ClearAllPoints(); menu:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -5); menu:Show()
    end)
    row:HookScript("OnHide", function() if menu then menu:Hide() end end)
    render()
    return button, render, function() if menu then menu:Hide() end end
end

-- Fill order: eight icons. Click moves one earlier, right-click later.
local function fillStrip(panel, y)
    local db = ns.db
    local row = O.Row(panel, y, 40, "Fill order",
        "Everyone the rules above don't cover gets the first free marker, left to right. Click an icon to move it earlier, right-click to move it later.")
    local icons = {}
    local function render()
        db.fill_order = ns.Assign.FillOrder(db.fill_order)
        for index, marker in ipairs(db.fill_order) do
            icons[index].marker = marker
            icons[index].tex:SetTexture(ns.MARKER_TEXTURES[marker])
        end
    end
    local function move(index, by)
        local order = ns.Assign.FillOrder(db.fill_order)
        local target = index + by
        if target < 1 or target > #order then return end
        order[index], order[target] = order[target], order[index]
        db.fill_order = order
        render()
        changed()
    end
    for index = 1, 8 do
        local button = CreateFrame("Button", nil, row)
        button:SetSize(24, 24)
        button:SetPoint("RIGHT", row, "RIGHT", -O.CELL_INSET - (8 - index) * 28, 0)
        button.tex = button:CreateTexture(nil, "ARTWORK")
        button.tex:SetAllPoints()
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        button:SetScript("OnClick", function(_, mouse) move(index, mouse == "RightButton" and 1 or -1) end)
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(index .. ". " .. markerName(self.marker))
            GameTooltip:AddLine("Click: earlier. Right-click: later.", 0.85, 0.85, 0.85)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
        icons[index] = button
    end
    O.OnRefresh(panel, render)
    render()
    return row, row.hcNextY
end

local function regularRow(panel, y, item)
    local title = item.label
    if item.account and item.seen then title = title .. " (last seen as " .. item.seen .. ")" end
    local row = O.Row(panel, y, 34, title, item.account and "A Battle.net friend: matches all their characters."
        or "One character.")
    local remove = O.Button(row, 26, 24)
    remove:SetPoint("RIGHT", row, "RIGHT", -O.CELL_INSET, 0)
    remove:SetText("x")
    O.AttachHint(remove, "Remove", function() return "Forget " .. item.label .. "." end)
    remove:SetScript("OnClick", function() ns.Assign.Forget(item.key); rebuild() end)
    local select, render, closeSelect = markerSelect(row, 130, function() return item.marker end, function(marker)
        ns.Assign.SetMarker(item.key, marker)
        item.marker = marker
        changed()
    end)
    select:ClearAllPoints()
    select:SetPoint("RIGHT", remove, "LEFT", -8, 0)
    local kind = O.FontString(row, "GameFontHighlightSmall", item.pinned and "accent" or "muted")
    kind:SetPoint("RIGHT", select, "LEFT", -10, 0)
    kind:SetText(item.pinned and "Pinned" or "Learned")
    if row.Title then row.Title:SetPoint("RIGHT", kind, "LEFT", -10, 0) end
    row.remove = remove
    row.SetItem = function(self, value)
        local owner = panel.hcHeaderOwner or panel
        if self.searchLabel and owner.hcRows and owner.hcRows[self.searchLabel] == self then
            owner.hcRows[self.searchLabel] = nil
        end
        self.searchLabel = nil
        if not value or value.key ~= item.key then closeSelect() end
        self:SetShown(value ~= nil)
        if not value then return end
        item = value
        local label = item.label
        if item.account and item.seen then label = label .. " (last seen as " .. item.seen .. ")" end
        self.Title:SetText(label)
        self.hcHintTitle = label
        self.hcHint = item.account and "A Battle.net friend: matches all their characters." or "One character."
        O.RegisterRow(panel, self, label)
        self.searchLabel = label
        kind:SetText(item.pinned and "Pinned" or "Learned")
        render()
    end
    return row, row.hcNextY
end

-- The first marker no pinned regular has.
local function freeMarker()
    local taken = {}
    for _, item in ipairs(ns.Assign.List()) do if item.pinned then taken[item.marker] = true end end
    for _, marker in ipairs(ns.Assign.FillOrder(ns.db.fill_order)) do
        if not taken[marker] then return marker end
    end
    return 1
end

local function assignments(panel, y)
    local db = ns.db

    _, y = O.ActionButton(panel, y, "Mark the party", function()
        if ns.isEligibleGroup() then ns.MarkWindow:Open() else ns.MarkWindow:Test() end
    end, "Open the marking window. Click each member to mark them; solo opens a sample party. Unavailable in combat.", "primary")
    _, y = O.Header(panel, "Who goes first", y, ICONS.rules)
    local values, labels = {}, {}
    for index, rule in ipairs(ns.Assign.RULES) do values[index], labels[index] = rule.value, rule.label end
    _, y = O.Dropdown(panel, "Who goes first", "Decides who gets their marker first when two choices clash.",
        y, values, labels, function() return db.marker_rules end,
        function(value) db.marker_rules = value; changed() end, nil, nil, 200)
    local where
    where, y = O.Text(panel, "", y)
    O.OnRefresh(panel, function()
        where:SetText("Saved in the " .. tostring(HC.Profiles:Active() or "active") .. " profile, with the role markers and fill order.")
    end)

    _, y = O.Header(panel, "Role markers (per profile)", y, ICONS.roles)
    for _, slot in ipairs(ns.ROLE_SLOTS) do
        local row = O.Row(panel, y, 34, ns.ROLE_SLOT_LABELS[slot], "The marker for the party's " .. ns.ROLE_SLOT_LABELS[slot]:lower() .. ".")
        local _, render = markerSelect(row, 140, function() return db.role_template[slot] or 0 end, function(marker)
            db.role_template[slot] = marker
            changed()
        end, function(marker)
            for _, other in ipairs(ns.ROLE_SLOTS) do
                if other ~= slot and marker > 0 and db.role_template[other] == marker then return ns.ROLE_SLOT_LABELS[other] end
            end
        end, true)
        O.OnRefresh(panel, render)
        y = row.hcNextY
    end

    _, y = O.Text(panel, "Each marker is used once. If two people want the same one, the earlier rule wins and the other takes the next free marker.", y)
    _, y = O.Header(panel, "Fill order", y, ICONS.fill)
    _, y = fillStrip(panel, y)

    _, y = O.PageReset(panel, y, function()
        db.role_template = { TANK = ns.Assign.ROLE_DEFAULT.TANK, HEALER = ns.Assign.ROLE_DEFAULT.HEALER }
        db.fill_order = ns.Assign.FillOrder(nil)
        db.marker_rules = ns.DEFAULT_DB.marker_rules
        changed()
    end, "Reset assignments")
    return y
end

local function regulars(panel, y)
    local db = ns.db
    _, y = O.Header(panel, "People (shared)", y, ICONS.regulars)
    _, y = O.Text(panel, "Pinned people always get the marker you chose. Learned people are ones CheckMark remembers from your clicks.", y)
    local list = CreateFrame("Frame", nil, panel)
    list:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, y)
    list:SetSize(O.CONTENT_WIDTH + O.PAD * 2, 1)
    list.hcColumns = 1
    list.hcHeaderOwner = panel.hcHeaderOwner or panel
    local rows, bottoms, listY = {}, {}, 0
    panel.regularRows = rows
    local note = O.FontString(list, "GameFontHighlightSmall", "muted")
    note:SetWidth(O.CONTENT_WIDTH)
    note:SetJustifyH("LEFT")
    local controls = CreateFrame("Frame", nil, panel)
    controls:SetSize(O.CONTENT_WIDTH + O.PAD * 2, 1)
    controls.hcColumns = 1
    controls.hcRefresh = panel.hcRefresh
    controls.hcRefreshAll = panel.hcRefreshAll
    controls.hcHeaderOwner = panel.hcHeaderOwner or panel
    local listTop = y
    y = -4
    _, y = O.DynamicDropdown(controls, "Add a Battle.net friend", "Pin a friend's account: they keep the marker on every character.", y,
        function()
            ns.Identity:RefreshFriends()
            local vals, labs = { "" }, { "Choose a friend" }
            local list = ns.Assign.List()
            local known = {}
            for _, item in ipairs(list) do if item.pinned and item.account then known[item.label] = true end end
            for _, friend in ipairs(ns.Identity.friends) do
                if not known[friend.tag] then
                    vals[#vals + 1] = friend.tag
                    labs[#labs + 1] = friend.character and (friend.tag .. " (" .. friend.character .. ")") or friend.tag
                end
            end
            return vals, labs
        end,
        function() return "" end,
        function(tag)
            if tag == "" then return end
            local character
            for _, friend in ipairs(ns.Identity.friends) do if friend.tag == tag then character = friend.character end end
            ns.Assign.PinTag(tag, freeMarker(), character)
            rebuild()
        end)
    _, y = O.DynamicDropdown(controls, "Add a party member", "Pin someone in your party to the marker they have now.", y,
        function()
            local vals, labs = { "" }, { "Choose a member" }
            for _, slot in ipairs(ns.Assign.Plan(ns.Identity.Label(ns.getGroupMembers()))) do
                if slot.marker > 0 and not ns.Assign.IsPinned(slot.member) then
                    vals[#vals + 1] = slot.member.key
                    labs[#labs + 1] = slot.member.label .. " (" .. markerName(slot.marker) .. ")"
                end
            end
            return vals, labs
        end,
        function() return "" end,
        function(key)
            if key == "" then return end
            for _, slot in ipairs(ns.Assign.Plan(ns.getGroupMembers())) do
                if slot.member.key == key then ns.Assign.Pin(slot.member, slot.marker) end
            end
            rebuild()
        end)
    _, y = O.ActionButton(controls, y, "Forget learned", function()
        ns.Assign.ForgetLearned()
        rebuild()
    end, "Remove all unpinned learned people from every profile. Pinned people and this party's current picks stay. Learning remains enabled and may learn them again.")

    _, y = O.Header(controls, "Learning and party sharing (shared)", y, ICONS.learning)
    for _, spec in ipairs({
        { "Learn from my choices", "Remember your CheckMark choices. Learned markers come after pinned people and roles, and only apply when pinned people are included.", "learn_mine" },
        { "Share with the party", "Tell party members running CheckMark who you marked with what.", "share_party" },
        { "Learn from the party", "Learn from what party members running CheckMark mark.", "learn_party" },
    }) do
        _, y = O.Check(controls, spec[1], spec[2], y,
            function() return db[spec[3]] ~= false end,
            function(value) db[spec[3]] = value end)
    end

    local controlsBottom, pageBottom = y
    controls:SetHeight(-controlsBottom + 4)
    local function refreshRegulars()
        local items = ns.Assign.List()
        local count = #items
        -- Remove the old index before reusing rows, including reordered names.
        for _, row in ipairs(rows) do
            local owner = list.hcHeaderOwner
            if row.searchLabel and owner.hcRows[row.searchLabel] == row then owner.hcRows[row.searchLabel] = nil end
            row.searchLabel = nil
        end
        while #rows < count do
            local index = #rows + 1
            rows[index], listY = regularRow(list, listY, { label = "", marker = 1 })
            bottoms[index] = listY
        end
        local labels = {}
        for _, item in ipairs(items) do labels[item.label] = (labels[item.label] or 0) + 1 end
        for _, item in ipairs(items) do
            if labels[item.label] > 1 then item.label = item.label .. " (" .. item.key .. ")" end
        end
        for index, row in ipairs(rows) do row:SetItem(index <= count and items[index] or nil) end
        local bottom = count > 0 and bottoms[count] or 0
        local message = #items == 0 and "Nobody yet. Pin someone from the marking window, or add a friend below."
            or nil
        note:SetShown(message ~= nil)
        if message then
            note:SetText(message)
            note:ClearAllPoints()
            note:SetPoint("TOPLEFT", O.PAD, bottom - 4)
            bottom = bottom - note:GetStringHeight() - 12
        end
        list:SetHeight(math.max(1, -bottom))
        controls:ClearAllPoints()
        controls:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, listTop + bottom - 8)
        pageBottom = listTop + bottom - 8 + controlsBottom
        if panel.hcSetBottom then panel.hcSetBottom(pageBottom) end
    end
    ns.RefreshRegularsSearch = refreshRegulars
    O.OnRefresh(panel, refreshRegulars)
    refreshRegulars()
    return pageBottom
end

HC.Settings:NewPage({
    name = "Markers",
    title = "Markers",
    group = "main",
    description = "Who gets which marker.",
    headerAction = ns.LivePreviewAction,
    profileScope = function(tab) return tab == "Assignments" end,
    tabs = {
        { name = "Assignments", build = assignments },
        { name = "People", build = regulars, columns = 1 },
    },
})
