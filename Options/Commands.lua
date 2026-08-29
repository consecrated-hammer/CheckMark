local addonName, ns = ...
local O = ns.Options

local commands = {
    { section = "GENERAL" },
    { "/checkmark or /cm", "Open or close the compact grid" },
    { "/checkmark options", "Open CheckMark settings" },
    { "/checkmark reset", "Reset saved CheckMark settings" },
    { section = "GRID" },
    { "Left-click a configured cell", "Apply that role's configured marker" },
    { "Right-click a configured cell", "Remove the marker on that party member" },
}

O.NewPage({ name = "Commands", title = "Commands", group = "REFERENCE", description = "Every CheckMark command and direct grid action." }, function(panel, y)
    for _, row in ipairs(commands) do
        if row.section then
            local heading = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            heading:SetPoint("TOPLEFT", 16, y); heading:SetText(row.section); heading:SetTextColor(unpack(O.theme.accent)); y = y - 22
        else
            local card = CreateFrame("Frame", nil, panel, "BackdropTemplate")
            card:SetPoint("TOPLEFT", 16, y); card:SetSize(540, 30)
            card:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
            card:SetBackdropColor(unpack(O.theme.raised)); card:SetBackdropBorderColor(unpack(O.theme.edge))
            local command = card:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            command:SetPoint("LEFT", 12, 0); command:SetWidth(225); command:SetJustifyH("LEFT"); command:SetText("|cff4c9a7a" .. row[1] .. "|r")
            local does = card:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            does:SetPoint("LEFT", 245, 0); does:SetWidth(280); does:SetJustifyH("LEFT"); does:SetText(row[2])
            y = y - 32
        end
    end
    return y - 8
end)
