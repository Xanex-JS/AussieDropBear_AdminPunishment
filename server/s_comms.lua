local taskCounts = {}

RegisterCommand("communityservice", function(source, args, rawCommand)
    local targetId = tonumber(args[1])
    local taskAmount = tonumber(args[2])

    if not targetId or not taskAmount then
        if source ~= 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Community Service',
                description = 'Usage: /communityservice [id] [taskCount]',
                type = 'error'
            })
        else
            print("Usage: /communityservice [id] [taskCount]")
        end
        return
    end

    taskCounts[targetId] = taskAmount
    TriggerClientEvent('community:startService', targetId, taskAmount)

    -- Optional: Clear inventory
    exports.ox_inventory:ClearInventory(targetId)

    if source ~= 0 then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Community Service',
            description = ('Player %s assigned to %s task(s).'):format(targetId, taskAmount),
            type = 'success'
        })
    else
        print(("Player %s assigned to %s tasks."):format(targetId, taskAmount))
    end
end, true)

RegisterNetEvent('community:taskCompleted', function()
    local src = source

    if taskCounts[src] then
        taskCounts[src] = taskCounts[src] - 1
        local remaining = taskCounts[src]

        if remaining <= 0 then
            taskCounts[src] = nil
            TriggerClientEvent('community:endService', src)

            -- Optional: Return items
            exports.ox_inventory:AddItem(src, "water", 2)
            exports.ox_inventory:AddItem(src, "sandwich", 2)
        else
            TriggerClientEvent('community:taskUpdate', src, remaining)
        end
    end
end)
