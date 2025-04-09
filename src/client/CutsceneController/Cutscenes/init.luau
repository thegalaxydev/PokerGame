local CutsceneLookup = {}
for i,v in pairs(script:GetChildren()) do
    if not v:IsA("ModuleScript") then continue end

    local Success, Cutscene = pcall(require,v)
    if not Success then
        warn(`Cutscene ({v:GetFullName()}) Encountered an error while loading!`)
        continue
    end

    if typeof(Cutscene) ~= "table" then
        warn(`Cutscene ({v:GetFullName()}) Does not return a table!`)
        continue
    end

    if Cutscene.Events then
        if typeof(Cutscene.Events) ~= "table" then
            warn(`Cutscene ({v:GetFullName()}) Does not have a valid events table!`)
            continue
        end

        local InvalidEvent = false
        for i,v in ipairs(Cutscene.Events) do
            if typeof(v) ~= "table" then
                warn(`Cutscene Event ({v:GetFullName()}.Events[{i}]) is not a valid event table!`)
                
                InvalidEvent = true
                break
            end

            if typeof(v.Time) ~= "number" then
                warn(`Cutscene Event ({v:GetFullName()}.Events[{i}]) Does not have a valid time!`)

                InvalidEvent = true
                break
            end
        end

        if InvalidEvent then continue end

        table.sort(Cutscene.Events, function(a,b)
            return a.Time < b.Time
        end)
    end

    CutsceneLookup[v.Name] = Cutscene
end

return CutsceneLookup