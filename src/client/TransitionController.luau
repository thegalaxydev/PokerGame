local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts

local InterfaceState = require(PlayerScripts.Client.Interface.State)
local TransitionConfig = require(ReplicatedStorage.Shared.Config.Transition)

local Controller = {}

function Controller:Transition(Obscured: (() -> ())?)
    InterfaceState.TransitionAt()

    if Obscured then
        task.delay(TransitionConfig.InTime + TransitionConfig.FullTime * 0.5, Obscured)
    end
end

return Controller