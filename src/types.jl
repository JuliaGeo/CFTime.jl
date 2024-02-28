abstract type AbstractCFDateTime{T,Torigintuple} <: Dates.TimeType
end

const RegTime = Union{Dates.Millisecond,Dates.Second,Dates.Minute,Dates.Hour,Dates.Day}



"""
Period wraps a number duration of type T where

duration * factor * 10^exponent

represents the time in seconds
"""
struct Period{T,factor,exponent}
    duration::T
end


for (CFDateTime,calendar) in [(:DateTimeStandard,"standard"),
                              (:DateTimeJulian,"julian"),
                              (:DateTimeProlepticGregorian,"prolepticgregorian"),
                              (:DateTimeAllLeap,"allleap"),
                              (:DateTimeNoLeap,"noleap"),
                              (:DateTime360Day,"360day")]
    @eval begin
        struct $CFDateTime{T,Torigintuple} <: AbstractCFDateTime{T,Torigintuple}
            instant::T
        end

    end
end
