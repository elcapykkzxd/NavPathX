--[[**
-------------------------------------------------------------------
TODO: This ModuleScript is for smart Pathfinding (especially for Node entities) that improves original SimplePath and PathfindingService!
Last Update: 29-11-2025
License: MIT

SimplePath Created by: @GrayzcaIe
Modified by: @Papisteve79
Lil Modifying Helper: @Asdfyc123
SimplePath Reference: https://grayzcale.github.io/simplepath/
SimplePath License: MIT
Shoutout to: @Dragoteryx, creator of DrGBase.
DrGBase Reference: https://github.com/Dragoteryx/drgbase

Special thanks to everyone involved in this project and the Open-Source contributors who made this possible. excellent work by all of them!
-------------------------------------------------------------------
**]]--

-----------------------------------------------------
local ServerScriptService = game:GetService("ServerScriptService")
local PathfindingService = game:GetService("PathfindingService")
local PathConfig = {}
PathConfig.__index = PathConfig
local function Log(Level: "print" | "warn" | "error" | "assert", msg, Condition)
	if Level == "print" then
		print(`[{script.Name} Log]: {msg}`)
	elseif Level == "warn" then
		warn(`[{script.Name} warn]: {msg}`)
	elseif Level == "error" then
		error(`[{script.Name} error]: {msg}`)
	elseif Level == "assert" then
		assert(Condition, `[{script.Name} assert Fail]: {msg}`)
	end
end

local botPathPoints = workspace.botPathPoints
local botsCoreSSS = ServerScriptService.botsCoreSSS
local botsPathPoints = botsCoreSSS.botsPathPoints
local visualWaypoint = botsPathPoints.botPathPoint
local function CreateVisualWaypoints(Waypoints)
	local VisualWaypoints = {}
	for i, Waypoint: PathWaypoint in ipairs(Waypoints) do
		local VisualWaypointClone = visualWaypoint:Clone()
		VisualWaypointClone.Name = tostring(i)
		VisualWaypointClone.Position = Waypoint.Position
		VisualWaypointClone.Locked = true
		VisualWaypointClone.Transparency = 0
		VisualWaypointClone.Color = (Waypoint == Waypoints[#Waypoints] and Color3.fromRGB(255, 0, 0)) or (Waypoint.Action == Enum.PathWaypointAction.Jump and Color3.fromRGB(112, 255, 172)) or (Waypoint.Action == Enum.PathWaypointAction.Walk and Color3.fromRGB(255, 255, 255))
		VisualWaypointClone.Parent = botPathPoints
		if VisualWaypointClone.Transparency == 1 then
			VisualWaypointClone:Destroy()
			VisualWaypointClone = nil
		else
			table.insert(VisualWaypoints, VisualWaypointClone)
		end
	end
	return VisualWaypoints
end

local function DestroyVisualWaypoints(Waypoints2)
	if Waypoints2 then
		for i2, Waypoint2 in ipairs(Waypoints2) do
			if Waypoint2 and Waypoint2:IsA("BasePart") then
				Waypoint2:Destroy()
				Waypoints2[i2] = nil
			end
		end
	end
	return Waypoints2
end

local function GetNonHumanoidWaypoint(self)
	for k = 2, #self._Waypoints do
		if (self._Waypoints[k].Position - self._Waypoints[k - 1].Position).Magnitude > 1 then
			return k
		end
	end
	return 2
end

local function DisconnectMoveConnection(self)
	if not getmetatable(self) then
		return
	end
	if self._MoveConnection and self._MoveConnection.Connected then
		pcall(self._MoveConnection.Disconnect, self._MoveConnection)
		self._MoveConnection = nil
	end
end

function PathConfig.SetSettings(agent, agentParameters, Visualize)
	local WarnMessage = ""
	if WarnMessage ~= "" then
		Log("warn", debug.traceback(`{WarnMessage}`))
		return nil
	end
	if type(agentParameters) ~= "table" then
		Log("warn", debug.traceback(`Invalid agentParameters: expected a table (type: {typeof(agentParameters)})`))
	end
	local Path: Path = PathfindingService:CreatePath(agentParameters)
	local self = setmetatable({
		_agent = agent,
		_Path = Path,
		_Waypoints = {},
		_CurrentWaypoint = 1,
		_target = nil,
		_Visualize = Visualize or false,
		_OriginalVisualize = Visualize or false,
		_VisualWaypoints = {},
	}, PathConfig)
	return self
end

local function SafeDestroyVisualWaypoints(self)
	if rawget(self, "_VisualWaypoints") == nil then
		Log("warn", debug.traceback(`Attempt to destroy visual waypoints but _VisualWaypoints is nil`))
		rawset(self, "_VisualWaypoints", {})
		return
	end
	if self._VisualWaypoints then
		DestroyVisualWaypoints(self._VisualWaypoints)
		self._VisualWaypoints = nil
	end
end

function PathConfig.PathDestroy(self)
	if not getmetatable(self) then
		return
	end
	SafeDestroyVisualWaypoints(self)
	if rawget(self, "_Path") and self._Path then
		pcall(self._Path.Destroy, self._Path)
		self._Path = nil
	end
	table.clear(self)
	setmetatable(self, nil)
end

function PathConfig.PathStop(self)
	if not getmetatable(self) then
		return
	end
	if rawget(self, "_VisualWaypoints") == nil then
		Log("warn", debug.traceback(`Attempt to call PathConfig.PathStop(self), _VisualWaypoints is nil`))
		rawset(self, "_VisualWaypoints", {})
	end
	DisconnectMoveConnection(self)
	self._VisualWaypoints = DestroyVisualWaypoints(self._VisualWaypoints)
end

export type Goal = Vector3 | BasePart
function PathConfig.Run(self, target: Goal?)
	if not self._agent:IsDescendantOf(workspace) then
		self._Visualize = false
	else
		self._Visualize = self._OriginalVisualize
	end
	if not (target and (typeof(target) == "Vector3" or target:IsA("BasePart"))) then
		Log("warn", debug.traceback(`target must be a valid Vector3 or BasePart.`))
		return nil
	end
	local PathComputed, _ = pcall(self._Path.ComputeAsync, self._Path, self._agent.Position, target)
	if not PathComputed or self._Path.Status == Enum.PathStatus.NoPath or #self._Path:GetWaypoints() < 2 then
		self._VisualWaypoints = DestroyVisualWaypoints(self._VisualWaypoints)
		return nil
	end
	if self._target ~= target then
		self._target = target
	end
	self._Waypoints = self._Path:GetWaypoints()
	self._CurrentWaypoint = 2
	DestroyVisualWaypoints(self._VisualWaypoints)
	if self._Visualize then
		self._VisualWaypoints = CreateVisualWaypoints(self._Waypoints)
	else
		self._VisualWaypoints = {}
	end
	if #self._Waypoints == 2 then
		self._VisualWaypoints = DestroyVisualWaypoints(self._VisualWaypoints)
	else
		self._CurrentWaypoint = GetNonHumanoidWaypoint(self)
	end
	task.wait()
	return self._target
end
return PathConfig
