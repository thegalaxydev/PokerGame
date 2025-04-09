local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientInterface = script.Parent.Parent

local Vide = require(ReplicatedStorage.Packages.vide)
local Functions = require(ClientInterface.Functions)
local Primitives = require(ClientInterface.Components.Primitive)

local Rem = Functions.Rem
local Group = Primitives.Group
local Frame = Primitives.Frame
local ImageButton = Primitives.ImageButton

local Create = Vide.create

local Defaults = {
    Size = UDim2.fromScale(1, 1),
    AnchorPoint = Vector2.new(.5,.5)
}

type ButtonAnimations = {
    onHovered: (() -> ())?,
    onPressed: (() -> ())?,
    onReleased: (() -> ())?,

    hoverFactor: ((value: number) -> ())?,
    pressFactor: ((value: number) -> ())?
}

local function Button(Props, Animations: ButtonAnimations?)
    Props = Props or {}
    for i,v in pairs(Defaults) do
        if Props[i] ~= nil then continue end

        Props[i] = Props[i] or Defaults[i]
    end

    local Hovered = Vide.source(false)
    local Pressed = Vide.source(false)

    local ButtonAnimations: ButtonAnimations = Animations or {
        onHovered = function()
            
        end,
        onPressed = function()
            
        end,
        onReleased = function()
            
        end
    }
    
    return ImageButton(Props)
end

return Button