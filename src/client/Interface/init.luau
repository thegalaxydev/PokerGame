local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Vide = require(ReplicatedStorage.Packages.vide)
local App = require(script.App)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Controller = {}

function Controller.Init()
    Vide.mount(function()
        return Vide.create "ScreenGui" {
            IgnoreGuiInset = true,

            App()
        }
    end,PlayerGui)
end

return Controller