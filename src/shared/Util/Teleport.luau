--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Janitor = require(ReplicatedStorage.Packages.janitor)

type Janitor = Janitor.Janitor
type TeleportData = {
    Data: any,
    Players: {number},
    Id: string,
    Retry: number,
}

local Util = {}

local ActiveTeleports: {[string]: {
    Thread: thread,
    Janitor: Janitor,
    Resumed: boolean,
    Players: {Player},
    FailedPlayers: number
}} = {}

local TeleportTryTimeoutTime = 20
local MaxTeleportRetries = 3

function Util.ReserveServer(Place: number)
    local AccessCode, ServerId = TeleportService:ReserveServer(Place)

    return AccessCode, ServerId
end

--[=[
    Attempts to teleport a set of players with the specified options.

    Yields until all players have either been removed from the game or exhausted their retries.

    Returns true if all players have left the game, most likely due to a successful teleport, and false if some players failed their teleport.
    Also returns a list of remaining players.
]=]
function Util.Teleport(TeleportPlayers: {Player}, Place: number, Options: TeleportOptions): (boolean, {Player})
    local PlayerIds = {}
    for i,v in pairs(TeleportPlayers) do
        table.insert(PlayerIds,v.UserId)
    end

    local TeleportUUID = HttpService:GenerateGUID()

    local TeleportData = {
        Data = Options:GetTeleportData(),
        Players = PlayerIds,
        Id = TeleportUUID ,
        Retry = 0
    }
    local TeleportOptions = Options:Clone()
    TeleportOptions:SetTeleportData(TeleportData)

    local Thread = coroutine.running()
    local TeleportJanitor = Janitor.new()
    
    local TeleportInfo = {
        Thread = Thread,
        Players = table.clone(TeleportPlayers),
        Janitor = TeleportJanitor,
        Resumed = false,
        FailedPlayers = 0
    }
    ActiveTeleports[TeleportUUID] = TeleportInfo

    local Success, _Result = pcall(function()
        return TeleportService:TeleportAsync(Place, TeleportPlayers, TeleportOptions)
    end)

    if not Success then
        ActiveTeleports[TeleportUUID] = nil
        TeleportJanitor:Destroy()
        return false, TeleportInfo.Players
    end

    TeleportJanitor:Add(function()
        if TeleportInfo.Resumed then return end

        TeleportInfo.Resumed = true
        coroutine.resume(TeleportInfo.Thread, false)
    end)

    TeleportJanitor:Add(task.delay(TeleportTryTimeoutTime, function()
        TeleportJanitor:Cleanup()
    end))

    for i,v in pairs(TeleportPlayers) do
        TeleportJanitor:Add(v.AncestryChanged:Connect(function()
            if v.Parent ~= Players then
                table.remove(TeleportInfo.Players, table.find(TeleportInfo.Players, v))
            end

            if TeleportInfo.FailedPlayers >= #TeleportInfo.Players then
                TeleportInfo.Resumed = true
                coroutine.resume(TeleportInfo.Thread, TeleportInfo.FailedPlayers < 1)
            end
        end), "Disconnect")
    end

    local Successful = coroutine.yield()
    TeleportInfo.Resumed = true
    TeleportInfo.Janitor:Cleanup()
    
    return not not Successful, TeleportInfo.Players
end

function Util.GetTeleportData(Player: Player): {[any]: any}
    local Data = Player:GetJoinData()
    
    local TeleportData = Data.TeleportData :: {[any]: any}
    if not TeleportData then return {} end
    if typeof(TeleportData) ~= "table" then return {} end

    local InternalTeleportData = TeleportData.Data
    if not InternalTeleportData then return {} end
    if typeof(InternalTeleportData) ~= "table" then return {} end

    return InternalTeleportData
end

TeleportService.TeleportInitFailed:Connect(function(Player: Player, Result: Enum.TeleportResult, Error: string, Place: number, Options: TeleportOptions)
    local TeleportData = Options:GetTeleportData() :: TeleportData
    if not TeleportData then return end
    if typeof(TeleportData) ~= "table" then return end
    if typeof(TeleportData.Id) ~= "string" then return end

    local TeleportInfo = ActiveTeleports[TeleportData.Id]
    if not TeleportInfo then return end

    if TeleportData.Retry < MaxTeleportRetries then
        TeleportData.Retry += 1
        Options:SetTeleportData(TeleportData)
        TeleportService:TeleportAsync(Place, {Player}, Options)
    else
        TeleportInfo.FailedPlayers += 1
        
        if TeleportInfo.FailedPlayers >= #TeleportInfo.Players then
            TeleportInfo.Resumed = true
            coroutine.resume(TeleportInfo.Thread, false)
        end
    end
end)

return Util