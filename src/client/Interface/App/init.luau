local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientInterface = script.Parent

local Vide = require(ReplicatedStorage.Packages.vide)
local Components = require(ClientInterface.Components)
local Functions = require(ClientInterface.Functions)
local Primitives = require(ClientInterface.Components.Primitive)

local Group = Primitives.Group
local Frame = Primitives.Frame

local Create = Vide.create

local NonePage = require(script.Pages.None)
local Transition = require(script.Transition)

local function App()
    return Group {
        NonePage(),
        Transition()
    }
end

return App