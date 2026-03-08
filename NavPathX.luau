--[[
=======================================================================
NavPathX Smart AI Navigation System Module - Standard Edition
Version: 1.2.2 | Last Updated: 2026-03-07
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

--------[[ DEBUG ZONE ]]--------
local Settings = {
	TimeVariance = 0.01, -- TODO: Pathfinding delay for lag compensation (higher = less lag but slower | lower = more lag but faster)
	ComparisonChecks = 1, -- TODO: Stuck position checks before triggering jump
	CanJump = true -- TODO: Enable/Disable NPC jumping (true = Enabled | false = Disabled)
}
-------------------------------------------------------------------
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
		error(Prefix .. Msg, 2)
	elseif Level == "assert" then
		assert(Condition, Prefix .. Msg)
	else
		print(`[{scriptName} info]: {Msg}`)
	end
end

local PathWaypoints = workspace.PathWaypoints
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WaypointTemplate = ReplicatedStorage.WaypointTemplate
local VisualWaypoint = WaypointTemplate.VisualWaypoint
local function CreateVisualWaypoints(Waypoints: {PathWaypoint})
	local VisualWaypoints = {}
	for _, Waypoint: PathWaypoint in Waypoints do
		local VisualWaypointClone = VisualWaypoint:Clone()
		VisualWaypointClone.Position = Waypoint.Position
		VisualWaypointClone.Locked = true
		VisualWaypointClone.Transparency = 0
		VisualWaypointClone.Color = (Waypoint == Waypoints[#Waypoints] and Color3.new(1, 0, 0)) or (Waypoint.Action == Enum.PathWaypointAction.Jump and Color3.fromRGB(112, 255, 172)) or (Waypoint.Action == Enum.PathWaypointAction.Walk and Color3.new(1, 1, 1))
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
		for i, Waypoint2 in Waypoints2 do
			if Waypoint2:IsA("BasePart") and Waypoint2:IsDescendantOf(PathWaypoints) then
				Waypoint2:Destroy()
				Waypoints2[i] = nil
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
		self._MoveConnection:Disconnect()
		self._MoveConnection = nil
	end
end

local function SetJumpState(self)
	local State = self._Humanoid:GetState()
	if State ~= Enum.HumanoidStateType.Jumping and State ~= Enum.HumanoidStateType.Freefall then
		self._Humanoid.Jump = true
	end
end

local function MoveAgent(self)
	if Settings.CanJump and (self._Waypoints[self._CurrentWaypoint].Action == Enum.PathWaypointAction.Jump or self._Waypoints[self._CurrentWaypoint].Label == "Jump" or not self._target) then
		SetJumpState(self)
	end
	self._Humanoid:MoveTo(self._Waypoints[self._CurrentWaypoint].Position)
end

local function MoveToFinish(self, Reached)
	if not getmetatable(self) or not self._Waypoints then
		return
	end
	if not self._Humanoid then
		if Reached and self._CurrentWaypoint + 1 <= #self._Waypoints then
			self._CurrentWaypoint += 1
		else
			self._VisualWaypoints = DestroyVisualWaypoints(self._VisualWaypoints)
		end
		return
	end
	if Reached and self._CurrentWaypoint + 1 <= #self._Waypoints then
		self._CurrentWaypoint += 1
		MoveAgent(self)
	else
		DisconnectMoveConnection(self)
		self._VisualWaypoints = DestroyVisualWaypoints(self._VisualWaypoints)
	end
end

local function ComparePosition(self)
	if self._CurrentWaypoint == #self._Waypoints then
		return
	end
	local CurrentPosition = self._agent.PrimaryPart.Position
	local HasMove = (CurrentPosition - self._last).Magnitude > Settings.TimeVariance
	if HasMove then
		self._count = 0
		self._lastMovedTime = tick()
	else
		self._count += 1
	end
	self._last = CurrentPosition
	if self._count >= Settings.ComparisonChecks then
		if Settings.CanJump then
			SetJumpState(self)
		end
	end
end

local PathfindingService = game:GetService("PathfindingService")
function PathConfig.SetSettings(agent, agentParameters, Visualize)
	Log("assert", debug.traceback(`agent must be a Model`), agent and agent:IsA("Model") and agent.PrimaryPart)
	local Humanoid = agent:FindFirstChildOfClass("Humanoid")
	Log("assert", debug.traceback(`agent must have a valid Humanoid`), Humanoid)
	local PrimaryPart = (agent.PrimaryPart) or (Humanoid.RootPart) or (agent:FindFirstChild("HumanoidRootPart"))
	Log("assert", debug.traceback(`agent must have a valid PrimaryPart`), PrimaryPart)
	local State2 = Humanoid:GetState()
	if State2 == Enum.HumanoidStateType.Dead then
		Log("warn", `Humanoid is dead. (State: {State2.Name})`)
		return nil
	end
	if agentParameters and type(agentParameters) ~= "table" then
		Log("warn", `Invalid agentParameters: table expected, got {typeof(agentParameters)}`)
	end
	local Path: Path = PathfindingService:CreatePath(agentParameters)
	local self = setmetatable({
		_agent = agent,
		_Humanoid = Humanoid,
		_PrimaryPart = PrimaryPart,
		_Path = Path,
		_Waypoints = {},
		_CurrentWaypoint = 1,
		_MoveConnection = nil,
		_target = nil,
		_Visualize = Visualize or false,
		_OriginalVisualize = Visualize or false,
		_VisualWaypoints = {},
		_lastMovedTime = tick(),
		--_Time = 0,
		_last = Vector3.new(),
		_count = 0,
		_BlockedConnection = nil,
		_DeathConnection = nil
	}, PathConfig)
	self._BlockedConnection = self._Path.Blocked:Connect(function(blockedWaypointIdx)
		if type(blockedWaypointIdx) ~= "number" then
			Log("warn", `blockedWaypointIdx is not a number (type: {typeof(blockedWaypointIdx)})`)
			return
		end
		if self._CurrentWaypoint <= blockedWaypointIdx and Settings.CanJump then
			if tick() - (self._lastMovedTime or 0) > 0.5 then
				SetJumpState(self)
				local State3 = self._Humanoid:GetState()
				if State3 ~= Enum.HumanoidStateType.Jumping and State3 ~= Enum.HumanoidStateType.Freefall then
					self:Run(self._target)
				end
			end
		end
	end)
	if Humanoid then
		self._DeathConnection = Humanoid.Died:Connect(function()
			if self._DeathConnection and self._DeathConnection.Connected then
				self._DeathConnection:Disconnect()
				self._DeathConnection = nil
			end
			if self._Visualize and self._VisualWaypoints then
				task.wait(0.05)
				DestroyVisualWaypoints(self._VisualWaypoints)
				self:PathDestroy()
			end
		end)
	end
	return self
end

local function SafeDestroyVisualWaypoints(self)
	if rawget(self, "_VisualWaypoints") == nil then
		Log("warn", `Attempt to destroy visual waypoints: _VisualWaypoints is {typeof(self._VisualWaypoints)}`)
		rawset(self, "_VisualWaypoints", {})
		return
	end
	if self._VisualWaypoints then
		DestroyVisualWaypoints(self._VisualWaypoints)
		self._VisualWaypoints = nil
	end
end

function PathConfig:PathDestroy()
	if not getmetatable(self) then
		return
	end
	DisconnectMoveConnection(self)
	SafeDestroyVisualWaypoints(self)
	if rawget(self, "_Path") and self._Path then
		pcall(self._Path.Destroy, self._Path)
		self._Path = nil
	end
	if self._BlockedConnection and self._BlockedConnection.Connected then
		self._BlockedConnection:Disconnect()
		self._BlockedConnection = nil
	end
	self._Humanoid = nil
	self._PrimaryPart = nil
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
	DisconnectMoveConnection(self)
	self._VisualWaypoints = DestroyVisualWaypoints(self._VisualWaypoints)
end

export type Goal = Vector3 | BasePart
function PathConfig:Run(target: Goal?)
	if not getmetatable(self) then
		return nil
	end
	if self._agent and not self._agent:IsDescendantOf(workspace) then
		DestroyVisualWaypoints(self._VisualWaypoints)
		self._Visualize = false
	else
		self._Visualize = self._OriginalVisualize
	end
	if not target and not self._Humanoid and self._target then
		MoveToFinish(self, true)
		return
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
	local PathComputed, _ = pcall(self._Path.ComputeAsync, self._Path, self._PrimaryPart.Position, target)
	if not PathComputed or self._Path.Status == Enum.PathStatus.NoPath or #self._Path:GetWaypoints() < 2 then
		self._VisualWaypoints = DestroyVisualWaypoints(self._VisualWaypoints)
		return nil
	end
	if self._Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
		self._VisualWaypoints = DestroyVisualWaypoints(self._VisualWaypoints)
		return true
	end
	if self._target ~= target then
		self._target = target
	end
	self._Waypoints = self._Path:GetWaypoints()
	self._CurrentWaypoint = 2
	if self._Humanoid then
		ComparePosition(self)
	end
	DestroyVisualWaypoints(self._VisualWaypoints)
	if self._Visualize then
		self._VisualWaypoints = CreateVisualWaypoints(self._Waypoints)
	else
		self._VisualWaypoints = {}
	end
	self._MoveConnection = self._PrimaryPart and (self._MoveConnection or self._Humanoid.MoveToFinished:Connect(function(...)
		MoveToFinish(self, ...)
	end))
	if self._PrimaryPart then
		MoveToFinish(self, true)
	end
	if self._Humanoid then
		MoveAgent(self)
	elseif #self._Waypoints == 2 then
		self._VisualWaypoints = DestroyVisualWaypoints(self._VisualWaypoints)
	else
		self._CurrentWaypoint = GetNonHumanoidWaypoint(self)
		MoveToFinish(self, true)
	end
	return true
end
return PathConfig
