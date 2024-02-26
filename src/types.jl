abstract type AbstractCFDateTime <: Dates.TimeType
end

const RegTime = Union{Dates.Millisecond,Dates.Second,Dates.Minute,Dates.Hour,Dates.Day}


for (CFDateTime,calendar) in [(:DateTimeStandard,"standard"),
                              (:DateTimeJulian,"julian"),
                              (:DateTimeProlepticGregorian,"prolepticgregorian"),
                              (:DateTimeAllLeap,"allleap"),
                              (:DateTimeNoLeap,"noleap"),
                              (:DateTime360Day,"360day")]
    @eval begin
        struct $CFDateTime <: AbstractCFDateTime
            instant::UTInstant{Millisecond}
            $CFDateTime(instant::UTInstant{Millisecond}) = new(instant)
        end
    end
end



"""
if T is a integer
duration * factor * 10^exponent represents the time in seconds
"""
struct Period{T,factor,exponent}
    duration::T
end


struct DateTime2{T,origintupe} <: AbstractCFDateTime
    instant::T
end
