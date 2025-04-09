local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.vide)

local Create = Vide.create

local Defaults = {
    Size = UDim2.fromScale(1, 1),
    Position = UDim2.fromScale(.5, .5),
    AnchorPoint = Vector2.new(.5,.5),
    BackgroundTransparency = 0,
}

local function Frame(Props)
    Props = Props or {}
    for i,v in pairs(Defaults) do
        if Props[i] ~= nil then continue end

        Props[i] = Props[i] or Defaults[i]
    end

    return Create "Frame" (Props)
end

return Frame