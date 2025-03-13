local SortedMap = require(script.SortedMap)

export type SortedMap<T = unknown> = SortedMap.SortedMap<T>

local Util = {}

function Util.SortedMap<T>(Name: string)
    return SortedMap.new(Name) :: SortedMap<T>
end

return Util