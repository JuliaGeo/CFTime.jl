function Dates.len(first::T, last::T, step::DT) where T <: AbstractCFDateTime where
    DT <: Union{Dates.Day,Dates.Hour,Dates.Minute,Dates.Second,Dates.Millisecond}
    return Dates.value(last-first) ÷ Dates.value(Dates.Millisecond(step))
end

function Dates.len(first::T, last::T, step) where T <: AbstractCFDateTime
    if Dates.value(step) == 0
        error("the step should not be zero")
    end
    len = 0
    next = first+step
    while next <= last
        next = next+step
        len = len+1
    end
    return len
end

