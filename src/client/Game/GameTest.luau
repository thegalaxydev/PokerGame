local GameTest = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ScreenGui = PlayerGui:WaitForChild("PokerTest")
local Frame = ScreenGui:WaitForChild("Frame")
local Start = ScreenGui:WaitForChild("Start")
local GameState = ScreenGui:WaitForChild("GameState")
local State = ScreenGui:WaitForChild("State")
local Chips = ScreenGui:WaitForChild("Chips")
local Table = ScreenGui:WaitForChild("Table")
local CardTemplate = ScreenGui:WaitForChild("CardTemplate")
local Hand = ScreenGui:WaitForChild("Hand")
local BestHand = ScreenGui:WaitForChild("BestHand")
local Pot = ScreenGui:WaitForChild("Pot")

local Others = ScreenGui:WaitForChild("Others")
local OtherTemplate = ScreenGui:WaitForChild("OtherTemplate")

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

local function updateActionButtons(gameData)
	
	if gameData.CurrentPlayer.Player.Name ~= Player.Name then
		for _, child in Frame:GetChildren() do
			if not child:IsA("TextButton") then continue end

			child.Visible = false
		end
		return
	end

	local myPlayerData
	for _, player in gameData.Players do
		if player.Player.Name == Player.Name then
			myPlayerData = player
			break
		end
	end

	if not myPlayerData or myPlayerData.State ~= "Active" then
		for _, child in Frame:GetChildren() do
			if child:IsA("TextButton") then
				child.Visible = false
			end
		end
		return
	end

	local round = gameData.Round
	local highestBet = 0
	for _, p in gameData.Players do
		if p.Bet and p.Bet > highestBet then
			highestBet = p.Bet
		end
	end

	local canCheck = myPlayerData.Bet == highestBet
	local canCall = myPlayerData.Bet < highestBet
	local hasChips = myPlayerData.Chips > 0

	for _, child in Frame:GetChildren() do
		if not child:IsA("TextButton") then continue end

		if child.Name == "Fold" then
			child.Visible = true

		elseif child.Name == "Check" then
			child.Visible = canCheck

		elseif child.Name == "Call" then
			child.Visible = canCall and hasChips

		elseif child.Name == "Bet" then
			child.Visible = (round == "Pre-Flop" or round == "Flop") and canCheck and hasChips

		elseif child.Name == "Raise" then
			child.Visible = canCall and hasChips

		elseif child.Name == "All-In" then
			child.Visible = hasChips

		else
			child.Visible = false
		end
	end
end

function GameTest:Init()
	Remotes.ReplicateGameData.OnClientEvent:Connect(function(gameData: Remotes.PokerGame)
		GameState.Text = `Round: {gameData.Round}`
		State.Text = `State: {gameData.Players[1].State}`
		Chips.Text = `Chips: {gameData.Players[1].Chips}`

		for _, child in Table:GetChildren() do
			if not child:IsA("Frame") then continue end
			child:Destroy()
		end

		for _, child in Hand:GetChildren() do
			if not child:IsA("Frame") then continue end
			child:Destroy()
		end

		for _, child in Others:GetChildren() do
			if not child:IsA("Frame") then continue end

			local player = nil
			for _, player in gameData.Players do
				if player.Player.Name == child.Name then
					player = player
					break
				end
			end

			if not player then
				child:Destroy()
				continue
			end

			child.OtherName.Text = `{player.Player.Name}`
			child.OtherChips.Text = `Chips: {player.Chips}`
			child.OtherState.Text = `State: {player.State}`
			child.OtherBet.Text = `Bet: {player.Bet}`

			child.UIStroke.Enabled = (gameData.CurrentPlayer.Player.Name == player.Player.Name)
		end

		for _, player in gameData.Players do
			if player.Player.Name == Player.Name then continue end

			local frame = Others:FindFirstChild(player.Player.Name)
			if not frame then
				frame = OtherTemplate:Clone()
				frame.Parent = Others
				frame.Name = player.Player.Name
			end

			frame.OtherName.Text = `{player.Player.Name}`
			frame.OtherChips.Text = `Chips: {player.Chips}`
			frame.OtherState.Text = `State: {player.State}`
			frame.OtherBet.Text = `Bet: {player.Bet}`

			frame.UIStroke.Enabled = (gameData.CurrentPlayer.Player.Name == player.Player.Name)

			frame.Visible = true
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

		print(gameData.CurrentPlayer.Player.Name)

		updateActionButtons(gameData)
	end)

	Remotes.GameEvent.OnClientEvent:Connect(function(event)
		
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