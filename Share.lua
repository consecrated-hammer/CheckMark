local addon, ns = ...

-- Marker traffic remains protocol 1/M. Q/A adds an optional diagnostic
-- request/reply; older CheckMark versions ignore those kinds safely.
local Share = { PREFIX = "CheckMark", VERSION = "1", RECENT = 120, LOG_LIMIT = 50, CHECK_SECONDS = 5 }
ns.Share = Share
local function readable(value) return ns.Identity.Readable(value) end
local function now() return GetTime and GetTime() or 0 end
local function channel()
    if IsInRaid and IsInRaid() then return nil end
    if IsInGroup and LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
    if IsInGroup and IsInGroup() then return "PARTY" end
end
local function memberByGuid(guid)
    for _, member in ipairs(ns.getGroupMembers()) do if member.guid == guid then return member end end
end
local function slot(member)
    return member and member.unit and member.unit:match("^party[1-4]$") and ("Party " .. member.unit:sub(6)) or "Party member"
end
local function normalized(value)
    return readable(value) and type(value)=="string" and value:gsub("%s", ""):lower() or nil
end
local function senderMatches(member, sender)
    local name = normalized(sender)
    if not name then return false end
    if name == normalized(member.fullName) then return true end
    local own = normalized(GetRealmName and GetRealmName())
    if normalized(member.realm)==own and name==normalized(member.full) then return true end
    -- Some Forever addon-message sender strings omit surnames. Only accept
    -- the first-name form when it identifies exactly one current member.
    if not ns.Identity.IsForever()then return false end
    local count=0
    for _,other in ipairs(ns.getGroupMembers())do
        if normalized(other.first)==normalized(member.first)then count=count+1 end
    end
    if count~=1 then return false end
    return name==normalized((member.first or "").."-"..(member.realm or ""))
        or normalized(member.realm)==own and name==normalized(member.first)
end
local function safeVersion(value)
    return readable(value) and type(value)=="string" and #value<=48 and value:match("^[%w%._+%-]+$")
        and (value=="unknown" or value:match("^v?%d")) and value or nil
end
local function version()
    local api=C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    return safeVersion(api and api(addon,"Version")) or "unknown"
end
local function roster()
    local keys={}
    for _,member in ipairs(ns.getGroupMembers())do
        if readable(member.guid) then keys[#keys+1]=member.guid end
    end
    table.sort(keys)
    return table.concat(keys,";")
end
function Share:RefreshUI()
    if self.refreshQueued then return end
    local function refresh()
        self.refreshQueued=nil
        local settings=ns.HammerCore and ns.HammerCore.Settings
        local panel=settings and settings.pages and settings.pages.Troubleshooting
        if panel and panel.IsShown and panel:IsShown() and panel.hcRefreshAll then panel.hcRefreshAll()end
    end
    if C_Timer and C_Timer.After then self.refreshQueued=true;C_Timer.After(0,refresh)else refresh()end
end
function Share:Log(event,detail)
    if not ns.db then return end
    if type(ns.db.sync_log)~="table" then ns.db.sync_log={}end
    local log=ns.db.sync_log
    local stamp=time and time()or 0
    local last=log[#log]
    if type(last)=="table" and last.event==event and last.detail==detail and type(last.at)=="number"
        and stamp>=last.at and stamp-last.at<=2 then
        last.count=(tonumber(last.count)or 1)+1;last.at=stamp
    else log[#log+1]={at=stamp,event=event,detail=detail}end
    while #log>self.LOG_LIMIT do table.remove(log,1)end
    self:RefreshUI()
end
function Share:Ignored(reason)
    self.ignoredAt=self.ignoredAt or {}
    if self.ignoredAt[reason] and now()-self.ignoredAt[reason]<5 then return end
    self.ignoredAt[reason]=now();self:Log("Ignored",reason)
end
function Share:ClearLog()
    if not ns.db then return end
    ns.db.sync_log={};self:RefreshUI()
end
function Share:Register()
    if self.registered then return true end
    local register=C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix or RegisterAddonMessagePrefix
    if not register then self.registered=false;self:Log("Registration failed","Prefix API unavailable");return false end
    local ok,result=pcall(register,self.PREFIX)
    self.registered=ok and result~=false
    self:Log(self.registered and "Ready" or "Registration failed","Addon-message prefix")
    return self.registered
end
function Share:SendPacket(text,kind)
    if ns.db.share_party==false then self:Log("Not sent","Party sharing is off");return false end
    local where=channel()
    local send=C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
    if not where then self:Log("Not sent","No supported party channel");return false end
    if not send then self:Log("Send failed","Addon-message API unavailable");return false end
    if not self:Register()then return false end
    local ok,result=pcall(send,self.PREFIX,text,where)
    local accepted=ok and (result==nil or result==true or readable(result) and type(result)=="number" and result==0)
    self.lastSendOk=accepted
    local reason
    if not ok then reason="Client API error"
    elseif not accepted then
        if not readable(result)then reason="Client result unavailable"end
        reason=reason or "Client rejected the message"
        for name,value in pairs(Enum and Enum.SendAddonMessageResult or {})do
            if value==result then reason=name;break end
        end
    end
    self:Log(accepted and "Queued" or "Send failed",kind.." on "..where..(reason and ": "..reason or ""))
    return accepted
end
function Share:Send(member,marker,source)
    if not(member and readable(member.guid))then return false end
    local me=UnitGUID and UnitGUID("player")
    if not readable(me)then self:Log("Not sent","Player identity unavailable");return false end
    local text=table.concat({self.VERSION,"M",me,member.guid,tostring(marker),tostring(source or "")},":")
    return self:SendPacket(text,"Marker choice")
end
function Share:FinishCheck(check,cancelled)
    if self.pending~=check then return end
    self.pending=nil
    if cancelled then self.checkSummary="Check cancelled: party changed. "..check.count.." of "..check.total.." replied before the change."
    else
        local missing={}
        for _,peer in pairs(check.peers)do if not peer.replied then missing[#missing+1]=peer.label end end
        table.sort(missing)
        for _,label in ipairs(missing)do self:Log("No reply",label..": older version, sharing off, or no delivery")end
        self.checkSummary=check.count.." of "..check.total.." party members replied."
        ..(check.count<check.total and " No reply can mean an older CheckMark, sharing off, or a delivery problem." or " Round-trip sync confirmed.")end
    self:Log(cancelled and "Check cancelled" or "Check complete",self.checkSummary)
    ns.HammerCore.Print(self.checkSummary)
end
function Share:Check()
    if self.pending then ns.HammerCore.Print("A sync check is already running.");return false end
    if self.lastCheckAt and now()-self.lastCheckAt<10 then ns.HammerCore.Print("Wait a few seconds before checking again.");return false end
    if self.lastAttemptAt and now()-self.lastAttemptAt<2 then ns.HammerCore.Print("Wait a moment before retrying the check.");return false end
    if ns.db.share_party==false then self:Log("Check unavailable","Party sharing is off");ns.HammerCore.Print("Party sharing is off. Enable it on Markers > People first.");return false end
    if not channel()then self:Log("Check unavailable","Join a non-raid party first");ns.HammerCore.Print("Join a party to check syncing.");return false end
    local me=UnitGUID and UnitGUID("player")
    if not readable(me)then self:Log("Check unavailable","Player identity unavailable");return false end
    self.sequence=(self.sequence or 0)+1
    local check={token=tostring(self.sequence).."-"..math.floor(now()*1000),peers={},count=0,total=0,roster=roster()}
    for _,member in ipairs(ns.getGroupMembers())do
        if readable(member.guid) and member.guid~=me then
            check.peers[member.guid]={label=slot(member)};check.total=check.total+1
        end
    end
    if check.total==0 then self:Log("Check unavailable","No readable party peers");ns.HammerCore.Print("No party peers with readable identities to check.");return false end
    self.pending=check;self.lastAttemptAt=now();self.checkSummary="Waiting for replies from "..check.total.." party members."
    ns.HammerCore.Print("Checking party sync; waiting up to "..self.CHECK_SECONDS.." seconds for replies.")
    if not self:SendPacket(table.concat({self.VERSION,"Q",me,check.token,version()},":"),"Sync check")then
        self.pending=nil;self.checkSummary="Check could not be sent. See the sync log.";self:RefreshUI();ns.HammerCore.Print(self.checkSummary);return false
    end
    self.lastCheckAt=now()
    if C_Timer and C_Timer.After then C_Timer.After(self.CHECK_SECONDS,function()
        self:FinishCheck(check,roster()~=check.roster)
    end)else self:FinishCheck(check,false)end
    return true
end
function Share:Receive(prefix,text,where,author)
    if prefix~=self.PREFIX or not(readable(text) and type(text)=="string")then return end
    if #text>255 or (where~="PARTY" and where~="INSTANCE_CHAT")then return end
    local protocol,kind,from,rest=text:match("^([^:]+):([^:]+):([^:]+):(.+)$")
    local me=UnitGUID and UnitGUID("player")
    if readable(me) and from==me then return end
    local sender=from and memberByGuid(from)
    if not sender then return end
    if not senderMatches(sender,author)then
        self:Ignored("Message sender did not match the current party identity")
        return
    end
    if protocol~=self.VERSION then self:Ignored("Unsupported protocol from "..slot(sender));return end
    if kind=="Q" or kind=="A" then
        local target,token,peerVersion
        if kind=="Q"then token,peerVersion=rest:match("^([^:]+):([^:]+)$")
        else target,token,peerVersion=rest:match("^([^:]+):([^:]+):([^:]+)$")end
        if not token or #token>32 or not token:match("^[%w%-]+$") or not safeVersion(peerVersion)then return end
        if kind=="Q" then
            if ns.db.share_party==false or not readable(me)then return end
            self.replied=self.replied or {};self.replyAttempts=self.replyAttempts or {}
            if self.replied[from] and now()-self.replied[from]<10 then return end
            if self.replyAttempts[from] and now()-self.replyAttempts[from]<2 then return end
            self.replyAttempts[from]=now()
            self:Log("Check received",slot(sender)..", v"..peerVersion)
            if self:SendPacket(table.concat({self.VERSION,"A",me,from,token,version()},":"),"Sync reply")then self.replied[from]=now()end
        else
            local check=self.pending
            if not check or target~=me or token~=check.token or not check.peers[from] or check.peers[from].replied then return end
            if roster()~=check.roster then self:FinishCheck(check,true);return end
            check.peers[from].replied=true;check.count=check.count+1
            self.checkSummary=check.count.." of "..check.total.." party members replied; waiting."
            self:Log("Reply received",check.peers[from].label..", v"..peerVersion)
            if check.count==check.total then self:FinishCheck(check,false)end
        end
        return
    end
    if kind~="M"then self:Ignored("Unknown message type from "..slot(sender));return end
    local target,marker,source=rest:match("^([^:]+):([^:]+):?([^:]*)$")
    marker=tonumber(marker)
    if not target or not marker or marker%1~=0 or marker<0 or marker>8 then self:Ignored("Invalid marker message");return end
    self.marking={guid=from,name=sender.label or sender.first,at=now()}
    self.theirs=self.theirs or {};self.theirs[target]=marker
    local member=memberByGuid(target)
    local role=source=="tank" or source=="healer"
    if member and source=="" then
        local template=ns.db.role_template or {}
        role=member.role~="NONE" and template[member.role]==marker
    end
    if marker==0 then self:Log("Received",slot(sender)..": cleared marker (not learned)")
    elseif member and not role and ns.db.learn_party~=false then
        local learned=ns.Assign.Learn(member,marker)
        self:Log("Received",slot(sender)..(learned and ": marker choice learned" or ": preference unchanged (pinned or unavailable)"))
    else self:Log("Received",slot(sender)..(role and ": role marker not learned" or ": learning off or target unavailable"))end
    if ns.MarkWindow then ns.MarkWindow:OthersMarking()end
end
function Share:OtherMarker()
    local marking=self.marking
    if not marking or now()-marking.at>self.RECENT or not memberByGuid(marking.guid)then return nil end
    return marking
end
function Share:Reset()
    self.marking,self.theirs,self.replied,self.replyAttempts=nil,nil,nil,nil
    if self.pending then self:FinishCheck(self.pending,true)end
end
function Share:LogText()
    local lines={}
    for index=#(ns.db.sync_log or {}),1,-1 do
        local entry=ns.db.sync_log[index]
        if type(entry)=="table" and type(entry.event)=="string" and type(entry.detail)=="string" then
            local stamp=type(entry.at)=="number" and date and date("%Y-%m-%d %H:%M:%S",entry.at)or "Time unavailable"
            lines[#lines+1]=stamp.." | "..entry.event.." | "..entry.detail
                ..(type(entry.count)=="number" and entry.count>1 and " (x"..entry.count..")"or "")
        end
    end
    return #lines>0 and table.concat(lines,"\n")or "No sync events recorded yet."
end
function Share:Report()
    return table.concat({"Party sharing: "..(ns.db.share_party==false and "off" or "on"),
        "Learn from party: "..(ns.db.learn_party==false and "off" or "on"),
        "Message prefix: "..(self.registered and "registered" or "unavailable"),
        "Channel: "..(channel()or "none (solo or raid)"),
        "Last check: "..(self.checkSummary or "not checked this session"),
        "Recent sync events (newest first):",self:LogText()},"\n")
end
