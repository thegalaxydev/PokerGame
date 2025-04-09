local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.vide)

local Create = Vide.create

local Defaults = {
    Size = UDim2.fromScale(1, 1),
    Position = UDim2.fromScale(.5, .5),
    AnchorPoint = Vector2.new(.5,.5),
    BackgroundTransparency = 1,
    TextColor3 = Color3.new(1,1,1),
    Text = "",
    TextScaled = true,
}

local function TextLabel(Props)
    Props = Props or {}
    for i,v in pairs(Defaults) do
        if Props[i] ~= nil then continue end

        Props[i] = Props[i] or Defaults[i]
    end

    return Create "TextLabel" (Props)
end

return TextLabel