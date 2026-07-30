--[[
    qbx_visuals - performance

    Meet de framerate en schakelt bij profiel 'auto' zelf tussen de
    kwaliteitsprofielen. Met hysterese en een cooldown, zodat hij niet elke
    paar seconden heen en weer pendelt.

    Kosten: een meting per Config.Auto.sampleInterval (default 2x per seconde).
]]

local cfg = Config.Auto

local function indexOf(name)
    for i = 1, #cfg.order do
        if cfg.order[i] == name then return i end
    end
    return nil
end

CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(500) end
    Wait(5000) -- eerste seconden na het spawnen zijn niet representatief

    local samples    = {}
    local lastSwitch = 0

    while true do
        if QV.state.profile ~= 'auto' then
            samples = {}
            Wait(2000)
        else
            local frameTime = GetFrameTime()

            if frameTime and frameTime > 0.0 then
                samples[#samples + 1] = 1.0 / frameTime
                if #samples > cfg.sampleCount then
                    table.remove(samples, 1)
                end

                local total = 0
                for i = 1, #samples do total = total + samples[i] end
                local avg = total / #samples
                QV.state.fps = math.floor(avg + 0.5)

                local now = GetGameTimer()
                if #samples >= cfg.sampleCount and (now - lastSwitch) > cfg.cooldown then
                    local cur = indexOf(QV.state.autoProfile) or indexOf(cfg.start) or 1
                    local target = cur

                    if avg < cfg.downThreshold and cur > 1 then
                        target = cur - 1
                    elseif avg > cfg.upThreshold and cur < #cfg.order then
                        target = cur + 1
                    end

                    if target ~= cur then
                        QV.state.autoProfile = cfg.order[target]
                        lastSwitch = now
                        samples = {}

                        QV.debug('auto-profiel -> %s (%.0f fps)', QV.state.autoProfile, avg)
                        if cfg.notify then
                            QV.notify(('Grafisch profiel: %s (%.0f fps)')
                                :format(Config.Profiles[QV.state.autoProfile].label, avg))
                        end

                        QV.emit()
                    end
                end
            end

            Wait(cfg.sampleInterval)
        end
    end
end)
