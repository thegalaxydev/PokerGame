local CutsceneEffect = require(script.CameraCutscene)
local Types = require(script.types)

type CutsceneEffect = CutsceneEffect.CutsceneEffect
type Cutscene = Types.Cutscene
type CutsceneSegment = Types.CutsceneSegment

local Controller = {}
Controller.CurrentCutscene = nil :: CutsceneEffect?

local SplinePathCache: {[CutsceneSegment]: {[number]: {Vector3}}?} = {}

function Controller:EndCutscene()
    if not Controller.CurrentCutscene then return end

    Controller.CurrentCutscene:Destroy()
    Controller.CurrentCutscene = nil
end

function Controller:PlayCutscene(Cutscene: Cutscene)
    Controller:EndCutscene()

    Controller.CurrentCutscene = CutsceneEffect.new(Cutscene)
end

function Controller:GetSplinePath(Segment: CutsceneSegment, Resolution: number): {Vector3}
    local Cache = SplinePathCache[Segment]
    if not Cache then
        local Path = self:CalculateSplinePath(Segment, Resolution)
        SplinePathCache[Segment] = {[Resolution] = Path}

        return Path
    end
    
    local Path = Cache[Resolution]
    if not Path then
        Path = self:CalculateSplinePath(Segment, Resolution)
        Cache[Resolution] = Path
    end

    return Path
end

function Controller:CalculateSplinePath(Segment: CutsceneSegment, Resolution: number): {Vector3}
    local FromPivot = Segment.From:GetPivot()
    local ToPivot = Segment.To:GetPivot()
    
    local P1 = FromPivot.Position
    local P2 = P1 + FromPivot.LookVector * (Segment.SplineControlPointDistance or 1)

    local P4 = ToPivot.Position
    local P3 = P4 - ToPivot.LookVector * (Segment.SplineControlPointDistance or 1)
    
    local Out = table.create(Resolution)
    for i = 0,Resolution-1 do
        table.insert(Out, Controller:SolveSpline(P1, P2, P3, P4, i / (Resolution-1)))
    end

    return Out
end

function Controller:SolveSpline(P1: Vector3, P2: Vector3, P3: Vector3, P4: Vector3,T: number): Vector3
    local I1 = P1:Lerp(P2, T)
    local I2 = P2:Lerp(P3, T)
    local I3 = P3:Lerp(P4, T)

    local J1 = I1:Lerp(I2, T)
    local J2 = I2:Lerp(I3, T)

    return J1:Lerp(J2, T)
end

function Controller.Init()

end

Controller.Init()

return Controller