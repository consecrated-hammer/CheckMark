local count=0
local function eq(a,b,label)count=count+1;assert(a==b,label..': '..tostring(a)..' ~= '..tostring(b))end
local clients={}
local function create(name,forever,saved)
    local env=setmetatable({},{__index=_G});env._G=env
    env.loadfile=function(path)
        local fn,err=loadfile(path);if fn then setfenv(fn,env)end;return fn,err
    end
    local wow=assert(env.loadfile('tests/hammercore/wow.lua'))()
    wow.Install({CheckMark={Version='1.5.0-dev2',['X-CheckMark-Target']=forever and 'Camelot' or nil}})
    local c={env=env,wow=wow,name=name,clock=100,timers={},peers={},sent={},deliver=true,forever=forever}
    env.GetTime=function()return c.clock end
    env.time=function()return 1794700000+math.floor(c.clock)end;env.date=os.date
    env.GetRealmName=function()return 'Realm'end
    env.RegisterStateDriver=function()end;env.UnregisterStateDriver=function()end
    env.IsInRaid=function()return c.raid==true end
    env.LE_PARTY_CATEGORY_INSTANCE=2
    env.IsInGroup=function(category)return #c.peers>0 and (category~=2 or c.instance==true)end
    local function who(unit)
        return unit=='player' and c or c.peers[tonumber(unit:match('^party(%d)$'))or 0]
    end
    env.UnitExists=function(unit)return who(unit)~=nil end
    env.UnitGUID=function(unit)local p=who(unit);return p and (p.guid or 'Player-'..p.name) end
    env.UnitName=function(unit)local p=who(unit);if p then return p.name,p.forever and p.surname or 'Realm'end end
    env.GetUnitName=function(unit)local p=who(unit);return p and p.name..(p.surname and ' '..p.surname or '')..'-Realm'end
    env.UnitClass=function()return 'Hunter','HUNTER'end
    env.UnitGroupRolesAssigned=function()return 'NONE'end
    env.UnitIsGroupLeader=function()return true end
    env.InCombatLockdown=function()return false end
    env.C_Timer={After=function(delay,fn)c.timers[#c.timers+1]={at=c.clock+delay,fn=fn}end}
    env.Enum={SendAddonMessageResult={Success=0,AddonMessageThrottle=3,AddOnMessageLockdown=11}}
    env.C_ChatInfo.RegisterAddonMessagePrefix=function()return c.registration~=false end
    env.C_ChatInfo.SendAddonMessage=function(prefix,text,channel)
        c.sent[#c.sent+1]={prefix=prefix,text=text,channel=channel}
        if c.sendResult~=nil then return c.sendResult end
        if c.deliver then
            for _,peer in ipairs(c.peers)do
                if peer.ns then peer.ns.Share:Receive(prefix,text,channel,c.name..(c.surname and ' '..c.surname or '')..'-Realm')end
            end
        end
        return 0
    end
    env.CheckMarkDB=saved or {}
    local ns={};c.ns=ns
    for line in io.lines(forever and 'CheckMark_Camelot.toc' or 'CheckMark.toc')do
        local path=line:gsub('\r',''):gsub('\\','/')
        if path:match('%.xml$')then wow.LoadHammerCore(path:match('^(.*)/[^/]+$'),'CheckMark',ns)
        elseif path:match('%.lua$')then assert(env.loadfile(path))('CheckMark',ns)end
    end
    ns.core.scripts.OnEvent(ns.core,'ADDON_LOADED','CheckMark')
    clients[#clients+1]=c
    return c
end
local function advance(c,seconds)
    c.clock=c.clock+seconds
    local due={}
    for i=#c.timers,1,-1 do if c.timers[i].at<=c.clock then due[#due+1]=table.remove(c.timers,i)end end
    for _,t in ipairs(due)do t.fn()end
end
for _,forever in ipairs({false,true})do
    local a,b=create('Alpha',forever),create('Beta',forever)
    if forever then a.surname='Moon-Brook';b.surname='Silver Leaf'end
    a.peers={b};b.peers={a}
    local share=a.ns.Share
    a.env.SlashCmdList.CHECKMARK('sync')
    eq(share.pending,nil,'round trip completes without waiting for timeout')
    eq(share.checkSummary:find('Round-trip sync confirmed',1,true)~=nil,true,'two real addon copies exchange request and reply')
    eq(#a.sent,1,'check sends one request')
    eq(#b.sent,1,'peer sends one reply')
    eq(a.sent[1].channel,'PARTY','ordinary party channel')
    eq(share.marking,nil,'probes do not claim another player is marking')
    eq(next(a.ns.db.regulars),nil,'probes do not change assignments')
    eq(a.ns.Share:Check(),false,'manual sync checks rate limited')
    local log=share:LogText()
    eq(log:find('Reply received',1,true)~=nil,true,'reply logged')
    eq(log:find('2026-',1,true)~=nil,true,'local event date recorded')
    eq(log:find('Player-',1,true),nil,'no GUIDs in log')
    eq(log:find('Alpha',1,true),nil,'own name not logged')
    eq(log:find('Beta',1,true),nil,'peer name not logged')
    a.ns.HammerCore.Settings:Show('Troubleshooting')
    eq(next(a.ns.HammerCore.Settings.errors),nil,'Troubleshooting with sync log builds')
    local labels={}
    for _,row in ipairs(a.ns.HammerCore.Settings:Search('sync'))do labels[row.label]=true end
    eq(labels['Check party sync'],true,'check action searchable')
    eq(labels['Copy sync report'],true,'report action searchable')
    eq(labels['Clear sync log'],true,'clear action searchable')
    advance(a,11);advance(b,11)
    a.instance=true;b.instance=true;a.env.SlashCmdList.CHECKMARK('sync')
    eq(a.sent[#a.sent].channel,'INSTANCE_CHAT','instance parties use instance channel')
    advance(a,11);a.instance=false;b.instance=false;b.deliver=false
    share:Check();local pending=share.pending
    eq(pending~=nil,true,'no reply remains pending')
    -- Wrong tokens, senders and channels cannot satisfy a live check.
    local packet='1:A:Player-Beta:Player-Alpha:'..pending.token..':1.5.0'
    share:Receive('CheckMark',packet,'PARTY','Impostor-Realm')
    eq(pending.count,0,'spoofed sender rejected')
    share:Receive('CheckMark',packet,'WHISPER','Beta-Realm')
    eq(pending.count,0,'non-party replies rejected')
    share:Receive('CheckMark',packet:gsub(pending.token,'wrong-token',1),'PARTY','Beta-Realm')
    eq(pending.count,0,'unrelated reply token rejected')
    advance(a,6)
    eq(share.pending,nil,'unanswered check terminates')
    eq(share.checkSummary:find('older CheckMark',1,true)~=nil,true,'timeout explains old or nonresponding peers without asserting failure')
    advance(a,11);share:Check();a.peers={};advance(a,6)
    eq(share.checkSummary:find('Check cancelled: party changed.',1,true)==1,true,'roster changes invalidate outstanding check')
    a.peers={b};advance(a,11);a.sendResult=3
    eq(share:Check(),false,'explicit client throttle rejects check')
    eq(share.lastSendOk,false,'nonthrowing send failure not reported successful')
    eq(share:LogText():find('AddonMessageThrottle',1,true)~=nil,true,'native failure reason logged')
    a.sendResult=nil;a.ns.db.share_party=false;advance(a,11)
    local sent=#a.sent;share:Check();eq(#a.sent,sent,'disabled sharing never silently enabled by sync check')
    a.ns.db.share_party=true;a.ns.db.learn_party=false
    share:Receive('CheckMark','1:M:Player-Beta:Player-Alpha:4:fill','PARTY','Beta-Realm')
    eq(next(a.ns.db.regulars),nil,'receiving logged marker respects learning off')
    eq(share:LogText():find('learning off',1,true)~=nil,true,'receive outcome explains learning preference')
    local regulars=a.ns.db.regulars
    for i=1,75 do share:Log('Test','Event '..i)end
    eq(#a.ns.db.sync_log,50,'persisted log bounded to latest fifty')
    local saved=a.ns.db
    local reloaded=create('Alpha',forever,saved)
    eq(reloaded.ns.Share:LogText():find('Event 75',1,true)~=nil,true,'sync events survive reload')
    reloaded.ns.Share:ClearLog()
    eq(#saved.sync_log,0,'clear empties local history')
    eq(saved.regulars,regulars,'clear leaves assignments intact')
    a.ns.db.share_party=true;a.ns.db.learn_party=true;a.sendResult=false;advance(a,11)
    eq(share:Check(),false,'explicit false send result rejected')
    eq(share.pending,nil,'failed send leaves no pending check')
    a.sendResult=nil;share.registered=false;a.registration=false;advance(a,11)
    local registeredSends=#a.sent
    eq(share:Check(),false,'failed prefix registration blocks check')
    eq(#a.sent,registeredSends,'failed registration never claims a send')
    a.registration=true;share.registered=false;a.sendResult=11;advance(a,11)
    eq(share:Check(),false,'client chat lockdown reported as failure')
    eq(share:LogText():find('AddOnMessageLockdown',1,true)~=nil,true,'lockdown result logged')
    a.sendResult=nil
    share:Receive('CheckMark','1:M:Player-Beta:Player-Alpha:4:fill','PARTY','Beta-Realm')
    eq(next(a.ns.db.regulars)~=nil,true,'legacy marker protocol still learns when enabled')
    local logAfterMarker=share:LogText()
    eq(logAfterMarker:find('Player-',1,true),nil,'actual marker traffic logs no GUIDs')
    eq(logAfterMarker:find('Alpha',1,true),nil,'actual learned marker logs no character name')
    local learned=a.ns.db.regulars
    share:Receive('CheckMark','1:M:Player-Beta:Player-Alpha:0:','PARTY','Beta-Realm')
    eq(a.ns.db.regulars,learned,'clear-marker traffic never clears learned preferences')
    eq(share:LogText():find('cleared marker (not learned)',1,true)~=nil,true,'clear marker is logged accurately')
    local logCount=#a.ns.db.sync_log
    for i=1,100 do share:Receive('CheckMark','2:M:Player-Beta:Player-Alpha:4:','PARTY','Beta-Realm')end
    eq(#a.ns.db.sync_log,logCount+1,'unsupported-protocol spam is coalesced')
    for i=1,10 do share:Log('Queued','Marker choice on PARTY')end
    eq(a.ns.db.sync_log[#a.ns.db.sync_log].count,10,'rapid identical transfer events are grouped with a count')
    if forever then
        local duplicate=create('Beta',true);duplicate.guid='Player-Beta2';duplicate.surname='Shadow Brook'
        a.peers={b,duplicate}
        local beforeChoice=share.theirs['Player-Alpha']
        share:Receive('CheckMark','1:M:Player-Beta2:Player-Alpha:5:fill','PARTY','Beta-Realm')
        eq(share.theirs['Player-Alpha'],beforeChoice,'ambiguous first-name author rejected')
        share:Receive('CheckMark','1:M:Player-Beta2:Player-Alpha:5:fill','PARTY','Beta Shadow Brook-Realm')
        eq(share.theirs['Player-Alpha'],5,'full Forever surname author resolves duplicate first names')
        a.peers={b}
    end
    local retryA,retryB=create('Gamma',forever),create('Delta',forever)
    retryA.peers={retryB};retryB.peers={retryA}
    retryA.sendResult=3
    eq(retryA.ns.Share:Check(),false,'initial throttled check fails')
    retryA.sendResult=nil
    eq(retryA.ns.Share:Check(),false,'failed checks retain only a short spam guard')
    advance(retryA,3)
    eq(retryA.ns.Share:Check(),true,'failed send can retry before ten-second success cooldown')
    eq(retryA.ns.Share.checkSummary:find('Round-trip sync confirmed',1,true)~=nil,true,'retry really exchanges acknowledgements')
    advance(retryB,11);retryB.sendResult=3
    local beforeReply=#retryB.sent
    retryB.ns.Share:Receive('CheckMark','1:Q:Player-Gamma:retry-one:1.5.0','PARTY','Gamma-Realm')
    eq(#retryB.sent,beforeReply+1,'failed reply attempted once')
    retryB.sendResult=nil;advance(retryB,3)
    retryB.ns.Share:Receive('CheckMark','1:Q:Player-Gamma:retry-two:1.5.0','PARTY','Gamma-Realm')
    eq(#retryB.sent,beforeReply+2,'failed reply may retry before successful reply cooldown')
    a.raid=true;local prior=#a.sent;advance(a,11);share:Check()
    eq(#a.sent,prior,'raid does not send party check')
end
io.write('CheckMark sync: '..count..' checks passed\n')
