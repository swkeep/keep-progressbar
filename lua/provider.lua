local function replaceExport(resourceName, exportName, func)
    if func and type(func) ~= 'function' then
        warn(('replaceExport: The provided func must be a function or nil'))
        func = nil
    end

    local eventName = ('__cfx_export_%s_%s'):format(resourceName, exportName)
    local cb = func or function()
        warn(("interactionMenu doesn't support %s"):format(exportName))
    end

    AddEventHandler(eventName, function(setCB) setCB(cb) end)
end

-- -------------------- --
--        QBCORE
-- -------------------- --

local exports = {
    Progress = function(data, onFinish)
        Progress:Start(data, nil, onFinish)
    end,
    isDoingSomething = function()
        return Progress._active
    end,
    ProgressWithStartEvent = function(data, on_start, on_finish)
        Progress:Start(data, on_start, on_finish)
    end,
    ProgressWithTickEvent = function(data, on_tick, on_finish)
        Progress:Start(data, nil, on_finish, on_tick)
    end,
    ProgressWithStartAndTick = function(data, on_start, on_tick, on_finish)
        Progress:Start(data, on_start, on_finish, on_tick)
    end
}

-- exports
for name, func in pairs(exports) do
    replaceExport("progressbar", name, func)
end

local netEvents = {
    ["progressbar:client:cancel"] = function(value)
        Progress:Cancel()
    end,
    ["progressbar:client:ToggleBusyness"] = function(value)
        if type(value) == "boolean" then
            Progress._active = value
        end
    end,
    ["progressbar:client:progress"] = function(data, on_finish)
        Progress:Start(data, nil, on_finish)
    end,
    ["progressbar:client:ProgressWithStartEvent"] = function(data, on_start, on_finish)
        Progress:Start(data, on_start, on_finish)
    end,
    ["progressbar:client:ProgressWithTickEvent"] = function(data, on_tick, on_finish)
        Progress:Start(data, nil, on_finish, on_tick)
    end,
    ["progressbar:client:ProgressWithStartAndTick"] = function(data, on_start, on_tick, on_finish)
        Progress:Start(data, on_start, on_finish, on_tick)
    end
}

for event, handler in pairs(netEvents) do
    RegisterNetEvent(event, handler)
end
