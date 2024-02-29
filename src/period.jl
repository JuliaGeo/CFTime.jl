# Period constructors or methods with Period as first (or main) argument

# sadly Dates.CompoundPeriod allocates a vector otherwise
# Dates.CompoundPeriod could have been used instead of CFTime.Period

Period(duration::Number,factor,exponent=-3) = Period{typeof(duration),Val(factor),Val(exponent)}(duration)

_type(p::Period{T,factor,exponent}) where {T,factor,exponent} = T
_factor(p::Period{T,factor,exponent}) where {T,factor,exponent} = unwrap(factor)
_exponent(p::Period{T,factor,exponent}) where {T,factor,exponent} = unwrap(exponent)


_type(::Type{Period{T,factor,exponent}}) where {T,factor,exponent} = T
_factor(::Type{Period{T,factor,exponent}}) where {T,factor,exponent} = unwrap(factor)
_exponent(::Type{Period{T,factor,exponent}}) where {T,factor,exponent} = unwrap(exponent)

function Base.zero(p::Period{T,numerator,denominator}) where {T,numerator,denominator}
    Period{T,numerator,denominator}(0)
end

function Base.one(p::Period{T,numerator,denominator}) where {T,numerator,denominator}
    Period{T,numerator,denominator}(1)
end


Dates.value(p::Period) = p.duration

@inline __tf(result,time) = result
@inline function __tf(result,time,d1,dn...)
   if d1 == 0
       __tf((result...,0),0,dn...)
   else
       p, time2 = divrem(time, d1, RoundDown)
       __tf((result...,p),time2,dn...)
    end
end
@inline tf(time,divi) = __tf((),time,divi...)

# rescale the time units for the ratio factor/exponent
@inline function division(T,factor,exponent)
    (T(10)^(-exponent) .* getindex.(TIME_DIVISION,2)) .÷ (T(10) .^ (.- getindex.(TIME_DIVISION,3)) .* factor)
end

@inline function datenum_(tuf::Tuple,factor,exponent)
    T =  promote_type(typeof.(tuf)...)
    divi = division(T,factor,exponent)
    return sum(divi[1:length(tuf)] .* tuf)
end

function timetuplefrac(t::Period{T,Tfactor}) where {T,Tfactor}
    # for integers
    factor = _factor(t)
    exponent = _exponent(t)
    divi = division(T,factor,exponent)
    time = t.duration
    tf(time,divi)
end


function Period(tuf::Tuple,factor,exponent=-3)
    duration = datenum_(tuf,factor,exponent)
    Period{typeof(duration),Val(factor),Val(exponent)}(duration)
end

function Period(T::DataType,tuf::Tuple,factor,exponent=-3)
    duration = T(datenum_(tuf,factor,exponent))
    Period{typeof(duration),Val(factor),Val(exponent)}(duration)
end

+(p1::Period,p2::Union{Dates.TimePeriod,Dates.Day}) = p1 + convert(CFTime.Period,p2)
+(p1::Union{Dates.TimePeriod,Dates.Day},p2::Period) = p2 + p1

function -(p::Period{T,Tfactor,Texponent}) where {T, Tfactor, Texponent}
    Period{T,Tfactor,Texponent}(-p.duration)
end

-(p1::Period,p2::Period) = p1 + (-p2)
-(p1::Period,p2) = p1 + (-p2)
-(p1,p2::Period) = p1 + (-p2)

for T in (:Day, :Hour, :Minute, :Second, :Millisecond, :Microsecond, :Nanosecond)
    unit = Symbol(lowercase(string(T)))
    factor, exponent = filter(td -> td[1] == unit,TIME_DIVISION)[1][2:end]

    @eval convert(::Type{CFTime.Period},t::Dates.$T) = Period{Int64,Val($factor),Val($exponent)}(Dates.value(t))
end

# Can throw an InexactError
Dates.Millisecond(p::CFTime.Period{T, Val{1}(), Val{-3}()}) where T =
    Dates.Millisecond(Int64(p.duration))

==(p1::Period,p2::Period) = Dates.value(p1 - p2) == 0
==(p1::Period,p2) = Dates.value(p1 - p2) == 0
==(p1,p2::Period) = Dates.value(p1 - p2) == 0

function isless(p1::Period,p2::Period)
    return Dates.value(p1 - p2) < 0
end
