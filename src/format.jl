# Text for results. 12 significant digits hides float noise (0.1 + 0.2 shows as 0.3).

fmt_number(x::Integer) = string(x)
fmt_number(x::Rational) = isinteger(x) ? string(numerator(x)) : fmt_number(float(x))   # exact unit factors
fmt_number(x::AbstractFloat) = @sprintf("%.12g", x)
fmt_number(x::AbstractIrrational) = fmt_number(float(x))
function fmt_number(z::Complex)
    re, im = reim(z)
    return string(fmt_number(re), signbit(im) ? " - " : " + ", fmt_number(abs(im)), "im")
end
fmt_number(x) = sprint(show, x)

# Unitful's own rendering with real superscripts (V cm⁻¹, m²); 45° has no space.
unit_string(u) = sprint(show, u; context = :fancy_exponent => true)
unit_text(u) = u == u"°" ? "°" : " " * unit_string(u)

"A unit as typed (\"cm^-1\", \"m^2\") with superscripts, for labels."
superscripts(s) = replace(s, "^-1" => "⁻¹", "^2" => "²", "^3" => "³")

"Number and unit only, for use inside messages."
short(x) = fmt_number(x)
short(q::Unitful.Quantity) = fmt_number(ustrip(q)) * unit_text(unit(q))

"Format any calculator result; angles are shown in both degrees and radians."
format_value(x) = fmt_number(x)
format_value(x::AbstractString) = x
"The same angle in the other unit (° ↔ rad), or `nothing` for anything that is not an angle."
other_angle(x) = x isa Unitful.Quantity && unit(x) in (u"°", u"rad") ?
    uconvert(unit(x) == u"°" ? u"rad" : u"°", x) : nothing

function format_value(q::Unitful.Quantity)
    alt = other_angle(q)
    return alt === nothing ? short(q) : short(q) * "   (= " * short(alt) * ")"
end
format_value(t::NamedTuple) = join(("$k = $(format_value(v))" for (k, v) in pairs(t)), "\n")
format_value(v::Union{Tuple,AbstractVector}) = "[" * join(map(format_value, v), ", ") * "]"
format_value(u::Unitful.Units) = unit_string(u)
