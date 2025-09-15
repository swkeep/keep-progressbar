-- just an experiment :)

local playerProps = {}

local blacklistedProps = {
    [`prop_beach_fire`] = true,
}

local message = "[keep-progressbar] ⚠️ Player %s tried to register blacklisted or invalid prop: %s"

RegisterNetEvent("keep-progressbar:server:register_props", function(netIds, models)
    local src = source

    if type(netIds) ~= "table" or type(models) ~= "table" then return end
    if #netIds ~= #models then return end

    if not playerProps[src] then playerProps[src] = {} end

    for i, netId in ipairs(netIds) do
        local model = models[i] and tonumber(models[i]) or 0
        if model ~= 0 and not blacklistedProps[model] and NetworkGetEntityFromNetworkId(netId) then
            table.insert(playerProps[src], netId)
        else
            print(message:format(src, tostring(model)))
            -- DropPlayer(src, "Spawning blacklisted object.")
        end
    end
end)

RegisterNetEvent("keep-progressbar:serer:cleanup_props", function(netIds)
    local src = source
    if not playerProps[src] then return end

    for _, netId in ipairs(netIds) do
        for i, trackedId in ipairs(playerProps[src]) do
            if trackedId == netId then
                local obj = NetworkGetEntityFromNetworkId(netId)
                if DoesEntityExist(obj) then
                    DeleteEntity(obj)
                end
                table.remove(playerProps[src], i)
                break
            end
        end
    end
end)

AddEventHandler("playerDropped", function()
    local src = source
    if playerProps[src] then
        for _, netId in ipairs(playerProps[src]) do
            local obj = NetworkGetEntityFromNetworkId(netId)
            if DoesEntityExist(obj) then
                DeleteEntity(obj)
            end
        end
        playerProps[src] = nil
    end
end)
