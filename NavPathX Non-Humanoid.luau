--[[
=======================================================================
NavPathX Smart AI Navigation System Module - Non-Humanoid Edition
Version: 1.2.2 | Last Updated: 2026-02-22
=======================================================================
Authors:
  - @Papisteve79 (Lead Developer)
  - @Asdfyc123 (Helper)
  - @xXPRO2929_XDXx (Helper/Inspiration)

Open-Source Helpers:
  - @GrayzcaIe (SimplePath Creator)

Licenses:
  - NavPathX License: MIT
  - SimplePath License: MIT

Inspirations:
  - @GrayzcaIe (SimplePath Creator)
  - @xXPRO2929_XDXx (Inspiration/Helper)

References:
  - https://github.com/elcapykkzxd/NavPathX
  - https://grayzcale.github.io/simplepath/ | https://github.com/grayzcale/simplepath
=======================================================================
]]--

local PathConfig = {}
PathConfig.__index = PathConfig
local scriptName = script.Name
local function Log(Level, Msg, Condition)
	local Prefix = `[{scriptName} {Level}]: `
	if Level == "info" then
		print(Prefix .. Msg)
	elseif Level == "warn" then
		warn(Prefix .. Msg)
	elseif Level == "error" then
		error(Prefix .. Msg)
	elseif Level == "assert" then
		assert(Condition, Prefix .. Msg)
	else
		print(`[{scriptName} info]: ` .. Msg)
	end
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WaypointTemplate = ReplicatedStorage.WaypointTemplate
local VisualWaypoint = WaypointTemplate.VisualWaypoint
local function CreateVisualWaypoints(Waypoints, ParentFolder)
	local VisualWaypoints = {}
	for i, Waypoint: PathWaypoint in ipairs(Waypoints) do
		local VisualWaypointClone = VisualWaypoint:Clone()
		VisualWaypointClone.Name = tostring(i)
		VisualWaypointClone.Position = Waypoint.Position
		VisualWaypointClone.Locked = true
		VisualWaypointClone.Transparency = 0
		VisualWaypointClone.Color = (Waypoint == Waypoints[#Waypoints] and Color3.fromRGB(255, 0, 0)) or (Waypoint.Action == Enum.PathWaypointAction.Jump and Color3.fromRGB(112, 255, 172)) or (Waypoint.Action == Enum.PathWaypointAction.Walk and Color3.fromRGB(255, 255, 255))
		VisualWaypointClone.Parent = ParentFolder
		table.insert(VisualWaypoints, VisualWaypointClone)
	end
	return VisualWaypoints
end

local function DestroyVisualWaypoints(self, Waypoints2)
	if Waypoints2 then
		for k, Waypoint2 in ipairs(Waypoints2) do
			if Waypoint2:IsA("BasePart") and Waypoint2:IsDescendantOf(self._CustomFolder) then
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
function PathConfig.SetSettings(agent, agentParameters, Visualize, CustomFolder)
	local HasPosition = agent:IsA("BasePart") or (agent:IsA("Model") and (agent.PrimaryPart or agent:FindFirstChildOfClass("BasePart")))
	Log("assert", debug.traceback("agent must have a valid position source (BasePart or Model with a BasePart)"), HasPosition)
	if agentParameters and type(agentParameters) ~= "table" then
		Log("warn", `Invalid agentParameters: table expected, got {typeof(agentParameters)}`)
	end
	local NewFolder = CustomFolder
	if not NewFolder then
		NewFolder = Instance.new("Folder", workspace)
		NewFolder.Name = `{agent.Name}Waypoints_{string.format("%x", tick() * 1e3)}`
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
		_CustomFolder = NewFolder,
		--_Time = 0
	}, PathConfig)
	self._Path.Blocked:Connect(function(blockedWaypointIdx)
		if type(blockedWaypointIdx) ~= "number" then
			Log("warn", `blockedWaypointIdx is not a number (type: {typeof(blockedWaypointIdx)})`)
			return
		end
		if self._target then
			self:Run(self._target)
		end
	end)
	return self
end

local function SafeDestroyVisualWaypoints(self)
	if rawget(self, "_VisualWaypoints") == nil then
		Log("warn", `Attempt to destroy visual waypoints: _VisualWaypoints is {typeof(self._VisualWaypoints)}`)
		rawset(self, "_VisualWaypoints", {})
		return
	end
	if self._VisualWaypoints then
		DestroyVisualWaypoints(self, self._VisualWaypoints)
		self._VisualWaypoints = nil
	end
end

function PathConfig:PathDestroy()
	if not getmetatable(self) then
		return
	end
	SafeDestroyVisualWaypoints(self)
	if rawget(self, "_Path") and self._Path then
		pcall(self._Path.Destroy, self._Path)
		self._Path = nil
	end
	if rawget(self, "_CustomFolder") and self._CustomFolder and self._CustomFolder.Parent then
		pcall(self._CustomFolder.Destroy, self._CustomFolder)
		self._CustomFolder = nil
	end
	self._agent = nil
	self._Waypoints = nil
	self._target = nil
end

function PathConfig:PathStop()
	if not getmetatable(self) then
		return
	end
	if rawget(self, "_VisualWaypoints") == nil then
		Log("warn", `Attempt to call PathConfig:PathStop(): _VisualWaypoints is {typeof(self._VisualWaypoints)}`)
		rawset(self, "_VisualWaypoints", {})
	end
	self._VisualWaypoints = DestroyVisualWaypoints(self, self._VisualWaypoints)
end

export type Goal = Vector3 | BasePart
function PathConfig:Run(target: Goal?)
	if not getmetatable(self) then
		return nil
	end
	if not self._agent:IsDescendantOf(workspace) then
		DestroyVisualWaypoints(self, self._VisualWaypoints)
		self._Visualize = false
	else
		self._Visualize = self._OriginalVisualize
	end
	if not (target and (typeof(target) == "Vector3" or target:IsA("BasePart"))) then
		Log("warn", `target must be a valid Vector3 or BasePart.`)
		return nil
	end
	--[[if os.clock() - self._Time <= self._Settings.TimeVariance and self._PrimaryPart then
		task.wait(os.clock() - self._Time)
		return false
	elseif self._PrimaryPart then
		self._Time = os.clock()
	end]] -- Uncomment this if you feel your NPC too laggy (Also you need uncomment _Time in PathConfig.SetSettings() function)
	local PathComputed, _ = pcall(self._Path.ComputeAsync, self._Path, self._agent.Position, target)
	if not PathComputed or self._Path.Status == Enum.PathStatus.NoPath or #self._Path:GetWaypoints() < 2 then
		self._VisualWaypoints = DestroyVisualWaypoints(self, self._VisualWaypoints)
		return nil
	end
	if self._target ~= target then
		self._target = target
	end
	self._Waypoints = self._Path:GetWaypoints()
	self._CurrentWaypoint = 2
	DestroyVisualWaypoints(self, self._VisualWaypoints)
	if self._Visualize then
		self._VisualWaypoints = CreateVisualWaypoints(self._Waypoints, self._CustomFolder)
	else
		self._VisualWaypoints = {}
	end
	if #self._Waypoints == 2 then
		self._VisualWaypoints = DestroyVisualWaypoints(self, self._VisualWaypoints)
	else
		self._CurrentWaypoint = GetNonHumanoidWaypoint(self)
	end
	return true
end
return PathConfig
