# The angle contract (README, "Angles"):
#   sin cos tan sec csc cot        read a plain number as radians
#   sind cosd tand secd cscd cotd  read a plain number as degrees
#   an angle with a unit (30°, 0.5rad) is converted, so it is right in both families
#   inverse functions return a tagged angle (rad or °), so the unit travels with the value
# Calls that look like the wrong family still compute, but leave a hint for the user.

"Messages for the user collected during one evaluation (the engine empties it)."
const HINTS = String[]

pi_fraction(k::Rational) = string(numerator(k) == 1 ? "" : numerator(k) == -1 ? "-" : numerator(k),
                                  "π", denominator(k) == 1 ? "" : "/$(denominator(k))")

# Whole multiples of 15 above 15 are almost always degrees.
function radian_hint(name, x)
    isinteger(x) && abs(x) >= 15 && rem(x, 15) == 0 || return
    push!(HINTS, "$name takes radians; $(fmt_number(x)) looks like degrees: use $(name)d($(fmt_number(x))) or $name($(fmt_number(x))°)")
end

# Non-integer multiples of π/12 (π/4, π/6, ...) are almost always radians.
function degree_hint(name, x)
    k = 12x / π
    !isinteger(x) && 0 < abs(x) <= 2π + 1e-9 && isapprox(k, round(k); atol = 1e-9) || return
    r = round(Int, k) // 12
    push!(HINTS, "$name takes degrees; $(pi_fraction(r)) looks like radians: use $(chop(name))($(pi_fraction(r))) or $name($(fmt_number(180r)))")
end

function on_angle(name, f, fd, x::Quantity)
    dimension(x) == NoDims || throw(ArgumentError("$name needs an angle such as 30° or 0.5rad, got $(short(x))"))
    return unit(x) == ° ? fd(ustrip(x)) : f(ustrip(NoUnits, x))   # degrees stay exact: sin(180°) == 0
end

for (f, fd) in ((:sin, :sind), (:cos, :cosd), (:tan, :tand), (:sec, :secd), (:csc, :cscd), (:cot, :cotd))
    @eval begin
        @doc $("$f(x): x in radians (plain number) or an angle with unit, e.g. $f(π/6), $f(30°)")
        $f(x::Real) = (radian_hint($(string(f)), x); Base.$f(x))
        $f(x::Number) = Base.$f(x)
        $f(x::Quantity) = on_angle($(string(f)), Base.$f, Base.$fd, x)

        @doc $("$fd(x): x in degrees (plain number) or an angle with unit, e.g. $fd(30), $fd(π/6*rad)")
        $fd(x::Real) = (degree_hint($(string(fd)), x); Base.$fd(x))
        $fd(x::Quantity) = on_angle($(string(fd)), Base.$f, Base.$fd, x)
    end
end

for (f, fd) in ((:asin, :asind), (:acos, :acosd), (:atan, :atand), (:asec, :asecd), (:acsc, :acscd), (:acot, :acotd))
    @eval begin
        @doc $("$f(x): returns an angle in radians, shown in rad and °")
        $f(x) = Base.$f(x) * rad
        @doc $("$fd(x): returns an angle in degrees, shown in ° and rad")
        $fd(x) = Base.$fd(x) * °
    end
end
atan(y, x) = Base.atan(y, x) * rad
atand(y, x) = Base.rad2deg(Base.atan(y, x)) * °

"deg2rad(x): x in degrees (plain number) or an angle with unit; returns rad"
deg2rad(x::Real) = Base.deg2rad(x) * rad
deg2rad(x::Quantity) = uconvert(rad, x)

"rad2deg(x): x in radians (plain number) or an angle with unit; returns °"
rad2deg(x::Real) = Base.rad2deg(x) * °
rad2deg(x::Quantity) = uconvert(°, x)

# SI reads a plain number as radians, so 45° + 10 would silently mean 45° + 10 rad.
# Refuse that mix. Adding a rad quantity and a plain number stays allowed: rad = 1 in SI.
isdegrees(x) = x isa Quantity && unit(x) == °
function check_angle_mix(op, x, y)
    plain = isdegrees(x) && y isa Real ? y : isdegrees(y) && x isa Real ? x : return
    throw(ArgumentError("$(short(x)) $op $(short(y)): a plain number next to degrees " *
                        "would be read as radians; write $(fmt_number(plain))° or $(fmt_number(plain))rad"))
end

"x + y: adding a plain number to degrees is refused (write 10° or 10rad)"
+(x, y) = (check_angle_mix(:+, x, y); Base.:+(x, y))
+(x) = Base.:+(x)
+(x, y, z, rest...) = +(+(x, y), z, rest...)

"x - y: subtracting a plain number from degrees is refused (write 10° or 10rad)"
-(x, y) = (check_angle_mix(:-, x, y); Base.:-(x, y))
-(x) = Base.:-(x)
