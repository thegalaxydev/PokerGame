local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)
local RunService = game:GetService("RunService")

export type PokerGame = Types.PokerGame

export type ClientEventMethod<T...> = {
	Connect: (self: ClientEventMethod<T...>, callback: (T...) -> ()) -> RBXScriptConnection,
	Once: (self: ClientEventMethod<T...>, callback: (T...) -> ()) -> RBXScriptConnection,
	Wait: (self: ClientEventMethod<T...>) -> (T...),
}

export type ServerEventMethod<T...> = {
	Connect: (self: ServerEventMethod<T...>, callback: (Player: Player, T...) -> ()) -> RBXScriptConnection,
	Once: (self: ServerEventMethod<T...>, callback: (Player: Player, T...) -> ()) -> RBXScriptConnection,
	Wait: (self: ServerEventMethod<T...>) -> (Player, T...)
}

export type Event<T...> = {
	Name: string,
	Parent: Instance,
	FireClient: (self: Event<T...>, Player: Player, T...) -> (),
	FireServer: (self: Event<T...>, T...) -> (),
	FireAllClients: (self: Event<T...>, T...) -> (),
	OnClientEvent: ClientEventMethod<T...>,
	OnServerEvent: ServerEventMethod<T...>,
} & Instance

export type Function<T...> = {
	Name: string,
	Parent: Instance,
	InvokeClient: (self: Function<T...>, Player: Player, T...) -> (T...),
	InvokeServer: (self: Function<T...>, T...) -> (T...),
	OnClientInvoke: (self: Function<T...>, T...) -> (T...),
	OnServerInvoke: (self: Function<T...>, T...) -> (T...),
} & Instance

local function RemoteEvent<T...>(name: string) : Event<T...>
	if RunService:IsServer() then
		local Event = Instance.new("RemoteEvent")
		Event.Parent = script
		Event.Name = name
		return Event :: Event<T...>
	else
		return script:WaitForChild(name) :: Event<T...>
	end
end

local function RemoteFunction<T...>(name: string, callback: ((T...) -> any)?) : Function<T...>
	if RunService:IsServer() then
		local Function = Instance.new("RemoteFunction")
		Function.Parent = script
		Function.Name = name
		Function.OnServerInvoke = callback
		return Function
	else
		return script:WaitForChild(name) :: Function<T...>
	end
end

local t = {
	SendAction = RemoteEvent("SendAction") :: Event<string>,
	ReplicateGameData = RemoteEvent("ReplicateGameData") :: Event<Types.PokerGame>,
	GameEvent = RemoteEvent("GameEvent") :: Event<Types.GameEvent, ...any>,
}

return t

