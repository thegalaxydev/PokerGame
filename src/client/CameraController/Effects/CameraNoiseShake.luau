--!strict
local Base = require(script.Parent.CameraEffectBase)

local EffectPriority = 0

local Effect = setmetatable({}, Base)
Effect.__index = Effect

type NoiseShakeEffect = Base.EffectBase & {
    Intensity: number;
    Strength: number;

    Random: Random;
    Seed: Vector3;
}

type CameraInfo = Base.CameraInfo
type EffectResult = Base.EffectResult

function Effect.new(Intensity: number?, Strength: number?, Seed: number?): NoiseShakeEffect
    local self = (setmetatable(Base.new(EffectPriority, 1), Effect) :: never) :: NoiseShakeEffect

    self.Intensity = Intensity or 1
    self.Strength = Strength or 1

    self.Random = Random.new(Seed or tick())
    self.Seed = Vector3.new(
        self.Random:NextNumber() * 20 - 10,
        self.Random:NextNumber() * 20 - 10,
        self.Random:NextNumber() * 20 - 10
    )

    return self
end

function Effect:Update(info: CameraInfo): EffectResult
    local self = self :: NoiseShakeEffect

    local Elapsed = tick() - self.CreatedAt

    local Strength = self.Strength
    local Intensity = self.Intensity

    local Angles = CFrame.Angles(
        math.noise(self.Seed.X, Elapsed * Intensity) * Strength,
        math.noise(self.Seed.Y, Elapsed * Intensity) * Strength,
        math.noise(self.Seed.Z, Elapsed * Intensity) * Strength
    )

    return {cf = info.cf * Angles}
end

function Effect:SetIntensity(Intensity: number)
    local self = self :: NoiseShakeEffect

    self.Intensity = Intensity
end

function Effect:SetStrength(Strength: number)
    local self = self :: NoiseShakeEffect

    self.Strength = Strength
end

return Effect