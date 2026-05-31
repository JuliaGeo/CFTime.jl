function Dates.len(first::T, last::T, step::DT) where {T <: AbstractCFDateTime} where
    {DT <: Union{Period, Dates.Day, Dates.Hour, Dates.Minute, Dates.Second, Dates.Millisecond}}
    roundlen(x::AbstractFloat) = Int(x)
    roundlen(x::T) where T = promote_type(T,Int)(x)

    if Dates.value(step) == 0
        throw(ArgumentError("step cannot be zero"))
    end
    return roundlen((last - first) ÷ step)
end

function Dates.len(first::T, last::T, step) where {T <: AbstractCFDateTime}
    if Dates.value(step) == 0
        throw(ArgumentError("step cannot be zero"))
    end
    len = 0
    next = first + step
    while next <= last
        next = next + step
        len = len + 1
    end
    return len
end
