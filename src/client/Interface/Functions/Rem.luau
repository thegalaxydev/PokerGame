local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.vide)

local Camera = workspace.CurrentCamera

local DEFAULT_REM = 16
local MIN_REM = 8
local MAX_REM = math.huge

local ASPECT_RATIO_WIDTH = 16
local ASPECT_RATIO_HEIGHT = 9
local MAX_ASPECT_RATIO = ASPECT_RATIO_WIDTH / ASPECT_RATIO_HEIGHT

local BASE_RESOLUTION_WIDTH = 1920
local BASE_RESOLUTION_HEIGHT = 1020
local BASE_RESOLUTION = Vector2.new(BASE_RESOLUTION_WIDTH, BASE_RESOLUTION_HEIGHT)

local SLOW_DOWN_SCALE = 0.25

local Rem = Vide.source(0)

local function update()
    local Resolution = Vector2.new(
        math.min(Camera.ViewportSize.X, Camera.ViewportSize.Y * MAX_ASPECT_RATIO),
        Camera.ViewportSize.Y
    )

    local Scale = Resolution.Magnitude / BASE_RESOLUTION.Magnitude
    local IsDesktop = Resolution.X > Resolution.Y or Scale >= 1

    local Factor = if IsDesktop then Scale else math.map(Scale, 0, 1, SLOW_DOWN_SCALE, 1)

    local NewRem = math.clamp(math.round(DEFAULT_REM * Factor), MIN_REM, MAX_REM)
    Rem(NewRem)
end

Camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
update()

return function(number: number): number
    return number * Rem()
end