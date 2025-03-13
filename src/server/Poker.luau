local Poker = {}
Poker.__index = Poker

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Remotes = require(ReplicatedStorage.Shared.Remotes)

type Card = {
	Rank: number,
	Suit: number,
}

type Deck = {
	Cards: {Card},
	Shuffle: (self: Deck) -> (),
	Draw: (self: Deck) -> Card
}

type PokerPlayer = {
	Player: Player,
	Chips: number,
	Hand: {Card},
	State: "Active" | "Folded" | "All-In" | "Out" | "Called" | "Raised" | "Betting" | "Showdown",
	Bet: number,
}

type PokerGameSettings = {
	Players: {Player},
	StartingChips: number,
	Ante: number,
}

type PokerGame = {
	Deck: Deck,
	Table: {Card},
	Players: {PokerPlayer},
	CurrentPlayer: PokerPlayer,
	Pot: number,
	Dealer: PokerPlayer,
	Ante: number,
	SmallBlindPlayer: PokerPlayer,
	BigBlindPlayer: PokerPlayer,
	GameStarted: boolean,
	Round: "Pre-Flop" | "Flop" | "Turn" | "River" | "Showdown" | "End",
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

function Poker:Fold(player: PokerPlayer)

end

function Poker:PreFlop()
	if not self.GameStarted then
		warn("Game not started")
		return
	end

	local timeOut = 10

	for _, player in self.Players do
		
	end


	-- round timer (not doin ts)
end

return Poker