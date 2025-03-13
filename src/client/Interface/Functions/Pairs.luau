local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.vide)

local function Pairs<I, VI, VO>(
    input: () -> {[I]: VI},
    transform: (value: VI, index: I) -> VO
)
    local index_caches = {} :: {[I]: {
        previous_input: VI,
        output: VO,
        destroy: () -> ()
    }}

    -- destroy all scopes if the parent scope is destroyed
    Vide.cleanup(function()
        for _, cache in index_caches do
            assert(cache).destroy()
        end
    end)

    return Vide.derive(function()
        local new_input = input()

        -- destroy scopes of removed indexes
        for i, cache in index_caches do
            if new_input[i] == nil or new_input[i] ~= cache.previous_input then
                assert(cache).destroy()
                index_caches[i] = nil
            end
        end

        -- create scopes or update sources of added or changed index values
        for i, v in new_input do
            local cache = index_caches[i]
            if cache then continue end

            local destroy, result = Vide.root(function()
                return transform(v, i)
            end)

            index_caches[i] = {
                destroy = destroy,
                output = result,
                previous_input = v
                }
        end

        -- return the cached output values as an array
        local array = table.create(#index_caches)

        for _, cache in index_caches do
            table.insert(array, assert(cache).output)
        end
        
        return array
    end)
end

return Pairs