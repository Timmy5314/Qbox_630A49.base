--[[
    qbx_visuals - server

    Bepaalt of een speler vrijgesteld is van de first-person verplichting.
    Dit hoort server-side: een client mag nooit zelf beslissen dat hij admin is.

    De ACE-namen komen uit je permissions.cfg (group.admin / group.mod /
    group.support met de bijbehorende aces 'admin', 'mod', 'support').
]]

lib.callback.register('qbx_visuals:firstPersonExempt', function(source)
    local fp = Config.FirstPerson
    if not fp.enabled then return true end

    for i = 1, #fp.exemptAces do
        if IsPlayerAceAllowed(source, fp.exemptAces[i]) then
            return true
        end
    end

    return false
end)
