local StarterGui = game:GetService("StarterGui")

local Util = {}

function Util.SetCoreEnabled(Type: Enum.CoreGuiType, Enabled: boolean)
    task.spawn(function()
        while true do
            local Success = pcall(function()
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType, Enabled)
            end)

            if Success then break end

            task.wait()
        end
    end)
end

function Util.SetCore(Name: string, Value: any)
    task.spawn(function()
        while true do
            local Success = pcall(function()
                StarterGui:SetCore(Name, Value)
            end)

            if Success then break end

            task.wait()
        end
    end)
end

function Util.GetCore(Name: string): any
    while true do
        local Success, CoreValue = pcall(function()
            return StarterGui:GetCore(Name)
        end)

        if Success then return CoreValue end

        task.wait()
    end
end

function Util.GetCoreGuiEnabled(Type: Enum.CoreGuiType): boolean
    while true do
        local Success, Enabled = pcall(function()
            return StarterGui:GetCoreGuiEnabled(Type)
        end)

        if Success then return Enabled end

        task.wait()
    end
end

return Util