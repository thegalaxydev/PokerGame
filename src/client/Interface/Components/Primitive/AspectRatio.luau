local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.vide)

local Create = Vide.create

local function AspectRatio(Ratio: number, FitMode: Enum.AspectType?)
    return Create "UIAspectRatioConstraint" {
        AspectRatio = Ratio,
        AspectType = FitMode or Enum.AspectType.ScaleWithParentSize
    }
end

return AspectRatio