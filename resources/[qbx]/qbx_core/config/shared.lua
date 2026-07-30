return {
    serverName = 'Los Balos',
    defaultSpawn = vec4(-63.49, -1092.83, 25.54, 245.68),
    notifyPosition = 'top-right', -- 'top' | 'top-right' | 'top-left' | 'bottom' | 'bottom-right' | 'bottom-left'
    ---@type { name: string, amount: integer, metadata: fun(source: number): table }[]
    starterItems = { -- Character starting items
        { name = 'phone', amount = 1 },
        { name = 'money', amount = 25000 },
        { name = 'id_card', amount = 1, metadata = function(source)
                assert(GetResourceState('qbx_idcard') == 'started', 'qbx_idcard resource not found. Required to give an id_card as a starting item')
                return exports.qbx_idcard:GetMetaLicense(source, {'id_card'})
            end
        },
        { name = 'driver_license', amount = 1, metadata = function(source)
                assert(GetResourceState('qbx_idcard') == 'started', 'qbx_idcard resource not found. Required to give an id_card as a starting item')
                return exports.qbx_idcard:GetMetaLicense(source, {'driver_license'})
            end
        },
    }
}
