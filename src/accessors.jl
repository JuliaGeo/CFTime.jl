Dates.year(dt::AbstractCFDateTime) = datetuple(dt)[1]
Dates.month(dt::AbstractCFDateTime) = datetuple(dt)[2]
Dates.day(dt::AbstractCFDateTime) = datetuple(dt)[3]
Dates.hour(dt::AbstractCFDateTime)   = datetuple(dt)[4]
Dates.minute(dt::AbstractCFDateTime) = datetuple(dt)[5]
Dates.second(dt::AbstractCFDateTime) = datetuple(dt)[6]
Dates.millisecond(dt::AbstractCFDateTime) = datetuple(dt)[7]

for (i,func) in enumerate((:microsecond,:nanosecond))
    ituple = i+7

    @eval function Dates.$func(dt::AbstractCFDateTime)
        t = datetuple(dt)
        if length(t) >= $ituple
            return t[$ituple]
        else
            return 0
        end
    end
end

for func in (:year, :month, :day, :hour, :minute, :second, :millisecond)
    name = string(func)
    @eval begin
        @doc """
            Dates.$($name)(dt::AbstractCFDateTime) -> Int64

        Extract the $($name)-part of a `AbstractCFDateTime` as an `Int64`.
        """ $func(dt::AbstractCFDateTime)
    end
end


for (i,(name,factor,exponent)) in enumerate(TIME_DIVISION)
    function_name = Symbol(uppercasefirst(String(name)))

    @eval begin
        @inline function $function_name(dt::T) where T <: AbstractCFDateTime
            datetuple(dt)[$(i+2)] # years and months are special
        end
    end
end

