------------------------------------------------------------
-- MegaTrucker / TruckerJob
-- SERVER
------------------------------------------------------------

local PAYMENT_AMOUNT = 200


RegisterNetEvent(
    'TruckerJob:server:DeliveryComplete',

    function()

        local src = source

        if not src then
            return
        end

        local success, result =
            pcall(function()

                return exports.qbx_core:AddMoney(
                    src,
                    'cash',
                    PAYMENT_AMOUNT,
                    'trucker-delivery'
                )

            end)

        if not success then

            print(
                '[MegaTrucker] Failed to pay player ' ..
                tostring(src)
            )

            print(
                '[MegaTrucker] Error: ' ..
                tostring(result)
            )

            return

        end

        print(
            '[MegaTrucker] Player ' ..
            tostring(src) ..
            ' received $' ..
            tostring(PAYMENT_AMOUNT) ..
            ' for a trucking delivery.'
        )

    end
)