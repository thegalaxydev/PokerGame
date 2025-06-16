local Poker = {} :: PokerGame
Poker.__index = Poker

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Replion = require(Packages.replion)
local Types = require(ReplicatedStorage.Shared.Types)

type PokerGame = Types.PokerGame
type PokerGameSettings = Types.PokerGameSettings
type PokerPlayer = Types.PokerPlayer
type Card = Types.Card
type Deck = Types.Deck

type Personality = {
	BluffMultiplier: number,
	RaiseAggression: number,
	FoldThreshold: number,
}

Poker.Personalities = {
	Aggressive = {
		BluffMultiplier = 1.2,
		RaiseAggression = 1.5,
		FoldThreshold = 0.1,
	},
	Conservative = {
		BluffMultiplier = 0.6,
		RaiseAggression = 0.8,
		FoldThreshold = 0.25,
	},
	Balanced = {
		BluffMultiplier = 1.0,
		RaiseAggression = 1.0,
		FoldThreshold = 0.15,
	},
}

local Deck = {}
Deck.__index = Deck

function Deck.new() : Deck
	local self = setmetatable({}, Deck)
	self.Cards = {}
	self.Random = Random.new()

	for i = 1, 4 do
		for j = 1, 13 do
			table.insert(self.Cards, {Rank = j, Suit = i})
		end
	end

	return self
end

function Deck:Shuffle()
	if #self.Cards <= 1 then
		return
	end

	for i = #self.Cards, 2, -1 do
		local j = self.Random:NextInteger(1, i)
		self.Cards[i], self.Cards[j] = self.Cards[j], self.Cards[i]
	end
end

function Deck:Draw()
	if #self.Cards == 0 then
		return
	end

	return table.remove(self.Cards, 1)
end


local function combinations(list, k)
	local result = {}

	local function combine(start, combo)
		if #combo == k then
			table.insert(result, table.clone(combo))
			return
		end
		for i = start, #list do
			table.insert(combo, list[i])
			combine(i + 1, combo)
			table.remove(combo)
		end
	end

	combine(1, {})
	return result
end

local function evaluateCombo(cards)
	local rankCounts = {}
	local suitCounts = {}
	local ranks = {}

	for _, card in cards do
		rankCounts[card.Rank] = (rankCounts[card.Rank] or 0) + 1
		suitCounts[card.Suit] = (suitCounts[card.Suit] or 0) + 1
		table.insert(ranks, card.Rank)
	end

	table.sort(ranks)

	local function isStraight(r)
		for i = 2, #r do
			if r[i] ~= r[i-1] + 1 then
				return r[1] == 1 and r[2] == 10 and r[3] == 11 and r[4] == 12 and r[5] == 13
			end
		end
		return true
	end

	local isFlush = false
	for _, count in pairs(suitCounts) do
		if count == 5 then
			isFlush = true
			break
		end
	end

	local straight = isStraight(ranks)

	if isFlush and straight and table.find(ranks, 1) and table.find(ranks, 13) then
		return 10, "Royal Flush"
	end
	if isFlush and straight then
		return 9, "Straight Flush"
	end

	local counts = {}
	for _, count in pairs(rankCounts) do
		table.insert(counts, count)
	end
	table.sort(counts, function(a, b) return a > b end)

	if counts[1] == 4 then return 8, "Four of a Kind" end
	if counts[1] == 3 and counts[2] == 2 then return 7, "Full House" end
	if isFlush then return 6, "Flush" end
	if straight then return 5, "Straight" end
	if counts[1] == 3 then return 4, "Three of a Kind" end
	if counts[1] == 2 and counts[2] == 2 then return 3, "Two Pair" end
	if counts[1] == 2 then return 2, "One Pair" end

	return 1, "High Card"
end

function Poker.GetValueForHand(hand: {Card}, tbl: {Card})
	local allCards = {}
	
	table.move(hand, 1, #hand, #allCards + 1, allCards)
	table.move(tbl, 1, #tbl, #allCards + #hand + 1, allCards)

	local bestValue = 0
	local bestName = "High Card"
	for _, combo in combinations(allCards, 5) do
		local value, name = evaluateCombo(combo)
		if value > bestValue then
			bestValue = value
			bestName = name
		end
	end

	return bestValue, bestName
end

function Poker:Replicate()
	for _, player in self.Players do
		if player.IsFake then continue end
		Remotes.ReplicateGameData:FireClient(player.Player, self)
	end
end

function Poker.CreateFakePlayer()
	return {
		Name = "Player_" .. HttpService:GenerateGUID(false),
	}
end

local function getRandomPersonality()
	local t = {}
	for personality, _ in Poker.Personalities do
		table.insert(t, personality)
	end

	return t[math.random(1, #t)]
end

function Poker.CreatePlayers(players: {Player}, startingChips: number) : {PokerPlayer}
	local pPlayers = {}

	for _, player in players do
		table.insert(pPlayers, {Player = player, Chips = startingChips, Hand = {}, State = "Active", Bet = 0, IsFake = false, BestHand = ""})
	end

	if #pPlayers == 1 then
		for i = 1, 5 do
			table.insert(pPlayers, {
				Player = Poker.CreateFakePlayer(), 
				Chips = startingChips, 
				Hand = {}, 
				State = "Active", 
				Bet = 0, 
				IsFake = true, 
				BestHand = "",
				Personality = getRandomPersonality(),
				Memory = {
					LastResult = nil,
					SeenRaises = 0,
					SeenFolds = 0,
					TiltFactor = 0,
					LostStreak = 0,
					Image = "Balanced",
					LastAction = nil,
					BluffSuccess = 0,
					BluffFailure = 0,
					RiskBias = 1.0,
				}
			})
		end
	end

	return pPlayers
end

function Poker:Init()
	Remotes.SendAction.OnServerEvent:Connect(function(player, action, ...)
		if action == "Start" then
			Poker.CreateGame({
				Players = game:GetService("Players"):GetPlayers(),
				StartingChips = 50,
				Ante = 10,
			}):Start()
		end
	end)
end

function Poker.CreateGame(settings: PokerGameSettings) : PokerGame
	local self = setmetatable({}, Poker)

	self.Deck = Deck.new()
	self.Players = Poker.CreatePlayers(settings.Players, settings.StartingChips)
	self.CurrentPlayer = nil
	self.Pot = 0
	self.Dealer = nil
	self.Ante = settings.Ante
	self.SmallBlindPlayer = nil
	self.BigBlindPlayer = nil
	self.GameStarted = false
	self.Round = "Pre-Flop"
	self.UUID = HttpService:GenerateGUID(false)

	for _, player in settings.Players do
		player.AncestryChanged:Once(function()
			self:RemovePlayer(player)
		end)
	end

	return self	
end

function Poker:UpdateBestHands()
	for _, player in self.Players do
		local _, hand = Poker.GetValueForHand(player.Hand, self.Table)
		player.BestHand = hand
	end
end

function Poker:Start()
	if self.GameStarted then
		return
	end

	print("GAME STARTING WITH PLAYERS: ", #self.Players)

	self.Deck:Shuffle()
	self.Table = {}
	self.Pot = 0
	self.CurrentPlayer = #self.Players >= 4 and self.Players[4] or self.Players[1]
	self.Dealer = self.Players[1]

	if #self.Players < 3 then
		self.BigBlindPlayer = self.Players[1]
		self.SmallBlindPlayer = self.Players[2]
	else
		self.BigBlindPlayer = self.Players[2]
		self.SmallBlindPlayer = self.Players[3]
	end

	self.GameStarted = true

	task.spawn(self.PreFlop, self)
end

function Poker:PreFlop()
	self = self :: PokerGame
	if not self.GameStarted then
		warn("Game not started")
		return
	end

	for _, player in self.Players do
		for i = 1,2 do
			table.insert(player.Hand, self.Deck:Draw())
		end
	end
	self:UpdateBestHands()

	self.Round = "Pre-Flop"

	self.BigBlindPlayer.Chips -= self.Ante
	self.SmallBlindPlayer.Chips -= math.round(self.Ante / 2)
	self.Pot += self.Ante * 1.5

	self:GameEvent("PreFlopStart")

	self:ResetBets()
	local success = self:GetPlayerDecisions()
	task.wait(1)

	if not success then
		task.spawn(self.Showdown, self)
		return
	end
	task.spawn(self.Flop, self)
end

function Poker:Flop()
	local self = self :: PokerGame
	if not self.GameStarted then
		warn("Game not started")
		return
	end

	for i = 1, 3 do
		table.insert(self.Table, self.Deck:Draw())
	end

	self.Round = "Flop"

	self:UpdateBestHands()
	self:ResetBets()
	self:GameEvent("Flop", self.Table)
	local success = self:GetPlayerDecisions()
	task.wait(1)

	if not success then
		task.spawn(self.Showdown, self)
		return
	end
	task.spawn(self.Turn, self)
end

function Poker:Turn()
	if not self.GameStarted then
		warn("Game not started")
		return
	end

	self.Round = "Turn"

	table.insert(self.Table, self.Deck:Draw())
	self:UpdateBestHands()
	self:ResetBets()

	self:GameEvent("Turn", self.Table)
	local success = self:GetPlayerDecisions()
	task.wait(1)

	if not success then
		task.spawn(self.Showdown, self)
		return
	end
	task.spawn(self.River, self)
end

function Poker:River()
	local self = self :: PokerGame
	if not self.GameStarted then
		warn("Game not started")
		return
	end

	self.Round = "River"

	table.insert(self.Table, self.Deck:Draw())
	self:UpdateBestHands()
	self:ResetBets()
	self:GameEvent("River", self.Table)
	local success = self:GetPlayerDecisions()
	task.wait(1)

	task.spawn(self.Showdown, self)
end

function Poker:DetermineWinner()
	local bestValue = 0
	local winners = {}

	for _, player in self.Players do
		if player.State ~= "Folded" then
			local value, _ = Poker.GetValueForHand(player.Hand, self.Table)
			if value > bestValue then
				bestValue = value
				winners = {player}
			elseif value == bestValue then
				table.insert(winners, player)
			end
		end
	end

	return winners
end

function Poker:Showdown()
	self = self :: PokerGame
	self.Round = "Showdown"
	self:UpdateBestHands()

	local winners = self:DetermineWinner()
	local splitPot = math.floor(self.Pot / #winners)

	for _, winner in winners do
		winner.Chips += splitPot
		self:GameEvent("PlayerWon", winner.Player, splitPot)
	end

	self:GameEvent("Showdown", winners)
	task.spawn(self.End, self)
end

function Poker:Restart()
	self = self :: PokerGame
	self:ResetBets()
	self.Dealer = self:GetNextPlayer()
	self.CurrentPlayer = self.Dealer

	table.move(self.Table, 1, #self.Table, #self.Deck.Cards + 1, self.Deck.Cards)
	table.clear(self.Table)

	for _, player in self.Players do
		table.move(player.Hand, 1, #player.Hand, #self.Deck.Cards + 1, self.Deck.Cards)
		table.clear(player.Hand)

		player.State = "Active"
		player.BestHand = ""
	end

	self.Deck:Shuffle()
	self.Pot = 0

	task.spawn(self.PreFlop, self)
end

function Poker:End()
	local self = self :: PokerGame

	self.Round = "End"

	self:GameEvent("End")
	task.spawn(self.Restart, self)
end

function Poker:GetNextPlayer()
	local index = table.find(self.Players, self.CurrentPlayer)
	if not index then return nil end

	local start = index
	repeat
		index = (index % #self.Players) + 1
		local nextPlayer = self.Players[index]

		return nextPlayer
	until index == start

	return nil
end

function Poker:GetPreviousPlayer(player: PokerPlayer)
	self = self :: PokerGame
	local index = table.find(self.Players, player)
	if not index then return nil end

	local startIndex = index
	repeat
		index -= 1
		if index < 1 then
			index = #self.Players
		end

		local previousPlayer = self.Players[index]
		if previousPlayer.State ~= "Folded" then
			return previousPlayer
		end
	until index == startIndex

	return nil
end

function Poker:Fold(player: PokerPlayer)
	if player.State ~= "Active" then
		return
	end

	player.State = "Folded"
	self:GameEvent("PlayerFolded", player.Player)
end

function Poker:Bet(player: PokerPlayer, amount: number)
	self = self :: PokerGame
	if player.State ~= "Active" then return end

	if self.Round == "Pre-Flop" and self.SmallBlindPlayer == player and amount < math.round(self.Ante / 2) then
		amount = math.round(self.Ante / 2)
	end

	if player.Chips < amount then
		self:AllIn(player)
		return
	end

	local previousPlayer = self:GetPreviousPlayer(player)
	local previousBet = previousPlayer and previousPlayer.Bet or 0

	if amount < previousBet then
		local raiseAmount = previousBet - amount
		if raiseAmount > 0 then
			self:Raise(player, raiseAmount)
		else
			self:Call(player)
		end
		return
	end

	self.Pot += amount
	player.Chips -= amount
	player.Bet += amount
	player.State = "Betting"

	self:GameEvent("PlayerBet", player.Player, amount)
end

function Poker:Call(player: PokerPlayer)
	self = self :: PokerGame
	if player.State ~= "Active" then return end

	local previousPlayer = self:GetPreviousPlayer(player)
	if not previousPlayer or previousPlayer.Bet == 0 then
		self:Check(player)
		return
	end

	local toCall = previousPlayer.Bet - player.Bet
	if toCall <= 0 then
		self:Check(player)
		return
	end

	if player.Chips <= toCall then
		self:AllIn(player)
		return
	end

	player.Chips -= toCall
	player.Bet += toCall
	self.Pot += toCall
	player.State = "Called"

	self:GameEvent("PlayerCalled", player.Player)
end

function Poker:Raise(player: PokerPlayer, amount: number)
	self = self :: PokerGame
	if player.State ~= "Active" then return end

	local previousPlayer = self:GetPreviousPlayer(player)
	local previousBet = previousPlayer and previousPlayer.Bet or 0

	local toCall = previousBet - player.Bet
	local totalAmount = toCall + amount

	if player.Chips < totalAmount then
		self:AllIn(player)
		return
	end

	player.Chips -= totalAmount
	player.Bet += totalAmount
	self.Pot += totalAmount
	player.State = "Raised"

	self:GameEvent("PlayerRaised", player.Player, amount)
end

function Poker:Check(player: PokerPlayer)
	self = self :: PokerGame
	if player.State ~= "Active" then return end

	if self.Round == "Pre-Flop" then
		if player == self.SmallBlindPlayer then
			local smallBlindAmount = math.round(self.Ante / 2)
			local toCall = smallBlindAmount - player.Bet
			if toCall > 0 and player.Chips >= toCall then
				self:Bet(player, toCall)
				return
			end
		else
			local toCall = self.Ante - player.Bet
			if toCall > 0 and player.Chips >= toCall then
				self:Bet(player, toCall)
				return
			end
		end
	end

	local previousPlayer = self:GetPreviousPlayer(player)
	if previousPlayer and previousPlayer.Bet > 0 and previousPlayer.Bet ~= player.Bet then
		self:Call(player)
		return
	end

	player.State = "Checked"
	self:GameEvent("PlayerChecked", player.Player)
end


function Poker:AllIn(player: PokerPlayer)
	self = self :: PokerGame
	if player.State ~= "Active" then
		return
	end

	player.Bet = player.Chips
	self.Pot += player.Bet
	player.Chips = 0

	player.State = "All-In"
	self:GameEvent("PlayerAllIn", player.Player)
end

function Poker:GameEvent(event: string, ...)
	self = self :: PokerGame

	self:Replicate()

	for _, player in self.Players do
		if player.IsFake then continue end
		Remotes.GameEvent:FireClient(player.Player, event, ...)
	end
end

function Poker:RemovePlayer(player: Player)
	self = self :: PokerGame

	local pPlayer = self:GetPlayer(player)
	if not pPlayer then
		return
	end

	local index = table.find(self.Players, pPlayer)
	if not index then
		return
	end

	table.remove(self.Players, index)
end

function Poker:GetPlayer(player: Player)
	for _, pPlayer in self.Players do
		if pPlayer.Player == player then
			return pPlayer
		end
	end

	return nil
end

function Poker:IsBettingRoundComplete()
	local activePlayers = {}
	local highestBet = 0

	for _, player in self.Players do
		if player.State == "Active" or player.State == "Called" or player.State == "Checked" or player.State == "All-In" then
			table.insert(activePlayers, player)
			if player.Bet > highestBet then
				highestBet = player.Bet
			end
		end
	end

	for _, player in activePlayers do
		if player.State ~= "All-In" and player.Bet < highestBet then
			return false
		end
	end

	return true
end

function Poker:ResetBets()
	for _, player in self.Players do
		player.Bet = 0
		if player.State ~= "Folded" and player.State ~= "All-In" then
			player.State = "Active"
		end

		local memory = player.Memory
		if memory then
			memory.SeenRaises = 0
			memory.SeenFolds = 0
			memory.LastAction = nil
		end
	end
end

function Poker:UpdatePlayerMemory()
	local winners = self:DetermineWinner()

	for _, player in self.Players do
		local memory = player.Memory
		if not memory then continue end

		local isWinner = table.find(winners, player)
		local handValue = Poker.GetValueForHand(player.Hand, self.Table)
		local wasBluff = memory.LastAction == "Raise" and handValue <= 2

		if isWinner then
			memory.LastResult = "Win"
			memory.LostStreak = 0
			memory.TiltFactor = math.max(memory.TiltFactor - 0.1, 0)

			if wasBluff then
				memory.BluffSuccess += 1
			end
		else
			memory.LastResult = "Loss"
			memory.LostStreak += 1
			memory.TiltFactor = math.min(memory.TiltFactor + 0.2, 2.0)

			if wasBluff then
				memory.BluffFailures += 1
			end
		end

		if memory.SeenRaises > memory.SeenFolds * 1.5 then
			memory.Image = "Aggressive"
		elseif memory.SeenFolds > memory.SeenRaises * 1.5 then
			memory.Image = "Passive"
		else
			memory.Image = "Balanced"
		end
	end
end

function Poker:GetAIBetAmount(player: PokerPlayer, handValue: number, personality: Personality): number	
	self = self :: PokerGame
	local rand = Random.new()
	local base = handValue * 10
	local variance = rand:NextInteger(-5, 15)
	local potFactor = math.clamp(self.Pot * 0.2, 10, 100)
	local betAmount
	if player.Chips > 10 then
		betAmount = math.clamp((base + variance) * personality.RaiseAggression + potFactor, 10, player.Chips)
	else
		betAmount = player.Chips
	end
	betAmount = math.max(1, math.floor(betAmount))
	return betAmount
end

function Poker:GetAIDecision(player: PokerPlayer, decisions: {[PokerPlayer]: {Action: string, Args: {any}}}): { Action: string, Args: {number} }
	local rand = Random.new()
	local memory = player.Memory

	local personality = Poker.Personalities[player.Personality or "Balanced"]

	local handValue = Poker.GetValueForHand(player.Hand, self.Table)
	local tableValue = #self.Table > 0 and Poker.GetValueForHand({}, self.Table) or 0
	local previousPlayer = self:GetPreviousPlayer(player)
	local previousBet = previousPlayer and previousPlayer.Bet or 0
	local toCall = math.max(previousBet - player.Bet, 0)
	local chips = player.Chips

	if player.Chips <= 0 then
		return { Action = "Quit", Args = {} }
	end

	local raises, allIns, calls = 0, 0, 0
	for _, decision in pairs(decisions) do
		if decision.Action == "Raise" then
			raises += 1
			memory.SeenRaises += 1
		elseif decision.Action == "Fold" then
			memory.SeenFolds += 1
		elseif decision.Action == "All-In" then
			allIns += 1
		elseif decision.Action == "Call" then
			calls += 1
		end
	end

	local isAggressive = raises > 0 or allIns > 0
	local potOdds = toCall / math.max(self.Pot, 1)
	local riskFactor = potOdds * (isAggressive and 1.5 or 1)

	local adjustedAggression = personality.RaiseAggression + memory.TiltFactor * 0.3
	local adjustedFoldThreshold = math.clamp(personality.FoldThreshold - memory.TiltFactor * 0.05, 0.05, 0.5)

	local bluffChance = 0
	if handValue <= 3 then
		bluffChance = ((1 - riskFactor) * 0.3 + (calls == 0 and raises == 0 and 0.2 or 0)) * personality.BluffMultiplier
	elseif handValue <= 6 then
		bluffChance = 0.05 * personality.BluffMultiplier
	end

	if rand:NextNumber() < bluffChance then
		if toCall <= chips then
			if rand:NextNumber() < 0.5 and chips > toCall + 15 then
				memory.LastAction = "Raise"
				local bluffRaise = math.min(chips - toCall, rand:NextInteger(15, 40))
				return { Action = "Raise", Args = { bluffRaise } }
			else
				memory.LastAction = "Call"
				return { Action = "Call", Args = {} }
			end
		end
	end

	local isOutplayed = handValue <= tableValue

	if toCall == 0 then
		if handValue <= 3 or isOutplayed then
			memory.LastAction = "Check"
			return { Action = "Check", Args = {} }
		else
			local bet = self:GetAIBetAmount(player, handValue, personality)
			memory.LastAction = "Bet"
			return { Action = "Bet", Args = { math.min(bet, chips) } }
		end
	end

	if handValue >= 7 then
		if chips <= toCall then
			memory.LastAction = "All-In"
			return { Action = "All-In", Args = {} }
		else
			local raiseAmount = self:GetAIBetAmount(player, handValue, personality)
			memory.LastAction = "Raise"
			return { Action = "Raise", Args = { math.min(raiseAmount, chips - toCall) } }
		end
	elseif handValue >= 4 and not isOutplayed then
		if toCall <= chips * (0.25 * adjustedAggression) then
			memory.LastAction = "Call"
			return { Action = "Call", Args = {} }
		end
	end

	if toCall <= chips * adjustedFoldThreshold and not isOutplayed then
		memory.LastAction = "Call"
		return { Action = "Call", Args = {} }
	end

	memory.LastAction = "Fold"
	return { Action = "Fold", Args = {} }
end

function Poker:GetPlayerDecisions()
	self = self :: PokerGame
	local timeOut = 10
	local decisions = {} :: {[PokerPlayer]: {Action: string, Args: {any}}}

	local startingPlayer = self.CurrentPlayer

	local connection = Remotes.SendAction.OnServerEvent:Connect(function(player, action, ...)
		local pPlayer = self:GetPlayer(player)
		if not pPlayer then
			return
		end

		if decisions[pPlayer] then
			return
		end

		local validActions = {"Fold", "Call", "Raise", "Check", "All-In", "Bet"}
		if not table.find(validActions, action) then
			return
		end

		decisions[pPlayer] = {Action = action, Args = {...}}
	end)

	local function awaitDecision()
		while true do
			if not self.CurrentPlayer then break end
	
			if self.CurrentPlayer.State ~= "Active" then
				local next = self:GetNextPlayer()
				if not next or next == startingPlayer then
					break
				end
				self.CurrentPlayer = next
				self:GameEvent("ActivePlayerChanged", self.CurrentPlayer.Player)
				continue
			end
	
			if self.CurrentPlayer.IsFake then
				task.wait(1)
				decisions[self.CurrentPlayer] = self:GetAIDecision(self.CurrentPlayer, decisions)
			else
				if self.CurrentPlayer.Chips <= 0 then
					decisions[self.CurrentPlayer] = {Action = "Quit", Args = {}}
				end
			end
	
			local waited = 0
			while not decisions[self.CurrentPlayer] and waited < timeOut do
				local dt = task.wait()
				waited += dt
			end
	
			if not decisions[self.CurrentPlayer] then
				decisions[self.CurrentPlayer] = {Action = "Fold", Args = {}}
			end
	
			local decision = decisions[self.CurrentPlayer]
			
			if decision.Action == "Fold" then
				self:Fold(self.CurrentPlayer)
			elseif decision.Action == "Call" then
				self:Call(self.CurrentPlayer)
			elseif decision.Action == "Raise" then
				self:Raise(self.CurrentPlayer, decision.Args[1])
			elseif decision.Action == "Check" then
				self:Check(self.CurrentPlayer)
			elseif decision.Action == "All-In" then
				self:AllIn(self.CurrentPlayer)
			elseif decision.Action == "Bet" then
				self:Bet(self.CurrentPlayer, decision.Args[1])
			end
	
			local nextPlayer = self:GetNextPlayer()
			if not nextPlayer or nextPlayer == startingPlayer then
				break
			end
	
			self.CurrentPlayer = nextPlayer

			if decision.Action == "Quit" then
				local index = table.find(self.Players, pPlayer)
				if not index then
					return
				end
			
				table.remove(self.Players, index)
			end

			self:GameEvent("ActivePlayerChanged", self.CurrentPlayer.Player)
		end
	end

	awaitDecision()

	connection:Disconnect()

	local activePlayers = 0
	local lastActivePlayer = nil

	for _, player in self.Players do
		if player.State ~= "Folded" then
			activePlayers += 1
			lastActivePlayer = player
		end
	end

	if activePlayers == 1 and lastActivePlayer then
		return false
	end

	return decisions
end

return Poker