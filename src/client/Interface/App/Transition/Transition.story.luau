local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.vide)

local ClientInterface = script.Parent.Parent.Parent

local Functions = require(ClientInterface.Functions)
local State = require(ClientInterface.State)
local QuickStory = Functions.QuickStory

local Transition = require(script.Parent)

return QuickStory(function()
    local TestThread = task.spawn(function()
        task.wait(2)
        
        while true do
            State.TransitionAt(tick())

            task.wait(10)
        end
    end)

    Vide.cleanup(function()
        pcall(task.cancel,TestThread)
    end)

    return Transition()
end)