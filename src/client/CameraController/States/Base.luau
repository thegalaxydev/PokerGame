--!strict
local CameraController = require(script.Parent.Parent)

type CameraEffect = CameraController.CameraEffectData
type CameraState = CameraEffect & {}

local State = {}
State.__index = {}

function State.new(): CameraState
    local self = (setmetatable({}, State) :: never) :: CameraState

    return self
end

function State:Update()
    
end

return State