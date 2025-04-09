local Types = {}

export type PVInstanceLike = {
    GetPivot: (self: PVInstanceLike) -> CFrame
}

export type CameraMode = "Spline" | "Linear"
export type TargetMode = "LookAt" | "Align" | "Ignore"
export type SpeedMode = "Duration" | "Constant"

export type TransitionData = {
    Style: Enum.EasingStyle?,
    Direction: Enum.EasingDirection?,
    Duration: number,
}

export type CutsceneEvent = {
    Time: number,
    Target: PVInstanceLike?,

    Speed: number?,
    Roll: number?,
    Fov: number?,

    Transition: TransitionData?,
}

export type CutsceneSegment = {
    From: PVInstanceLike,
    To: PVInstanceLike,

    SplineControlPointDistance: number?,

    Duration: number,

    CameraMode: CameraMode,
    SpeedMode: SpeedMode?,

    Target: PVInstanceLike?,
    TargetMode: TargetMode?,

    Events: {CutsceneEvent}


}

export type Cutscene = {CutsceneSegment}

return Types