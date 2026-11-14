local _,ns=...
local HC=ns.HammerCore
local UI=HC.UI
ns.SyncOptions={}
function ns.SyncOptions.Build(panel,y)
    _,y=UI.Header(panel,"Party sync",y)
    local card;card,y=UI.Card(panel,y,118)
    UI.RegisterRow(panel,card,"Party sync status","Communication, sharing and learning status")
    local status=UI.FontString(card,"GameFontHighlightSmall","text")
    status:SetPoint("TOPLEFT",12,-10);status:SetPoint("BOTTOMRIGHT",-12,10)
    status:SetJustifyH("LEFT");status:SetJustifyV("TOP")
    UI.OnRefresh(panel,function()
        local share=ns.Share
        status:SetText("Sharing: "..(ns.db.share_party==false and "off" or "on")
            .." | Learning: "..(ns.db.learn_party==false and "off" or "on")
            .."\n"..(share.checkSummary or "No sync check this session.")
            .."\nA queued send does not prove receipt. Older versions may not reply.")
    end)
    _,y=UI.ActionButton(panel,y,"Check party sync",function()ns.Share:Check()end,
        "Send a check to the party and wait for compatible CheckMark copies to reply. Does not mark anyone or change assignments.")
    _,y=UI.Header(panel,"Recent sync events",y)
    _,y=UI.Text(panel,"Latest 50 events, saved locally across reloads.",y)
    _,y=UI.Text(panel,"Anonymous party slots only. No names, GUIDs or message payloads.",y)
    local logTop=y
    local logCard;logCard,y=UI.Card(panel,y,120)
    UI.RegisterRow(panel,logCard,"Recent sync events","Dated local sync history")
    local log=UI.FontString(logCard,"GameFontHighlightSmall","muted")
    log:SetPoint("TOPLEFT",12,-10);log:SetPoint("TOPRIGHT",-12,-10)
    log:SetJustifyH("LEFT");log:SetWordWrap(true)
    local copy,clear
    copy,y=UI.ActionButton(panel,y,"Copy sync report",function()HC.Copy:Show("CheckMark sync",ns.Share:Report())end,
        "Copy the sync status and recent local events for troubleshooting.")
    clear,y=UI.ActionButton(panel,y,"Clear sync log",function()ns.Share:ClearLog()end,
        "Clear recent local sync events. Marker preferences and assignments stay intact.")
    UI.OnRefresh(panel,function()
        log:SetText(ns.Share:LogText())
        local height=math.max(54,(log:GetStringHeight()or 14)+24)
        logCard:SetHeight(height)
        local nextY=logTop-height-14
        copy:ClearAllPoints();copy:SetPoint("TOPLEFT",UI.PAD,nextY-10)
        clear:ClearAllPoints();clear:SetPoint("TOPLEFT",UI.PAD,nextY-58)
        if panel.hcSetBottom then panel.hcSetBottom(nextY-96)end
    end)
    return y
end
