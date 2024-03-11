


function round(::Type{DateTime}, dt::AbstractCFDateTime,r = RoundNearestTiesUp)
    origin = _origin_period(dt)
    t = dt.instant + (origin + DATETIME_OFFSET)

    t_ms =
        if 3+_exponent(t) > 0
            t.duration * _factor(t) * 10^(3+_exponent(t))
        else
            t.duration * _factor(t) / 10^(-3-_exponent(t))
        end

    t_ms_rounded = round(Int64,t_ms,r)
    return DateTime(UTInstant{Millisecond}(Dates.Millisecond(t_ms_rounded)))
end


function Base.floor(dt::DateTimeStandard,p::Period)
    origintuple = _origintuple(dt)
    origin = _origin_period(dt)
    t = dt.instant + origin

    tt = t - mod(t,p)

    ttt = tt - origin

    return DateTimeStandard{typeof(ttt), Val(origintuple)}(ttt)
end

function Base.floor(dt::DateTimeStandard,p::Dates.TimePeriod)
    floor(dt,convert(Period,p))
end
