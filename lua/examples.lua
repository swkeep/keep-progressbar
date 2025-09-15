local examples = false

if not GetResourceState('interactionMenu') == 'started' then return end
if not examples then return end

local objects = {}
local function spawn_object(objectModel, c)
    local id = #objects + 1
    local entity, net_id = CreateObject(objectModel)
    objects[id] = entity

    SetEntityCoordsNoOffset(entity, c.x, c.y, c.z, false, false, true)
    SetEntityHeading(objects[id], c.w or 0)
    FreezeEntityPosition(entity, true)
    return objects[id]
end

local function makeEntityFaceEntity(entity1, entity2)
    local p1 = GetEntityCoords(entity1, true)
    local p2 = GetEntityCoords(entity2, true)

    local dx = p2.x - p1.x
    local dy = p2.y - p1.y

    local heading = GetHeadingFromVector_2d(dx, dy)
    SetEntityHeading(entity1, heading)
end

local positions = {
    vector4(794.00, -2997.10, -70.00, 0),
    vector4(796.50, -2997.10, -70.00, 0),
    vector4(799.00, -2997.10, -70.00, 0),
    vector4(801.50, -2997.10, -70.00, 0),
}

-- default qb like test

local function default()
    local object = spawn_object("m24_1_prop_m41_jammer_01a", positions[1])

    exports['interactionMenu']:Create {
        entity = object,
        options = {
            {
                label = "Hack Military Tech",
                icon = "fa-solid fa-laptop-code",
                action = function(entity)
                    exports['keep-progressbar']:Start({
                        name = "hack_task", -- i didn't use name we can just ignore it
                        duration = 4000,
                        label = "Hacking military tech...",
                        icon = "fa-solid fa-laptop-code",
                        useWhileDead = false,
                        canCancel = true,
                        controlDisables = {
                            disableMovement = true,
                            disableCarMovement = true,
                            disableMouse = false,
                            disableCombat = true,
                        },
                        animation = {
                            animDict = "anim@heists@humane_labs@emp@hack_door",
                            anim = "hack_loop",
                        },
                        prop = {
                            model = "prop_police_phone",
                            bone = 28422,
                            coords = vector3(0.00, 0.0, 0.0),
                            rotation = vector3(0.0, 0.0, 0.0),
                        },
                    }, function(cancelled)
                        if not cancelled then
                            print("Hack complete!")
                        else
                            print("Hack cancelled.")
                        end
                    end)
                end
            }
        }
    }
end

-- stages with minigames

local function stages_with_minigame()
    local props = {
        { model = 'm24_1_prop_m41_jammer_01a',       label = "Disable Jammer",     icon = "fa-solid fa-bolt",        theme = "jammer" },
        { model = 'm24_1_prop_m41_militarytech_01a', label = "Hack Military Tech", icon = "fa-solid fa-laptop-code", theme = "tech" },
        { model = 'm23_2_prop_m32_jammer_01a',       label = "Bypass Signal",      icon = "fa-solid fa-signal",      theme = "signal" },
        { model = 'm23_2_prop_m32_sub_console_01a',  label = "Access Console",     icon = "fa-solid fa-terminal",    theme = "console" },
    }

    local busy = false

    for i = 1, #props do
        local pos = positions[i]
        local prop = props[i]
        local obj = spawn_object(prop.model, pos)

        exports['interactionMenu']:Create {
            entity = obj,
            options = {
                {
                    label = prop.label,
                    icon = prop.icon,
                    action = function(entity)
                        if busy then return end
                        busy = true
                        local stages = {}

                        if prop.theme == "jammer" then
                            stages = {
                                { message = "🔌 Connecting Override...", duration = 2000 },
                                { message = "⚡ Disabling Jammer...", duration = 5000, progressColor = "red" },
                                { message = "✅ Jammer Disabled!", duration = 1500 }
                            }
                        elseif prop.theme == "tech" then
                            stages = {
                                { message = "💻 Booting Interface...", duration = 2500 },
                                {
                                    message = "⌨️ Running Exploit...",
                                    duration = 5000,
                                    minigame = function()
                                        return lib
                                            .skillCheck({ 'easy', 'easy' }, { 'w', 'a', 's', 'd' })
                                    end
                                },
                                { message = "✅ Access Granted", duration = 1500 }
                            }
                        elseif prop.theme == "signal" then
                            stages = {
                                { message = "📡 Scanning Frequencies...", duration = 3000 },
                                {
                                    message = "🔧 Adjusting Signal...",
                                    duration = 4000,
                                    minigame = function()
                                        return lib
                                            .skillCheck({ 'easy', }, { 'q', 'e' })
                                    end
                                },
                                { message = "✅ Signal Bypassed", duration = 1500 }
                            }
                        elseif prop.theme == "console" then
                            stages = {
                                { message = "🖥️ Logging In...", duration = 2000 },
                                { message = "🔑 Verifying Credentials...", duration = 4000 },
                                {
                                    message = "⌨️ Executing Commands...",
                                    duration = 3000,
                                    minigame = function()
                                        return lib
                                            .skillCheck({ 'easy', 'easy' }, { 'w', 's' })
                                    end
                                },
                                { message = "✅ Console Accessed", duration = 1500 }
                            }
                        end

                        exports['keep-progressbar']:Start({
                            label = prop.label,
                            icon = prop.icon,
                            canCancel = true,
                            controlDisables = { disableMovement = true, disableCombat = true },
                            animation = { task = "WORLD_HUMAN_WELDING" },
                            stages = stages,
                            -- theme = "theme-1",
                            -- position = "center-top"
                        }, function(cancelled, result)
                            if not cancelled then
                                print("✅ Finished:", prop.label, result)
                            else
                                print("❌ Cancelled:", prop.label)
                            end

                            busy = false
                        end)
                    end
                },
            }
        }
    end
end

local function no_stage_but_with_animations()
    local object = spawn_object("m24_1_prop_m41_jammer_01a", positions[1])

    exports['interactionMenu']:Create {
        entity = object,
        options = {
            {
                label = "Hack Military Tech",
                icon = "fa-solid fa-laptop-code",
                action = function(entity)
                    exports['keep-progressbar']:Start({
                        duration = 8000,
                        label = "Hacking military tech...",
                        icon = "fa-solid fa-laptop-code",
                        useWhileDead = false,
                        canCancel = true,
                        controlDisables = {
                            disableMovement = true,
                            disableCarMovement = true,
                            disableMouse = false,
                            disableCombat = true,
                        },
                        animations = {
                            {
                                animDict = "anim@heists@humane_labs@emp@hack_door",
                                anim = "hack_intro",
                                flags = 1,
                                duration = 2500,
                                blendIn = 3.0,
                                blendOut = 3.0,
                            },
                            {
                                animDict = "anim@heists@humane_labs@emp@hack_door",
                                anim = "hack_loop",
                                flags = 1,
                                duration = 3000,
                                blendIn = 3.0,
                                blendOut = 3.0,
                            },
                            {
                                animDict = "anim@heists@humane_labs@emp@hack_door",
                                anim = "hack_outro",
                                flags = 1,
                                duration = 2000,
                                blendIn = 3.0,
                                blendOut = 3.0,
                            }
                        },
                        prop = {
                            model = "prop_v_m_phone_01",
                            bone = 28422,
                            coords = vector3(0.00, 0.0, 0.0),
                            rotation = vector3(0.0, 0.0, 0.0),
                        },
                    }, function(cancelled)
                        if not cancelled then
                            print("Hack complete!")
                        else
                            print("Hack cancelled.")
                        end
                    end)
                end
            }
        }
    }
end

local function stages_with_animations()
    local object = spawn_object("m23_2_prop_m32_sub_console_01a", positions[1])

    exports['interactionMenu']:Create {
        entity = object,
        offset = vec3(0, 0, 0.5),
        options = {
            {
                label = "Hack",
                icon = "fa-solid fa-laptop-code",
                action = function(entity)
                    if LocalPlayer.state.inv_busy then return end

                    exports['keep-progressbar']:Start({
                        duration = 4000,
                        label = "Hacking military tech...",
                        icon = "fa-solid fa-laptop-code",
                        useWhileDead = false,
                        canCancel = true,
                        controlDisables = {
                            disableMovement = true,
                            disableCarMovement = true,
                            disableMouse = false,
                            disableCombat = true,
                        },
                        prop = {
                            model = "prop_police_phone",
                            bone = 28422,
                            coords = vector3(0.00, 0.0, 0.0),
                            rotation = vector3(0.0, 0.0, 0.0),
                        },

                        stages = {
                            {
                                message = "💻 Booting Interface...",
                                duration = 2500,
                                animation = {
                                    animDict = "anim@heists@humane_labs@emp@hack_door",
                                    anim = "hack_intro",
                                    flags = 1,
                                    duration = 2500,
                                    blendIn = 3.0,
                                    blendOut = 3.0,
                                }
                            },
                            {
                                message = "⌨️ Running Exploit...",
                                duration = 5000,
                                animation = {
                                    animDict = "anim@heists@humane_labs@emp@hack_door",
                                    anim = "hack_loop",
                                    flags = 1,
                                    duration = 5000,
                                    blendIn = 3.0,
                                    blendOut = 3.0,
                                }
                            },
                            {
                                message = "✅ Access Granted",
                                duration = 1000,
                                animation = {
                                    {
                                        animDict = "anim@heists@humane_labs@emp@hack_door",
                                        anim = "hack_outro",
                                        flags = 1,
                                        duration = 1000,
                                        blendIn = 8.0,
                                        blendOut = 8.0,
                                    }
                                }
                            }
                        }
                    }, function(cancelled)
                        if not cancelled then
                            print("Hack complete!")
                        else
                            print("Hack cancelled.")
                        end
                    end)
                end
            }
        }
    }
end

local function stages_with_animations_and_minigame()
    local object = spawn_object("m23_2_prop_m32_sub_console_01a", positions[1])

    exports['interactionMenu']:Create {
        entity = object,
        offset = vec3(0, 0, 0.5),
        options = {
            {
                label = "Hack",
                icon = "fa-solid fa-laptop-code",
                action = function(entity)
                    exports['keep-progressbar']:Start({
                        duration = 4000,
                        label = "Hacking military tech...",
                        icon = "fa-solid fa-laptop-code",
                        useWhileDead = false,
                        canCancel = true,
                        controlDisables = {
                            disableMovement = true,
                            disableCarMovement = true,
                            disableMouse = false,
                            disableCombat = true,
                        },
                        props = {
                            {
                                model = "prop_police_phone",
                                bone = 28422,
                                coords = vector3(0.00, 0.0, 0.0),
                                rotation = vector3(0.0, 0.0, 0.0),
                            }
                        },

                        stages = {
                            {
                                message = "💻 Booting Interface...",
                                duration = 2500,
                                animation = {
                                    animDict = "anim@heists@humane_labs@emp@hack_door",
                                    anim = "hack_intro",
                                    flags = 1,
                                    duration = 2500,
                                    blendIn = 3.0,
                                    blendOut = 3.0,
                                }
                            },
                            {
                                message = "⌨️ Running Exploit...",
                                animation = {
                                    animDict = "anim@heists@humane_labs@emp@hack_door",
                                    anim = "hack_loop",
                                    flags = 1,
                                    duration = 5000,
                                    blendIn = 3.0,
                                    blendOut = 3.0,
                                },
                                duration = 15000,
                                cancelMode = "hard", -- "soft" or "hard"
                                progressColor = "chartreuse",
                                minigame = function()
                                    return lib.skillCheck({ 'easy', 'easy', 'easy' }, { 'w', 's', 'a' })
                                end,
                                onFinish = function()
                                    print("Skillcheck was successful")
                                end
                            },
                            {
                                message = "✅ Access Granted",
                                duration = 1000,
                                animation = {
                                    {
                                        animDict = "anim@heists@humane_labs@emp@hack_door",
                                        anim = "hack_outro",
                                        flags = 1,
                                        duration = 1000,
                                        blendIn = 8.0,
                                        blendOut = 8.0,
                                    }
                                }
                            }
                        }
                    }, function(cancelled, skill_check)
                        if not cancelled then
                            print("Hack complete! skillcheck->", skill_check)
                        else
                            print("Hack cancelled.")
                        end
                    end)
                end
            }
        }
    }
end

local function stages_many_minigame()
    local object = spawn_object("m23_2_prop_m32_sub_console_01a", positions[1])

    exports['interactionMenu']:Create {
        entity = object,
        offset = vec3(0, 0, 0.5),
        options = {
            {
                label = "Hack",
                icon = "fa-solid fa-laptop-code",
                action = function(entity)
                    exports['keep-progressbar']:Start({
                        name = "hack_task",
                        duration = 4000,
                        label = "Hacking military tech...",
                        icon = "fa-solid fa-laptop-code",
                        useWhileDead = false,
                        canCancel = true,
                        controlDisables = {
                            disableMovement = true,
                            disableCarMovement = true,
                            disableMouse = false,
                            disableCombat = true,
                        },
                        props = {
                            {
                                model = "prop_police_phone",
                                bone = 28422,
                                coords = vector3(0.00, 0.0, 0.0),
                                rotation = vector3(0.0, 0.0, 0.0),
                            }
                        },

                        stages = {
                            {
                                message = "💻 Booting Interface...",
                                duration = 2500,
                                animation = {
                                    animDict = "anim@heists@humane_labs@emp@hack_door",
                                    anim = "hack_intro",
                                    flags = 1,
                                    duration = 2500,
                                    blendIn = 3.0,
                                    blendOut = 3.0,
                                }
                            },
                            {
                                message = "⌨️ Running Exploit...",
                                animation = {
                                    animDict = "anim@heists@humane_labs@emp@hack_door",
                                    anim = "hack_loop",
                                    flags = 1,
                                    duration = 5000,
                                    blendIn = 3.0,
                                    blendOut = 3.0,
                                },
                                duration = 15000,
                                cancelMode = "hard", -- "soft" or "hard"
                                progressColor = "chartreuse",
                                minigame = function()
                                    return lib.skillCheck({ 'easy', 'easy', 'easy' }, { 'w', 's', 'a' })
                                end,
                                onFinish = function()
                                    print("Skillcheck was successful")
                                end
                            },
                            {
                                message = "⌨️ Running Exploit...",
                                animation = {
                                    animDict = "anim@heists@humane_labs@emp@hack_door",
                                    anim = "hack_loop",
                                    flags = 1,
                                    duration = 5000,
                                    blendIn = 3.0,
                                    blendOut = 3.0,
                                },
                                duration = 15000,
                                cancelMode = "hard", -- "soft" or "hard"
                                progressColor = "chartreuse",
                                minigame = function()
                                    return lib.skillCheck({ 'easy', 'easy', 'easy' }, { 'w', 's', 'a' })
                                end,
                                onFinish = function()
                                    print("Skillcheck was successful")
                                end
                            },
                            {
                                message = "⌨️ Running Exploit...",
                                animation = {
                                    animDict = "anim@heists@humane_labs@emp@hack_door",
                                    anim = "hack_loop",
                                    flags = 1,
                                    duration = 5000,
                                    blendIn = 3.0,
                                    blendOut = 3.0,
                                },
                                duration = 15000,
                                cancelMode = "hard", -- "soft" or "hard"
                                progressColor = "chartreuse",
                                minigame = function()
                                    return lib.skillCheck({ 'easy', 'easy', 'easy' }, { 'w', 's', 'a' })
                                end,
                                onFinish = function()
                                    print("Skillcheck was successful")
                                end
                            },
                            {
                                message = "✅ Access Granted",
                                duration = 1000,
                                animation = {
                                    {
                                        animDict = "anim@heists@humane_labs@emp@hack_door",
                                        anim = "hack_outro",
                                        flags = 1,
                                        duration = 1000,
                                        blendIn = 8.0,
                                        blendOut = 8.0,
                                    }
                                }
                            }
                        }
                    }, function(cancelled, skill_check)
                        if not cancelled then
                            print("Hack complete! skillcheck->", skill_check)
                        else
                            print("Hack cancelled.")
                        end
                    end)
                end
            }
        }
    }
end

local triggered = false

local function action_on_animation()
    local object = spawn_object("ng_proc_box_01a", positions[2])

    exports['interactionMenu']:Create {
        entity = object,
        options = {
            {
                label = "Open Crate",
                icon = "fas fa-box-open",
                action = function(ent)
                    exports['keep-progressbar']:Start({
                        label = "Opening Crate",
                        icon = "fa-solid fa-box-open",

                        animations = {
                            {
                                animDict = "anim@heists@load_box",
                                anim = "lift_box",
                                duration = 3000,
                                flags = 2,
                                onStart = function()
                                    makeEntityFaceEntity(PlayerPedId(), object)
                                end,
                                onTick = function(frame)
                                    if not triggered and frame >= 1500 and frame <= 2000 then
                                        triggered = true
                                        AttachEntityToPlayer(object, {
                                            boneIndex = 60309,
                                            coords = vec3(0.135, -0.1, 0.22),
                                            rotation = vec3(-125.0, 100.0, 0.0),
                                        })
                                    end
                                end,
                                onFinish = function()
                                end
                            },
                            {
                                animDict = "anim@heists@box_carry@",
                                anim = "idle",
                                duration = 3000,
                            },
                        },
                        canCancel = true,
                        controlDisables = { disableMovement = true, disableCombat = true },
                        stages = {
                            { message = "Breaking lock...", duration = 3000 },
                            { message = "Opening door...",  duration = 2000 },
                        },
                    }, function(cancel, result)
                        if not cancel then
                            triggered = false
                            DeleteEntity(object)
                            print("✅ Crate opened!")
                        else
                            triggered = false
                            FreezeEntityPosition(object, false)
                            DetachEntity(object, true, true)
                            print("❌ Aborted opening crate.")
                        end
                    end)
                end
            }
        }
    }
end

local function many_stages_theme_position()
    local object = spawn_object("m23_2_prop_m32_sub_console_01a", positions[1])
    local stages = {}

    for i = 1, 10, 1 do
        stages[i] = {
            message = "Stage -> " .. i,
            duration = 500,
            onFinish = function()
                print(("Lua stage [%d] finished"):format(i))
            end
        }
    end

    exports['interactionMenu']:Create {
        entity = object,
        offset = vec3(0, 0, 0.5),
        options = {
            {
                label = "Hack",
                icon = "fa-solid fa-laptop-code",
                action = function(entity)
                    exports['keep-progressbar']:Start({
                        duration = 4000,
                        label = "Hacking military tech...",
                        icon = "fa-solid fa-laptop-code",
                        useWhileDead = false,
                        canCancel = true,
                        controlDisables = {
                            disableMovement = true,
                            disableCarMovement = true,
                            disableMouse = false,
                            disableCombat = true,
                        },
                        theme = "theme-1",
                        position = "center-top",
                        props = {
                            {
                                model = "prop_police_phone",
                                bone = 28422,
                                coords = vector3(0.00, 0.0, 0.0),
                                rotation = vector3(0.0, 0.0, 0.0),
                            }
                        },

                        stages = stages
                    }, function(cancelled)
                        print("Done")
                    end)
                end
            }
        }
    }
end

local trigger_condition = false

local function on_condition()
    local object = spawn_object("m24_1_prop_m41_jammer_01a", positions[1])

    exports['interactionMenu']:Create {
        entity = object,
        options = {
            {
                label = "Hack Military Tech",
                icon = "fa-solid fa-laptop-code",
                action = function(entity)
                    SetTimeout(10000, function()
                        trigger_condition = true
                    end)

                    exports['keep-progressbar']:Start({
                        label = "Hacking military tech...",
                        icon = "fa-solid fa-laptop-code",
                        useWhileDead = false,
                        canCancel = true,
                        controlDisables = {
                            disableMovement = true,
                            disableCarMovement = true,
                            disableMouse = false,
                            disableCombat = true,
                        },
                        stages = {
                            { message = "Breaking lock...", duration = 1000 },
                            {
                                message = "Opening door...",
                                duration = 2000,
                                condition = function()
                                    return trigger_condition
                                end
                            },
                            { message = "Opening door...",  duration = 2000 },
                        },
                    }, function(cancelled)
                        trigger_condition = false
                        if not cancelled then
                            print("Hack complete!")
                        else
                            print("Hack cancelled.")
                        end
                    end)
                end
            }
        }
    }
end

CreateThread(function()
    Wait(500)

    on_condition()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for key, value in pairs(objects) do
        if DoesEntityExist(value) then DeleteEntity(value) end
    end
end)
