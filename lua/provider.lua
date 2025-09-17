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

if GetResourceState("qb-core") ~= "missing" then
    local _exports = {
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
    for name, func in pairs(_exports) do
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
end

-- -------------------- --
--        ox_lib
-- -------------------- --

if GetResourceState("ox_lib") ~= "missing" then
    local function cancel()
        if not Progress._task_instance.canCancel then return end

        Progress:Cancel()
    end

    local function ox_lib_progress_start(data)
        local _promise = promise.new()

        if data.anim then
            if data.anim then
                local anim = data.anim

                data.animation = {
                    animDict = anim.dict,
                    anim = anim.clip,
                    flags = anim.flag,
                    duration = anim.duration,
                    blendIn = anim.blendIn,
                    blendOut = anim.blendOut,
                    lockX = anim.lockX,
                    lockY = anim.lockY,
                    lockZ = anim.lockZ,
                }
            end

            if data.disable then
                data.controlDisables = {
                    disableMovement = data.disable.move,
                    disableMouse = data.disable.mouse,
                    disableSprint = data.disable.sprint,
                    disableCarMovement = data.disable.car,
                    disableCombat = data.disable.combat,
                }
            end

            if data.prop then
                data.prop = {
                    model = data.prop.model,
                    bone = data.prop.bone,
                    coords = data.prop.coords,
                    rotation = data.prop.rotation,
                    rotOrder = data.prop.rotOrder,
                }
            end

            if data.position == 'middle' then
                data.position = 'center'
            elseif data.position == 'bottom' then
                data.position = 'center-bottom'
            end

            -- add
            -- allowSwimming
            -- useWhileDead
            -- allowRagdoll
            -- allowCuffed
            -- allowFalling
        end

        Progress:Start(data, nil, function(cancelled)
            _promise:resolve(not cancelled)
        end)
        return Citizen.Await(_promise)
    end

    local function ox_lib_progress_progressActive()
        return Progress._active and true
    end

    exports("ox_lib_cancel", cancel)
    exports("ox_lib_progressBar", ox_lib_progress_start)
    exports("ox_lib_progressCircle", ox_lib_progress_start)
    exports("ox_lib_progressActive", ox_lib_progress_progressActive)
end

-- -------------------- --
--         ESX
-- -------------------- --

if GetResourceState("es_extended") ~= "missing" then
    local function cancel()
        if not Progress._task_instance.canCancel then return end

        Progress:Cancel()
    end

    local function esx_Progressbar(message, length, Options)
        local data = {}

        data.label = message
        data.duration = length

        if Options.animation and Options.animation.type == "anim" then
            data.animation = {
                animDict = Options.animation.dict,
                anim = Options.animation.lib,
            }
        elseif Options.animation and Options.animation.type == "Scenario" then
            data.animation = {
                task = Options.animation.Scenario
            }
        end

        if Options.FreezePlayer then
            FreezeEntityPosition(Progress.player_ped_id, true)
        end

        Progress:Start(data, nil, function(cancelled)
            if Options.FreezePlayer then
                FreezeEntityPosition(Progress.player_ped_id, false)
            end

            if Options.onFinish and not cancelled then
                pcall(Options.onFinish)
            end
        end)

        return true
    end

    replaceExport("esx_progressbar", "Progressbar", esx_Progressbar)
    replaceExport("esx_progressbar", "CancelProgressbar", cancel)
end
