local taskCounts = {}
local savedInventories = {} 

lib.addCommand('comms', {
    help = 'Usage: [TargetID] [Amount]',
    restricted = 'group.admin',
}, function(source, args, raw)
    TriggerClientEvent("community:openUiMenu", source)
end)

RegisterNetEvent('community:taskCompleted', function()
    local src = source

    if taskCounts[src] then
        taskCounts[src] = taskCounts[src] - 1
        local remaining = taskCounts[src]

        if remaining <= 0 then
            taskCounts[src] = nil
            TriggerClientEvent('community:endService', src)
        else
            TriggerClientEvent('community:taskUpdate', src, remaining)
        end
    end
end)

RegisterNetEvent("community:assignServiceFromUI", function(targetId, taskCount)
    local src = source
    if not targetId or not taskCount then return end

    taskCounts[targetId] = taskCount
    TriggerClientEvent('community:startService', targetId, taskCount)

    exports.ox_inventory:ClearInventory(targetId)

    TriggerClientEvent('ox_lib:notify', src, {
        title = "Community Service",
        description = ("Assigned %s tasks to player ID %s."):format(taskCount, targetId),
        type = "success"
    })
end)