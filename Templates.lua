local addon, ns = ...

-- Role presets are intentionally the only assignment model for this release.
-- They keep the small Salve-like panel deterministic and remove per-party
-- saved state until that workflow earns its own dedicated design.
function ns.assignRoleSlots(members)
    local slotToMember, memberToSlot, dps = {}, {}, {}
    for _, member in ipairs(members) do
        if member.role == "TANK" and not slotToMember.TANK then
            slotToMember.TANK, memberToSlot[member.fullName] = member, "TANK"
        elseif member.role == "HEALER" and not slotToMember.HEALER then
            slotToMember.HEALER, memberToSlot[member.fullName] = member, "HEALER"
        else
            dps[#dps + 1] = member
        end
    end
    for index, member in ipairs(dps) do
        if index <= 3 then
            local slot = "DPS" .. index
            slotToMember[slot], memberToSlot[member.fullName] = member, slot
        end
    end
    return slotToMember, memberToSlot
end

function ns.getRoleMarker(slot)
    return ns.db and ns.db.role_template[slot] or 0
end

function ns.getTemplateMembers(members)
    local slotToMember = ns.assignRoleSlots(members)
    local result = {}
    for _, slot in ipairs(ns.ROLE_SLOTS) do
        if slotToMember[slot] then result[#result + 1] = slotToMember[slot] end
    end
    return result
end

function ns.buildDefaultAssignments(members)
    local assignments, slotToMember = {}, ns.assignRoleSlots(members)
    for slot, member in pairs(slotToMember) do assignments[member.fullName] = ns.getRoleMarker(slot) end
    for _, member in ipairs(members) do if assignments[member.fullName] == nil then assignments[member.fullName] = 0 end end
    return assignments
end
