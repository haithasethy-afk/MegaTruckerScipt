------------------------------------------------------------
-- MegaTrucker / TruckerJob
-- QBX Core
-- Unlimited Trucking Job
------------------------------------------------------------

local Job = {
    active = false,
    state = 'IDLE',

    npc = nil,
    truck = nil,
    trailer = nil,

    depotBlip = nil,
    trailerBlip = nil,
    deliveryBlip = nil,

    deliveryCount = 0,
    deliveryArrived = false
}

------------------------------------------------------------
-- CONFIG
------------------------------------------------------------

local Config = {

    InteractionKey = 38, -- E

    NPC = {
        model = 's_m_m_trucker_01',

        coords = vector4(
            1226.1221,
            -3204.8772,
            6.0280,
            177.5642
        ),

        distance = 3.0
    },

    Truck = {
        model = 'actros',

        coords = vector4(
            1222.9777,
            -3218.4448,
            6.0524,
            91.2739
        )
    },

    Trailer = {
        model = 'trailers',

        coords = vector4(
            1193.0276,
            -3200.7493,
            7.6195,
            180.6632
        )
    },

    -- DELIVERY DROP-OFF
    Delivery = {
        coords = vector3(
            56.1642,
            6385.3447,
            31.2322
        ),

        radius = 12.0
    }
}

------------------------------------------------------------
-- DEBUG
------------------------------------------------------------

local function Debug(message)
    print('[MegaTrucker] ' .. tostring(message))
end

------------------------------------------------------------
-- NOTIFICATION
------------------------------------------------------------

local function Notify(message)

    BeginTextCommandThefeedPost('STRING')

    AddTextComponentSubstringPlayerName(message)

    EndTextCommandThefeedPostTicker(
        false,
        false
    )

end

------------------------------------------------------------
-- LOAD MODEL
------------------------------------------------------------

local function LoadModel(model)

    if not model then
        return nil
    end

    local hash = joaat(model)

    if not IsModelInCdimage(hash) then

        Debug(
            'Model not found: ' ..
            tostring(model)
        )

        return nil
    end

    if not IsModelValid(hash) then

        Debug(
            'Model invalid: ' ..
            tostring(model)
        )

        return nil
    end

    RequestModel(hash)

    local timeout =
        GetGameTimer() + 15000

    while not HasModelLoaded(hash) do

        Wait(50)

        if GetGameTimer() > timeout then

            Debug(
                'Model loading timeout: ' ..
                tostring(model)
            )

            return nil
        end
    end

    return hash
end

------------------------------------------------------------
-- DELETE ENTITY
------------------------------------------------------------

local function DeleteSafe(entity)

    if entity and DoesEntityExist(entity) then

        SetEntityAsMissionEntity(
            entity,
            true,
            true
        )

        DeleteEntity(entity)

    end
end

------------------------------------------------------------
-- REMOVE BLIP
------------------------------------------------------------

local function RemoveBlipSafe(blip)

    if blip and DoesBlipExist(blip) then
        RemoveBlip(blip)
    end

end

------------------------------------------------------------
-- CREATE BLIP
------------------------------------------------------------

local function CreateBlip(
    coords,
    sprite,
    colour,
    scale,
    name
)

    local blip =
        AddBlipForCoord(
            coords.x,
            coords.y,
            coords.z
        )

    SetBlipSprite(
        blip,
        sprite
    )

    SetBlipColour(
        blip,
        colour
    )

    SetBlipScale(
        blip,
        scale
    )

    SetBlipAsShortRange(
        blip,
        false
    )

    BeginTextCommandSetBlipName(
        'STRING'
    )

    AddTextComponentString(name)

    EndTextCommandSetBlipName(blip)

    return blip
end

------------------------------------------------------------
-- CLOSE NUI
------------------------------------------------------------

local function CloseMenu()

    SetNuiFocus(
        false,
        false
    )

    SetNuiFocusKeepInput(
        false
    )

    SendNUIMessage({
        action = 'close'
    })

end

------------------------------------------------------------
-- OPEN NUI
------------------------------------------------------------

local function OpenMenu()

    SetNuiFocus(
        true,
        true
    )

    SetNuiFocusKeepInput(
        false
    )

    SendNUIMessage({

        action = 'open',

        active = Job.active,

        state = Job.state,

        deliveryCount =
            Job.deliveryCount

    })

end

------------------------------------------------------------
-- SPAWN NPC
------------------------------------------------------------

local function SpawnNPC()

    local model =
        LoadModel(
            Config.NPC.model
        )

    if not model then
        return
    end

    local c =
        Config.NPC.coords

    Job.npc =
        CreatePed(
            4,
            model,
            c.x,
            c.y,
            c.z - 1.0,
            c.w,
            false,
            true
        )

    if not DoesEntityExist(Job.npc) then

        Debug(
            'Failed to spawn trucking NPC.'
        )

        return
    end

    SetEntityAsMissionEntity(
        Job.npc,
        true,
        true
    )

    FreezeEntityPosition(
        Job.npc,
        true
    )

    SetEntityInvincible(
        Job.npc,
        true
    )

    SetBlockingOfNonTemporaryEvents(
        Job.npc,
        true
    )

    SetPedCanRagdoll(
        Job.npc,
        false
    )

    SetModelAsNoLongerNeeded(model)

    Debug(
        'Trucking manager spawned.'
    )

end

------------------------------------------------------------
-- SPAWN TRUCK
------------------------------------------------------------

local function SpawnTruck()

    DeleteSafe(Job.truck)

    Job.truck = nil

    local model =
        LoadModel(
            Config.Truck.model
        )

    if not model then

        Notify(
            '~r~Actros model could not be loaded.'
        )

        return false
    end

    local c =
        Config.Truck.coords

    Job.truck =
        CreateVehicle(
            model,
            c.x,
            c.y,
            c.z,
            c.w,
            true,
            true
        )

    if not DoesEntityExist(Job.truck) then

        Notify(
            '~r~Could not spawn the Actros.'
        )

        return false
    end

    SetEntityAsMissionEntity(
        Job.truck,
        true,
        true
    )

    local netId =
        NetworkGetNetworkIdFromEntity(
            Job.truck
        )

    SetNetworkIdCanMigrate(
        netId,
        true
    )

    SetVehicleOnGroundProperly(
        Job.truck
    )

    SetVehicleHasBeenOwnedByPlayer(
        Job.truck,
        true
    )

    SetVehicleDoorsLocked(
        Job.truck,
        1
    )

    SetVehicleDoorsLockedForAllPlayers(
        Job.truck,
        false
    )

    SetVehicleNeedsToBeHotwired(
        Job.truck,
        false
    )

    SetVehicleEngineOn(
        Job.truck,
        true,
        true,
        false
    )

    SetVehicleEngineHealth(
        Job.truck,
        1000.0
    )

    SetVehicleBodyHealth(
        Job.truck,
        1000.0
    )

    SetVehiclePetrolTankHealth(
        Job.truck,
        1000.0
    )

    SetVehicleNumberPlateText(
        Job.truck,
        'MEGA01'
    )

    SetVehRadioStation(
        Job.truck,
        'OFF'
    )

    SetModelAsNoLongerNeeded(model)

    Debug(
        'Actros spawned.'
    )

    return true
end

------------------------------------------------------------
-- ENTER TRUCK
------------------------------------------------------------

local function EnterTruck()

    if not DoesEntityExist(Job.truck) then
        return false
    end

    local player =
        PlayerPedId()

    TaskWarpPedIntoVehicle(
        player,
        Job.truck,
        -1
    )

    local timeout =
        GetGameTimer() + 5000

    while GetGameTimer() < timeout do

        Wait(100)

        if GetVehiclePedIsIn(
            player,
            false
        ) == Job.truck then

            Debug(
                'Player entered Actros.'
            )

            return true
        end
    end

    return false
end

------------------------------------------------------------
-- SPAWN TRAILER
------------------------------------------------------------

local function SpawnTrailer()

    if not Job.active then
        return false
    end

    if DoesEntityExist(Job.trailer) then

        Notify(
            '~r~You already have a trailer.'
        )

        return false
    end

    local model =
        LoadModel(
            Config.Trailer.model
        )

    if not model then

        Notify(
            '~r~Trailer model could not be loaded.'
        )

        return false
    end

    local c =
        Config.Trailer.coords

    Job.trailer =
        CreateVehicle(
            model,
            c.x,
            c.y,
            c.z,
            c.w,
            true,
            true
        )

    if not DoesEntityExist(Job.trailer) then

        Notify(
            '~r~Could not spawn trailer.'
        )

        return false
    end

    SetEntityAsMissionEntity(
        Job.trailer,
        true,
        true
    )

    local netId =
        NetworkGetNetworkIdFromEntity(
            Job.trailer
        )

    SetNetworkIdCanMigrate(
        netId,
        true
    )

    SetVehicleOnGroundProperly(
        Job.trailer
    )

    SetVehicleDoorsLocked(
        Job.trailer,
        1
    )

    SetVehicleNumberPlateText(
        Job.trailer,
        'MEGATR1'
    )

    SetModelAsNoLongerNeeded(model)

    Debug(
        'Trailer spawned.'
    )

    return true
end

------------------------------------------------------------
-- TRAILER GPS
------------------------------------------------------------

local function SetTrailerGPS()

    RemoveBlipSafe(
        Job.trailerBlip
    )

    Job.trailerBlip =
        CreateBlip(
            Config.Trailer.coords,
            479,
            5,
            0.75,
            'Assigned Trailer'
        )

    SetBlipRoute(
        Job.trailerBlip,
        true
    )

    SetBlipRouteColour(
        Job.trailerBlip,
        5
    )

    SetNewWaypoint(
        Config.Trailer.coords.x,
        Config.Trailer.coords.y
    )

end

------------------------------------------------------------
-- DELIVERY GPS
------------------------------------------------------------

local function SetDeliveryGPS()

    RemoveBlipSafe(
        Job.deliveryBlip
    )

    Job.deliveryBlip =
        CreateBlip(
            Config.Delivery.coords,
            478,
            2,
            0.85,
            'Cargo Delivery'
        )

    SetBlipRoute(
        Job.deliveryBlip,
        true
    )

    SetBlipRouteColour(
        Job.deliveryBlip,
        2
    )

    SetNewWaypoint(
        Config.Delivery.coords.x,
        Config.Delivery.coords.y
    )

end

------------------------------------------------------------
-- START JOB
------------------------------------------------------------

local function StartJob()

    if Job.active then

        Notify(
            '~r~You already have an active trucking job.'
        )

        return
    end

    Debug(
        'Starting trucking job.'
    )

    Job.active = true

    Job.state =
        'SPAWNING_TRUCK'

    Job.deliveryCount = 0

    Job.deliveryArrived = false

    CloseMenu()

    local success =
        SpawnTruck()

    if not success then

        Job.active = false
        Job.state = 'IDLE'

        return
    end

    local entered =
        EnterTruck()

    if not entered then

        Notify(
            '~r~Could not enter the Actros.'
        )

        DeleteSafe(
            Job.truck
        )

        Job.truck = nil

        Job.active = false
        Job.state = 'IDLE'

        return
    end

    --------------------------------------------------------
    -- IMPORTANT:
    -- NO TRAILER IS SPAWNED HERE.
    --------------------------------------------------------

    Job.state =
        'WAITING_FOR_TRAILER'

    Notify(
        '~g~TRUCKING SHIFT STARTED~s~\n' ..
        'Return to the trucking manager and select ~y~GET TRAILER~s~.'
    )

    SetNewWaypoint(
        Config.NPC.coords.x,
        Config.NPC.coords.y
    )

end

------------------------------------------------------------
-- GET NEXT TRAILER
------------------------------------------------------------

local function GetNextTrailer()

    if not Job.active then

        Notify(
            '~r~You need to start a trucking job first.'
        )

        return
    end

    if Job.state ~=
        'WAITING_FOR_TRAILER'
    then

        Notify(
            '~y~You cannot get a new trailer right now.'
        )

        return
    end

    if DoesEntityExist(Job.trailer) then

        Notify(
            '~r~You already have a trailer.'
        )

        return
    end

    CloseMenu()

    local success =
        SpawnTrailer()

    if not success then
        return
    end

    Job.state =
        'ATTACH_TRAILER'

    Job.deliveryArrived =
        false

    SetTrailerGPS()

    Notify(
        '~b~TRAILER ASSIGNED~s~\n' ..
        'Follow the GPS and attach the trailer to your Actros.'
    )

end

------------------------------------------------------------
-- STOP JOB
------------------------------------------------------------

local function StopJob()

    if not Job.active then

        Notify(
            '~r~You do not have an active trucking job.'
        )

        CloseMenu()

        return
    end

    Job.active = false

    Job.state = 'IDLE'

    Job.deliveryArrived = false

    RemoveBlipSafe(
        Job.trailerBlip
    )

    RemoveBlipSafe(
        Job.deliveryBlip
    )

    Job.trailerBlip = nil
    Job.deliveryBlip = nil

    DeleteSafe(
        Job.trailer
    )

    Job.trailer = nil

    DeleteSafe(
        Job.truck
    )

    Job.truck = nil

    CloseMenu()

    Notify(
        '~y~TRUCKING JOB STOPPED~s~'
    )

end

------------------------------------------------------------
-- CHECK TRAILER ATTACHMENT
------------------------------------------------------------

local function CheckTrailerAttachment()

    if not Job.active then
        return
    end

    if Job.state ~=
        'ATTACH_TRAILER'
    then
        return
    end

    if not DoesEntityExist(Job.truck) then

        Notify(
            '~r~Your Actros is missing.'
        )

        StopJob()

        return
    end

    if not DoesEntityExist(Job.trailer) then

        Notify(
            '~r~Your assigned trailer is missing.'
        )

        Job.state =
            'WAITING_FOR_TRAILER'

        return
    end

    local hasTrailer,
          attachedTrailer =
        GetVehicleTrailerVehicle(
            Job.truck
        )

    if not hasTrailer then
        return
    end

    if attachedTrailer
        ~= Job.trailer
    then
        return
    end

    Job.state =
        'DELIVER_CARGO'

    RemoveBlipSafe(
        Job.trailerBlip
    )

    Job.trailerBlip = nil

    SetDeliveryGPS()

    Notify(
        '~g~TRAILER ATTACHED~s~\n' ..
        'Drive to the marked delivery location.'
    )

    Debug(
        'Trailer attached successfully.'
    )

end

------------------------------------------------------------
-- DELIVERY LOCATION CHECK
------------------------------------------------------------

local function CheckDeliveryLocation()

    if not Job.active then
        return
    end

    if Job.state ~=
        'DELIVER_CARGO'
    then
        return
    end

    if not DoesEntityExist(Job.truck) then
        return
    end

    if not DoesEntityExist(Job.trailer) then
        return
    end

    local player =
        PlayerPedId()

    local vehicle =
        GetVehiclePedIsIn(
            player,
            false
        )

    if vehicle
        ~= Job.truck
    then
        return
    end

    local coords =
        GetEntityCoords(
            player
        )

    local distance =
        #(coords -
            Config.Delivery.coords)

    if distance >
        Config.Delivery.radius
    then
        return
    end

    if not Job.deliveryArrived then

        Job.deliveryArrived =
            true

        Notify(
            '~y~DELIVERY ZONE~s~\n' ..
            'Detach the trailer here to complete the delivery.'
        )

    end

end

------------------------------------------------------------
-- CHECK TRAILER DETACH
------------------------------------------------------------

local function CheckTrailerDetach()

    if not Job.active then
        return
    end

    if Job.state ~=
        'DELIVER_CARGO'
    then
        return
    end

    if not Job.deliveryArrived then
        return
    end

    if not DoesEntityExist(Job.trailer) then
        return
    end

    local hasTrailer,
          attachedTrailer =
        GetVehicleTrailerVehicle(
            Job.truck
        )

    if hasTrailer
        and attachedTrailer
            == Job.trailer
    then
        return
    end

    local trailerCoords =
        GetEntityCoords(
            Job.trailer
        )

    local distance =
        #(trailerCoords -
            Config.Delivery.coords)

    if distance >
        Config.Delivery.radius
    then

        Notify(
            '~r~Trailer is not inside the delivery zone.'
        )

        return
    end

    --------------------------------------------------------
    -- DELIVERY COMPLETE
    --------------------------------------------------------

    Job.deliveryCount =
        Job.deliveryCount + 1

    Job.state =
        'WAITING_FOR_TRAILER'

    Job.deliveryArrived =
        false

    RemoveBlipSafe(
        Job.deliveryBlip
    )

    Job.deliveryBlip = nil

    TriggerServerEvent(
        'TruckerJob:server:DeliveryComplete'
    )

    Notify(
        '~g~DELIVERY COMPLETE~s~\n' ..
        'Delivery #' ..
        Job.deliveryCount ..
        ' completed. +$200'
    )

    DeleteSafe(
        Job.trailer
    )

    Job.trailer = nil

    SetNewWaypoint(
        Config.NPC.coords.x,
        Config.NPC.coords.y
    )

    Wait(1000)

    Notify(
        '~b~NEXT LOAD AVAILABLE~s~\n' ..
        'Return to the trucking manager and select ~y~GET TRAILER~s~.'
    )

end

------------------------------------------------------------
-- NPC INTERACTION
------------------------------------------------------------

CreateThread(function()

    while true do

        local sleep = 1000

        if DoesEntityExist(Job.npc) then

            local player =
                PlayerPedId()

            local playerCoords =
                GetEntityCoords(
                    player
                )

            local npcCoords =
                vector3(
                    Config.NPC.coords.x,
                    Config.NPC.coords.y,
                    Config.NPC.coords.z
                )

            local distance =
                #(playerCoords -
                    npcCoords)

            if distance < 10.0 then

                sleep = 0

                if distance <=
                    Config.NPC.distance
                then

                    BeginTextCommandDisplayHelp(
                        'STRING'
                    )

                    AddTextComponentSubstringPlayerName(
                        'Press ~INPUT_CONTEXT~ to interact with ~b~MegaTrucker~s~'
                    )

                    EndTextCommandDisplayHelp(
                        0,
                        false,
                        true,
                        -1
                    )

                    if IsControlJustReleased(
                        0,
                        Config.InteractionKey
                    ) then

                        OpenMenu()

                    end
                end
            end
        end

        Wait(sleep)

    end

end)

------------------------------------------------------------
-- TRAILER ATTACHMENT THREAD
------------------------------------------------------------

CreateThread(function()

    while true do

        if Job.active
            and Job.state ==
                'ATTACH_TRAILER'
        then

            CheckTrailerAttachment()

            Wait(250)

        else

            Wait(1000)

        end

    end

end)

------------------------------------------------------------
-- DELIVERY THREAD
------------------------------------------------------------

CreateThread(function()

    while true do

        if Job.active
            and Job.state ==
                'DELIVER_CARGO'
        then

            CheckDeliveryLocation()

            CheckTrailerDetach()

            Wait(300)

        else

            Wait(1000)

        end

    end

end)

------------------------------------------------------------
-- NUI START JOB
------------------------------------------------------------

RegisterNUICallback(
    'startJob',

    function(data, cb)

        StartJob()

        cb({
            success = true
        })

    end
)

------------------------------------------------------------
-- NUI GET TRAILER
------------------------------------------------------------

RegisterNUICallback(
    'getTrailer',

    function(data, cb)

        GetNextTrailer()

        cb({
            success = true
        })

    end
)

------------------------------------------------------------
-- NUI STOP JOB
------------------------------------------------------------

RegisterNUICallback(
    'stopJob',

    function(data, cb)

        StopJob()

        cb({
            success = true
        })

    end
)

------------------------------------------------------------
-- NUI CLOSE
------------------------------------------------------------

RegisterNUICallback(
    'close',

    function(data, cb)

        CloseMenu()

        cb({
            success = true
        })

    end
)

------------------------------------------------------------
-- CANCEL COMMAND
------------------------------------------------------------

RegisterCommand(
    'canceltrucker',

    function()

        StopJob()

    end,

    false
)

------------------------------------------------------------
-- RESOURCE STOP
------------------------------------------------------------

AddEventHandler(
    'onResourceStop',

    function(resource)

        if resource
            ~= GetCurrentResourceName()
        then
            return
        end

        SetNuiFocus(
            false,
            false
        )

        SetNuiFocusKeepInput(
            false
        )

        DeleteSafe(Job.npc)

        DeleteSafe(Job.truck)

        DeleteSafe(Job.trailer)

        RemoveBlipSafe(
            Job.depotBlip
        )

        RemoveBlipSafe(
            Job.trailerBlip
        )

        RemoveBlipSafe(
            Job.deliveryBlip
        )

    end
)

------------------------------------------------------------
-- INITIALIZE
------------------------------------------------------------

CreateThread(function()

    Wait(1000)

    SpawnNPC()

    Job.depotBlip =
        CreateBlip(
            Config.NPC.coords,
            477,
            5,
            0.8,
            'Trucking Depot'
        )

    Debug(
        'MegaTrucker initialized successfully.'
    )

end)