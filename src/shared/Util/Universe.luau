local Util = {}

type EnvironmentValues<T> = {
    Production: T;
    Staging: T;
    Development: T;
}

local Places = {
	Lobby = 132592681211617,
	Game = 111860833280751
}

local Experiences = {
	Production = 7361112416,
    Staging = 0,
    Development = 0,
}

function Util.IsPublic(): boolean
    return not (Util.IsReserved() or Util.IsPrivate())
end

function Util.IsReserved(): boolean
    return game.PrivateServerId ~= "" and not Util.IsPrivate()
end

function Util.IsPrivate(): boolean
    return game.PrivateServerId ~= "" and game.PrivateServerOwnerId ~= 0
end

function Util.IsProduction(): boolean
    return game.GameId == Experiences.Production
end

function Util.IsStaging(): boolean
    return game.GameId == Experiences.Staging
end

function Util.IsDevelopment(): boolean
    return game.GameId == Experiences.Development
end

function Util.LobbyId()
    return Places.Lobby
end

function Util.GameValue<T>(Values: EnvironmentValues<T>): T
    if Util.IsProduction() then
        return Values.Production
    elseif Util.IsStaging() then
        return Values.Staging
    elseif Util.IsDevelopment then
        return Values.Staging
    end

    warn("Invalid game for UniverseUtil.GameValue:", game.GameId)
    return nil :: never
end

return Util