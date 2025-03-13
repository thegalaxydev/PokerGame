local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.vide)

export type Page = "None" | "Lobby"

return {
    Page = Vide.source("None") :: Vide.source<Page>,
    TransitionAt = Vide.source(0)
}