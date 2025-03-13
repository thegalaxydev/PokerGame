--!strict
local MemoryStoreService = game:GetService("MemoryStoreService")

local DEFAULT_EXPIRATION = 60 * 60 * 24 * 30 --// 30 days, GDPR compliant
local DEFAULT_RETRIES = 3

local SortedMap = {}
SortedMap.__index = SortedMap

type SortKey = string | number
type SortBound = {
    Key: string,
    SortKey: SortKey?
}

type UpdateTransformCallback<T> = (data: T?, sortKey: SortKey?) -> (T?, SortKey?)

export type SortedMap<T = unknown> = {
    InternalStore: MemoryStoreSortedMap,
    Name: string,

    Get: (self: SortedMap<T>, Key: string, Retries: number?) -> (boolean, T),
    Set: (self: SortedMap<T>, Key: string, Value: T, Expiration: number?, SortKey: SortKey?, Retries: number?) -> (boolean, boolean),
    Update: (self: SortedMap<T>, Key: string, Transform: UpdateTransformCallback<T>, Expiration: number?, Retries: number?) -> (boolean, T, SortKey),
    Remove: (self: SortedMap<T>, Key: string, Retries: number?) -> boolean,
    GetRange: (self: SortedMap<T>, Direction: Enum.SortDirection, Count: number, LowerBound: SortBound?, UpperBound: SortBound?, Retries: number?) -> (boolean, {T}),
}

function SortedMap.new<T>(Name: string): SortedMap<T>
    local self = (setmetatable({}, SortedMap) :: never) :: SortedMap<T>

    self.InternalStore = MemoryStoreService:GetSortedMap(Name)
    self.Name = Name

    return self
end

function SortedMap:Set(Key: string, Value: unknown, Expiration: number?, SortKey: SortKey?, Retries: number?): (boolean, boolean)
    local self = self :: SortedMap
    local Retries = (Retries or DEFAULT_RETRIES - 1)
    local Expiration = Expiration or DEFAULT_EXPIRATION

    local Success, DidOverwrite = pcall(function()
        return self.InternalStore:SetAsync(Key, Value, Expiration, SortKey)
    end)

    if Success then return true, DidOverwrite end
    if Retries <= 0 then return false, false end

    return self:Set(Key, Value, Expiration, SortKey, Retries - 1)
end

function SortedMap:Get(Key: string, Retries: number?): (boolean, unknown)
    local self = self :: SortedMap
    local Retries = (Retries or DEFAULT_RETRIES - 1)

    local Success, Data = pcall(function()
        return self.InternalStore:GetAsync(Key)
    end)

    if Success then return true, Data end
    if Retries <= 0 then return false end

    return self:Get(Key, Retries - 1)
end

function SortedMap:Remove(Key: string, Retries: number?): boolean
    local self = self :: SortedMap
    local Retries = (Retries or DEFAULT_RETRIES - 1)

    local Success, Data = pcall(function()
        return self.InternalStore:RemoveAsync(Key)
    end)

    if Success then return true, Data end
    if Retries <= 0 then return false end

    return self:Remove(Key, Retries - 1)
end

function SortedMap:Update(Key: string, Transform: UpdateTransformCallback<unknown>, Expiration: number?, Retries: number?): (boolean, unknown?, SortKey?)
    local self = self :: SortedMap
    local Retries = (Retries or DEFAULT_RETRIES - 1)
    local Expiration = Expiration or DEFAULT_EXPIRATION

    local Success, NewValue: unknown?, NewKey: SortKey? = pcall(function()
        return self.InternalStore:UpdateAsync(Key, Transform, Expiration) :: never
    end)

    if Success then return true, NewValue, NewKey end
    if Retries <= 0 then return false end

    return self:Update(Key, Transform, Expiration, Retries)
end

function SortedMap:GetRange(Direction: Enum.SortDirection, Count: number, LowerBound: SortBound?, UpperBound: SortBound?, Retries: number?): (boolean, {unknown}?)
    local self = self :: SortedMap
    local Retries = (Retries or DEFAULT_RETRIES - 1)

    local Success, Values = pcall(function()
        return self.InternalStore:GetRangeAsync(
            Direction,
            Count,
            if LowerBound then { key = LowerBound.Key, sortKey = LowerBound.SortKey} else nil,
            if UpperBound then { key = UpperBound.Key, sortKey = UpperBound.SortKey} else nil
        )
    end)

    if Success then return true, Values end
    if Retries <= 0 then return false end

    return self:GetRange(Direction, Count, LowerBound, UpperBound, Retries)
end

return SortedMap