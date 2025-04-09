local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)
local RunService = game:GetService("RunService")

export type Event<T> = {
	Name: string,
	Parent: Instance,
	FireClient: (Player: Player, T) -> (),
	FireServer: (T) -> (),
	FireAllClients: (T) -> (),
	OnClientEvent: {
		Connect: ((T)->()) -> RBXScriptConnection,
		Once: ((T)->()) -> RBXScriptConnection,
		Wait: () -> T,
	},
	OnServerEvent: {
		Connect: ((T)->()) -> RBXScriptConnection,
		Once: ((T)->()) -> RBXScriptConnection,
	},
} & Instance

export type Function<T> = {
	Name: string,
	Parent: Instance,
	InvokeClient: (Player: Player, T) -> T,
	InvokeServer: (T) -> T,
	OnClientInvoke: (T) -> T,
	OnServerInvoke: (T) -> T,
} & Instance

local function RemoteEvent(name: string)
	if RunService:IsServer() then
		local Event = Instance.new("RemoteEvent")
		Event.Parent = script
		Event.Name = name
		return Event
	else
		return script:WaitForChild(name)
	end
end

local function RemoteFunction<T>(name: string, callback: ((T) -> any)?) : Function<T>
	if RunService:IsServer() then
		local Function = Instance.new("RemoteFunction")
		Function.Parent = script
		Function.Name = name
		Function.OnServerInvoke = callback
		return Function
	else
		return script:WaitForChild(name)
	end
end

local t = {
	SendAction = RemoteEvent("SendAction") :: Event<string>,
	ReplicateGameData = RemoteEvent("ReplicateGameData") :: Event<Types.PokerGame>,
	GameEvent = RemoteEvent("GameEvent") :: Event<string>,
}

return t
