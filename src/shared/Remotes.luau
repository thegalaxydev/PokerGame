local RunService = game:GetService("RunService")

type Remote<T...> = {
	Name: string,
	Parent: Instance,
	FireClient: (Player: Player, T...) -> (),
	FireServer: (T...) -> (),
	FireAllClients: (T...) -> (),
	OnClientEvent: {
		Connect: ((T...)->()) -> RBXScriptConnection,
		Once: ((T...)->()) -> RBXScriptConnection,
		Wait: () -> T...,
	},
	OnServerEvent: {
		Connect: ((T...)->()) -> RBXScriptConnection,
		Once: ((T...)->()) -> RBXScriptConnection,
	},
} & RemoteEvent

local function Remote(name: string)
	if RunService:IsServer() then
		local Event = Instance.new("RemoteEvent")
		Event.Parent = script
		Event.Name = name
		return Event
	else
		return script:WaitForChild(name)
	end
end

local t = {
	SendAction = Remote("SendAction") :: Remote<string, any?>,
}



return t
