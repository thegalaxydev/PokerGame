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
		local j = self.Random:NextNumber(1, i)
		self.Cards[i], self.Cards[j] = self.Cards[j], self.Cards[i]
	end
end

function Deck:Draw()
	if #self.Cards == 0 then
		return
	end

	return table.remove(self.Cards, 1)
end


function Poker.CreatePlayers(players: {Player}, startingChips: number) : {PokerPlayer}
	local pPlayers = {}

	for _, player in players do
		table.insert(pPlayers, {Player = player, Chips = startingChips, Hand = {}, State = "Active", Bet = 0})
	end

	return pPlayers
end

function Poker.GetValueForHand(hand: {Card}) : (number, string)
	table.sort(hand, function(a,b)
		return a.Rank < b.Rank
	end)

	local rankCounts = {}
	local suitCounts = {}
	local lastSuit = hand[1].Suit

	local isFlush = true
	for _, card in hand do
		rankCounts[card.Rank] = (rankCounts[card.Rank] or 0) + 1
		suitCounts[card.Suit] = (suitCounts[card.Suit] or 0) + 1

		if card.Suit ~= lastSuit then
			isFlush = false
		end
	end

	local isStraight = true
	for i = 2, #hand do
		if hand[i].Rank ~= hand[i-1].Rank + 1 then
			isStraight = false
			break
		end
	end

	if not isStraight and hand[1].Rank == 1 and hand[2].Rank == 10 then
		isStraight = true
	end

	local pairsCount, threeOfAKindCount, fourOfAKindCount = 0, 0, 0

	for _, count in rankCounts do
		if count == 2 then
			pairsCount += 1
		elseif count == 3 then
			threeOfAKindCount += 1
		elseif count == 4 then
			fourOfAKindCount += 1
		end
	end

	if isFlush and isStraight and hand[#hand].Rank == 13 and hand[1].Rank == 1 then
		return 10, "Royal Flush"
	end

	if isFlush and isStraight then
		return 9, "Straight Flush"
	end

	if fourOfAKindCount > 0 then
		return 8, "Four of a Kind"
	end

	if threeOfAKindCount > 0 and pairsCount > 0 then
		return 7, "Full House"
	end

	if isFlush then
		return 6, "Flush"
	end

	if isStraight then
		return 5, "Straight"
	end

	if threeOfAKindCount > 0 then
		return 4, "Three of a Kind"
	end

	if pairsCount == 2 then
		return 3, "Two Pair"
	end

	if pairsCount == 1 then
		return 2, "One Pair"
	end

	return 1, "High Card"

end

function Poker:Replicate()
	for _, player in self.Players do
		Remotes.ReplicateGameData:FireClient(player, self)
	end
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

function Poker:Start()
	if self.GameStarted then
		return
	end

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
end

function Poker:GetNextPlayer()
	for i = 1, #self.Players do
		if self.Players[i] == self.CurrentPlayer then
			return self.Players[(i % #self.Players) + 1]
		end
	end

	return nil
end

function Poker:GetPreviousPlayer(player: PokerPlayer)
	local index = table.find(self.Players, player)
	local previousPlayer = self.Players[index - 1] or self.Players[#self.Players]
	while previousPlayer and previousPlayer.State == "Folded" do
		index = index - 1
		previousPlayer = self.Players[index - 1] or self.Players[#self.Players]
	end
	return previousPlayer
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
	if player.State ~= "Active" then
		return
	end

	if self.Round == "Pre-Flop" and self.SmallBlindPlayer == player and amount < math.round(self.Ante / 2) then
		amount = math.round(self.Ante / 2)
	end

	if player.Chips < amount then
		Poker:AllIn(player)
		return
	end

	local previousPlayer = self:GetPreviousPlayer(player)

	if previousPlayer.Bet > amount then
		Poker:Raise(player, previousPlayer.Bet - amount)
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
	if player.State ~= "Active" then
		return
	end

	local previousPlayer = self:GetPreviousPlayer(player)

	if previousPlayer.Bet > player.Chips then
		Poker:AllIn(player)
		return
	end

	player.Bet = previousPlayer.Bet
	self.Pot += player.Bet
	player.Chips -= player.Bet
	player.State = "Called"
	
	self:GameEvent("PlayerCalled", player.Player)
end

function Poker:Raise(player: PokerPlayer, amount: number)
	self = self :: PokerGame
	if player.State ~= "Active" then
		return
	end
	
	local previousPlayer = self:GetPreviousPlayer(player)

	if player.Chips < previousPlayer.Bet + amount then
		Poker:AllIn(player)
		return
	end

	self.Pot += previousPlayer.Bet + amount
	player.Chips -= previousPlayer.Bet + amount
	player.Bet += previousPlayer.Bet + amount
	player.State = "Raised"

	self:GameEvent("PlayerRaised", player.Player, amount)
end

function Poker:Check(player: PokerPlayer)
	self = self :: PokerGame
	if player.State ~= "Active" then
		return
	end

	local previousPlayer = self:GetPreviousPlayer(player)

	if previousPlayer.Bet > 0 and previousPlayer.Bet == player.Bet then
		Poker:Call(player)
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
		Remotes.GameEvent:FireClient(player.Player, event, ...)
	end
end

function Poker:RemovePlayer(player: Player)
	self = self :: PokerGame

	local pPlayer = self:GetPlayer(player)
	if not pPlayer then
		return
	end

	table.remove(self.Players, pPlayer)
end

function Poker:GetPlayer(player: Player)
	for _, pPlayer in self.Players do
		if pPlayer.Player == player then
			return pPlayer
		end
	end

	return nil
end

function Poker:GetPlayerDecisions()
	self = self :: PokerGame
	local timeOut = 10
	local startTime = os.time()
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
		repeat task.wait() until decisions[self.CurrentPlayer] or (os.time() - startTime >= timeOut)
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
		if nextPlayer == startingPlayer then
			if not nextPlayer then
				return
			end

			if self.CurrentPlayer.Bet <= nextPlayer.Bet then
				return
			end
		end

		self.CurrentPlayer = nextPlayer
		awaitDecision()
	end

	awaitDecision()

	return decisions
end

function Poker:PreFlop()
	self = self :: PokerGame
	if not self.GameStarted then
		warn("Game not started")
		return
	end

	self.BigBlindPlayer.Chips -= self.Ante
	self.SmallBlindPlayer.Chips -= math.round(self.Ante / 2)
	self.Pot += self.Ante

	Poker:GameEvent("PreFlopStart")

	self:GetPlayerDecisions()
	self:Flop()
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

	self:GameEvent("Flop", self.Table)
	self:GetPlayerDecisions()
	self:Turn()
end

function Poker:Turn()
	local self = self :: PokerGame
	if not self.GameStarted then
		warn("Game not started")
		return
	end
	
	table.insert(self.Table, self.Deck:Draw())
	self:GameEvent("Turn", self.Table)
	self:GetPlayerDecisions()
	self:River()
end

function Poker:River()
	local self = self :: PokerGame
	if not self.GameStarted then
		warn("Game not started")
		return
	end
	
	table.insert(self.Table, self.Deck:Draw())
	self:GameEvent("River", self.Table)
	self:GetPlayerDecisions()
	self:Showdown()
end

function Poker:Showdown()
	local self = self :: PokerGame
	if not self.GameStarted then
		warn("Game not started")
		return
	end

	self:GameEvent("Showdown")
end

function Poker:End()
	local self = self :: PokerGame
	
	self:GameEvent("End")
end

return Poker