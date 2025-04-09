local Util = {}

export type PVInstanceLike = {
    GetPivot: (self: PVInstanceLike) -> CFrame
}

function Util.GetPivotRoll(Pivot: PVInstanceLike): number
    local _X, _Y, Roll = Pivot:GetPivot():ToEulerAnglesYXZ()

    return Roll
end

--[=[
    @param current Vector3 -- The current rotation to use as a basis
    @param vec Vector3 -- The target rotation which you'd like to be fixed

    This function is designed to fix some simple issues with converting orientations directly into vector3s,
    specifically to make springing or interpolating these values easier.

    Given two vectors `current` and `vec`, calculates whether any of the axes of rotation make more than `math.pi` degrees of rotation
    in any direction and flips those orientations to be less than `math.pi`. This fixed rotation vector represents the same orientation
    as `vec`, except the difference between each respective component in `current` and `vec` is within +/- `math.pi`.

    @return Vector3 -- A fixed rotation that represents the same orientation as `vec` but with the minimum distance from `current` in euler space.
]=]
function Util.FixVectorOrientation(current: Vector3, vec: Vector3): Vector3
    -- if math.abs(vec.X - current.X) > math.pi then if current.X < 0 then print("X1") else print("X2") end else end
    -- if math.abs(vec.Y - current.Y) > math.pi then if current.Y < 0 then print("Y1") else end else end
    -- if math.abs(vec.Z - current.Z) > math.pi then if current.Z < 0 then print("Z1", current, vec) else print("Z2", current, vec) end else end

    return Vector3.new(
        if math.abs(vec.X - current.X) > math.pi then if current.X < 0 then vec.X - math.pi * 2 else vec.X + math.pi * 2 else vec.X,
        if math.abs(vec.Y - current.Y) > math.pi then if current.Y < 0 then vec.Y - math.pi * 2 else vec.Y + math.pi * 2 else vec.Y,
        if math.abs(vec.Z - current.Z) > math.pi then if current.Z < 0 then vec.Z - math.pi * 2 else vec.Z + math.pi * 2 else vec.Z
    )
end

function Util.DeltaLerp(a: number, b: number, f: number, dt: number): number
    local alpha = 1 - (1 - f)^dt

    return a + (b - a) * alpha
end

function Util.PVAttachment(Attachment: Attachment): PVInstanceLike
    return {
        GetPivot = function()
            return Attachment.WorldCFrame
        end
    }
end

return Util