local addon, ns = ...

-- Every visible assignment cell is its own small, explicit secure action.
-- This mirrors Salve's action cells: one player decision, one prepared unit
-- token and one marker. There is deliberately no automatic queue.

local pendingCells, pendingMembers, pendingAssignments

local function inCombat()
    return InCombatLockdown and InCombatLockdown()
end

function ns.bindMarkerCells(cells, members, assignments)
    if inCombat() then
        ns.pendingMarkerRebuild = true
        pendingCells, pendingMembers, pendingAssignments = cells, members, assignments
        return false
    end

    ns.pendingMarkerRebuild = false
    pendingCells, pendingMembers, pendingAssignments = nil, nil, nil
    for index, cell in ipairs(cells or {}) do
        local member = members and members[index]
        local marker = member and assignments and assignments[member.fullName] or 0
        if member and marker and marker > 0 then
            -- Native Midnight secure delegate: one real click sets the
            -- configured icon; right-click clears whichever icon is there.
            cell:SetAttribute("type1", "raidtarget")
            cell:SetAttribute("unit1", member.unit)
            cell:SetAttribute("marker1", marker)
            cell:SetAttribute("action1", "set")
            cell:SetAttribute("type2", "raidtarget")
            cell:SetAttribute("unit2", member.unit)
            cell:SetAttribute("action2", "clear")
            cell:Enable()
        elseif member then
            -- No marker action is prepared here; the UI uses this live cell
            -- as a direct shortcut to configure the missing role marker.
            cell:SetAttribute("type1", nil)
            cell:SetAttribute("unit1", nil)
            cell:SetAttribute("marker1", nil)
            cell:SetAttribute("action1", nil)
            cell:SetAttribute("type2", nil)
            cell:SetAttribute("unit2", nil)
            cell:SetAttribute("action2", nil)
            cell:Enable()
        else
            cell:SetAttribute("type1", nil)
            cell:SetAttribute("unit1", nil)
            cell:SetAttribute("marker1", nil)
            cell:SetAttribute("action1", nil)
            cell:SetAttribute("type2", nil)
            cell:SetAttribute("unit2", nil)
            cell:SetAttribute("action2", nil)
            cell:Disable()
        end
    end
    return true
end

function ns.rebuildPendingRowSecureButtons()
    if inCombat() or not ns.pendingMarkerRebuild then return false end
    return ns.bindMarkerCells(pendingCells, pendingMembers, pendingAssignments)
end
