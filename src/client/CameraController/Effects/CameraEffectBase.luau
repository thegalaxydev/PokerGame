--!strict
local CameraController = require(script.Parent.Parent)

type CameraEffect = CameraController.CameraEffectData
type EffectInfo = CameraController.EffectInfo

export type EffectBase = CameraEffect & {
    SetWeight: (self: EffectBase, weight: number) -> (),
    FadeIn: (self: EffectBase, duration: number?, resetWeight: boolean?) -> (),
    FadeOut: (self: EffectBase, duration: number?, resetWeight: boolean?) -> (),
    DoFade: (self: EffectBase, info: FadeInfo) -> (),
    Lifetime: (self: EffectBase, duration: number, fadeIn: number?, fadeOut: number?) -> (),

    GetCameraInfo: (self: EffectBase) -> CameraInfo,

    Destroy: (self: EffectBase) -> ()
}

export type FadeInfo = {
    Duration: number,
    Start: number?,
    Target: number,
    EasingDirection: Enum.EasingDirection?,
    EasingStyle: Enum.EasingStyle?,
}

export type CameraInfo = CameraController.CameraUpdateInfo
export type EffectResult = CameraController.CameraEffectResult

local Effect = {}
Effect.__index = Effect

function Effect.new(Priority: number?, Weight: number?): EffectBase
    local _id, effect = CameraController:AddEffect({
        Priority = Priority,
        Weight = Weight
    } :: never)

    setmetatable(effect, Effect)
    local self = (effect :: never) :: EffectBase

    return self
end

function Effect:SetWeight(Weight: number)
    local self = self :: EffectBase

    self.Weight = Weight
end

function Effect:FadeIn(Duration: number?, ResetWeight: boolean?)
    local self = self :: EffectBase

    if ResetWeight then
        self:SetWeight(0)
    end

    local FadeSpeed = 1 / (Duration or 0.05)

    local CurrentWeight = self.Weight
    local Distance = 1 - CurrentWeight
    local FadeDuration = Distance / FadeSpeed

    self.Fade = {
        FadeAt = tick(),
        FadeDuration = FadeDuration,
        FadeStart = CurrentWeight,
        FadeTarget = 1
    }
end

function Effect:FadeOut(Duration: number?, ResetWeight: boolean?)
    local self = self :: EffectBase

    if ResetWeight then
        self:SetWeight(1)
    end

    local FadeSpeed = 1 / (Duration or 0.05)

    local CurrentWeight = self.Weight
    local Distance = CurrentWeight
    local FadeDuration = Distance / FadeSpeed

    self.Fade = {
        FadeAt = tick(),
        FadeDuration = FadeDuration,
        FadeStart = CurrentWeight,
        FadeTarget = 0
    }
end

function Effect:DoFade(Info: FadeInfo)
    local self = self :: EffectBase

    if Info.Start then
        self.Weight = Info.Start
    end

    self.Fade = {
        FadeAt = tick(),
        FadeDuration = Info.Duration,
        FadeStart = self.Weight,
        FadeTarget = Info.Target,
        FadeEasingDirection = Info.EasingDirection,
        FadeEasingStyle = Info.EasingStyle,
    }
end

function Effect:Lifetime(Duration: number, FadeIn: number?, FadeOut: number?)
    local self = self :: EffectBase

    task.spawn(function()
        self:FadeIn(FadeIn, true)
        task.wait(Duration)
        self:FadeOut(FadeOut)
        task.wait(FadeOut or 0.05)
        self:Destroy()
    end)
end

function Effect:GetCameraInfo()
    return CameraController:GetCameraInfo()
end

function Effect:Update()
    return
end

function Effect:Destroy()
    local self = self :: EffectBase

    CameraController:RemoveEffect(self.Id)
end

return table.freeze(Effect)