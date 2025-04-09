local GameTest = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ScreenGui = PlayerGui:WaitForChild("PokerTest")
local Frame = ScreenGui:WaitForChild("Frame")
local Start = ScreenGui:WaitForChild("Start")
function GameTest:Init()

	Remotes.ReplicateGameData.OnClientEvent:Connect(function(game)
		print(game.Round)
	end)

	for _, child in Frame:GetChildren() do
		if not child:IsA("TextButton") then continue end

		child.Activated:Connect(function()
			local amountBox = child:FindFirstChild("Amount")
			local amount = nil
			if amountBox then
				amount = tonumber(amountBox.Text)
			end

			Remotes.SendAction:FireServer(child.Name, amount)
		end)
	end

	Start.Activated:Connect(function()
		Remotes.SendAction:FireServer("Start")
		Start.Visible = false
	end)
end

return GameTest