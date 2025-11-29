<p align="center">
  <img src="./banner.jpg" alt="NavPathX banner" width="500px" height=auto>
</p>
<h1 align="center">NavPath X</h1>

- A forked and optimized version of the pathfinding tool called [SimplePath](https://github.com/grayzcale/simplepath) module.

## Credits:
- [GrayzcaIe](https://github.com/grayzcale)
  - SimplePath Creator.

- [elcapykkzxd](https://github.com/elcapykkzxd)
  - NavPath X owner.

- [Asdfyc123](https://www.roblox.com/users/3669138152/profile)
  - NavPath X Contributor.

- [boydev1444](https://github.com/boydev-1444)
  - NavPath X Contributor.
  - Teached how to make smart pathfinding systems.

## Initialization
- As a "fork" of SimplePath, the function names got renamed.
- Initialization is below this message.
```lua
local NavPathX = require("@self/NavPathX") -- Or "Navpath.lua(u)?"
local Path = NavPathX.SetSettings( 
    Model : <Instance : Model>,  -- Pathfinding Agent.
    AgentParameters <table? : { [string] : any }>, -- Default agent parameters.
    VisualizePathfinding : <boolean? : true/false>  -- If visualize the pathfinding operations.
) :: <table { -- Must be called as namecall (Path:NAMECALL)
   PathDestroy : function, -- Destroys the path.
   PathStop : function, -- Stops the current pathfinding.
   Run : function, -- Begins pathfinding to goal.
}>

```