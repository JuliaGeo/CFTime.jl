abstract type AbstractCFDateTime{T,Torigintuple} <: Dates.TimeType
end


"""
    Period{T,Tfactor,Texponent}

Period wraps a number duration of type T where

duration * factor * 10^exponent

represents the time in seconds
"""
struct Period{T,Tfactor,Texponent}
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
