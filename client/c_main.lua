local hasShockCollar = false
local isBeingShocked = false
local CommandRan = 0
local zapCount = 0

RegisterNetEvent("shockcollar:setState", function(state)
    hasShockCollar = state

    if not hasShockCollar then
        isBeingShocked = false
        zapCount = 0
        CommandRan = 0
    end

    lib.notify({
        title = 'Shock Collar',
        description = hasShockCollar and 'A shock collar has been locked around your neck...' or 'The shock collar has been removed.',
        type = hasShockCollar and 'error' or 'success'
    })
end)

CreateThread(function()
    while true do
        if hasShockCollar then
            local ped = PlayerPedId()
            local weapon = GetSelectedPedWeapon(ped)

            if weapon ~= `WEAPON_UNARMED` then
                if not isBeingShocked then
                    isBeingShocked = true
                    StartShockingLoop()
                end
            else
                isBeingShocked = false
                zapCount = 0
                CommandRan = 0
            end
            Wait(500)
        else
            isBeingShocked = false
            zapCount = 0
            CommandRan = 0
            Wait(1500)
        end
    end
end)

function StartShockingLoop()
    CreateThread(function()
        while isBeingShocked do
            ElectrocutePlayer()
            Wait(1000) 
        end
    end)
end

function ElectrocutePlayer()
    local ped = PlayerPedId()

    StartScreenEffect("Shock", 0, false)
    SetPedToRagdoll(ped, 750, 750, 0, false, false, false)
    ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 1.0)

    zapCount = zapCount + 1

    if zapCount > 10 then
        local health = GetEntityHealth(ped)
        local newHealth = math.max(math.floor(health - (health / 2)), 1)
        SetEntityHealth(ped, newHealth)
    end

    if CommandRan < 2 then
        CommandRan = CommandRan + 1
        ExecuteCommand("me This is what i get for trolling government")
    end

    RequestNamedPtfxAsset("core")
    while not HasNamedPtfxAssetLoaded("core") do Wait(0) end

    UseParticleFxAssetNextCall("core")
    local fx = StartParticleFxLoopedOnEntity("ent_sht_electrical_box", ped, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.2, false, false, false)
    Wait(1000)
    StopParticleFxLooped(fx, false)

    lib.notify({
        title = 'Shock Collar',
        description = 'You are being shocked! Put the weapon away!',
        type = 'error'
    })
end
