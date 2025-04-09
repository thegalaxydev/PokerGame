--!strict
if true then return end

local Types = require(script.Parent.Parent.types)

type Cutscene = Types.Cutscene

local Cutscene: Cutscene = {
    {
        From = workspace.Cutscene.Test.Node1,
        To = workspace.Cutscene.Test.Node2,

        CameraMode = "Linear",
        SpeedMode = "Duration",
        LookAt = workspace.Cutscene.Test.Target,

        SplineControlPointDistance = 20,

        Duration = 5,

        Events = {
            {
                Roll = math.rad(90),
                Time = 0.5,
                Transition = {
                    Direction = Enum.EasingDirection.InOut,
                    Style = Enum.EasingStyle.Sine,
                    Duration = 0.1
                }
            },

            {
                Roll = math.rad(270),
                Fov = 20,
                Time = 2,
                Transition = {
                    Direction = Enum.EasingDirection.InOut,
                    Style = Enum.EasingStyle.Sine,
                    Duration = 1
                },
            },
            
            {
                Roll = math.rad(90),
                Time = 4,
                Transition = {
                    Direction = Enum.EasingDirection.InOut,
                    Style = Enum.EasingStyle.Sine,
                    Duration = 1
                }
            },
            {
                Fov = 70,
                Time = 5,

                Transition = {
                    Duration = 1,
                    Style = Enum.EasingStyle.Back,
                    Direction = Enum.EasingDirection.Out
                }
            }
        }
    },

    {
        From = workspace.Cutscene.Test.Node2,
        To = workspace.Cutscene.Test.Node3,

        CameraMode = "Spline",
        SpeedMode = "Duration",
        LookAt = workspace.Cutscene.Test.Target2,

        SplineControlPointDistance = 20,

        Duration = 5,

        Speed = 10,

        Events = {}
    }
}

return Cutscene