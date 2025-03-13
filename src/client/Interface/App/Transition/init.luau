local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local TransitionConfig = require(ReplicatedStorage.Shared.Config.Transition)

local ClientInterface = script.Parent.Parent

local Vide = require(ReplicatedStorage.Packages.vide)
local Components = require(ClientInterface.Components)
local Functions = require(ClientInterface.Functions)
local Primitives = require(ClientInterface.Components.Primitive)
local State = require(ClientInterface.State)

local Group = Primitives.Group
local Frame = Primitives.Frame

local Create = Vide.create

local function Transition()
    local Transparency = Vide.derive(function()
        local Time = Functions.Time()
        local TransitionTime = State.TransitionAt()

        local FullStartTime = TransitionTime + TransitionConfig.InTime
        local FullEndTime = TransitionTime + TransitionConfig.InTime + TransitionConfig.FullTime

        if Time < FullStartTime then
            return 1 - (Time - TransitionTime) / TransitionConfig.InTime
        elseif Time > FullEndTime then
            return TweenService:GetValue(math.clamp((Time - FullEndTime) / TransitionConfig.OutTime,0,1), Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
        else
            return 0
        end
    end)

    return Frame {
        BackgroundColor3 = Color3.new(1,1,1),
        ZIndex = 10,

        BackgroundTransparency = Transparency
    }
end

return Transition