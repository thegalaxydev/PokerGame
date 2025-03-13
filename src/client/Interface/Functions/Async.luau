local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.vide)

local function Async<T>(Default: T, Compute: () -> T?): Vide.source<T>
    local Value = Vide.source(Default)

    task.spawn(function()
        local Result = Compute()
        if not Result then return end

        Value(Result)
    end)

    return Value
end

return Async