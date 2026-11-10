local addon, ns = ...

-- Who a party member is. The player sees first names; everything stored
-- (regulars, learned markers, party sharing) uses the full identity:
--   Retail   name and realm
--   Forever  first name and surname (the game's second name value is a
--            surname there, not a realm), on our own realm
-- plus the character GUID where the game gives one, and the BattleTag for
-- Battle.net friends so a regular keeps their marker on every alt.
--
-- Midnight can hand back secret values; a secret is treated as unknown and
-- never compared.

local Identity = { tags = {}, friends = {} }
ns.Identity = Identity

local function readable(value)
    if value == nil then return false end
    if issecretvalue and issecretvalue(value) then return false end
    return true
end
Identity.Readable = readable

local function text(value)
    return readable(value) and type(value) == "string" and value ~= "" and value or nil
end

local function metadata(key)
    local get = C_AddOns and C_AddOns.GetAddOnMetadata
    local value = get and get(addon, key)
    if value == nil and GetAddOnMetadata then value = GetAddOnMetadata(addon, key) end
    return value
end

function Identity.IsForever()
    return metadata("X-CheckMark-Target") == "Camelot"
end

local function ownRealm()
    return text(GetRealmName and GetRealmName()) or ""
end

local function squash(value) return (value:gsub("%s", ""):lower()) end

-- Forever's GetUnitName(unit, true) can carry our realm as a suffix; a
-- surname may hold hyphens of its own, so only strip a suffix matching ours.
local function stripOwnRealm(name)
    local own = squash(ownRealm())
    if own == "" then return name end
    for i = #name, 1, -1 do
        if name:sub(i, i) == "-" then
            if squash(name:sub(i + 1)) == own then return name:sub(1, i - 1) end
            break
        end
    end
    return name
end

-- { unit, guid, first, full, realm, key, fullName } or nil.
function Identity.Unit(unit)
    if not (UnitExists and UnitExists(unit)) then return nil end
    local guid = text(UnitGUID and UnitGUID(unit))
    local first, second = UnitName(unit)
    first, second = text(first), text(second)
    if not first then
        -- The name is hidden (a secret value): still markable, never learned.
        local label = unit == "player" and "You" or ("Party " .. (unit:match("%d+") or "?"))
        return { unit = unit, guid = guid, first = label, full = label, realm = ownRealm(), anonymous = true,
            fullName = "unit:" .. unit, key = "unit:" .. unit }
    end
    local full, realm
    if Identity.IsForever() then
        full = text(GetUnitName and GetUnitName(unit, true))
        full = full and stripOwnRealm(full) or (second and (first .. " " .. second) or first)
        realm = ownRealm()
    else
        full, realm = first, second or ownRealm()
    end
    local fullName = full .. "-" .. realm
    return { unit = unit, guid = guid, first = full:match("^(%S+)") or first, full = full, realm = realm,
        fullName = fullName, key = "char:" .. squash(fullName) }
end

-- Display labels: first names, unless two members share one. Then Forever
-- shows full names and Retail adds the realm.
function Identity.Label(members)
    local counts = {}
    for _, member in ipairs(members) do
        local first = (member.first or member.name or "?"):lower()
        counts[first] = (counts[first] or 0) + 1
    end
    for _, member in ipairs(members) do
        local first = member.first or member.name or "?"
        if counts[first:lower()] > 1 then
            member.label = Identity.IsForever() and (member.full or first) or (first .. "-" .. (member.realm or ""))
        else
            member.label = first
        end
    end
    return members
end

-- Battle.net ------------------------------------------------------------------

local function remember(guid, tag)
    if not (guid and tag) then return end
    Identity.tags[guid] = tag
    -- Kept across sessions, so a friend still matches if Midnight hides the
    -- friends list inside an instance.
    if ns.db then
        ns.db.bnet_seen = ns.db.bnet_seen or {}
        ns.db.bnet_seen[guid] = tag
    end
end

local function gameAccount(info, tag)
    if type(info) ~= "table" then return end
    local guid = text(info.playerGuid)
    if guid then remember(guid, tag) end
    return guid, text(info.characterName), info.isOnline
end

-- Reads the friends list: GUID -> BattleTag, and the friends you could add
-- as regulars. Safe to call often; every call is guarded.
function Identity:RefreshFriends()
    self.friends = {}
    self.friendsReadable = false
    local api = C_BattleNet
    if BNGetInfo then
        local ok, _, tag = pcall(BNGetInfo)
        self.selfTag = ok and text(tag) or self.selfTag
        local guid = text(UnitGUID and UnitGUID("player"))
        if self.selfTag and guid then remember(guid, self.selfTag) end
    end
    if not (api and api.GetFriendAccountInfo and BNGetNumFriends) then return end
    local ok, total = pcall(BNGetNumFriends)
    total = ok and readable(total) and tonumber(total) or 0
    for index = 1, total do
        local okInfo, info = pcall(api.GetFriendAccountInfo, index)
        local tag = okInfo and type(info) == "table" and text(info.battleTag)
        if tag then
            self.friendsReadable = true
            local _, character = gameAccount(info.gameAccountInfo, tag)
            local accounts = 0
            if api.GetFriendNumGameAccounts then
                local okCount, count = pcall(api.GetFriendNumGameAccounts, index)
                accounts = okCount and readable(count) and tonumber(count) or 0
            end
            for account = 1, accounts do
                local okGame, game = pcall(api.GetFriendGameAccountInfo, index, account)
                if okGame then
                    local _, name = gameAccount(game, tag)
                    character = character or name
                end
            end
            self.friends[#self.friends + 1] = { tag = tag, character = character }
        end
    end
    table.sort(self.friends, function(a, b) return a.tag:lower() < b.tag:lower() end)
end

function Identity.TagFor(guid)
    if not guid then return nil end
    return Identity.tags[guid] or (ns.db and ns.db.bnet_seen and ns.db.bnet_seen[guid]) or nil
end

-- "Bianca" from "Bianca#1234".
function Identity.TagName(tag)
    return tag and (tag:match("^([^#]+)") or tag) or nil
end

-- The regular keys a member can match, account first.
function Identity.Keys(member)
    local keys = {}
    local tag = member.tag or Identity.TagFor(member.guid)
    if member.anonymous and not tag then return { member.key } end
    if tag then keys[#keys + 1] = "bnet:" .. tag end
    if member.key then keys[#keys + 1] = member.key end
    return keys
end
