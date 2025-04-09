local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CameraEffects = require(script.Parent.Parent.CameraController.Effects)
local TestConfig = require(ReplicatedStorage.Shared.Config.Test)
local UIState = require(script.Parent.Parent.Interface.State)

local Controller = {}

function Controller:Init()
    local CameraPosition = workspace.Lobby.Map.Cameras.MainMenuCam

    CameraEffects.TrackTarget.new(CameraPosition)

    task.spawn(function()
        Controller:PlayIntro()
    end)
end

function Controller:PlayIntro()
    if not TestConfig.SkipIntro then
        --// TODO: Put intro here
    end

    UIState.Page("Lobby")
end

return Controller