local addon, ns = ...

-- ── Secure buttons ─────────────────────────────────────────────────────────
-- SetRaidTarget is protected in retail WoW.  We use SecureActionButtonTemplate
-- buttons whose macrotext is built out-of-combat; the user must physically
-- click Apply or Clear — we never call :Click() programmatically.

local applyBtn
local clearBtn

local function makeSecureBtn(name)
    local b = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
    b:RegisterForClicks("AnyUp", "AnyDown")
    b:SetAttribute("type", "macro")
    b:SetAttribute("macrotext", "")
    b:Hide()
    return b
end

-- Build a macro that targets each member with an assignment and marks them.
-- Entries with marker == 0 are skipped.
-- Returns the macro string (may be empty if no assignments).
local function buildApplyMacro(members, assignments)
    local lines = {}
    for _, m in ipairs(members) do
        local marker = assignments and assignments[m.fullName] or 0
        if marker and marker > 0 then
            table.insert(lines, "/targetexact "..m.targetName)
            table.insert(lines, "/tm "..marker)
        end
    end
    if #lines == 0 then return "" end
    table.insert(lines, "/targetlasttarget")
    return table.concat(lines, "\n")
end

-- Build a clear macro that removes marks from all assigned members.
local function buildClearMacro(members, assignments)
    local lines = {}
    for _, m in ipairs(members) do
        local marker = assignments and assignments[m.fullName] or 0
        if marker and marker > 0 then
            table.insert(lines, "/targetexact "..m.targetName)
            table.insert(lines, "/tm 0")
        end
    end
    if #lines == 0 then return "" end
    table.insert(lines, "/targetlasttarget")
    return table.concat(lines, "\n")
end

-- Called whenever the popup's current assignments change.
-- Must be called out-of-combat; if in combat, defers via pendingMarkerRebuild.
function ns.rebuildSecureButtons(members, assignments)
    if InCombatLockdown() then
        ns.pendingMarkerRebuild = true
        -- Store args so the deferred rebuild has them
        ns._pendingMembers    = members
        ns._pendingAssignments = assignments
        return false
    end

    -- Use stored pending args if called from PLAYER_REGEN_ENABLED with no args
    members     = members     or ns._pendingMembers    or {}
    assignments = assignments or ns._pendingAssignments or {}
    ns._pendingMembers    = nil
    ns._pendingAssignments = nil

    if not applyBtn then
        applyBtn = makeSecureBtn("CheckMarkApplySecure")
        clearBtn = makeSecureBtn("CheckMarkClearSecure")
    end

    applyBtn:SetAttribute("macrotext", buildApplyMacro(members, assignments))
    clearBtn:SetAttribute("macrotext", buildClearMacro(members, assignments))
    return true
end

-- Returns the pre-built secure buttons so UI.lua can overlay visible buttons on top.
function ns.getSecureButtons()
    if not applyBtn then
        applyBtn = makeSecureBtn("CheckMarkApplySecure")
        clearBtn = makeSecureBtn("CheckMarkClearSecure")
    end
    return applyBtn, clearBtn
end
