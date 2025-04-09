--!strict

for i,v in pairs(script:GetDescendants()) do
    if not v:IsA("ModuleScript") then continue end

    local success, result = pcall(function()
        return require(v) :: never
    end)

    if not success then
        warn(`Failure while trying to load module \"({v:GetFullName()})\", \"{result}\"`)
        continue
    end

    if typeof(result) ~= "table" then continue end
    if typeof(result.Init) ~= "function" then continue end

    result:Init()
end