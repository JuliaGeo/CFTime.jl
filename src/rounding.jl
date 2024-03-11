


function round(::Type{DateTime}, dt::AbstractCFDateTime,r = RoundNearestTiesUp)
    function round_ms(t)
        t_ms =
            if 3+_exponent(t) > 0
                t.duration * _factor(t) * 10^(3+_exponent(t))
            else
                t.duration * _factor(t) / 10^(-3-_exponent(t))
            end

        t_ms_rounded =
            if t_ms isa Integer
                Int64(t_ms)
            else
                round(Int64,t_ms,r)
            end
        return Dates.Millisecond(t_ms_rounded)
    end

    origintuple = _origintuple(dt)
    origin = _origin_period(dt)

    if length(origintuple) >= 7
        # origin needs to be taken into account when rounding
        duration = round_ms(dt.instant + origin) + DATETIME_OFFSET
    else
        # better accuracy if dt.instant is a Float
        duration = round_ms(dt.instant) + origin + DATETIME_OFFSET
    end

    return DateTime(UTInstant{Millisecond}(Dates.Millisecond(duration)))

end


# TODO: make generic
function Base.floor(dt::DateTimeStandard,p::Period)
    origintuple = _origintuple(dt)
    origin = _origin_period(dt)
    t = dt.instant + origin
    t_mod = (t - mod(t,p)) - origin
    return DateTimeStandard{typeof(t_mod), Val(origintuple)}(t_mod)
end

function Base.floor(dt::AbstractCFDateTime,p::Dates.TimePeriod)
    floor(dt,convert(Period,p))
end
