local taskCounts = {}
local savedInventories = {} 

RegisterCommand("csui", function(source)
    if source == 0 then
        print("This command can only be used in-game.")
        return
    end
    TriggerClientEvent("community:openUiMenu", source)
end, false)

RegisterNetEvent('community:taskCompleted', function()
    local src = source

    if taskCounts[src] then
        taskCounts[src] = taskCounts[src] - 1
        local remaining = taskCounts[src]

        if remaining <= 0 then
            taskCounts[src] = nil
            TriggerClientEvent('community:endService', src)

            -- exports.ox_inventory:AddItem(src, "water", 2)
            -- exports.ox_inventory:AddItem(src, "sandwich", 2)
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