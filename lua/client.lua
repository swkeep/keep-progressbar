local MAX_PROPS <const> = 5

Progress = {
    _active = false,
    _task_instance = {},
    _cancelled = false,
    _minigame_result = false,

    _controls = {
        disableMouse = { 1, 2, 106 },
        disableMovement = { 30, 31, 36, 21, 75 },
        disableSprint = { 30, 31, 36, 21, 75 },
        disableCarMovement = { 63, 64, 71, 72 },
        disableCombat = { 24, 25, 37, 47, 58, 140, 141, 142, 143, 263, 264, 257 }
    },

    _nui_callbacks = {},
    _sendNUI = function(self, action, data)
        SendNUIMessage({ action = action, data = data })
    end,

    _registerNUI = function(self, name, fn)
        self._nui_callbacks[name] = fn
        RegisterNUICallback(name, function(data, cb)
            fn(data)
            cb("ok")
        end)
    end
}

local function _load_resource(request_fn, check_fn, name, timeout)
    timeout = timeout or 1000
    local start_time = GetGameTimer()
    request_fn(name)
    while not check_fn(name) do
        Wait(50)
        request_fn(name)
        if GetGameTimer() - start_time >= timeout then
            print("Failed to load resource: " .. name)
            return false
        end
    end
    return true
end

local function _create_object(model, ped)
    local success = _load_resource(RequestModel, HasModelLoaded, model)
    if not success then return 0, 0 end
    local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, 0.0)
    local entity = CreateObjectNoOffset(GetHashKey(model), coords.x, coords.y, coords.z, true, true, true)
    local netId = NetworkGetNetworkIdFromEntity(entity)

    SetNetworkIdExistsOnAllMachines(netId, true)
    SetNetworkIdCanMigrate(netId, false)
    SetModelAsNoLongerNeeded(model)
    return entity, netId
end

function CreateObject(model)
    return _create_object(model, PlayerPedId())
end

local function _attach_entity_to_ped(obj, prop, ped)
    local boneIndex = GetPedBoneIndex(ped, prop.bone or 60309)
    local rotation_order = 0

    if prop.rotOrder then
        rotation_order = prop.rotOrder
    end
    AttachEntityToEntity(obj, ped, boneIndex,
        prop.coords.x, prop.coords.y, prop.coords.z,
        prop.rotation.x, prop.rotation.y, prop.rotation.z,
        true, true, false, true, rotation_order, true
    )
end

function AttachEntityToPlayer(object, data)
    _attach_entity_to_ped(object, data, PlayerPedId())
end

function Progress:_initializeProps()
    local props = self._task_instance.props or {}

    -- backward compatibility :)
    if self._task_instance.prop and not props[1] then table.insert(props, self._task_instance.prop) end
    if self._task_instance.propTwo and not props[2] then table.insert(props, self._task_instance.propTwo) end

    if #props > MAX_PROPS then
        print("Warning: Too many props")
        while #props > MAX_PROPS do table.remove(props) end
    end

    self._net_props = {}
    local models = {}
    for _, propData in ipairs(props) do
        if propData.model then
            local obj, net_id = _create_object(propData.model, self.player_ped_id)
            if not (obj == 0 and net_id == 0) then
                _attach_entity_to_ped(obj, propData, self.player_ped_id)
                table.insert(self._net_props, net_id)
                table.insert(models, GetHashKey(propData.model))
            end
        end
    end

    if #self._net_props > 0 then
        TriggerServerEvent("keep-progressbar:server:register_props", self._net_props, models)
    end
end

function Progress:_cleanupProps()
    if not self._net_props then return end
    for _, netId in ipairs(self._net_props) do
        local obj = NetToObj(netId)
        if DoesEntityExist(obj) then
            DetachEntity(obj, true, true)
            DeleteObject(obj)
        end
    end

    -- notify server cleanup
    TriggerServerEvent("keep-progressbar:serer:cleanup_props", self._net_props)

    self._net_props = {}
end

function Progress:_disableControls()
    CreateThread(function()
        self.player_id = PlayerId()

        while self._active do
            for disable_type, is_enabled in pairs(self._task_instance.controlDisables or {}) do
                if is_enabled and self._controls[disable_type] then
                    for _, control in ipairs(self._controls[disable_type]) do
                        DisableControlAction(0, control, true)
                    end
                end
            end
            if self._task_instance.controlDisables and self._task_instance.controlDisables.disableCombat then
                DisablePlayerFiring(self.player_id, true)
            end
            Wait(0)
        end
    end)
end

function Progress:_startAnimation()
    local anim = self._task_instance.animation
    local animSequence = self._task_instance.animations

    self:_stopAnimation()

    if animSequence and type(animSequence) == "table" then
        self._animationCancelled = false
        self._animationThread = CreateThread(function()
            for _, a in ipairs(animSequence) do
                if self._animationCancelled then break end

                if a.task then
                    TaskStartScenarioInPlace(self.player_ped_id, a.task, 0, true)
                    if a.duration then
                        local startTime = GetGameTimer()
                        while GetGameTimer() - startTime < a.duration do
                            if self._animationCancelled then break end
                            Wait(0)
                        end
                    end
                elseif a.animDict and a.anim then
                    _load_resource(RequestAnimDict, HasAnimDictLoaded, a.animDict)

                    if a.onStart then pcall(a.onStart) end

                    TaskPlayAnim(
                        self.player_ped_id,
                        a.animDict,
                        a.anim,
                        a.blendIn or 3.0,
                        a.blendOut or 3.0,
                        a.duration or -1,
                        a.flags or 1,
                        a.playbackRate or 0,
                        a.lockX or false,
                        a.lockY or false,
                        a.lockZ or false
                    )

                    if a.duration and a.duration > 0 then
                        local startTime = GetGameTimer()
                        while GetGameTimer() - startTime < a.duration do
                            if self._animationCancelled then break end
                            if a.onTick then pcall(a.onTick, GetGameTimer() - startTime) end
                            Wait(0)
                        end

                        if a.onFinish and not self._animationCancelled then
                            pcall(a.onFinish)
                        end
                    end
                    RemoveAnimDict(a.animDict)
                end
            end
        end)
    elseif anim then
        if anim.task then
            TaskStartScenarioInPlace(self.player_ped_id, anim.task, 0, true)
        elseif anim.animDict and anim.anim then
            _load_resource(RequestAnimDict, HasAnimDictLoaded, anim.animDict)
            TaskPlayAnim(
                self.player_ped_id,
                anim.animDict,
                anim.anim,
                anim.blendIn or 3.0,
                anim.blendOut or 3.0,
                anim.duration or -1,
                anim.flags or 1,
                anim.playbackRate or 0,
                anim.lockX or false,
                anim.lockY or false,
                anim.lockZ or false
            )
            RemoveAnimDict(anim.animDict)
        end
    end
end

function Progress:_stopAnimation()
    -- signal the thread to stop
    if self._animationThread then
        self._animationCancelled = true
        self._animationThread = nil
    end

    local anim = self._task_instance.animation
    local animSequence = self._task_instance.animations

    local function stopSingle(a)
        if not a then return end
        if a.animDict and a.anim then
            StopAnimTask(self.player_ped_id, a.animDict, a.anim, 1.0)
        end
        if a.task then
            ClearPedTasks(self.player_ped_id)
        end
    end

    if animSequence and type(animSequence) == "table" then
        for _, a in ipairs(animSequence) do
            stopSingle(a)
        end
        ClearPedSecondaryTask(self.player_ped_id)
    elseif anim then
        stopSingle(anim)
        ClearPedSecondaryTask(self.player_ped_id)
    end

    if Progress.currentAnimation then
        local prev = Progress.currentAnimation
        if prev.animDict and prev.anim then
            StopAnimTask(self.player_ped_id, prev.animDict, prev.anim, 1.0)
        elseif prev.task then
            ClearPedTasks(self.player_ped_id)
        end
        Progress.currentAnimation = nil
    end
end

function Progress:_setPlayerState(key, value)
    LocalPlayer.state:set(key, value, true)
end

function Progress:_startActions()
    self:_startAnimation()
    self:_initializeProps()
    self:_disableControls()
end

function Progress:_cleanup()
    self:_stopAnimation()
    self:_cleanupProps()
    self._active = false
    self._cancelled = false
    self:_setPlayerState('inv_busy', false)
end

function Progress:_handleStages()
    if not self._task_instance.stages then return end

    for _, stage in ipairs(self._task_instance.stages) do
        if stage.minigame and not stage.cancelMode then
            stage.cancelMode = "hard"
        end
    end

    CreateThread(function()
        while self._active do
            local currentTime = GetGameTimer()

            for i, stage in ipairs(self._task_instance.stages) do
                -- condition
                if stage.condition and not stage.triggered then
                    local success, res = pcall(stage.condition)
                    if success and res == true then
                        stage.triggered = true
                        self:_sendNUI("CONDITIONAL_SKIP", { index = i })
                    end
                end

                -- in here we can also trigger minigames but needs a bit of work
            end

            Wait(100)
        end
    end)
end

function Progress:_monitor(on_start, on_finish, on_tick)
    local start_time = GetGameTimer()

    if on_tick then
        CreateThread(function()
            while self._active do
                if on_tick then
                    pcall(on_tick, GetGameTimer())
                end
                Wait(100)
            end
        end)
    end

    CreateThread(function()
        if on_start then
            pcall(on_start, start_time)
        end
        if self._task_instance.onStart then
            pcall(self._task_instance.onStart, start_time)
        end

        local event = AddEventHandler("keep-progressbar:client:_cancel_progress", function()
            if GetInvokingResource() ~= GetCurrentResourceName() then return end

            self:Cancel()
            self._cancelled = true
            self._minigame_result = nil
        end)

        while self._active do
            Wait(0)

            -- if player died and we should not continue while dead
            if IsEntityDead(self.player_ped_id) and not self._task_instance.useWhileDead then
                self:Cancel()
                self._cancelled = true
                break
            end
        end

        RemoveEventHandler(event)

        if on_finish then
            pcall(on_finish, self._cancelled, self._minigame_result)
        end

        if self._task_instance.on_finish then
            pcall(self._task_instance.on_finish, self._cancelled, self._minigame_result)
        end
    end)
end

RegisterCommand('+keep_progreebar:cancel', function()
    if not Progress._active then return end
    TriggerEvent("keep-progressbar:client:_cancel_progress")
end, false)

RegisterKeyMapping('+keep_progreebar:cancel', 'Cancel current progress', 'KEYBOARD', "X")
TriggerEvent('chat:removeSuggestion', '/+keep_progreebar:cancel')

function Progress:Cancel()
    self:_cleanup()
    self:_sendNUI("CANCEL")
end

function Progress:Start(task, on_start, on_finish, on_tick)
    if not Progress.is_nui_ready then return end
    if self._active then return end

    self.player_ped_id = PlayerPedId()
    if IsEntityDead(self.player_ped_id) and not task.useWhileDead then return end

    self._active = true
    self._task_instance = task
    self:_setPlayerState('inv_busy', true)

    local nuiData = {
        label = task.label or "Progress",
        icon = task.icon or "fa-solid fa-spinner",
        canCancel = task.canCancel ~= false,
        stages = task.stages or {},
        duration = task.duration,
        theme = task.theme,
        position = task.position,
    }

    -- order matters
    self:_handleStages()
    self:_startActions()
    self:_sendNUI("START_PROGRESS", nuiData)
    self:_monitor(on_start, on_finish, on_tick)
end

Progress:_registerNUI("ready", function(data)
    Progress.is_nui_ready = true
end)

Progress:_registerNUI("progressFinished", function(data)
    if data.cancelled then Progress._cancelled = true end
    Progress:_cleanup()
end)

Progress:_registerNUI("stageStart", function(data)
    if not Progress._task_instance.stages then return end
    local stage = Progress._task_instance.stages[data.stage_index + 1]
    local animation = stage.animation
    if not animation then return end

    local ped = Progress.player_ped_id

    if Progress.currentAnimation then
        local prev = Progress.currentAnimation
        if prev.animDict and prev.anim then
            StopAnimTask(ped, prev.animDict, prev.anim, 1.0)
        elseif prev.task then
            ClearPedTasks(ped)
        end
        Progress.currentAnimation = nil
    end

    if animation.task then
        TaskStartScenarioInPlace(ped, animation.task, 0, true)
    elseif animation.animDict and animation.anim then
        _load_resource(RequestAnimDict, HasAnimDictLoaded, animation.animDict)
        TaskPlayAnim(
            ped,
            animation.animDict,
            animation.anim,
            animation.blendIn or 3.0,
            animation.blendOut or 3.0,
            animation.duration or -1,
            animation.flags or 1,
            animation.playbackRate or 0,
            animation.lockX or false,
            animation.lockY or false,
            animation.lockZ or false
        )
        RemoveAnimDict(animation.animDict)
    end

    Progress.currentAnimation = animation
end)

Progress:_registerNUI("stageFinished", function(data)
    if not Progress._task_instance.stages then return end
    local stage = Progress._task_instance.stages[data.stage_index + 1]
    if stage.onFinish then pcall(stage.onFinish, GetGameTimer(), data.timestamp) end
end)

Progress:_registerNUI("stageMinigame", function(data)
    local lua_index = data.stage_index + 1
    local stage = Progress._task_instance.stages[data.stage_index + 1]

    if stage.minigame then
        local success, res = pcall(stage.minigame, GetGameTimer(), data.timestamp)
        if success then
            Progress._minigame_result = res
            Progress:_sendNUI("MINIGAME_RESULT", { result = res, stage_index = lua_index })
        else
            Progress._minigame_result = false
            Progress:_sendNUI("MINIGAME_RESULT", { result = false })
        end
    end
end)

Progress:_registerNUI("minigameFailed", function(data)
    local stage = Progress._task_instance.stages[data.stage_index + 1]

    if stage.cancelMode == "hard" then
        Progress._cancelled = true
        Progress:_cleanup()
    end
end)

exports("Start", function(data, on_finish)
    Progress:Start(data, nil, on_finish)
end)

exports("isActive", function()
    return Progress._active
end)

AddEventHandler("onResourceStop", function()
    Progress:_cleanup()
end)
