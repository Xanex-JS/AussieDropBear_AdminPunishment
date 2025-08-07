local inService = false
local serviceTime = 0
local currentTask = nil
local watchNPCs = {}
local propNetId = nil

local serviceLocation = vector3(1731.32, 2540.54, 45.56)
local taskLocations = {
    vector3(1725.1, 2530.7, 45.56),
    vector3(1738.5, 2528.3, 45.56),
    vector3(1735.7, 2543.9, 45.56),
    vector3(1724.6, 2547.2, 45.56)
}

function Draw3DText(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local camCoords = GetGameplayCamCoords()
    local dist = #(vector3(x, y, z) - camCoords)

    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextCentre(true)
        SetTextOutline()
        BeginTextCommandDisplayText("STRING")
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayText(_x, _y)
    end
end

CreateThread(function()
    while true do
        Wait(0)
        if inService then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            if #(playerCoords - serviceLocation) < 25.0 then
                DrawMarker(2, serviceLocation.x, serviceLocation.y, serviceLocation.z + 0.2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.4, 0.4, 0.4, 102, 204, 255, 150, false, false, 2, false, nil, nil, false)
                if #(playerCoords - serviceLocation) < 5.0 then
                    Draw3DText(serviceLocation.x, serviceLocation.y, serviceLocation.z + 0.6, "[🧹] Community Service Yard")
                end
            end

            for _, loc in ipairs(taskLocations) do
                if #(playerCoords - loc) < 15.0 then
                    DrawMarker(2, loc.x, loc.y, loc.z + 0.2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 153, 255, 153, 120, false, false, 2, false, nil, nil, false)
                    if #(playerCoords - loc) < 4.0 then
                        Draw3DText(loc.x, loc.y, loc.z + 0.5, "[🧹] Task Zone")
                    end
                end
            end
        end
    end
end)

local function spawnGuards()
    local models = { `s_m_m_prisguard_01`, `s_m_m_security_01` }
    local positions = {
        vector4(1718.0, 2532.5, 47.0, 180.0),
        vector4(1740.0, 2545.5, 47.0, 270.0),
    }

    for i, pos in ipairs(positions) do
        RequestModel(models[i])
        while not HasModelLoaded(models[i]) do Wait(0) end

        local ped = CreatePed(4, models[i], pos.x, pos.y, pos.z, pos.w, false, true)
        SetEntityInvincible(ped, true)
        TaskStartScenarioInPlace(ped, "WORLD_HUMAN_GUARD_STAND", 0, true)
        watchNPCs[#watchNPCs + 1] = ped
    end
end

local function clearGuards()
    for _, ped in ipairs(watchNPCs) do
        DeleteEntity(ped)
    end
    watchNPCs = {}
end

local function startTask(loc)
    local ped = PlayerPedId()

    TaskGoStraightToCoord(ped, loc.x, loc.y, loc.z, 1.0, -1, 0.0, 0.0)
    while #(GetEntityCoords(ped) - loc) > 1.5 do Wait(500) end

    TaskTurnPedToFaceCoord(ped, loc.x, loc.y, loc.z, 1000)
    Wait(1000)

    lib.progressCircle({
        duration = math.random(6000, 10000),
        label = 'Doing community service...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = false,
        disable = { car = true, move = true, combat = true },
    })

    local propModel = `prop_tool_broom`
    RequestModel(propModel)
    while not HasModelLoaded(propModel) do Wait(0) end

    local prop = CreateObject(propModel, loc.x, loc.y, loc.z, true, true, false)
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    propNetId = ObjToNet(prop)

    TaskStartScenarioInPlace(ped, "world_human_janitor", 0, true)
    Wait(7000)
    ClearPedTasks(ped)
    DeleteObject(prop)
    propNetId = nil

    TriggerServerEvent('community:taskCompleted')
end

RegisterNetEvent('community:startService', function(taskCount)
    inService = true
    serviceTime = taskCount
    spawnGuards()

    lib.notify({
        title = 'Community Service',
        description = ('You have been assigned %s tasks. Complete them to finish your sentence.'):format(taskCount),
        type = 'inform'
    })

    SetEntityCoords(PlayerPedId(), serviceLocation)

    CreateThread(function()
        while inService do
            if not currentTask then
                local loc = taskLocations[math.random(#taskLocations)]
                currentTask = lib.zones.sphere({
                    coords = loc,
                    radius = 1.5,
                    debug = false,
                    inside = function()
                        currentTask:remove()
                        currentTask = nil
                        startTask(loc)
                    end
                })
            end
            Wait(1000)
        end
    end)
end)

RegisterNetEvent('community:endService', function()
    inService = false
    serviceTime = 0
    clearGuards()

    lib.notify({
        title = 'Community Service',
        description = 'You have completed your service.',
        type = 'success'
    })

    SetEntityCoords(PlayerPedId(), vector3(1850.5, 2585.0, 45.67))
end)

RegisterNetEvent('community:taskUpdate', function(remaining)
    lib.notify({
        title = 'Community Service',
        description = ('Task completed! %s task(s) remaining.'):format(remaining),
        type = 'success'
    })
end)
