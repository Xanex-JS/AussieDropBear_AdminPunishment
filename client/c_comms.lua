local inService = false
local serviceTime = 0
local currentTask = nil
local watchNPCs = {}
local propNetId = nil
local maxServiceDistance = 150.0
local serviceReturnCooldown = false
local taskCount = 0

local serviceLocation = vector3(-3251.69, 3910.15, 15.26)
local taskLocations = {
    vector3(-3256.88, 3982.22, 15.26),
    vector3(-3245.66, 4003.28, 15.26),
    vector3(-3219.03, 4038.24, 15.72),
    vector3(-3209.74, 4014.27, 15.58),
    vector3(-3217.38, 3989.66, 15.25),
    vector3(-3226.81, 3961.13, 15.26),
    vector3(-3216.4, 3910.95, 15.26)
}

local taskVariants = {
    {
        anim = "world_human_janitor",
        prop = `prop_tool_broom`,
        bone = 28422,
        offset = vec3(0.0, 0.0, 0.0),
        rot = vec3(0.0, 0.0, 0.0),
        duration = 7000
    },
    {
        anim = "world_human_gardener_plant",
        prop = `prop_cs_rake`,
        bone = 28422,
        offset = vec3(0.0, 0.0, 0.0),
        rot = vec3(0.0, 0.0, 0.0),
        duration = 8000
    },
    {
        anim = "world_human_hammering",
        prop = `prop_tool_hammer`,
        bone = 28422,
        offset = vec3(0.0, 0.0, 0.0),
        rot = vec3(0.0, 0.0, 0.0),
        duration = 6500
    },
    {
        anim = "world_human_maid_clean",
        prop = `prop_sponge_01`,
        bone = 28422,
        offset = vec3(0.0, 0.0, 0.0),
        rot = vec3(0.0, 0.0, 0.0),
        duration = 7500
    },
    {
        anim = "world_human_welding",
        prop = `prop_weld_torch`,
        bone = 28422,
        offset = vec3(0.13, 0.02, 0.0),
        rot = vec3(0.0, 90.0, 180.0),
        duration = 8500
    }
}

function Draw3DText(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local camCoords = GetGameplayCamCoords()

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
                DrawMarker(2, serviceLocation.x, serviceLocation.y, serviceLocation.z + 0.2, 0, 0, 0, 0, 0, 0, 0.4, 0.4, 0.4, 102, 204, 255, 150, false, false, 2, false, nil, nil, false)
                if #(playerCoords - serviceLocation) < 5.0 then

                    -- if not IsControlReleased(0, 38) then 
                    -- lib.notify({
                    -- title = 'Community Service',
                    -- description = 'You have ' .. taskCount .. ' actions left to complete',
                    -- type = 'error'
                    -- })
                    -- end

                    Draw3DText(serviceLocation.x, serviceLocation.y, serviceLocation.z + 0.6, "[🧹] Community Service Yard")
                end
            end

            for _, loc in ipairs(taskLocations) do
                if #(playerCoords - loc) < 15.0 then
                    DrawMarker(2, loc.x, loc.y, loc.z + 0.2, 0, 0, 0, 0, 0, 0, 0.3, 0.3, 0.3, 153, 255, 153, 120, false, false, 2, false, nil, nil, false)
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
        vector4(-3254.71, 3915.13, 14.26, 270.56),
        vector4(-3235.22, 3776.6, 14.26, 3.37)
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

local function spawnHelper()
    local models = { `s_m_m_prisguard_01`, `s_m_m_security_01` }
    local positions = {
        vector4(-3255.32, 3907.28, 14.26, 266.12)
    }

    for i, pos in ipairs(positions) do
        RequestModel(models[i])
        while not HasModelLoaded(models[i]) do Wait(0) end

        local ped = CreatePed(4, models[i], pos.x, pos.y, pos.z, pos.w, false, true)
        SetPedFleeAttributes(ped, 0, 0)
        SetPedDiesWhenInjured(ped, false)
        TaskStartScenarioInPlace(ped, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)
        SetPedKeepTask(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetEntityInvincible(ped, true)
        FreezeEntityPosition(ped, true)
        watchNPCs[#watchNPCs + 1] = ped
    end

    exports.ox_target:addBoxZone({
    coords = vector3(-3254.75, 3907.34, 15.26),
    size = vec3(1, 1, 5),
    rotation = positions.w or 0.0,
    debug = true,
    drawSprite = false,
    options = {
        {
            label = 'Actions Remaining',
            name = 'Actions Remaining',
            icon = 'fa-solid fa-envelope',
            onSelect = function()
                lib.notify({
                title = 'Community Service',
                description = 'You have ' .. taskCount .. ' actions left to complete',
                type = 'error'
                })
            end,
            distance = 1.5,
        },
    },
    })

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

    local variant = taskVariants[math.random(#taskVariants)]

    RequestModel(variant.prop)
    while not HasModelLoaded(variant.prop) do Wait(0) end

    local prop = CreateObject(variant.prop, loc.x, loc.y, loc.z, true, true, false)
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, variant.bone),
        variant.offset.x, variant.offset.y, variant.offset.z,
        variant.rot.x, variant.rot.y, variant.rot.z,
        true, true, false, true, 1, true)

    propNetId = ObjToNet(prop)

    TaskStartScenarioInPlace(ped, variant.anim, 0, true)

    lib.progressCircle({
        duration = variant.duration,
        label = 'Doing community service...',
        position = 'bottom',
        useWhileDead = false,
        canCancel = false,
        disable = { car = true, move = true, combat = true },
    })

    ClearPedTasks(ped)
    DeleteObject(prop)
    propNetId = nil

    TriggerServerEvent('community:taskCompleted')
end


RegisterNetEvent('community:startService', function(newTaskCount)
    inService = true
    taskCount = newTaskCount
    serviceTime = taskCount
    spawnGuards()
    spawnHelper()

    CreateThread(function()
    while inService do
        Wait(5000)
        local ped = PlayerPedId()
        local dist = #(GetEntityCoords(ped) - serviceLocation)

        if dist > maxServiceDistance and not serviceReturnCooldown and inService then
            serviceReturnCooldown = true
            SetEntityCoords(ped, serviceLocation)
            lib.notify({
                title = 'Community Service',
                description = 'You tried to escape. You have been returned and given an extra task.',
                type = 'error'
            })
            taskCount = taskCount + 1

            SetTimeout(3000, function()
                serviceReturnCooldown = false
            end)
            end
            end
            end)


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

RegisterNetEvent("community:openUiMenu", function()
    local input = lib.inputDialog("Assign Community Service", {
        { type = "number", label = "Player ID", required = true },
        { type = "number", label = "Number of Tasks", required = true, default = 5 },
    })

    if not input then return end

    local targetId, taskCount = table.unpack(input)

    if not targetId or not taskCount then
        lib.notify({
            title = "Community Service",
            description = "Invalid input.",
            type = "error"
        })
        return
    end

    TriggerServerEvent("community:assignServiceFromUI", targetId, taskCount)
end)
