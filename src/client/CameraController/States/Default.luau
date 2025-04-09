local Base = require(script.Parent.Base)

local State = {}
State.__index = Base

function State.new()
    return setmetatable(Base.new(), State)
end

return State