--[[**
-------------------------------------------------------------------
TODO: This ModuleScript is for smart Pathfinding (especially for Nextbots) that improves original SimplePath and PathfindingService!
Last update: 05/12/25
License: MIT

SimplePath created by: @GrayzcaIe
Modified by: @Papisteve79
Lil modifying helper: @Asdfyc123
SimplePath reference: https://grayzcale.github.io/simplepath/
SimplePath license: MIT
Shoutout to: @Dragoteryx, creator of DrGBase.
DrGBase reference: https://github.com/Dragoteryx/drgbase

Special thanks to everyone involved in this project and the Open-Source contributors who made this possible. Excellent work by all of them!
-------------------------------------------------------------------
 **]]--

--------[[ CONTROL PANEL ZONE ]]--------
local Settings = {
	TimeVariance = 0.01, -- TODO: This makes delay for the Pathfinding (in cases of extreme lag in your NPC), (higher number = less lag but Pathfinding is more slow | less number = more lag but Pathfinding is more faster).
	ComparisonChecks = 1, -- TODO: Number of stuck checks required before triggering jump.
	CanJump = true -- TODO: This makes your NPC can jump! (true = Jump Enabled | false = Jump Disabled).
}
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
	for _, Waypoint: PathWaypoint in ipairs(Waypoints) do
		local VisualWaypointClone = visualWaypoint:Clone()
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
		for i, Waypoint2 in ipairs(Waypoints2) do
			if Waypoint2 and Waypoint2:IsA("BasePart") and Waypoint2.Name:match("^botPathPoint") then
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
		pcall(self._MoveConnection.Disconnect, self._MoveConnection)
		self._MoveConnection = nil
	end
end

local function SetJumpState(self)
	if self._Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping and self._Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
		self._Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end

local function MoveSelf(self)
	if Settings.CanJump ~= false and self._Waypoints[self._CurrentWaypoint].Action == Enum.PathWaypointAction.Jump or self._Waypoints[self._CurrentWaypoint].Label == "Jump" or self._target == nil then
		SetJumpState(self)
	end
	self._Humanoid:MoveTo(self._Waypoints[self._CurrentWaypoint].Position)
end

local function MoveToFinish(self, reached)
	if not getmetatable(self) or not self._Waypoints then
		return
	end
	if not self._Humanoid then
		if reached and self._CurrentWaypoint + 1 <= #self._Waypoints then
			self._CurrentWaypoint += 1
		else
			self._VisualWaypoints = DestroyVisualWaypoints(self._VisualWaypoints)
		end
		return
	end
	if reached and self._CurrentWaypoint + 1 <= #self._Waypoints then
		self._CurrentWaypoint += 1
		MoveSelf(self)
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
		if Settings.CanJump ~= false then
			SetJumpState(self)
		end
	end
end

local DeathConnection
function PathConfig.SetSettings(agent, agentParameters, Visualize)
	local Humanoid = agent:FindFirstChildOfClass("Humanoid")
	Log("assert", debug.traceback(`agent must have a valid Humanoid`), Humanoid)
	local PrimaryPart = (agent.PrimaryPart) or (Humanoid.RootPart) or (agent:FindFirstChild("HumanoidRootPart"))
	local WarnMessage = ""
	if not agent or not agent:IsA("Model") then
		WarnMessage ..= `agent is nil or not a Model (agent type: {typeof(agent)})`
	end
	if not PrimaryPart or not PrimaryPart:IsA("BasePart") then
		WarnMessage ..= `PrimaryPart is nil or not a BasePart (PrimaryPart type: {typeof(PrimaryPart)})`
	end
	if not Humanoid then
		WarnMessage ..= `Humanoid is nil`
	elseif Humanoid:GetState() == Enum.HumanoidStateType.Dead then
		WarnMessage ..= `Humanoid is dead (Humanoid State: {Humanoid:GetState().Name})`
	end
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
		_count = 0
	}, PathConfig)
	self._Path.Blocked:Connect(function(blockedWaypointIdx)
		if type(blockedWaypointIdx) ~= "number" then
			Log("warn", debug.traceback(`blockedWaypointIdx is not a number (type: {typeof(blockedWaypointIdx)})`))
			return
		end
		if self._CurrentWaypoint <= blockedWaypointIdx and Settings.CanJump ~= false then
			if tick() - (self._lastMovedTime or 0) > 0.5 then
				SetJumpState(self)
			end
		end
	end)
	if Humanoid then
		DeathConnection = Humanoid.Died:Connect(function()
			if self._Visualize and self._VisualWaypoints then
				for _ = 0, 5 do
					task.wait(0.05)
					DestroyVisualWaypoints(self._VisualWaypoints)
					if DeathConnection and DeathConnection.Connected then
						pcall(DeathConnection.Disconnect, DeathConnection)
						DeathConnection = nil
					end
					PathConfig.PathDestroy(self)
				end
			end
		end)
	end
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
	if not target and not self._Humanoid and self._target then
		MoveToFinish(self, true)
		return
	end
	if not (target and (typeof(target) == "Vector3" or target:IsA("BasePart"))) then
		Log("warn", debug.traceback(`target must be a valid Vector3 or BasePart.`))
		return nil
	end
	--[[if os.clock() - self._Time <= Settings.TimeVariance and self._Humanoid then
		task.wait(os.clock() - self._Time)
		return false
	elseif self._Humanoid then
		self._Time = os.clock()
	end]] -- Enable this if you feel your NPC too laggy (you need Enable _Time = 0 in PathConfig.new(...) function).
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
	if #self._Waypoints == 2 then
		self._VisualWaypoints = DestroyVisualWaypoints(self._VisualWaypoints)
	else
		self._CurrentWaypoint = GetNonHumanoidWaypoint(self)
		MoveToFinish(self, true)
	end
	task.wait()
	return self._target
end
return PathConfig
