# keep-progressbar

<center>

<img src=".github/images/keep-progressbar_cover.jpg"/>

</center>

A flexible, progress bar system for FiveM.  
Supports animations, props, stages/minigames, cancel/death monitoring, networked props with blacklist protection, and more.

## Features

- Multi-stage progress with optional **skill-check / minigame** support
- Animation helper with synchronized scenes and entity attachments
- Automatic cleanup server and client side
- Prop support: multiple props per action
- Customizable cancel button
- Animation hooks
- Themes

## Installation

### 1. Download

Clone or download this repository into your FiveM `resources` folder.

#### 1.1. QBCore

If using **QBCore**, move/delete the `progressbar` resource from your `[standalone]` and place `keep-progressbar` in `[standalone]`

```bash
resources/[standalone]/keep-progressbar
```

#### 1.2. ESX

If using **ESX**, move/delete the `esx_progressbar` resource from your `[core]` and place `keep-progressbar` in `[core]`

```bash
resources/[core]/keep-progressbar
```

### 1.3 ox_lib

To integrate progress bars made for **ox\_lib**:

1. First open:

   ```
   ox_lib/resource/interface/progress.lua
   ```

2. **Make a backup** of the file.
3. Delete all contents, then replace them with:

    ```lua
    function lib.progressBar(data)
        return exports['keep-progressbar']:ox_lib_progressBar(data)
    end

    function lib.progressCircle(data)
        return exports['keep-progressbar']:ox_lib_progressBar(data)
    end

    function lib.cancelProgress()
        exports['keep-progressbar']:cancelProgress()
    end

    function lib.progressActive()
        exports['keep-progressbar']:progressActive()
    end
    ```

4. Ensure it's loading before ox_lib and it's placed at `[standalont]`.

    ```bash
    resources/[standalone]/keep-progressbar
    ```

    ```cfg
    ensure keep-progressbar
    ensure ox_lib
    ```

## Usage

### Basic Usage

```lua
exports['keep-progressbar']:Start({
    duration = 5000,
    label = "Loading Crate",
    icon = "fa-solid fa-box",
    canCancel = true,
    useWhileDead = false,
    controlDisables = {
        disableMovement = true,
        disableCombat = true,
    },
    animation = {
        animDict = "anim@heists@box_crate@load",
        anim = "load_box",
        duration = 5000,
        lockX = true,
        lockY = false,
        lockZ = true,
    },
    prop = {
        model = "prop_crate_01a",
        bone = 28422,
        coords = vec3(0.0, 0.0, 0.0),
        rotation = vec3(0.0, 0.0, 0.0),
    }
}, function(cancelled)
    if not cancelled then
        print("✅ completed")
    else
        print("❌ Cancelled.")
    end
end)
```

### Multi-stage progress

```lua
exports['keep-progressbar']:Start({
    label = "Opening Crate",
    icon = "fa-solid fa-box-open",
    animation = {
        task = "WORLD_HUMAN_CLIPBOARD"
    },
    canCancel = true,
    controlDisables = { disableMovement = true, disableCombat = true },
    stages = {
        { message = "Breaking lock...", duration = 3000 },
        { message = "Opening door...", duration = 2000 },
    },
    props = {
        {
            model = "prop_ld_case_01",
            bone = 57005,
            coords = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0),
        },
    }
}, function(cancel, result)
    if not cancel then
        print("✅ Crate opened!")
    else
        print("❌ Aborted opening crate.")
    end
end)
```

## 📦 Examples

I’ve provided a bunch of examples for different features in `lua/examples.lua`

## `Start`

### Options

| Key               | Type       | Description                                                                                      |
|-------------------|------------|--------------------------------------------------------------------------------------------------|
| `duration`        | number(ms) | Total duration if no `stages` are used                                                           |
| `label`           | string     | Title of progress window                                                                         |
| `icon`            | string     | Icon (FontAwesome)                                                                               |
| `useWhileDead`    | boolean    | Allow while dead                                                                                 |
| `canCancel`       | boolean    | Whether player can progress cancel or not                                                        |
| `controlDisables` | table      | e.g. `{ disableMovement=true, disableCarMovement=true, disableMouse=false, disableCombat=true }` |
| `theme`           | string     | Optional theme name                                                                              |
| `position`        | string     | UI position (e.g. `center-top`)                                                                  |
| `offset`          | vec3       | Progress bar offset                                                                              |
| `prop`            | table      | Single prop attached during progress                                                             |
| `propTwo`         | table      | Single prop attached during progress                                                             |
| `props`           | table[]    | Array of props                                                                                   |
| `animation`       | table      | Single animation                                                                                 |
| `animations`      | table[]    | Array of animations                                                                              |
| `stages`          | table[]    | Array of stages                                                                                  |

**Prop, PropTwo, Props:**

| Field      | Type    | Description        |
|------------|---------|--------------------|
| `model`    | string  | Model name         |
| `bone`     | number  | Bone index         |
| `coords`   | vector3 | Offset coordinates |
| `rotation` | vector3 | Rotation           |

```lua
prop = {
    model = "prop_police_phone",
    bone = 28422,
    coords = vector3(0.00, 0.0, 0.0),
    rotation = vector3(0.0, 0.0, 0.0),
},
propTwo = {
    model = "prop_police_phone",
    bone = 28422,
    coords = vector3(0.00, 0.0, 0.0),
    rotation = vector3(0.0, 0.0, 0.0),
},
```

Or simply using an array

```lua
props = {
    {
        model = "prop_police_phone",
        bone = 28422,
        coords = vector3(0.00, 0.0, 0.0),
        rotation = vector3(0.0, 0.0, 0.0),
    }
}
```

**Animation:**

| Field      | Type   | Description                    |
|------------|--------|--------------------------------|
| `animDict` | string | Animation dictionary           |
| `anim`     | string | Animation name                 |
| `flags`    | number | Animation flags                |
| `duration` | number | Duration in ms                 |
| `blendIn`  | number | Blend-in speed                 |
| `blendOut` | number | Blend-out speed                |
| `onStart`  | func   | Called at start                |
| `onTick`   | func   | Called during, with frame time |
| `onFinish` | func   | Called after                   |

Single animation

```lua
animation = {
    animDict = "anim@heists@humane_labs@emp@hack_door",
    anim = "hack_loop",
},
```

Array of animations

```lua

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

```

### Stages

Each stage is a table inside `stages` array.

| Field           | Type    | Description                                                                         |
|-----------------|---------|-------------------------------------------------------------------------------------|
| `message`       | string  | Stage text shown to player                                                          |
| `duration`      | number  | Stage duration (ms)                                                                 |
| `progressColor` | string  | Optional color                                                                      |
| `animation`     | table   | Stage specific animation                                                            |
| `minigame`      | func    | Returns boolean or result                                                           |
| `cancelMode`    | boolean | Changes how minigame works: `hard` = reset/close on fail, `soft` = continue on fail |
| `onFinish`      | func    | Called when stage completes                                                         |
| `condition`     | func    | Must return true before stage proceeds                                              |

```lua

stages = {
    { message = "Breaking lock...", duration = 1000 },
    {
        message = "Opening door...",
        duration = 2000,
        condition = function()
            return trigger_condition
        end,
        minigame = function()
            return lib
                .skillCheck({ 'easy', 'easy' }, { 'w', 'a', 's', 'd' })
        end,
        animation = {
            animDict = "anim@heists@humane_labs@emp@hack_door",
            anim = "hack_intro",
            flags = 1,
            duration = 2500,
            blendIn = 3.0,
            blendOut = 3.0,
        }
    },
    { message = "Opening door...",  duration = 2000 },
},

```

### Callback

| Parameter   | Type | Description                    |
|-------------|------|--------------------------------|
| `cancelled` | bool | Whether progress was cancelled |
| `result`    | any  | Skill check outcome            |

```lua
exports['keep-progressbar']:Start({ ... }, function(cancelled, result)
  
end)
```
