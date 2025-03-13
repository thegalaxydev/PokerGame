local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Janitor = require(ReplicatedStorage.Packages.janitor)

type Janitor = Janitor.Janitor

export type Character = Model & {
    HumanoidRootPart: BasePart,
    Humanoid: Humanoid & {
        Animator: Animator
    }
}

local Util = {}

local CharacterDescendantWaitTimeout = 10

function Util.Validate(Character: Model): Character?
    local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart", CharacterDescendantWaitTimeout)
    if not HumanoidRootPart then return end
    if not HumanoidRootPart:IsA("BasePart") then return end

    local Humanoid = Character:WaitForChild("Humanoid", CharacterDescendantWaitTimeout)
    if not Humanoid then return end
    if not Humanoid:IsA("Humanoid") then return end

    local Animator = Humanoid:WaitForChild("Animator",CharacterDescendantWaitTimeout)
    if not Animator then return end
    if not Animator:IsA("Animator") then return end

    return Character :: Character
end

function Util.HookToCharacterRemove(Character: Character, CharacterJanitor: Janitor)
    local Humanoid = Character.Humanoid

    CharacterJanitor:Add(Humanoid.Died:Once(function()
        CharacterJanitor:Cleanup()
    end), "Disconnect")

    CharacterJanitor:Add(Character.AncestryChanged:Connect(function()
        if Character.Parent then return end
        
        CharacterJanitor:Cleanup()
    end), "Disconnect")

    CharacterJanitor:Add(Character.Destroying:Connect(function()
        CharacterJanitor:Cleanup()
    end), "Disconnect")
end

function Util.GetFloorHeight(Character: Model): number?
    local Humanoid = Character:FindFirstAncestorOfClass("Humanoid")
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    if not Humanoid or not HumanoidRootPart or not HumanoidRootPart:IsA("BasePart") then return Character:GetExtentsSize().Y/2 end

    local RootHeight = HumanoidRootPart.Size.Y/2

    if Humanoid.RigType == Enum.HumanoidRigType.R6 then
        local LeftLegHeight = 0

        local LeftLeg = Character:FindFirstChild("LeftLeg")
        if LeftLeg and LeftLeg:IsA("BasePart") then LeftLegHeight = LeftLeg.Size.Y end

        return LeftLegHeight + RootHeight + Humanoid.HipHeight
    end

    return RootHeight + Humanoid.HipHeight
end

return Util