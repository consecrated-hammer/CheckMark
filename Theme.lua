local addon, ns = ...

-- CheckMark deliberately shares Salve's quiet, functional visual language:
-- slate surfaces, one-pixel edges and a single prominent action.
ns.Theme = {
    outer = { 0.043, 0.051, 0.063, 0.98 },
    rail = { 0.071, 0.082, 0.102, 1 },
    content = { 0.086, 0.098, 0.118, 1 },
    raised = { 0.110, 0.125, 0.153, 1 },
    edge = { 0.169, 0.192, 0.227, 1 },
    selected = { 0.247, 0.604, 0.925, 1 },
    accent = { 0.298, 0.604, 0.478, 1 },
    muted = { 0.553, 0.584, 0.639, 1 },
    danger = { 0.788, 0.337, 0.306, 1 },
    text = { 0.94, 0.96, 0.98, 1 },
}

local T = ns.Theme

function ns.applySurface(frame, background, edge)
    if not frame.SetBackdrop then return end
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(unpack(background or T.content))
    frame:SetBackdropBorderColor(unpack(edge or T.edge))
end

function ns.makeText(parent, size, colour, template)
    local text = parent:CreateFontString(nil, "ARTWORK", template or "GameFontHighlight")
    text:SetFont(text:GetFont(), size or 12, "")
    text:SetTextColor(unpack(colour or T.text))
    return text
end

function ns.styleButton(button, variant)
    ns.applySurface(button, variant == "primary" and T.accent or T.raised,
        variant == "primary" and T.accent or T.edge)
    button:SetHighlightTexture("Interface\\Buttons\\WHITE8X8", "ADD")
    local highlight = button:GetHighlightTexture()
    if highlight then
        highlight:SetAllPoints()
        highlight:SetVertexColor(1, 1, 1, variant == "primary" and 0.14 or 0.08)
    end
end

function ns.attachHint(control, title, body)
    if not body then return end
    control:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title or "CheckMark", unpack(T.accent))
        GameTooltip:AddLine(body, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    control:HookScript("OnLeave", function(self)
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)
end
