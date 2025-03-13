local Util = {}

type DurationInfo = {
    Years: number,
    Months: number,
    Days: number,
    Hours: number,
    Minutes: number,
    Seconds: number,

    Fraction: number,
    Sign: number,
}

local AverageDaysPerMonth = 365 / 12

local MinuteLength = 60
local HourLength = 60 * MinuteLength
local DayLength = 24 * HourLength
local MonthLength = AverageDaysPerMonth * DayLength
local YearLength = 12 * MonthLength

function Util.DurationInfo(Time: number): DurationInfo
    local Sign = math.sign(Time)
    local Time = math.abs(Time)

    local Years = math.floor(Time / YearLength)
    local Months = math.floor((Time - Years * YearLength) / MonthLength)
    local TotalMonths = Years * 12 + Months

    local Days = math.floor((Time - TotalMonths * MonthLength) / DayLength)
    local TotalDays = TotalMonths * AverageDaysPerMonth + Days

    local Hours = math.floor((Time - TotalDays * DayLength) / HourLength)
    local TotalHours = TotalDays * 24 + Hours

    local Minutes = math.floor((Time - TotalHours * HourLength) / MinuteLength)
    local TotalMinutes = TotalHours * 60 + Minutes

    local Seconds = math.floor((Time - TotalMinutes * MinuteLength))

    return {
        Years = Years,
        Months = Months,
        Days = Days,
        Hours = Hours,
        Minutes = Minutes,
        Seconds = Seconds,

        Fraction = Time - Seconds,
        Sign = if Sign == -1 then -1 else 1
    }
end

function Util.FormatDuration(Duration: DurationInfo, Separator: string?): string
    local Separator: string = Separator or " "

    return `{if Duration.Sign == -1 then "-" else ""}`
    .. `{if Duration.Years > 0 then `{Duration.Years}` .. "Y" .. Separator else ""}`
    .. `{if Duration.Months > 0 then `{Duration.Months}` .. "M" .. Separator else ""}`
    .. `{if Duration.Days > 0 then `{Duration.Days}` .. "D" .. Separator else ""}`
    .. `{if Duration.Hours > 0 then `{Duration.Hours}` .. "h" .. Separator else ""}`
    .. `{if Duration.Minutes > 0 then `{Duration.Minutes}` .. "m" .. Separator else ""}`
    .. `{if Duration.Seconds > 0 then `{Duration.Seconds}` .. "s" .. Separator else ""}`
end

return Util