--!strict
local RunService = game:GetService("RunService")
local StepEvent = if RunService:IsClient() then RunService.RenderStepped else RunService.Heartbeat

local Gizmo = require(script.Gizmo)

type Gizmo = {
    setColor: (color: Color3) -> Gizmo,
    setScale: (scale: number) -> Gizmo,
    setThickness: (thickness: number) -> Gizmo,

    lifetime: (time: number) -> Gizmo,

    arrow: (from: Vector3, to: Vector3) -> Gizmo,
    box: (at: CFrame, size: Vector3) -> Gizmo,
    line: (from: Vector3, to: Vector3) -> Gizmo,
    point: (at: Vector3) -> Gizmo,
    ray: (at: Vector3, direction: Vector3) -> Gizmo,
    sphere: (at: Vector3, radius: number) -> Gizmo,
    text: (at: Vector3, text: string, ...unknown) -> Gizmo,
    wireBox: (at: CFrame, size: Vector3) -> Gizmo,
    wireSphere: (at: Vector3, radius: number) -> Gizmo,
}

local Util = {}
local GizmoUtil = Util :: Gizmo

function Util.Start(): Gizmo
    Gizmo.reset()

    return GizmoUtil
end

function Util.setColor(color: Color3): Gizmo
    Gizmo.setColor(color)

    return GizmoUtil
end

function Util.setScale(scale: number): Gizmo
    Gizmo.setScale(scale)

    return GizmoUtil
end

function Util.setThickness(thickness: number): Gizmo
    Gizmo.setThickness(thickness)

    return GizmoUtil
end

function Util.arrow(from: Vector3, to: Vector3): Gizmo
    Gizmo.drawArrow(from, to)

    return GizmoUtil
end

function Util.box(at: CFrame, size: Vector3): Gizmo
    Gizmo.drawBox(at, size)

    return GizmoUtil
end

function Util.line(from: Vector3, to: Vector3): Gizmo
    Gizmo.drawLine(from, to)

    return GizmoUtil
end

function Util.point(at: Vector3): Gizmo
    Gizmo.drawPoint(at)

    return GizmoUtil
end

function Util.ray(at: Vector3, direction: Vector3): Gizmo
    Gizmo.drawRay(at, direction)

    return GizmoUtil
end

function Util.sphere(at: Vector3, radius: number): Gizmo
    Gizmo.drawSphere(CFrame.new(at), radius)

    return GizmoUtil
end

function Util.text(at: Vector3, text: string, ...: unknown): Gizmo
    Gizmo.drawText(at, text, ...)

    return GizmoUtil
end

function Util.wireBox(at: CFrame, size: Vector3): Gizmo
    Gizmo.drawWireBox(at, size)

    return GizmoUtil
end

function Util.wireSphere(at: Vector3, radius: number): Gizmo
    Gizmo.drawWireSphere(CFrame.new(at), radius)

    return GizmoUtil
end

function Util.lifetime(time: number): Gizmo
    local Lifetime = time

    local GizmoInstructions = {}
    local StartedAt = tick()

    local GizmoLifetimeTable
    GizmoLifetimeTable = setmetatable({}, {
        __index = function(tab, index)
            if index == "lifetime" then
                return function(fakeTime: number)
                    Lifetime = fakeTime

                    return GizmoLifetimeTable
                end
            end

            local GizmoValue = Util[index]
            if not GizmoValue then return nil :: never end

            if typeof(GizmoValue) == "function" then
                return function(...)
                    table.insert(GizmoInstructions, {Instruction = index, Args = {...}})
                    return GizmoLifetimeTable
                end
            end

            return Util[index]
        end
    }) :: never

    local LifetimeConnection: RBXScriptConnection
    LifetimeConnection = StepEvent:Connect(function()
        if tick() - StartedAt > Lifetime then
            LifetimeConnection:Disconnect()
            return
        end

        Util.Start()

        for i,v in pairs(GizmoInstructions) do
            Util[v.Instruction](unpack(v.Args))
        end
    end)

    return GizmoLifetimeTable
end

return function(): Gizmo
    return Util.Start()
end
