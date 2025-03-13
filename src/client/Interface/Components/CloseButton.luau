local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientInterface = script.Parent.Parent

local Vide = require(ReplicatedStorage.Packages.vide)
local Functions = require(ClientInterface.Functions)
local Primitives = require(ClientInterface.Components.Primitive)

local Rem = Functions.Rem
local Group = Primitives.Group
local Frame = Primitives.Frame
local ImageButton = Primitives.ImageButton
local AspectRatio = Primitives.AspectRatio

local Create = Vide.create

local function Component(onClick: () -> ())
    local HoveredTarget = Vide.source(0)
    local PressedTarget = Vide.source(0)

    local HoverAnimation = Vide.spring(HoveredTarget,0.2)
    local PressedAnimation = Vide.spring(PressedTarget,0.1)

    return Group {
        AspectRatio(1),
        ImageButton {
            Image = "rbxassetid://86093328799058",
            Activated = onClick,
            Size = function()
                local Scale = 1 + HoverAnimation() * .2 + PressedAnimation() * -.3
                return UDim2.fromScale(Scale, Scale)
            end,

            MouseEnter = function()
                HoveredTarget(1)
            end,
            MouseLeave = function()
                HoveredTarget(0)
                PressedTarget(0)
            end,

            MouseButton1Down = function()
                PressedTarget(1)
            end,
            MouseButton1Up = function()
                PressedTarget(0)
            end
        },
    }
end

return Component