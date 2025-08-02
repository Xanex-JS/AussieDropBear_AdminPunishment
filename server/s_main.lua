local QBCore = exports['qb-core']:GetCoreObject()

local collars = {}       
local timers = {}       
local pausedTimers = {}  

local dataFile = ('%s/collars.json'):format(GetResourcePath(GetCurrentResourceName()))

local function saveData()
    local data = {}
    for license, active in pairs(collars) do
        data[license] = {
            active = active,
            timer = timers[license],
            paused = pausedTimers[license]
        }
    end
    SaveResourceFile(GetCurrentResourceName(), 'collars.json', json.encode(data, { indent = true }), -1)
end

local function loadData()
    local file = LoadResourceFile(GetCurrentResourceName(), 'collars.json')
    if not file then return end
    local decoded = json.decode(file)
    if not decoded then return end

    for license, info in pairs(decoded) do
        collars[license] = info.active
        timers[license] = info.timer
        pausedTimers[license] = info.paused
    end
end

local function startTimer(license, duration)
    local expireAt = os.time() + duration
    timers[license] = expireAt
    pausedTimers[license] = nil
    saveData()
end

local function cancelTimer(license)
    timers[license] = nil
    pausedTimers[license] = nil
    saveData()
end

local function WaitForPlayer(id, attempts)
    attempts = attempts or 20
    while attempts > 0 do
        local player = QBCore.Functions.GetPlayer(id)
        if player then return player end
        Wait(250)
        attempts -= 1
    end
    return nil
end

function GetLicense2(playerId)
    if not playerId then
        print("[ShockCollar] GetLicense2 called with nil playerId!")
        return nil
    end

    local identifiers = GetPlayerIdentifiers(playerId)
    if not identifiers then
        print("[ShockCollar] No identifiers found for playerId:", playerId)
        return nil
    end

    for _, id in ipairs(identifiers) do
        if id:match("^license2:") then
            return id
        end
    end

    return nil 
end


CreateThread(function()
    loadData()
    while true do
        Wait(1000)
        local now = os.time()
        for license, expireAt in pairs(timers) do
            if now >= expireAt then
                collars[license] = false
                timers[license] = nil
                pausedTimers[license] = nil

                for _, id in pairs(GetPlayers()) do
                    local idLicense = GetLicense2(id) 
                    if idLicense == license then
                        TriggerClientEvent('shockcollar:setState', id, false)
                        TriggerClientEvent('QBCore:Notify', id, 'Your shock collar has been automatically removed.', 'success')
                        break
                    end
                end
                saveData()
            end
        end
    end
end)


lib.addCommand('shockcollar', {
    help = 'Toggle shock collar on a player optionally for a duration (seconds OR blank for perma)',
    restricted = 'group.admin',
    arguments = {
        { name = 'id', type = 'number', help = 'Player server ID to collar' },
        { name = 'duration', type = 'number', help = 'Duration in seconds (OR blank for perma)' }
    }
}, function(source, args)
    local targetId = tonumber(args[1])
    local duration = tonumber(args[2])

    if not targetId then
        lib.notify(source, { title = 'Shock Collar', description = 'Usage: /shockcollar [playerID] [duration - OR blank for perma]', type = 'error' })
        return
    end

    local targetPlayer = WaitForPlayer(targetId)
    if not targetPlayer then
        lib.notify(source, { title = 'Shock Collar', description = 'Player not found or not fully loaded.', type = 'error' })
        return
    end

    local license = targetPlayer.PlayerData.license
    if not license then
        lib.notify(source, { title = 'Shock Collar', description = 'License not found.', type = 'error' })
        return
    end

    local newState = not collars[license]
    collars[license] = newState

    TriggerClientEvent('shockcollar:setState', targetId, newState)

    if newState then
        if duration and duration > 0 then
            startTimer(license, duration)
            lib.notify(source, { title = 'Shock Collar', description = ('Shock collar applied to ID %s for %d seconds'):format(targetId, duration), type = 'success' })
            lib.notify(targetId, { title = 'Shock Collar', description = ('You have been shock collared for %d seconds! You cannot escape this.'):format(duration), type = 'error' })
        else
            saveData()
            lib.notify(source, { title = 'Shock Collar', description = ('Shock collar applied to ID %s indefinitely'):format(targetId), type = 'success' })
            lib.notify(targetId, { title = 'Shock Collar', description = 'You have been shock collared indefinitely! You cannot escape this.', type = 'error' })
        end
    else
        cancelTimer(license)
        lib.notify(source, { title = 'Shock Collar', description = ('Shock collar removed from ID %s'):format(targetId), type = 'success' })
        lib.notify(targetId, { title = 'Shock Collar', description = 'Your shock collar has been removed.', type = 'success' })
    end
end)

AddEventHandler('playerJoining', function()
    local src = source
    Citizen.SetTimeout(1500, function() 
        local license2 = GetLicense2(src)
        print(('[ShockCollar] Player %d license2 on join: %s'):format(src, tostring(license2)))

        if license2 and collars[license2] then
            print(('[ShockCollar] Applying collar to player %d'):format(src))
            TriggerClientEvent('shockcollar:setState', src, true)
            lib.notify(src, {
                title = 'Shock Collar',
                description = 'You are still shock collared! You cannot escape this.',
                type = 'error'
            })

            if pausedTimers[license2] then
                local remaining = pausedTimers[license2]
                pausedTimers[license2] = nil
                timer[license2] = os.time() + remaining
                print(('[ShockCollar] Resumed timer for %d seconds'):format(remaining))
            end
        end
    end)
end)

