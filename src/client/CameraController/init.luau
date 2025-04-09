--!strict
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Camera = workspace.CurrentCamera

local BlurEffectInstance = Lighting:FindFirstChildWhichIsA("BlurEffect")
if not BlurEffectInstance then
    BlurEffectInstance = Instance.new("BlurEffect", Lighting)
end

export type CameraEffectResult = {
    cf: CFrame?,
    fov: number?,
    blur: number?,
}

export type CameraUpdateInfo = {
    cf: CFrame,
    fov: number,
    blur: number,
    dt: number,
}

export type CameraEffectUpdateFunction = (self: CameraEffectData, info: CameraUpdateInfo)
-> CameraEffectResult?

export type FadeInfo = {
    FadeAt: number,
    FadeDuration: number,
    FadeStart: number,
    FadeTarget: number,
    FadeEasingStyle: Enum.EasingStyle?,
    FadeEasingDirection: Enum.EasingDirection?
}

export type CameraEffectData = {
    Id: string,
    Priority: number,
    Update: CameraEffectUpdateFunction,
    Weight: number,
    CreatedAt: number,
    Fade: FadeInfo?
}

export type EffectInfo = {
    Update: CameraEffectUpdateFunction,
    Priority: number?,
    Weight: number?
}

type CameraState = "Default" | "Custom"
local CameraStates: {[string]: CameraState} = {
    Default = "Default",
    Custom = "Custom",
}

local function lerp<T>(a: T,b: T,alpha: number): T
    return a :: never + (b - a :: never) * alpha
end

local Controller = {}
Controller.CameraStates = CameraStates
Controller.CurrentState = "Default"

local InternalCameraInfo = {
    cf = Camera.CFrame,
    blur = 0,
    fov = Camera.FieldOfView,
}
Controller.InternalInfo = InternalCameraInfo

Controller.CurrentCoreEffect = nil :: CameraEffectData?
Controller.FadingCoreEffects = {} :: {CameraEffectData}

Controller.Effects = {} :: {CameraEffectData}
Controller.EffectsToAdd = {} :: {CameraEffectData}
Controller.EffectsToRemove = {} :: {string}
Controller.EffectsStackNeedsSorting = false
Controller.IsSolving = false

local CurrentCameraInfo: CameraUpdateInfo = {
    blur = 0,
    cf = Camera.CFrame,
    dt = 0,
    fov = Camera.FieldOfView
}
Controller.CameraInfo = CurrentCameraInfo

function Controller:SetState(State: CameraState, ...: unknown)
    local Module = script.States:FindFirstChild(State)
    if not Module then return end
    if not Module:IsA("ModuleScript") then return end

    Controller.CurrentState = State

    if Controller.CurrentCoreEffect then
        table.insert(Controller.FadingCoreEffects, Controller.CurrentCoreEffect)
    end
    
    local State = require(Module) :: never
    Controller.CurrentCoreEffect = State.new(...)
end

function Controller:GetCameraInfo(): CameraUpdateInfo
    return Controller.CameraInfo
end

--[=[
    @param Effect EffectInfo -- The data for your effect to add
    @param FadeIn FadeInfo? -- How to fade in this effect. Defaults to nil, meaning the effect will be applied at full weight instantly.

    Adds an effect to the camera stack

    @returns string -- An if used to reference this effect in the camera stack
]=]
function Controller:AddEffect(Effect: EffectInfo, FadeIn: FadeInfo?): (string, CameraEffectData)
    local EffectId = HttpService:GenerateGUID(false)
    local EffectData: CameraEffectData = {
        CreatedAt = tick(),
        Fade = FadeIn,
        Priority = Effect.Priority or 0,
        Weight = Effect.Weight or 1,
        Id = EffectId,
        Update = Effect.Update

    }

    if Controller.IsSolving then
        table.insert(Controller.EffectsToAdd, EffectData)
    else
        table.insert(Controller.Effects, EffectData)
        Controller.EffectsStackNeedsSorting = true
    end

    return EffectId, EffectData
end


function Controller:RemoveEffect(Id: string, FadeOut: FadeInfo?)
    if table.find(Controller.EffectsToRemove, Id) then end
    
    for i,v in pairs(Controller.EffectsToAdd) do
        if v.Id ~= Id then continue end

        table.remove(Controller.EffectsToAdd, i)
        return
    end

    local Effect: CameraEffectData?
    for i,v in pairs(Controller.Effects) do
        if v.Id ~= Id then continue end

        Effect = v
        break
    end

    if not Effect then return end

    if FadeOut then
        if Effect.Fade then
            FadeOut.FadeStart = Effect.Weight
        end
        Effect.Fade = FadeOut

        task.delay(FadeOut.FadeDuration, function()
            Controller:RemoveEffectInternal(Id)
        end)
    else
        Controller:RemoveEffectInternal(Id)
    end
end

function Controller:RemoveEffectInternal(Id: string)
    if table.find(Controller.EffectsToRemove, Id) then return end

    if Controller.IsSolving then
        table.insert(Controller.EffectsToRemove, Id)
        return
    end

    for i,v in pairs(Controller.Effects) do
        if v.Id ~= Id then continue end
        
        table.remove(Controller.Effects,i)
        return
    end
end

function Controller:UpdateFadeWeight(effect: CameraEffectData, current: number)
    local FadeInfo = effect.Fade
    if not FadeInfo then return end

    local Diff = current - FadeInfo.FadeAt
    if Diff < 0 then return end

    local Progress = Diff / FadeInfo.FadeDuration
    if Progress > 1 then
        effect.Fade = nil
        effect.Weight = FadeInfo.FadeTarget
        return
    end

    local EasingStyle = FadeInfo.FadeEasingStyle or Enum.EasingStyle.Linear
    local EasingDirection = FadeInfo.FadeEasingDirection or Enum.EasingDirection.InOut
    
    effect.Weight = lerp(
        FadeInfo.FadeStart,
        FadeInfo.FadeTarget,
        TweenService:GetValue(Progress, EasingStyle, EasingDirection)
    )
end

function Controller:UpdateCoreFadeEffects(dt: number)
    if not Controller.CurrentCoreEffect then return end

    if Controller.CurrentCoreEffect.Weight == 1 then
        table.clear(Controller.FadingCoreEffects)
        return
    end

    local EffectsInfo: {{
        Result: CameraEffectResult,
        effect: CameraEffectData
    }} = {}

    local CurrentTime = tick()
    for i,v in pairs(Controller.FadingCoreEffects) do
        Controller:UpdateFadeWeight(v, CurrentTime)

        local Result = v:Update(Controller.CameraInfo)
        if not Result then continue end

        table.insert(EffectsInfo, {
            Result = Result,
            effect = v
        })
    end

    local ClearBack = false
    for i = #Controller.FadingCoreEffects, 1, -1 do
        if ClearBack then
            table.remove(Controller.FadingCoreEffects, i)
            continue
        end

        local Effect = Controller.FadingCoreEffects[i]
        if Effect.Weight == 1 then
            ClearBack = true
        end
    end

    table.insert(EffectsInfo,{
        Result = Controller.CameraInfo :: CameraEffectResult,
        effect = Controller.CurrentCoreEffect
    })

    local cf: CFrame?

    for i,v in pairs(EffectsInfo) do
        local Result = v.Result
        if not Result.cf then continue end

        if not cf then
            cf = Result.cf
            continue
        end

        cf = lerp(cf, Result.cf, v.effect.Weight)
    end

    if cf then
        Controller.CameraInfo.cf = cf
    end
end

function Controller:SortEffectStack()
    table.sort(Controller.Effects, function(a,b)
        if a.Priority ~= b.Priority then return a.Priority > b.Priority end

        return a.Id < b.Id
    end)
end

function Controller:ResolveEffectStack()
    for i,v in pairs(Controller.EffectsToRemove) do
        for effectInd, effect in pairs(Controller.Effects) do
            if effect.Id ~= v then continue end

            table.remove(Controller.Effects, effectInd)
            break
        end
    end

    for i,v in pairs(Controller.EffectsToAdd) do
        Controller.EffectsStackNeedsSorting = true
        table.insert(Controller.Effects, v)
    end

    if Controller.EffectsStackNeedsSorting then
        Controller:SortEffectStack()
    end
end

function Controller.Init()
    RunService:BindToRenderStep("CameraController_PreDefaultCameraUpdate", Enum.RenderPriority.Camera.Value - 1, function()
        Camera.CFrame = Controller.InternalInfo.cf
        Controller.CameraInfo = table.clone(Controller.InternalInfo) :: CameraUpdateInfo
        Controller.CameraInfo.dt = 0
    end)

    RunService:BindToRenderStep("CameraController_CoreEffectUpdate", Enum.RenderPriority.Camera.Value, function(dt: number)
        if Controller.CurrentState == CameraStates.Default then return end
        
        local CoreEffect = Controller.CurrentCoreEffect
        if not CoreEffect then return end

        Controller:UpdateFadeWeight(CoreEffect, tick())

        Controller.CameraInfo.dt = dt
        local Result = CoreEffect:Update(Controller.CameraInfo)
        if not Result then return end
        
        if Result.cf then
            Camera.CFrame = Result.cf
        end

        if Result.blur then
            Controller.CameraInfo.blur = Result.blur
            BlurEffectInstance.Size = Result.blur
        end

        if Result.fov then
            Controller.CameraInfo.fov = Result.fov
            Camera.FieldOfView = Result.fov
        end
    end)

    RunService:BindToRenderStep("CameraController_PostDefaultCameraUpdate", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
        Controller.InternalInfo.cf = Camera.CFrame
        Controller.CameraInfo.cf = Camera.CFrame
        Controller.CameraInfo.fov = Camera.FieldOfView
        Controller.CameraInfo.dt = dt

        if Controller.CurrentCoreEffect and #Controller.FadingCoreEffects > 0 then
            Controller:UpdateCoreFadeEffects(dt)
        end

        local CurrentTime = tick()

        Controller:ResolveEffectStack()
        Controller.IsSolving = true

        for i,v in pairs(Controller.Effects) do
            Controller:UpdateFadeWeight(v, CurrentTime)
            local Result = v:Update(Controller.CameraInfo)
            if not Result then continue end

            if Result.cf then
                Controller.CameraInfo.cf = Controller.CameraInfo.cf:Lerp(Result.cf, v.Weight)
            end

            if Result.fov then
                Controller.CameraInfo.fov = lerp(Controller.CameraInfo.fov, Result.fov, v.Weight)
            end
            if Result.blur then
                Controller.CameraInfo.blur = lerp(Controller.CameraInfo.blur, Result.blur, v.Weight)
            end
        end

        Camera.CFrame = Controller.CameraInfo.cf
        Camera.FieldOfView = Controller.CameraInfo.fov
        BlurEffectInstance.Size = Controller.CameraInfo.blur

        Controller.IsSolving = false
    end)
end

Controller.Init()

return Controller