--[[
=======================================================================
NavPathX Smart AI Navigation System Module - Non-Humanoid Edition
Version: 1.0.1 | Last Updated: 2026-01-22
=======================================================================
Authors:
  - @Papisteve79 (Lead Developer)
  - @Asdfyc123 (Helper)
  - @xXPRO2929_XDXx (Inspiration/Helper)

Open-Source Helpers:
  - @GrayzcaIe (SimplePath Creator)

Licenses:
  - NavPathX License: MIT
  - SimplePath License: MIT

Inspirations:
  - @GrayzcaIe (SimplePath Creator)
  - @xXPRO2929_XDXx (Inspiration/Helper)
  - @Dragoteryx (DrGBase Creator)

References:
  - https://github.com/elcapykkzxd/NavPathX
  - https://grayzcale.github.io/simplepath/ | https://github.com/grayzcale/simplepath
  - https://github.com/Dragoteryx/drgbase
=======================================================================
]]--

--------[[ DEBUG ZONE ]]--------
--[[local Settings = {
	TimeVariance = 0.01, -- TODO: Pathfinding delay for lag compensation (higher = less lag but slower | lower = more lag but faster)
}]]
-------------------------------------------------------------------
local PathConfig = {}
PathConfig.__index = PathConfig
local scriptName = script.Name
local function Log(level, Msg, Condition)
	local ValidLevels = {
		print = true,
		warn = true,
		error = true,
		assert = true
	}
	if not ValidLevels[level] then
		level = "print"
	end
	local Prefix = `[{scriptName} {level}]: `
	if level == "print" then
		print(Prefix .. Msg)
	elseif level == "warn" then
		warn(Prefix .. Msg)
	elseif level == "error" then
		error(Prefix .. Msg)
	elseif level == "assert" then
		assert(Condition, Prefix .. Msg)
	end
end

local PathWaypoints = workspace.PathWaypoints
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VisualWaypoint = ReplicatedStorage.VisualWaypoint
local function CreateVisualWaypoints(Waypoints)
	local VisualWaypoints = {}
	for i, Waypoint: PathWaypoint in ipairs(Waypoints) do
		local VisualWaypointClone = VisualWaypoint:Clone()
		VisualWaypointClone.Name = tostring(i)
		VisualWaypointClone.Position = Waypoint.Position
		VisualWaypointClone.Locked = true
		VisualWaypointClone.Transparency = 0
		VisualWaypointClone.Color = (Waypoint == Waypoints[#Waypoints] and Color3.fromRGB(255, 0, 0)) or (Waypoint.Action == Enum.PathWaypointAction.Jump and Color3.fromRGB(112, 255, 172)) or (Waypoint.Action == Enum.PathWaypointAction.Walk and Color3.fromRGB(255, 255, 255))
		VisualWaypointClone.Parent = PathWaypoints
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
		for k, Waypoint2 in ipairs(Waypoints2) do
			if Waypoint2 and Waypoint2:IsA("BasePart") then
				Waypoint2:Destroy()
				Waypoints2[k] = nil
			end
		end
	end
	return Waypoints2
end

local function GetNonHumanoidWaypoint(self)
	for j = 2, #self._Waypoints do
		if (self._Waypoints[j].Position - self._Waypoints[j - 1].Position).Magnitude > 1 then
			return j
		end
	end
	return 2
end

local PathfindingService = game:GetService("PathfindingService")
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
		--_Time = 0
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
	self._VisualWaypoints = DestroyVisualWaypoints(self._VisualWaypoints)
end

export type Goal = Vector3 | BasePart
function PathConfig.Run(self, target: Goal?)
	if self._agent and not self._agent:IsDescendantOf(workspace) then
		DestroyVisualWaypoints(self._VisualWaypoints)
		self._Visualize = false
	else
		self._Visualize = self._OriginalVisualize
	end
	if not (target and (typeof(target) == "Vector3" or target:IsA("BasePart"))) then
		Log("warn", debug.traceback(`target must be a valid Vector3 or BasePart.`))
		return nil
	end
	--[[if os.clock() - self._Time <= Settings.TimeVariance and self._agent and self._agent:IsDescendantOf(workspace) then
		task.wait(os.clock() - self._Time)
		return false
	elseif self._agent and self._agent:IsDescendantOf(workspace) then
		self._Time = os.clock()
	end]] -- Enable this if you feel your NPC too laggy (you need Enable _Time = 0 in PathConfig.new(...) function)
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
