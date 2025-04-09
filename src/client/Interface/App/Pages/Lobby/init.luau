local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientInterface = script.Parent.Parent.Parent

local Vide = require(ReplicatedStorage.Packages.vide)
local Components = require(ClientInterface.Components)
local Functions = require(ClientInterface.Functions)
local Primitives = require(ClientInterface.Components.Primitive)
local State = require(ClientInterface.State)

local Group = Primitives.Group
local Frame = Primitives.Frame

local Create = Vide.create

local function Lobby()
    return Group {
        
    }
end

return Lobby