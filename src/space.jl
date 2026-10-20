"""
The names a user can type, on top of Julia's Base and the units found by `lookup_unit`.
Exported names shadow Base in each session. The first line of each docstring is the
signature shown in GUI tooltips and in the live signature line.
"""
module Space

using Unitful: Unitful, Quantity, NoDims, NoUnits, dimension, unit, ustrip, uconvert, upreferred, rad, °, @u_str
using ..JuliaCalc: fmt_number, short, photon_equivalent, readable

include("angles.jl")
include("geometry.jl")
include("physics.jl")

"e: Euler's number 2.71828..."
const e = ℯ

"si(x): convert a quantity to SI base units, e.g. si(1mi) gives 1609.344 m"
si(x) = upreferred(x)

export sin, cos, tan, sec, csc, cot, sind, cosd, tand, secd, cscd, cotd,
       asin, acos, atan, asec, acsc, acot, asind, acosd, atand, asecd, acscd, acotd,
       deg2rad, rad2deg, +, -,
       circle, sphere, cylinder, cone, rectangle, box, arc, polar, cart, dist, triangle, photon,
       e, si

end
