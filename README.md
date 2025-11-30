<p align="center">
  <img src="./banner.jpg" alt="NavPathX banner" width="500px" height=auto>
</p>
<h1 align="center">NavPathX</h1>

- A forked and optimized version of the pathfinding tool called [SimplePath](https://github.com/grayzcale/simplepath) module.
- Documentation [here](https://github.com/elcapykkzxd/NavPathX/blob/main/Docs.md)
## Credits:
- [GrayzcaIe](https://github.com/grayzcale)
  - SimplePath Creator.

- [elcapykkzxd](https://github.com/elcapykkzxd)
  - NavPathX owner.

- [Asdfyc123](https://www.roblox.com/users/3669138152/profile)
  - NavPathX Contributor.

- [boydev1444](https://github.com/boydev-1444)
  - NavPathX Contributor.
  - Teached how to make smart pathfinding systems.

## Initialization
- As a "fork" of SimplePath, the function names got renamed.
- Initialization is below this message.
```lua
local NavPathX = require("@self/NavPathX") -- Or "NavPathX.lua(u)?"
local Path = NavPathX.SetSettings( 
    Model : <Instance : Model>,  -- Pathfinding Agent.
    AgentParameters <table? : { [string] : any }>, -- Default agent parameters.
    VisualizePathfinding : <boolean? : true/false>  -- If visualize the pathfinding operations.
) :: <table { -- Must be called as namecall (NavPathX.NAMECALL(Path, target))
   NavPathX.Destroy : function, -- Destroys the path.
   NavPathX.Stop : function, -- Stops the current pathfinding.
   NavPathX.Run : function, -- Begins pathfinding to goal.
}>

```
