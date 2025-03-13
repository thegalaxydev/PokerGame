--!strict
--!nolint LocalShadow

local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Janitor = require(ReplicatedStorage.Packages.janitor)
local Gizmo = require(ReplicatedStorage.Shared.Util.Gizmo)

type Janitor = Janitor.Janitor

export type PathState = "NoPath" | "Computing" | "ValidPath" | "Blocked"

export type AgentParameters = {
    AgentRadius: number?,
    AgentHeight: number?,
    AgentCanJump: boolean?,
    AgentCanClimb: boolean?,
    WaypointSpacing: number?,
    Costs: {[string]: number}?
}

export type PathInstance = {
    Path: Path,
    State: PathState,
    Janitor: Janitor,
    Blocked: RBXScriptSignal<number>;
    Unblocked: RBXScriptSignal<number>;

    ComputeAsync: (self: PathInstance, from: Vector3, to: Vector3) -> PathState,
    Compute: (self: PathInstance, from: Vector3, to: Vector3) -> (),
    GetWaypoints: (self: PathInstance) -> {PathWaypoint},
    GetStatus: (self: PathInstance) -> PathState,
    Destroy: (self: PathInstance) -> (),

    Debug: (self: PathInstance) -> (),
}

local Path = {}
Path.__index = Path

function Path.new(Parameters: AgentParameters?): PathInstance
    local self = (setmetatable({}, Path) :: never) :: PathInstance

    self.Path = PathfindingService:CreatePath(Parameters)
    self.State = "NoPath"
    self.Janitor = Janitor.new()
    self.Blocked = self.Path.Blocked
    self.Unblocked = self.Path.Unblocked

    self.Blocked:Connect(function()
        self.State = "Blocked"
    end)

    self.Unblocked:Connect(function()
        self.State = "ValidPath"
    end)

    return self
end

function Path:ComputeAsync(from: Vector3, to: Vector3): PathState
    local self = self :: PathInstance

    self.Janitor:Cleanup()
    self.State = "Computing"

    local RunningThread = coroutine.running()
    local Resumed = false

    self.Janitor:Add(task.spawn(function()
        self.Path:ComputeAsync(from, to)

        if Resumed then return end
        Resumed = true

        if self.Path.Status == Enum.PathStatus.Success then
            self.State = "ValidPath"
        else
            self.State = "NoPath"
        end

        coroutine.resume(RunningThread, self.State)
    end))

    self.Janitor:Add(function()
        if Resumed then return end
        Resumed = true

        self.State = "NoPath"
        coroutine.resume(RunningThread, self.State)
    end)

    return coroutine.yield()
end

function Path:Compute(from: Vector3, to: Vector3)
    local self = self :: PathInstance
    
    task.spawn(function()
        self:ComputeAsync(from, to)
    end)
end

function Path:GetWaypoints(): {PathWaypoint}
    local self = self :: PathInstance
    
    return self.Path:GetWaypoints()
end

function Path:Destroy()
    local self = self :: PathInstance
    
    self.Janitor:Destroy()
    self.Path:Destroy()
end

function Path:Debug()
    local self = self :: PathInstance
    
    local Waypoints = self:GetWaypoints()
    for i,v in pairs(Waypoints) do
        Gizmo()
        .setColor(
            if i == 1 then Color3.new(0.101961, 1.000000, 0.176471) else
            if i == #Waypoints then Color3.new(1.000000, 0.062745, 0.062745) else
            Color3.new(1,1,1)
        )
        .sphere(v.Position, 1)
    end
end

return Path