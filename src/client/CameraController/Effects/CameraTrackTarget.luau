--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Base = require(script.Parent.CameraEffectBase)
local Spring = require(ReplicatedStorage.Shared.Util.Spring)
local MathUtil = require(ReplicatedStorage.Shared.Util.Math)

local EffectPriority = 2

local Effect = setmetatable({}, Base)
Effect.__index = Effect

type PVInstanceLike = MathUtil.PVInstanceLike
type Spring<T> = Spring.Spring<T>

type TrackEffect = Base.EffectBase & {
    Target: PVInstanceLike,

    PositionSpring: Spring<Vector3>,
    RotationSpring: Spring<Vector3>,

    UpdateTargetSprings: (self: TrackEffect) -> (),

    SetTarget: (self: TrackEffect, Target: PVInstanceLike) -> (),
}

type CameraInfo = Base.CameraInfo
type EffectResult = Base.EffectResult

function Effect.new(Target: PVInstanceLike): TrackEffect
    local self = (setmetatable(Base.new(EffectPriority, 1), Effect) :: never) :: TrackEffect

    self.Target = Target

    local CameraInfo = self:GetCameraInfo()

    self.PositionSpring = Spring.new(CameraInfo.cf.Position, {
        Speed = 20
    })
    self.RotationSpring = Spring.new(Vector3.new(CameraInfo.cf:ToOrientation()),{
        Speed = 20
    })

    self:UpdateTargetSprings()

    return self
end

function Effect:UpdateTargetSprings()
    local self = self :: TrackEffect

    local Target = self.Target

    self.PositionSpring.Target = Target:GetPivot().Position
    self.RotationSpring.Target = MathUtil.FixVectorOrientation(self.RotationSpring.Position,Vector3.new(Target:GetPivot():ToOrientation()))
end

function Effect:Update(info: CameraInfo): EffectResult
    local self = self :: TrackEffect

    self:UpdateTargetSprings()

    local CF = CFrame.new(self.PositionSpring.Position) * CFrame.fromOrientation(
        self.RotationSpring.Position.X,
        self.RotationSpring.Position.Y,
        self.RotationSpring.Position.Z
    )

    return {cf = CF}
end

function Effect:SetTarget(Target: PVInstanceLike)
    local self = self :: TrackEffect

    self.Target = Target
end

return Effect