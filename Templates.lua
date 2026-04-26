local addon, ns = ...

-- ── Role-based assignment ──────────────────────────────────────────────────
-- Maps members to role slots (TANK, HEALER, DPS1, DPS2, DPS3) using their
-- assigned group role; DPS slots are filled in party order.
-- Returns: { slotKey -> member } and { member.fullName -> slotKey }
function ns.assignRoleSlots(members)
    local slotToMember = {}
    local memberToSlot = {}
    local dps = {}

    for _, m in ipairs(members) do
        local r = m.role
        if r == "TANK" and not slotToMember["TANK"] then
            slotToMember["TANK"] = m
            memberToSlot[m.fullName] = "TANK"
        elseif r == "HEALER" and not slotToMember["HEALER"] then
            slotToMember["HEALER"] = m
            memberToSlot[m.fullName] = "HEALER"
        else
            table.insert(dps, m)
        end
    end

    for i, m in ipairs(dps) do
        local slot = "DPS"..i
        if i <= 3 then
            slotToMember[slot] = m
            memberToSlot[m.fullName] = slot
        end
    end

    return slotToMember, memberToSlot
end

-- Returns default marker index for a role slot from the saved role template
function ns.getRoleMarker(slot)
    if not ns.db then return 0 end
    return ns.db.role_template[slot] or 0
end

-- ── Name-based assignment ──────────────────────────────────────────────────

function ns.getNameTemplate(fullName)
    if not ns.db then return 0 end
    return ns.db.name_templates[fullName] or 0
end

function ns.saveNameTemplate(fullName, markerIndex)
    if not ns.db then return end
    ns.db.name_templates[fullName] = (markerIndex ~= 0) and markerIndex or nil
end

-- ── Remembered groups ──────────────────────────────────────────────────────

function ns.getRememberedGroup(signature)
    if not ns.db then return nil end
    return ns.db.remembered_groups[signature]
end

function ns.saveRememberedGroup(signature, mode, assignments)
    if not ns.db then return end
    ns.db.remembered_groups[signature] = {
        mode        = mode,
        assignments = assignments,
    }
end

function ns.forgetGroup(signature)
    if not ns.db then return end
    ns.db.remembered_groups[signature] = nil
end

-- ── Build default assignments for current group ────────────────────────────
-- Returns a flat table: { member.fullName -> markerIndex }
-- Priority: remembered group > role/name template defaults
function ns.buildDefaultAssignments(mode, members)
    local sig = ns.getGroupSignature()
    local remembered = ns.getRememberedGroup(sig)

    -- Use remembered group if mode matches
    if remembered and remembered.mode == mode and remembered.assignments then
        return remembered.assignments
    end

    local assignments = {}

    if mode == "ROLE" then
        local slotToMember = ns.assignRoleSlots(members)
        for slot, m in pairs(slotToMember) do
            assignments[m.fullName] = ns.getRoleMarker(slot)
        end
        -- Members not in any slot get no marker
        for _, m in ipairs(members) do
            if assignments[m.fullName] == nil then
                assignments[m.fullName] = 0
            end
        end
    else  -- "NAME"
        for _, m in ipairs(members) do
            assignments[m.fullName] = ns.getNameTemplate(m.fullName)
        end
    end

    return assignments
end
