local Util = {
    Character = {}
}

type AnimationProps = {
    Priority: Enum.AnimationPriority
}

function Util.LoadAnimation(Animator: Animator, Animation: Animation): AnimationTrack?
    local Success, Track = pcall(function()
        return Animator:LoadAnimation(Animation)
    end)
    if not Success then return end

    local Weight = Animation:GetAttribute("Weight") :: number?
    local Speed = Animation:GetAttribute("Speed") :: number?

    Track:GetPropertyChangedSignal("IsPlaying"):Connect(function()
        if not Track.IsPlaying then return end

        if Weight then
            Track:AdjustWeight(Weight)
        end

        if Speed then
            Track:AdjustSpeed(Speed)
        end
    end)

    return Track
end

local AnimationTemplate = Instance.new("Animation")
function Util.LoadAnimationId(Animator: Animator, AnimationId: string): AnimationTrack?
    local Animation = AnimationTemplate:Clone()
    Animation.AnimationId = AnimationId

    return Util.LoadAnimation(Animator, Animation)
end

function Util.GetAnimator(Model: Model): Animator?
    local AnimationRoot = Model:FindFirstChildOfClass("Humanoid") or Model:FindFirstChildOfClass("AnimationController")
    if not AnimationRoot then return end

    return AnimationRoot:FindFirstChildOfClass("Animator")
end

function Util.Character.LoadAnimation(Character: Model, Animation: Instance?, Props: AnimationProps?): AnimationTrack?
    if not Animation then return end
    if not Animation:IsA("Animation") then return end

    local Animator = Util.GetAnimator(Character)
    if not Animator then return end

    local Track = Util.LoadAnimation(Animator, Animation)
    if not Track then return end

    for i,v in pairs(Props or {}) do
        (Track :: never)[i] = v
    end

    return Track
end

function Util.Character.Play(Track: AnimationTrack?)
    if not Track then return end
    if Track.IsPlaying then return end

    Track:Play()
end

function Util.Character.Stop(Track: AnimationTrack?)
    if not Track then return end
    if not Track.IsPlaying then return end

    Track:Stop()
end

function Util.Character.StopList(Tracks: {[any]: AnimationTrack?})
    for i,v in pairs(Tracks) do
        Util.Character.Stop(v)
    end
end

function Util.Character.IsPlaying(Track: AnimationTrack?): boolean
    if not Track then return false end

    return Track.IsPlaying
end

function Util.Character.GetTimePosition(Track: AnimationTrack?): number
    if not Track then return 0 end

    return Track.TimePosition
end

function Util.Character.GetLength(Track: AnimationTrack?): number
    --// Making a special case for the non-exist would be cumbersome, so easier to just return a really small number instead of 0
    if not Track then return 0.0001 end

    return Track.Length
end

function Util.Character.SetTimePosition(Track: AnimationTrack?, position: number)
    if not Track then return end

    Track.TimePosition = position
end

return Util