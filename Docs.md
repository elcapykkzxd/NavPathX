# NavPathX Documentation

<p align="center">
  <img src="./banner.jpg" alt="NavPathX banner" width="500px">
</p>

Complete documentation for NavPathX - An optimized Pathfinding module for Roblox NPCs and Nextbots.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [API Reference](#api-reference)
  - [NavPathX.SetSettings()](#navpathxsetsettings)
  - [NavPathX.Run()](#navpathxrun)
  - [NavPathX.PathStop()](#navpathxpathstop)
  - [NavPathX.PathDestroy()](#navpathxpathdestroy)
- [Configuration](#configuration)
  - [Control Panel Settings](#control-panel-settings)
  - [Agent Parameters](#agent-parameters)
- [Usage Examples](#usage-examples)
  - [Basic Nextbot](#basic-nextbot)
  - [Patrolling NPC](#patrolling-npc)
  - [Advanced Zombie AI](#advanced-zombie-ai)
  - [Multiple NPCs Management](#multiple-npcs-management)
- [Visual Waypoints](#visual-waypoints)
- [Best Practices](#best-practices)
- [Performance Tips](#performance-tips)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)

## Overview

NavPathX is a powerful fork of SimplePath that provides enhanced pathfinding capabilities specifically designed for Roblox NPCs and Nextbots. 

### Key Features

- **Smart Pathfinding** - Intelligent obstacle avoidance and path computation
- **Automatic Jumping** - NPCs automatically jump over obstacles when needed
- **Visual Debugging** - See waypoints in real-time during development
- **Stuck Detection** - Automatic recovery when NPCs get stuck
- **Optimized Performance** - Designed for multiple NPCs without lag
- **Dynamic Targeting** - Support for both Vector3 positions and BasePart targets
- **Highly Configurable** - Extensive customization options

## Installation

### Step 1: Download the Module

Download or copy the `NavPathX.luau` ModuleScript from this repository.

### Step 2: Setup Folder Structure

Place the module in your game and create the required folder structure:

```
workspace/
└── botPathPoints/          (Folder - Contains visual waypoints during runtime)

ServerScriptService/
├── NavPathX                (ModuleScript - The main module)
└── botsCoreSSS/            (Folder)
    └── botsPathPoints/     (Folder)
        └── botPathPoint    (Part - Template for visual waypoints)
```

### Step 3: Configure botPathPoint

Create a Part named `botPathPoint` in `ServerScriptService/botsCoreSSS/botsPathPoints/`:

**Properties:**
- Shape: Ball or Block
- Size: Vector3.new(1, 1, 1)
- Transparency: 0.5
- CanCollide: false
- Anchored: true

This part will be used as a template for visual waypoints.

## Quick Start

Here's a minimal example to get you started:

```lua
local NavPathX = require(game.ServerScriptService.NavPathX)

-- Setup pathfinding for your NPC
local NPC = workspace.YourNPC
local Path = NavPathX.SetSettings(NPC, {}, false)

-- Main loop
while NPC and NPC.Parent do
    local target = workspace.TargetPart.Position
    NavPathX.Run(Path, target)
    task.wait(0.1)
end
```

## API Reference

### NavPathX.SetSettings()

Creates and initializes a new pathfinding instance for an NPC.

**Syntax:**
```lua
local Path = NavPathX.SetSettings(agent, agentParameters, visualize)
```

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `agent` | Model | Yes | - | The NPC model. Must contain a Humanoid and PrimaryPart/HumanoidRootPart |
| `agentParameters` | table | No | `{}` | Pathfinding configuration table (see [Agent Parameters](#agent-parameters)) |
| `visualize` | boolean | No | `false` | Enable visual waypoint debugging |

**Returns:**
- `Path` object if successful
- `nil` if configuration fails (invalid agent, missing Humanoid, etc.)

**Example:**
```lua
local Path = NavPathX.SetSettings(
    workspace.Zombie,
    {
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        WaypointSpacing = 4,
        Costs = {
            Water = math.huge,
            Mud = 5
        }
    },
    true -- Enable visualization during development
)

if not Path then
    warn("Failed to create path")
    return
end
```

### NavPathX.Run(Path)

Computes and executes pathfinding to the specified target.

**Syntax:**
```lua
local result = NavPathX.Run(Path, target)
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `target` | Vector3 or BasePart | Yes | Destination position or part to pathfind to |

**Returns:**
- `target` - Pathfinding succeeded and is executing
- `true` - Agent is in freefall state
- `nil` - Pathfinding failed (no path found, invalid target, etc.)

**Example:**
```lua
-- Pathfind to a position
local result = NavPathX.Run(Path, Vector3.new(100, 5, 100))

-- Pathfind to a part
NavPathX.Run(Path, workspace.Player.HumanoidRootPart)

-- Pathfind to player
local player = game.Players:GetChildren()[1]
if player and player.Character then
    NavPathX.Run(Path, player.Character.HumanoidRootPart)
end

-- Check result
if not result then
    print("Pathfinding failed")
end
```

### NavPathX.PathStop(Path)

Stops the current pathfinding operation and clears all visual waypoints.

**Syntax:**
```lua
NavPathX.PathStop(Path)
```

**Example:**
```lua
-- Stop when reaching destination
local distance = (NPC.HumanoidRootPart.Position - target.Position).Magnitude
if distance < 5 then
    NavPathX.PathStop(Path)
end

-- Stop on player command
game.ReplicatedStorage.StopNPC.OnServerEvent:Connect(function()
    NavPathX.PathStop(Path)
end)
```

### NavPathX.PathDestroy(Path)

Completely destroys the path instance and frees all resources. Call this when removing the NPC or when no longer needed.

**Syntax:**
```lua
NavPathX.PathDestroy(Path)
```

**Example:**
```lua
-- Cleanup on death
NPC.Humanoid.Died:Connect(function()
    NavPathX.PathDestroy(Path)
    NavPathX = nil
end)

-- Cleanup on removal
NPC.AncestryChanged:Connect(function(_, parent)
    if not parent then
        NavPathX.PathDestroy(Path)
        NavPathX = nil
    end
end)
```

## Configuration

### Control Panel Settings

Located at the top of the module. Modify these for global behavior:

```lua
local Settings = {
    TimeVariance = 0.01,
    ComparisonChecks = 1,
    CanJump = true
}
```

**Settings:**

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `TimeVariance` | number | 0.01 | Delay between pathfinding updates. Increase if NPCs cause lag (higher = less lag, slower pathfinding) |
| `ComparisonChecks` | number | 1 | Number of position checks before triggering stuck jump. Higher = less jumping, more stuck time |
| `CanJump` | boolean | true | Global jump enable/disable. Set to `false` to prevent all NPCs from jumping |

**Usage:**
```lua
-- For high-performance servers with many NPCs
Settings.TimeVariance = 0.05

-- For smoother movement with fewer NPCs
Settings.TimeVariance = 0.01

-- Disable jumping globally
Settings.CanJump = false
```

### Agent Parameters

Customize individual NPC pathfinding behavior:

```lua
local agentParams = {
    AgentRadius = 2,
    AgentHeight = 5,
    AgentCanJump = true,
    AgentCanClimb = false,
    WaypointSpacing = 4,
    Costs = {}
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `AgentRadius` | number | 2 | Collision radius in studs. Should match NPC width |
| `AgentHeight` | number | 5 | Character height in studs. Should match NPC height |
| `AgentCanJump` | boolean | true | Whether this specific agent can jump |
| `AgentCanClimb` | boolean | false | Whether agent can climb TrussParts |
| `WaypointSpacing` | number | 4 | Distance between waypoints in studs. Lower = more precise, higher = more optimized |
| `Costs` | table | `{}` | Material traversal costs (see below) |

**Material Costs:**

Control how NPCs navigate different materials:

```lua
Costs = {
    Water = math.huge,      -- Never pathfind through water
    Mud = 10,               -- Strongly avoid mud
    Grass = 1,              -- Neutral (default cost)
    Concrete = 0.5          -- Prefer concrete paths
}
```

Available materials: Water, Mud, Grass, Concrete, Sand, Snow, Ice, etc. See [Roblox Materials](https://create.roblox.com/docs/reference/engine/enums/Material) for the complete list.

## Usage Examples

### Basic Nextbot

Simple chasing AI that follows the nearest player:

```lua
local NavPathX = require(game.ServerScriptService.NavPathX)

local function createNextbot(npc)
    local Path = NavPathX.SetSettings(npc, {
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true
    })
    
    if not Path then
        warn("Failed to create path for", npc.Name)
        return
    end
    
    -- Chase loop
    while npc and npc.Parent and npc.Humanoid.Health > 0 do
        local nearestPlayer = nil
        local shortestDistance = math.huge
        
        for _, player in pairs(game.Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local distance = (npc.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                
                if distance <= shortestDistance then
                    shortestDistance = distance
                    nearestPlayer = player
                end
            end
        end
        
        if nearestPlayer and nearestPlayer.Character then
            NavPathX.Run(Path, nearestPlayer.Character.HumanoidRootPart)
        end
        
        task.wait(0.1)
    end
    
    NavPathX.PathDestroy(Path)
end

-- Spawn nextbot
local zombie = workspace.Zombie
createNextbot(zombie)
```

### Patrolling NPC

Guard that patrols between waypoints:

```lua
local NavPathX = require(game.ServerScriptService.NavPathX)

local function createPatrolNPC(npc, waypointFolder)
    local waypoints = waypointFolder:GetChildren()
    
    if #waypoints == 0 then
        warn("No waypoints found")
        return
    end
    
    local Path = NavPathX.SetSettings(npc, {
        WaypointSpacing = 3
    }, true)
    
    local currentIndex = 1
    
    while npc and npc.Parent and npc.Humanoid.Health > 0 do
        local targetWaypoint = waypoints[currentIndex]
        
        -- Navigate to waypoint
        NavPathX.Run(Path, targetWaypoint.Position)
        
        -- Wait until close enough
        repeat
            task.wait(0.1)
            if not npc.Parent then break end
        until (npc.HumanoidRootPart.Position - targetWaypoint.Position).Magnitude < 5
        
        -- Pause at waypoint
        NavPathX.PathStop(Path)
        task.wait(2)
        
        -- Move to next waypoint
        currentIndex = currentIndex % #waypoints + 1
    end
    
    NavPathX.PathDestroy(Path)
end

-- Usage
local guard = workspace.Guard
local patrolPoints = workspace.PatrolPoints
createPatrolNPC(guard, patrolPoints)
```

### Advanced Zombie AI

Zombie with detection range and attack behavior:

```lua
local NavPathX = require(game.ServerScriptService.NavPathX)

local DETECTION_RANGE = 50
local ATTACK_RANGE = 5
local DAMAGE = 10

local function createZombie(zombie)
    local Path = NavPathX.SetSettings(zombie, {
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        Costs = {
            Water = math.huge
        }
    })
    
    local attacking = false
    
    local function findTarget()
        local nearestPlayer = nil
        local shortestDistance = DETECTION_RANGE
        
        for _, player in pairs(game.Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local humanoid = player.Character:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local distance = (zombie.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                    
                    if distance <= shortestDistance then
                        shortestDistance = distance
                        nearestPlayer = player
                    end
                end
            end
        end
        
        return nearestPlayer, shortestDistance
    end
    
    local function attack(target)
        if attacking then return end
        attacking = true
        
        local humanoid = target.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:TakeDamage(DAMAGE)
        end
        
        task.wait(1)
        attacking = false
    end
    
    -- Main loop
    while zombie and zombie.Parent and zombie.Humanoid.Health > 0 do
        local target, distance = findTarget()
        
        if target and target.Character then
            if distance <= ATTACK_RANGE then
                NavPathX.PathStop(Path)
                attack(target)
            else
                NavPathX.Run(Path, target.Character.HumanoidRootPart)
            end
        else
            NavPathX.PathStop(Path)
        end
        
        task.wait(0.15)
    end
    
    NavPathX.PathDestroy(Path)
end

-- Spawn zombies
for _, zombie in pairs(workspace.Zombies:GetChildren()) do
    task.spawn(createZombie, zombie)
end
```

### Multiple NPCs Management

Managing multiple NPCs efficiently:

```lua
local NavPathX = require(game.ServerScriptService.NavPathX)

local NPCManager = {}
NPCManager.ActiveNPCs = {}

function NPCManager:CreateNPC(npcModel, config)
    local Path = NavPathX.SetSettings(npcModel, config or {})
    
    if not Path then
        warn("Failed to create NPC:", npcModel.Name)
        return nil
    end
    
    local npcData = {
        Model = npcModel,
        Path = NavPathX,
        PathSettings = Path,
        Target = nil,
        Active = true
    }
    
    table.insert(self.ActiveNPCs, npcData)
    
    -- Cleanup on death
    npcModel.Humanoid.Died:Connect(function()
        self:RemoveNPC(npcData)
    end)
    
    return npcData
end

function NPCManager:RemoveNPC(npcData)
    npcData.Active = false
    npcData.Path.PathDestroy(npcData.PathSettings)
    
    local index = table.find(self.ActiveNPCs, npcData)
    if index then
        table.remove(self.ActiveNPCs, index)
    end
end

function NPCManager:UpdateAll()
    for _, npcData in pairs(self.ActiveNPCs) do
        if npcData.Active and npcData.Target then
            npcData.Path.Run(npcData.PathSettings, npcData.Target)
        end
    end
end

function NPCManager:SetTarget(npcData, target)
    npcData.Target = target
end

-- Usage
local zombie1 = NPCManager:CreateNPC(workspace.Zombie1, {AgentRadius = 2})
local zombie2 = NPCManager:CreateNPC(workspace.Zombie2, {AgentRadius = 2})

-- Update loop
while true do
    local player = game.Players:GetChildren()[1]
    if player and player.Character then
        for _, npcData in pairs(NPCManager.ActiveNPCs) do
            NPCManager:SetTarget(npcData, player.Character.HumanoidRootPart)
        end
    end
    
    NPCManager:UpdateAll()
    task.wait(0.1)
end
```

## Visual Waypoints

When visualization is enabled, waypoints appear with different colors:

| Color | Meaning |
|-------|---------|
| White | Normal walking waypoint |
| Green | Jump waypoint |
| Red | Final destination |

**Enable visualization:**
```lua
local Path = NavPathX.SetSettings(npc, {}, true)
```

**Note:** Always disable visualization in production for better performance.

## Best Practices

### Proper Initialization

Always check if the path was created successfully:

```lua
local Path = NavPathX.SetSettings(npc, {})

if not Path then
    warn("Path creation failed")
    return
end
```

### Update Frequency

Balance performance and responsiveness:

```lua
-- Fast-moving targets (players)
task.wait(0.1)

-- Slow-moving or stationary targets
task.wait(0.3)

-- Patrol routes
task.wait(0.2)
```

### Cleanup

Always clean up paths when done:

```lua
-- On death
npc.Humanoid.Died:Connect(function()
    if NavPathX then
        NavPathX.PathDestroy(Path)
        NavPathX = nil
    end
end)

-- On removal
npc.AncestryChanged:Connect(function(_, parent)
    if not parent and NavPathX then
        NavPathX.PathDestroy(Path)
        NavPathX = nil
    end
end)
```

### Error Handling

Use pcall for critical operations:

```lua
local success, err = pcall(function()
    NavPathX.Run(Path, target)
end)

if not success then
    warn("Pathfinding error:", err)
    NavPathX.PathStop(Path)
end
```

### Agent Parameters

Match parameters to NPC size:

```lua
-- Small NPC
AgentRadius = 1
AgentHeight = 3

-- Normal NPC
AgentRadius = 2
AgentHeight = 5

-- Large NPC
AgentRadius = 4
AgentHeight = 8
```

## Performance Tips

### Optimize for Many NPCs

1. **Increase TimeVariance**
```lua
Settings.TimeVariance = 0.05  -- From default 0.01
```

2. **Use larger WaypointSpacing**
```lua
WaypointSpacing = 6  -- From default 4
```

3. **Reduce update frequency**
```lua
task.wait(0.2)  -- Instead of 0.1
```

4. **Disable visualization**
```lua
local Path = NavPathX.SetSettings(npc, {}, false)
```

### Optimization Example

```lua
local MAX_NPCS = 20
local UPDATE_INTERVAL = 0.15

local function optimizedNextbot(npc)
    local Path = NavPathX.SetSettings(npc, {
        WaypointSpacing = 6,
        AgentRadius = 2
    }, false)  -- Visualization off
    
    while npc and npc.Parent do
        -- Your pathfinding logic
        NavPathX.Run(Path, target)
        task.wait(UPDATE_INTERVAL)
    end
    
    NavPathX.PathDestroy(Path)
end
```

### Memory Management

Clean up unused NPCs:

```lua
local function cleanupInactive()
    for i = #NPCManager.ActiveNPCs, 1, -1 do
        local npcData = NPCManager.ActiveNPCs[i]
        if not npcData.Model.Parent then
            npcData.Path.PathDestroy(npcData.PathSettings)
            table.remove(NPCManager.ActiveNPCs, i)
        end
    end
end

-- Run periodically
while true do
    task.wait(10)
    cleanupInactive()
end
```

## Troubleshooting

### NPC Won't Move

**Possible causes:**

1. Missing Humanoid
```lua
-- Check
if not npc:FindFirstChild("Humanoid") then
    warn("No Humanoid found")
end
```

2. Missing PrimaryPart
```lua
-- Check
if not npc.PrimaryPart then
    warn("No PrimaryPart set")
    npc.PrimaryPart = npc:FindFirstChild("HumanoidRootPart")
end
```

3. Target unreachable
```lua
local result = Path:Run(target)
if not result then
    warn("No path found to target")
end
```

### NPC Gets Stuck

**Solutions:**

1. Increase ComparisonChecks for more aggressive unstucking:
```lua
Settings.ComparisonChecks = 3
```

2. Enable jumping:
```lua
Settings.CanJump = true
AgentCanJump = true
```

3. Adjust agent size:
```lua
AgentRadius = 2.5  -- Increase if NPC is larger
```

### Pathfinding Fails

**Check these:**

1. Obstacles blocking path
2. Target in unanchored/moving parts
3. Agent parameters too restrictive
4. Invalid target (nil, destroyed, etc.)

```lua
-- Validation
if not target or not target:IsDescendantOf(workspace) then
    warn("Invalid target")
    return
end
```

### Performance Issues

**Solutions:**

1. Reduce number of active NPCs
2. Increase TimeVariance
3. Lower update frequency
4. Disable visualization
5. Use larger WaypointSpacing

```lua
-- Performance preset
Settings.TimeVariance = 0.05
local Path = NavPathX.SetSettings(npc, {
    WaypointSpacing = 8
}, false)
task.wait(0.2)  -- In your loop
```

### Visual Waypoints Not Showing

**Check:**

1. Visualization enabled:
```lua
local Path = NavPathX.SetSettings(npc, {}, true)
```

2. Folder structure exists:
```
workspace/botPathPoints
ServerScriptService/botsCoreSSS/botsPathPoints/botPathPoint
```

3. botPathPoint part properly configured

## FAQ

**Q: Can I use this with non-humanoid NPCs?**

A: NavPathX requires a Humanoid component. For non-humanoid movement, you'll need to modify the module or use a different approach.

**Q: How many NPCs can I run simultaneously?**

A: Depends on your game's complexity and server resources. Typically 20-50 NPCs work well with proper optimization. Use the performance tips section for better results.

**Q: Does this work with R15 and R6?**

A: Yes, NavPathX works with both R15 and R6 character rigs.

**Q: Can NPCs navigate moving platforms?**

A: NavPathX recalculates paths regularly, so NPCs can adapt to moving platforms, but may struggle with very fast-moving or unpredictable platforms.

**Q: How do I make NPCs avoid certain areas?**

A: Use material costs or place invisible parts with high-cost materials in areas you want NPCs to avoid.

```lua
Costs = {
    Mud = math.huge  -- NPCs will never pathfind through mud
}
```

**Q: Can I make NPCs swim?**

A: NavPathX doesn't have built-in swimming. NPCs will avoid water by default. You can allow water pathfinding with:

```lua
Costs = {
    Water = 1  -- Allow water pathfinding
}
```

But you'll need to implement custom swimming animations and movement.

**Q: Is this compatible with other pathfinding modules?**

A: NavPathX is standalone and doesn't require other modules. Using multiple pathfinding systems on the same NPC may cause conflicts.

**Q: How do I contribute?**

A: Check the main README.md for contribution guidelines, or open an issue on GitHub.

---

## Credits

- **[GrayzcaIe](https://github.com/grayzcale)** - SimplePath Creator
- **[elcapykkzxd](https://github.com/elcapykkzxd)** - NavPathX Owner
- **[Asdfyc123](https://www.roblox.com/users/3669138152/profile)** - NavPathX Contributor
- **[boydev1444](https://github.com/boydev-1444)** - NavPathX Contributor

## License

MIT License - See LICENSE file for details

---


For more information, visit the [GitHub Repository](https://github.com/elcapykkzxd/NavPath-X)



