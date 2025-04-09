local GameTest = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ScreenGui = PlayerGui:WaitForChild("PokerTest")
local Frame = ScreenGui:WaitForChild("Frame")
local Start = ScreenGui:WaitForChild("Start")
local GameState = ScreenGui:WaitForChild("GameState")
local State = ScreenGui:WaitForChild("State")
local Chips = ScreenGui:WaitForChild("Chips")
local OtherChips = ScreenGui:WaitForChild("OtherChips")
local OtherState = ScreenGui:WaitForChild("OtherState")
local Table = ScreenGui:WaitForChild("Table")
local CardTemplate = ScreenGui:WaitForChild("CardTemplate")
local Hand = ScreenGui:WaitForChild("Hand")
local BestHand = ScreenGui:WaitForChild("BestHand")
local Pot = ScreenGui:WaitForChild("Pot")

local function suitToChar(suit: number)
	if suit == 1 then
		return "♠"
	elseif suit == 2 then
		return "♥"
	elseif suit == 3 then
		return "♣"
	else
		return "♦"
	end
end

local function rankToChar(rank: number)
	if rank == 1 then
		return "A"
	end

	if rank == 11 then
		return "J"
	end

	if rank == 12 then
		return "Q"
	end

	if rank == 13 then
		return "K"
	end

	return rank
end

function GameTest:Init()
	Remotes.ReplicateGameData.OnClientEvent:Connect(function(gameData: Remotes.PokerGame)
		GameState.Text = `Round: {gameData.Round}`
		State.Text = `State: {gameData.Players[1].State}`
		Chips.Text = `Chips: {gameData.Players[1].Chips}`
		OtherChips.Text = `OtherChips: {gameData.Players[2].Chips}`
		OtherState.Text = `OtherState: {gameData.Players[2].State}`

		for _, child in Table:GetChildren() do
			if not child:IsA("Frame") then continue end
			child:Destroy()
		end

		for _, child in Hand:GetChildren() do
			if not child:IsA("Frame") then continue end
			child:Destroy()
		end

		for i, card in gameData.Table do
			local cardFrame = CardTemplate:Clone()
			cardFrame.Parent = Table
			cardFrame["1"].Text = rankToChar(card.Rank)
			cardFrame["2"].Text = rankToChar(card.Rank)
			cardFrame["Suit"].Text = suitToChar(card.Suit)

			if card.Suit == 2 or card.Suit == 4 then
				cardFrame["1"].TextColor3 = Color3.fromRGB(255, 0, 0)
				cardFrame["2"].TextColor3 = Color3.fromRGB(255, 0, 0)
				cardFrame["Suit"].TextColor3 = Color3.fromRGB(255, 0, 0)
			end

			cardFrame.Name = i

			cardFrame.Visible = true
		end

		for i, card in gameData.Players[1].Hand do
			local cardFrame = CardTemplate:Clone()
			cardFrame.Parent = Hand
			cardFrame["1"].Text = rankToChar(card.Rank)
			cardFrame["2"].Text = rankToChar(card.Rank)
			cardFrame["Suit"].Text = suitToChar(card.Suit)

			if card.Suit == 2 or card.Suit == 4 then
				cardFrame["1"].TextColor3 = Color3.fromRGB(255, 0, 0)
				cardFrame["2"].TextColor3 = Color3.fromRGB(255, 0, 0)
				cardFrame["Suit"].TextColor3 = Color3.fromRGB(255, 0, 0)
			end

			cardFrame.Name = i
			cardFrame.Visible = true
		end

		BestHand.Text = `{gameData.Players[1].BestHand}`
		Pot.Text = `Pot: {gameData.Pot}`
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