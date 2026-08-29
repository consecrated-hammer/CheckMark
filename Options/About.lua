local addonName, ns = ...
local O = ns.Options

local quips = {
    "All marked up. Try not to make it a personality.",
    "A skull for the tank. Classic for a reason.",
    "Markers applied. The pull is now at least emotionally prepared.",
    "One click per person. That is the whole CheckMark thesis.",
    "The raid icons have been asked politely to behave.",
    "No targets were inspected in the making of this assignment.",
    "CheckMark: because 'you are the triangle' is an actionable plan.",
    "Eight icons, zero prophecy. Just a tidy little roster.",
    "The marker grid is compact. Your responsibilities remain enormous.",
    "Pre-pull admin complete. Now comes the part with the dragons.",
}
local nextQuipIndex = 0

O.NewPage({ name = "About", title = "About", group = "REFERENCE", description = "Version and the deliberately simple pre-pull workflow." }, function(panel, y)
    local heading
    heading, y = O.Header(panel, "CheckMark", y)
    local card = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    card:SetPoint("TOPLEFT", 16, y); card:SetSize(540, 112)
    card:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    card:SetBackdropColor(unpack(O.theme.raised)); card:SetBackdropBorderColor(unpack(O.theme.edge))
    local icon = card:CreateTexture(nil, "ARTWORK")
    icon:SetSize(82, 82); icon:SetPoint("LEFT", 14, 0); icon:SetTexture("Interface\\AddOns\\CheckMark\\Textures\\CheckMark")
    local body = card:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    body:SetPoint("TOPLEFT", icon, "TOPRIGHT", 16, -14); body:SetPoint("RIGHT", -14, 0); body:SetJustifyH("LEFT"); body:SetJustifyV("TOP")
    body:SetText("|cffffd100Version|r  " .. tostring(ns.getVersion and ns.getVersion() or "unknown")
        .. "\n|cffffd100Author|r  consecrated-hammer\n\nConfigure a role-marker plan, then use one click per party member before the pull.")
    y = y - 132
    heading, y = O.Header(panel, "CheckMarker's note", y)
    local quipCard = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    quipCard:SetPoint("TOPLEFT", 16, y); quipCard:SetSize(540, 120)
    quipCard:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    quipCard:SetBackdropColor(unpack(O.theme.raised)); quipCard:SetBackdropBorderColor(unpack(O.theme.edge))
    local quip = quipCard:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    quip:SetPoint("TOPLEFT", 12, -12); quip:SetWidth(510); quip:SetJustifyH("LEFT"); quip:SetJustifyV("TOP")
    local function showQuip()
        nextQuipIndex = nextQuipIndex % #quips + 1
        quip:SetText(quips[nextQuipIndex])
    end
    panel.salveRefresh[#panel.salveRefresh + 1] = showQuip
    local apply = CreateFrame("Button", nil, quipCard, "UIPanelButtonTemplate")
    apply:SetSize(174, 54)
    apply:SetPoint("BOTTOMLEFT", 12, 10)
    apply:SetText("Apply CheckMark")
    local applyIcon = apply:CreateTexture(nil, "ARTWORK")
    applyIcon:SetSize(32, 32); applyIcon:SetPoint("LEFT", 6, 0)
    applyIcon:SetTexture("Interface\\AddOns\\CheckMark\\Textures\\CheckMark")
    applyIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    if apply.Text then
        apply.Text:ClearAllPoints(); apply.Text:SetPoint("CENTER", 12, 0)
    end
    O.AttachHint(apply, "Apply CheckMark", "Applies a ceremonial, entirely non-binding CheckMark.")
    apply:SetScript("OnClick", function()
        showQuip()
        print("|cffffd200CheckMark:|r " .. quips[nextQuipIndex])
    end)
    y = y - 140
    heading, y = O.Header(panel, "How it works", y)
    local note = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", 16, y); note:SetWidth(530); note:SetJustifyH("LEFT"); note:SetJustifyV("TOP")
    note:SetText("CheckMark prepares direct secure actions for stable party unit tokens. Left-click applies the configured marker; right-click clears a marker. It does not inspect, compare or infer markers placed by anyone else.")
    return y - 72
end)
