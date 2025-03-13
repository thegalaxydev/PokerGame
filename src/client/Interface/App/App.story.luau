local ClientInterface = script.Parent.Parent

local Functions = require(ClientInterface.Functions)
local QuickStory = Functions.QuickStory

local App = require(script.Parent)

return QuickStory(function()
    return App()
end)