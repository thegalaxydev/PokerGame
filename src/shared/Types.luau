export type Card = {
	Rank: number,
	Suit: number,
}

export type Deck = {
	Cards: {Card},
	Shuffle: (self: Deck) -> (),
	Draw: (self: Deck) -> Card
}

export type GameEvent = "PreFlopStart" | "FlopStart" | "TurnStart" | "RiverStart" | "ShowdownStart" | "End" | "PlayerWon" | "PlayerFolded" | "PlayerAllIn" | "PlayerCalled" | "PlayerRaised" | "PlayerBet" | "PlayerChecked" | "PlayerShowdown" | "PlayerOut" | "PlayerCalled" | "PlayerRaised" | "PlayerBet" | "PlayerChecked" | "PlayerShowdown" | "PlayerOut"

export type PokerPlayer = {
	Player: Player,
	Chips: number,
	Hand: {Card},
	BestHand: string,
	State: "Active" | "Folded" | "All-In" | "Out" | "Called" | "Raised" | "Betting" | "Showdown" | "Checked",
	Bet: number,
	IsFake: boolean?,
	Personality: string?,
	Memory: {
		LastResult: "Win" | "Loss" | nil,
		SeenRaises: number,
		SeenFolds: number,
		TiltFactor: number,
		LostStreak: number,
		Image: string,
		LastAction: string,
		BluffSuccess: number,
		BluffFailure: number,
		RiskBias: number,
	}?,
}

export type PokerGameSettings = {
	Players: {Player},
	StartingChips: number,
	Ante: number,
}

export type PokerGame = {
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
	UUID: string,

	Start: (self: PokerGame) -> (),
	Fold: (self: PokerGame, player: PokerPlayer) -> (),
	Bet: (self: PokerGame, player: PokerPlayer, amount: number) -> (),
	Call: (self: PokerGame, player: PokerPlayer) -> (),
	Raise: (self: PokerGame, player: PokerPlayer, amount: number) -> (),
	Check: (self: PokerGame, player: PokerPlayer) -> (),
	AllIn: (self: PokerGame, player: PokerPlayer) -> (),
	GetNextPlayer: (self: PokerGame) -> PokerPlayer,
	GetPreviousPlayer: (self: PokerGame, player: PokerPlayer) -> PokerPlayer,
	GetPlayerDecisions: (self: PokerGame) -> {[PokerPlayer]: {Action: string, Args: {any}}},
	PreFlop: (self: PokerGame) -> (),
	Flop: (self: PokerGame) -> (),
	Turn: (self: PokerGame) -> (),
	River: (self: PokerGame) -> (),
	Showdown: (self: PokerGame) -> (),
	End: (self: PokerGame) -> (),

	GetValueForHand: (hand: {Card}) -> number,
	UpdateBestHands: (self: PokerGame) -> (),
	CreateGame: (settings: PokerGameSettings) -> PokerGame,
	GameEvent: (self: PokerGame, event: string, ...any) -> (),
}

return {}