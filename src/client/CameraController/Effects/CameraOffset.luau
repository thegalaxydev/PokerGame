--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Base = require(script.Parent.CameraEffectBase)
local Spring = require(ReplicatedStorage.Shared.Util.Spring)
local MathUtil = require(ReplicatedStorage.Shared.Util.Math)

local EffectPriority = 2

local Effect = setmetatable({}, Base)
Effect.__index = Effect

type Spring<T> = Spring.Spring<T>

type TrackEffect = Base.EffectBase & {
    Offset: CFrame,
    PositionOffset: Vector3,

    PositionSpring: Spring<Vector3>,
    PositionOffsetSpring: Spring<Vector3>,
    RotationSpring: Spring<Vector3>,

    UpdateTargetSprings: (self: TrackEffect) -> (),

    SetOffset: (self: TrackEffect, Offset: CFrame) -> (),
    SetPositionOffset: (self: TrackEffect, Offset: Vector3) -> (),
}

type CameraInfo = Base.CameraInfo
type EffectResult = Base.EffectResult

function Effect.new(Offset: CFrame?, PositionOffset: Vector3?): TrackEffect
    local self = (setmetatable(Base.new(EffectPriority, 1), Effect) :: never) :: TrackEffect

    self.Offset = Offset or CFrame.identity
    self.PositionOffset = PositionOffset or Vector3.zero

    self.PositionSpring = Spring.new(Vector3.zero, {
        Speed = 20
    })
    self.PositionOffsetSpring = Spring.new(Vector3.zero, {
        Speed = 20
    })
    self.RotationSpring = Spring.new(Vector3.zero,{
        Speed = 20
    })

    self:UpdateTargetSprings()

    return self
end

function Effect:UpdateTargetSprings()
    local self = self :: TrackEffect

    local Offset = self.Offset

    self.PositionSpring.Target = Offset.Position
    self.RotationSpring.Target = MathUtil.FixVectorOrientation(self.RotationSpring.Position,Vector3.new(Offset:ToOrientation()))
    self.PositionOffsetSpring.Target = self.PositionOffset
end

function Effect:Update(info: CameraInfo): EffectResult
    local self = self :: TrackEffect

    self:UpdateTargetSprings()

    local CF = CFrame.new(self.PositionSpring.Position) * CFrame.fromOrientation(
        self.RotationSpring.Position.X,
        self.RotationSpring.Position.Y,
        self.RotationSpring.Position.Z
    ) + self.PositionOffsetSpring.Position

    return {cf = info.cf * CF + self.PositionOffsetSpring.Position}
end

function Effect:SetOffset(Offset: CFrame)
    local self = self :: TrackEffect

    self.Offset = Offset
end

function Effect:SetPositionOffset(Offset: Vector3)
    local self = self :: TrackEffect

    self.PositionOffset = Offset
end

return Effect