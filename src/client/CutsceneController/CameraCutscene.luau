--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Base = require(script.Parent.Parent.CameraController.Effects.CameraEffectBase)
local Types = require(script.Parent.types)
local Spring = require(ReplicatedStorage.Shared.Util.Spring)
local MathUtil = require(ReplicatedStorage.Shared.Util.Math)

local EffectPriority = 10
local BaseFov = 70

local Effect = setmetatable({}, Base)
Effect.__index = Effect

type Cutscene = Types.Cutscene
type CutsceneSegment = Types.CutsceneSegment
type TransitionData = Types.TransitionData
type CameraMode = Types.CameraMode
type SpeedMode = Types.SpeedMode
type PVInstanceLike = MathUtil.PVInstanceLike

export type CutsceneEffect = Base.EffectBase & {
    Cutscene: Cutscene,
    
    CameraMode: CameraMode,
    SpeedMode: SpeedMode,
    
    Percent: number,
    Distance: number,
    Segment: number,
    SegmentStartAt: number,
    SegmentYVector: Vector3,

    RotationSpring: Spring.Spring<Vector3>;
    InternalRotation: CFrame;

    CurrentRoll: number,
    TargetRoll: number,
    TargetRollUpdateTime: number,
    ProcessedRollEvents: {number},
    
    CurrentFov: number,
    TargetFov: number,
    TargetFovUpdateTime: number,
    ProcessedFovEvents: {number},
    
    CurrentSpeed: number,
    TargetSpeed: number,
    
    CameraTarget: PVInstanceLike?,

    GetSegment: (self: CutsceneEffect) -> CutsceneSegment?,
    SetSegment: (self: CutsceneEffect, Segment: number) -> CutsceneSegment?,
    SolveSpline: (self: CutsceneEffect, P1: Vector3, P2: Vector3, P3: Vector3, P4: Vector3, T: number) -> Vector3,

    SolveSplineDuration: (self: CutsceneEffect) -> CFrame?,
    SolveLinearDuration: (self: CutsceneEffect) -> CFrame?,

    EvaluateRollTargets: (self: CutsceneEffect, Segment: CutsceneSegment) -> (),
    CalculateRollTarget: (self: CutsceneEffect, Segment: CutsceneSegment, t: {Time: number, Roll: number, Transition: TransitionData}) -> (),
    EvaluateFovTargets: (self: CutsceneEffect, Segment: CutsceneSegment) -> (),
    CalculateFovTarget: (self: CutsceneEffect, Segment: CutsceneSegment, t: {Time: number, Fov: number, Transition: TransitionData}) -> (),
}

type CameraInfo = Base.CameraInfo
type EffectResult = Base.EffectResult

function Effect.new(Cutscene: Cutscene): CutsceneEffect
    local self = (setmetatable(Base.new(EffectPriority, 1), Effect) :: never) :: CutsceneEffect

    self.Cutscene = Cutscene
    
    self.Percent = 0
    self.Distance = 0
    self.ProcessedRollEvents = {}
    self.ProcessedFovEvents = {}
    self.RotationSpring = Spring.new(Vector3.zero)
    self.RotationSpring.Speed = 5
    self.RotationSpring.Damper = 0.7
    
    local FirstSegment = self:SetSegment(1)
    if not FirstSegment then
        self:Destroy()
    else
        local Rot = if FirstSegment.CameraMode == "Spline" then Vector3.new(FirstSegment.From:GetPivot():ToOrientation())
        else Vector3.new(CFrame.lookAt(FirstSegment.From:GetPivot().Position, FirstSegment.To:GetPivot().Position):ToOrientation())
        self.RotationSpring.Position = MathUtil.FixVectorOrientation(Rot,Rot)
        self.RotationSpring.Target = MathUtil.FixVectorOrientation(Rot,Rot)
        self.RotationSpring.Velocity = Vector3.zero

        self.InternalRotation = FirstSegment.From:GetPivot().Rotation
    end

    return self
end

function Effect:SetSegment(Index: number): CutsceneSegment?
    local self = self :: CutsceneEffect

    if not self.Cutscene[Index] then return end

    local Segment = self.Cutscene[Index]

    self.Segment = Index
    self.SpeedMode = Segment.SpeedMode or "Duration"
    self.CameraMode = Segment.CameraMode or "Linear"
    self.CameraTarget = Segment.Target

    self.CurrentRoll = self.TargetRoll or MathUtil.GetPivotRoll(Segment.From)
    self.TargetRoll = self.CurrentRoll
    self.TargetRollUpdateTime = 0
    
    self.CurrentFov = self.TargetFov or BaseFov
    self.TargetFov = self.CurrentFov
    self.TargetFovUpdateTime = 0
    
    self.SegmentYVector = (Segment.From:GetPivot() * CFrame.Angles(0,0,self.TargetRoll - MathUtil.GetPivotRoll(Segment.From))).YVector
    table.clear(self.ProcessedRollEvents)
    table.clear(self.ProcessedFovEvents)
    self.SegmentStartAt = tick()

    return Segment
end

function Effect:GetSegment(): Types.CutsceneSegment?
    local Cutscene = self.Cutscene

    return Cutscene[self.Segment]
end

function Effect:Update(info: CameraInfo): EffectResult?
    local self = self :: CutsceneEffect

    local Segment = self:GetSegment()
    if not Segment then return end

    if Segment.Duration < tick() - self.SegmentStartAt then
        local NewSegment = self:SetSegment(self.Segment + 1)
        if not NewSegment then
            self:Destroy()
            return
        end

        return self:Update(info)
    end

    local Node2 = Segment.To

    self:EvaluateRollTargets(Segment)
    self:EvaluateFovTargets(Segment)

    local CutsceneCF: CFrame?
    if self.CameraMode == "Spline" then
        if self.SpeedMode == "Duration" then
            CutsceneCF = self:SolveSplineDuration()
        -- elseif self.SpeedMode == "Speed" then
            -- CutsceneCF = self:SolveSplineSpeed(Node1, Node2)
        end
    elseif self.CameraMode == "Linear" then
        if self.SpeedMode == "Duration" then
            CutsceneCF = self:SolveLinearDuration()
        -- elseif self.SpeedMode == "Speed" then
            -- CutsceneCF = self:SolveLinearSpeed(Node1, Node2)
        end
    elseif self.CameraMode == "Constant" then
        CutsceneCF = Node2:GetPivot()
    end

    if not CutsceneCF then return end

    self.RotationSpring.Position = Vector3.new(
        self.RotationSpring.Position.X % (math.pi * 2),
        self.RotationSpring.Position.Y % (math.pi * 2),
        self.RotationSpring.Position.Z % (math.pi * 2)
    )
    self.RotationSpring.Target = MathUtil.FixVectorOrientation(self.RotationSpring.Position, Vector3.new(CutsceneCF:ToOrientation()))
    self.InternalRotation = self.InternalRotation:Lerp(CutsceneCF.Rotation, MathUtil.DeltaLerp(0, 1, 0.8, info.dt * 4))

    -- return {
    --     cf = CFrame.new(CutsceneCF.Position) * self.InternalRotation
    -- }

    return {
        cf = CFrame.new(CutsceneCF.Position) * CFrame.fromOrientation(
        self.RotationSpring.Position.X,
        self.RotationSpring.Position.Y,
        self.RotationSpring.Position.Z
    ),
    fov = self.TargetFov
}
end

function Effect:EvaluateRollTargets(Segment: CutsceneSegment)
    local self = self :: CutsceneEffect

    local CurrentElapsed = tick() - self.SegmentStartAt

    local TargetRollEvent: {
        Time: number,
        Roll: number,
        Transition: TransitionData?
    } = {
        Time = Segment.Duration,
        Roll = MathUtil.GetPivotRoll(Segment.To),
        Transition = {
            Duration = Segment.Duration - self.TargetRollUpdateTime,
        }
    }
    local RollEventIndex: number? = nil
    
    for i,Event in pairs(Segment.Events) do
        if table.find(self.ProcessedRollEvents, i) then continue end

        if Event.Roll and Event.Time <= TargetRollEvent.Time then
            TargetRollEvent = Event :: never
            RollEventIndex = i
        end
    end

    if TargetRollEvent.Time < CurrentElapsed then
        self.CurrentRoll = TargetRollEvent.Roll
        self.TargetRoll = self.CurrentRoll
        self.TargetRollUpdateTime = CurrentElapsed

        if RollEventIndex then
            table.insert(self.ProcessedRollEvents, RollEventIndex)
        end
    elseif TargetRollEvent.Transition then
        self.TargetRoll = self:CalculateRollTarget(Segment, TargetRollEvent :: never)
    end
end

function Effect:EvaluateFovTargets(Segment: CutsceneSegment)
    local self = self :: CutsceneEffect

    local CurrentElapsed = tick() - self.SegmentStartAt

    local TargetEvent: {
        Time: number,
        Fov: number,
        Transition: TransitionData?
    } = {
        Time = Segment.Duration,
        Fov = self.TargetFov,
        Transition = {
            Duration = Segment.Duration - self.TargetFovUpdateTime,
        }
    }
    local EventIndex: number? = nil
    
    for i,Event in pairs(Segment.Events) do
        if table.find(self.ProcessedFovEvents, i) then continue end
        if not Event.Fov then continue end

        if Event.Time <= TargetEvent.Time then
            TargetEvent = Event :: never
            EventIndex = i
        end
    end

    if TargetEvent.Time < CurrentElapsed then
        self.CurrentFov = TargetEvent.Fov
        self.TargetFov = self.CurrentFov
        self.TargetFovUpdateTime = CurrentElapsed

        if EventIndex then
            table.insert(self.ProcessedFovEvents, EventIndex)
        end
    elseif TargetEvent.Transition then
        self.TargetFov = self:CalculateFovTarget(Segment, TargetEvent :: never)
    end
end

function Effect:CalculateRollTarget(Segment: CutsceneSegment, Target: {Time: number, Roll: number, Transition: TransitionData}): number
    local self = self :: CutsceneEffect

    local Transition = Target.Transition

    local CurrentRoll = self.CurrentRoll
    local CurrentElapsed = tick() - self.SegmentStartAt

    local RollChange = Target.Roll - CurrentRoll
    if math.abs(RollChange) > math.pi then
        RollChange -= 2 * math.sign(RollChange) * math.pi
    elseif math.abs(RollChange) == math.pi then
        RollChange = math.abs(RollChange)
    end

    local CurrentRollChange = RollChange * TweenService:GetValue(
        1 - (Target.Time - CurrentElapsed) / Transition.Duration,
        Transition.Style or Enum.EasingStyle.Linear,
        Transition.Direction or Enum.EasingDirection.InOut
    )

    return CurrentRoll + CurrentRollChange
end

function Effect:CalculateFovTarget(Segment: CutsceneSegment, Target: {Time: number, Fov: number, Transition: TransitionData}): number
    local self = self :: CutsceneEffect

    local Transition = Target.Transition

    local CurrentFov = self.CurrentFov
    local CurrentElapsed = tick() - self.SegmentStartAt

    local FovChange = Target.Fov - CurrentFov

    local CurrentFovChange = FovChange * TweenService:GetValue(
        1 - (Target.Time - CurrentElapsed) / Transition.Duration,
        Transition.Style or Enum.EasingStyle.Linear,
        Transition.Direction or Enum.EasingDirection.InOut
    )

    return CurrentFov + CurrentFovChange
end

function Effect:SolveLinearDuration(): CFrame?
    local self = self :: CutsceneEffect

    local Segment = self:GetSegment()
    if not Segment then return end

    local FromPivot = Segment.From:GetPivot()
    local ToPivot = Segment.To:GetPivot()

    self.Percent = (tick() - self.SegmentStartAt) / Segment.Duration
    if self.Percent <= 0 then return FromPivot end
    if self.Percent >= 1 then return ToPivot end

    local Percent = math.clamp(self.Percent, 0, 1)

    local P1 = FromPivot.Position
    local P2 = ToPivot.Position

    local Direction = (P2 - P1).Unit
    local Position = P1:Lerp(P2, Percent)

    local InitialCF = CFrame.lookAlong(Position, Direction) * CFrame.Angles(0,0,self.TargetRoll)
    if self.SegmentYVector:Dot(InitialCF.YVector) < 0 then
        InitialCF *= CFrame.Angles(0, 0, math.pi)
    end
    self.SegmentYVector = InitialCF.YVector

    return InitialCF
end

function Effect:SolveSplineDuration(): CFrame?
    local self = self :: CutsceneEffect

    local Segment = self:GetSegment()
    if not Segment then return end

    local FromPivot = Segment.From:GetPivot()
    local ToPivot = Segment.To:GetPivot()

    self.Percent = (tick() - self.SegmentStartAt) / Segment.Duration
    if self.Percent <= 0 then return FromPivot end
    if self.Percent >= 1 then return ToPivot end

    local Percent = math.clamp(self.Percent,0,1)

    local P1 = FromPivot.Position
    local P2 = FromPivot.LookVector
    * (Segment.SplineControlPointDistance or 1)
    + P1

    local P4 = ToPivot.Position
    local P3 = -ToPivot.LookVector
    * (Segment.SplineControlPointDistance or 1)
    + P4
    
    local V1 = self:SolveSpline(P1, P2, P3, P4, Percent - 0.015)
    local V2 = self:SolveSpline(P1, P2, P3, P4, Percent)
    local V3 = self:SolveSpline(P1, P2, P3, P4, Percent + 0.015)

    local MoveVector = (V3 - V2)

    local InitialCF = CFrame.lookAlong(V2, MoveVector.Unit) * CFrame.Angles(0,0,self.TargetRoll)
    if self.SegmentYVector:Dot(InitialCF.YVector) < 0 then
        InitialCF *= CFrame.Angles(0, 0, math.pi)
    end
    self.SegmentYVector = InitialCF.YVector

    local Steer = V3 - V1

    local HorizontalSteer = Steer - self.SegmentYVector * Steer:Dot(self.SegmentYVector)

    local Angle = HorizontalSteer:Angle(MoveVector, self.SegmentYVector) * 1.5

    return InitialCF * CFrame.Angles(0, 0, Angle)
end

function Effect:SolveSpline(P1: Vector3, P2: Vector3, P3: Vector3, P4: Vector3,T: number): Vector3
    local I1 = P1:Lerp(P2, T)
    local I2 = P2:Lerp(P3, T)
    local I3 = P3:Lerp(P4, T)

    local J1 = I1:Lerp(I2, T)
    local J2 = I2:Lerp(I3, T)

    return J1:Lerp(J2, T)
end

return Effect