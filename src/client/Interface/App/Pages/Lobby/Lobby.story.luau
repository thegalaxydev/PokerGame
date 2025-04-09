local ClientInterface = script.Parent.Parent.Parent.Parent

local Functions = require(ClientInterface.Functions)
local QuickStory = Functions.QuickStory

local Component = require(script.Parent)

return QuickStory(function()
    return Component()
end)