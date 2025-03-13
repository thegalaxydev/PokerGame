local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Vide = require(ReplicatedStorage.Packages.vide)

return function(story: () -> ())
    return {
        vide = Vide,
        story = function(props)
            return Vide.create "Frame" {
                Size = UDim2.fromScale(1,1),
                Position = UDim2.fromScale(.5,.5),
                AnchorPoint = Vector2.new(.5,.5),
                BackgroundTransparency = 1,

                story()
            }
        end
    }
end