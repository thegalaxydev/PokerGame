local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Vide = require(ReplicatedStorage.Packages.vide)

local Time = Vide.source(tick())

RunService.RenderStepped:Connect(function()
    Time(tick())
end)

return Time