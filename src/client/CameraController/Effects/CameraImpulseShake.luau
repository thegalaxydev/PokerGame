--!strict
local TweenService = game:GetService("TweenService")

local Base = require(script.Parent.CameraEffectBase)

local EffectPriority = 0

local Effect = setmetatable({}, Base)
Effect.__index = Effect

type ImpulseShakeEffect = Base.EffectBase & {
    Intensity: number;
    Strength: number;

    Random: Random;
    Targets: {{Target: Vector3, Time: number}}
}

type CameraInfo = Base.CameraInfo
type EffectResult = Base.EffectResult

function Effect.new(Intensity: number?, Strength: number?, Seed: number?): ImpulseShakeEffect
    local self = (setmetatable(Base.new(EffectPriority, 1), Effect) :: never) :: ImpulseShakeEffect

    self.Intensity = Intensity or 1
    self.Strength = Strength or 1

    self.Random = Random.new(Seed or tick())
    self.Targets = {}

    local TargetNum = math.max(1, math.floor(0.5 / self.Intensity))
    local LastVector = self.Random:NextUnitVector()
    for i = 1,TargetNum do
        local Time = 0.5 * i / TargetNum

        local Direction = self.Random:NextUnitVector()
        if Direction:Dot(LastVector) > 0 then
            local Parallel = Direction:Dot(LastVector) * LastVector
            Direction -= Parallel * 2
        end

        LastVector = Direction

        local Target = Direction * (self.Strength / 20) * (TargetNum - i + 1) / TargetNum

        table.insert(self.Targets, {
            Time = Time,
            Target = Target,
        })
    end

    table.insert(self.Targets, {
        Time = 0.5 + 0.5/TargetNum,
        Target = Vector3.zero
    })

    return self
end

function Effect:Update(info: CameraInfo): EffectResult
    local self = self :: ImpulseShakeEffect

    local Elapsed = tick() - self.CreatedAt

    local CurrentTarget = self.Targets[1]
    local LastTarget = {
        Time = 0,
        Target = Vector3.zero
    }
    for i,v in pairs(self.Targets) do
        if v.Time > Elapsed then continue end
        
        CurrentTarget = self.Targets[i + 1] or v
        LastTarget = v
    end

    if not CurrentTarget then return {cf = info.cf} end

    local LAlpha = (Elapsed - LastTarget.Time) / (CurrentTarget.Time / LastTarget.Time)
    local Alpha = TweenService:GetValue(LAlpha, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    local Target = LastTarget.Target:Lerp(LastTarget.Target, Alpha)

    local Angles = CFrame.Angles(Target.X, Target.Y, Target.Z)

    return {cf = info.cf * Angles}
end

return Effect