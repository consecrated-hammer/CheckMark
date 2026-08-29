local addon, ns = ...

local button

local function orbitRadius()
    local width = Minimap:GetWidth() or 0
    local height = Minimap:GetHeight() or 0
    local diameter = math.min(width, height)
    if diameter <= 0 then return 80 end
    -- Match Salve's LibDBIcon-style orbit: this keeps the visible button at a
    -- consistent distance from the minimap edge at every UI scale.
    return diameter / 2 + button:GetWidth() / 2 - 10
end

local function position()
    if not button or not ns.db then return end
    local angle = ns.db.minimap_angle or 225
    local radians = math.rad(angle)
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(radians) * orbitRadius(), math.sin(radians) * orbitRadius())
end

local function updateDragPosition()
    local x, y = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    x, y = x / scale, y / scale
    local mx, my = Minimap:GetCenter()
    if mx and my and ns.db then
        ns.db.minimap_angle = math.deg((math.atan2 or math.atan)(y - my, x - mx))
        position()
    end
end

function ns.createMinimapButton()
    if button then return button end
    button = CreateFrame("Button", "CheckMarkMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button:GetHighlightTexture():SetBlendMode("ADD")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetAllPoints()

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", 5, -5)
    icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -5, 5)
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT")

    button:SetScript("OnClick", function(self, mouseButton)
        if self.dragged then self.dragged = nil return end
        if mouseButton == "RightButton" then
            if ns.showOptions then ns.showOptions() end
        elseif ns.togglePopup then
            ns.togglePopup()
        end
    end)
    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function() updateDragPosition() end)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        updateDragPosition()
        self.dragged = true
    end)
    ns.attachHint(button, "CheckMark", "Left-click: show or hide the pre-pull marker panel. Right-click: open settings. Drag to move this button around the minimap.")
    position()
    button:SetShown(not (ns.db and ns.db.hide_minimap))
    Minimap:HookScript("OnSizeChanged", position)
    return button
end

function ns.refreshMinimapButton()
    if not button then return end
    button:SetShown(not (ns.db and ns.db.hide_minimap))
    position()
end
