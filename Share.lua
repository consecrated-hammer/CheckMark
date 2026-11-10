local addon, ns = ...

-- Tells the party's other CheckMark users who you marked with what, and
-- learns from theirs. A message carries GUIDs only, so each copy of
-- CheckMark turns the people into its own regulars (BattleTags through its
-- own friends list). Markers set by hand or by other addons can't be seen:
-- the game hides party markers from addons.
--
-- Message: "1:M:<sender GUID>:<target GUID>:<marker>:<source>". The source
-- (tank, healer, pinned...) lets receivers skip role markers, which say
-- nothing about the person.

local Share = { PREFIX = "CheckMark", VERSION = "1", RECENT = 120 }
ns.Share = Share

local function readable(value) return ns.Identity.Readable(value) end

function Share:Register()
    if self.registered then return end
    local register = C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix or RegisterAddonMessagePrefix
    if register then self.registered = pcall(register, self.PREFIX) end
end

local function channel()
    if IsInRaid and IsInRaid() then return nil end
    if IsInGroup and LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
    if IsInGroup and IsInGroup() then return "PARTY" end
end

function Share:Send(member, marker, source)
    if ns.db.share_party == false or not (member and member.guid) then return false end
    local me = UnitGUID and UnitGUID("player")
    local where = channel()
    local send = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
    if not (readable(me) and where and send) then return false end
    local text = table.concat({ self.VERSION, "M", me, member.guid, tostring(marker), tostring(source or "") }, ":")
    local ok = pcall(send, self.PREFIX, text, where)
    self.lastSendOk = ok
    return ok
end

local function memberByGuid(guid)
    for _, member in ipairs(ns.getGroupMembers()) do
        if member.guid == guid then return member end
    end
end

function Share:Receive(prefix, text)
    if prefix ~= self.PREFIX or not (readable(text) and type(text) == "string") then return end
    local version, kind, from, target, marker, source = text:match("^([^:]+):([^:]+):([^:]+):([^:]+):([^:]+):?([^:]*)$")
    if version ~= self.VERSION or kind ~= "M" then return end
    marker = tonumber(marker)
    local me = UnitGUID and UnitGUID("player")
    if not (from and target and marker) or (readable(me) and from == me) then return end
    local sender = memberByGuid(from)
    if not sender then return end
    self.marking = { guid = from, name = sender.label or sender.first, at = GetTime and GetTime() or 0 }
    self.theirs = self.theirs or {}
    self.theirs[target] = marker
    local member = memberByGuid(target)
    local role = source == "tank" or source == "healer"
    if member and source == "" then
        -- No source given: don't learn what looks like their role's marker.
        local template = ns.db.role_template or {}
        role = member.role ~= "NONE" and template[member.role] == marker
    end
    if member and not role and ns.db.learn_party ~= false then ns.Assign.Learn(member, marker) end
    if ns.MarkWindow then ns.MarkWindow:OthersMarking() end
end

-- Who else is marking this party, if anyone has lately.
function Share:OtherMarker()
    local marking = self.marking
    if not marking then return nil end
    local now = GetTime and GetTime() or 0
    if now - marking.at > self.RECENT or not memberByGuid(marking.guid) then return nil end
    return marking
end

function Share:Reset()
    self.marking, self.theirs = nil, nil
end
