# Unit vocabulary. Everything comes from Unitful; this file only adds a few common non-SI
# units, ASCII spellings for symbols that are awkward to type, and the converter categories.

module ExtraUnits
using Unitful
using Unitful: m, s, J, kg, hr, mi, inch, ft, lbf

@unit nmi "nmi" NauticalMile     1852m                  false
@unit kn  "kn"  Knot             1852m / 3600s          false
@unit mph "mph" MilePerHour      1mi / hr               false
@unit gal "gal" USGallon         231inch^3              false
@unit t   "t"   Tonne            1000kg                 false
@unit au  "au"  AstronomicalUnit 149_597_870_700m       false
@unit ly  "ly"  LightYear        9_460_730_472_580_800m false
@unit hp  "hp"  Horsepower       550ft * lbf / s        false
@unit Wh  "Wh"  WattHour         3600J                  true   # true: kWh, MWh, ... too

__init__() = Unitful.register(ExtraUnits)
end

# `h` is the hour (SI symbol) rather than Unitful's Planck constant, which becomes `planck`.
# `min` is resolved to minutes only where it is used as a value (see engine.jl).
const ALIASES = Dict{Symbol,Any}(
    :deg => u"°", :degC => u"°C", :degF => u"°F", :ohm => u"Ω", :um => u"μm", :us => u"μs",
    :h => u"hr", :min => u"minute", :kph => u"km/hr", :kmh => u"km/hr",
    :planck => Unitful.h, :hbar => Unitful.ħ,
)

"""
    lookup_unit(name::Symbol)

The unit or physical constant (`c0`, `G`, `k`, ...) called `name`, or `nothing`.
Order: ASCII aliases, then JuliaCalc's extra units, then Unitful.
"""
function lookup_unit(name::Symbol)
    haskey(ALIASES, name) && return ALIASES[name]
    for mod in (ExtraUnits, Unitful)
        isdefined(mod, name) || continue
        v = getfield(mod, name)
        (v isa Unitful.Units || v isa Unitful.Quantity) && return v
    end
    return nothing
end

"Evaluate a unit expression such as `\"km/h\"` or `\"m^2\"` using `lookup_unit` for names."
function parse_unit(str::AbstractString)
    resolve(x::Symbol) = something(lookup_unit(x), x)   # operators (/, ^) stay symbols
    resolve(x::Expr) = Expr(x.head, map(resolve, x.args)...)
    resolve(x) = x
    return Core.eval(@__MODULE__, resolve(Meta.parse(str)))
end

# Photon equivalence: E = h ν = h c / λ and wavenumber 1/λ describe the same photon. This is
# physics, not a unit identity, so it is opt-in: only `photon(x)` and the Photon category use it.
function photon_wavelength(x)
    d = dimension(x)
    d == dimension(u"m") && return x
    d == dimension(u"Hz") && return Unitful.c0 / x
    d == dimension(u"J") && return Unitful.h * Unitful.c0 / x
    d == dimension(u"m^-1") && return 1 / x
    throw(ArgumentError("a photon needs a wavelength, frequency, energy or wavenumber, got $(short(x))"))
end

"The photon given by `x` (wavelength, frequency, energy or wavenumber) expressed in unit `u` of any of those kinds."
function photon_equivalent(u, x)
    λ = photon_wavelength(x)
    d = dimension(u)
    y = d == dimension(u"m") ? λ : d == dimension(u"Hz") ? Unitful.c0 / λ :
        d == dimension(u"J") ? Unitful.h * Unitful.c0 / λ : d == dimension(u"m^-1") ? 1 / λ :
        throw(ArgumentError("a photon has no $(dimension(u)) quantity"))
    return uconvert(u, y)
end

"`x` in the largest of `units` (given small to large) that keeps the value ≥ 1: 0.00124 nm → 1.24 pm."
function readable(x, units)
    us = parse_unit.(units)
    i = findlast(u -> abs(ustrip(u, x)) >= 1 - 1e-9, us)   # tolerate round-off: 0.99999… THz is 1 THz
    return uconvert(us[something(i, 1)], x)
end

# Converter tab: the value is shown in every unit of the chosen category. `convert(unit, value)`
# is plain unit conversion except for the Photon category.
category(name, units, convert = uconvert) = (; name, units, convert)
const CATEGORIES = [
    category("Length", ["m", "km", "cm", "mm", "μm", "nm", "Å", "inch", "ft", "yd", "mi", "nmi", "au", "ly"]),
    category("Area", ["m^2", "km^2", "cm^2", "mm^2", "ha", "inch^2", "ft^2", "yd^2", "ac", "mi^2"]),
    category("Volume", ["m^3", "L", "mL", "cm^3", "gal", "inch^3", "ft^3"]),
    category("Mass", ["kg", "g", "mg", "t", "lb", "oz", "u"]),
    category("Density", ["kg/m^3", "g/cm^3", "g/L", "lb/ft^3"]),
    category("Time", ["s", "ms", "μs", "ns", "minute", "h", "d", "wk", "yr"]),
    category("Frequency", ["Hz", "kHz", "MHz", "GHz", "THz"]),
    category("Speed", ["m/s", "km/h", "mph", "kn", "ft/s"]),
    category("Temperature", ["°C", "K", "°F", "Ra"]),
    category("Pressure", ["Pa", "hPa", "kPa", "MPa", "bar", "mbar", "atm", "psi", "Torr"]),
    category("Energy", ["J", "kJ", "MJ", "eV", "meV", "keV", "MeV", "GeV", "TeV", "erg", "cal", "kcal", "Wh", "kWh", "btu"]),
    category("Power", ["W", "mW", "kW", "MW", "GW", "hp"]),
    category("Force", ["N", "kN", "lbf", "dyn"]),
    category("Voltage", ["V", "mV", "kV", "MV"]),
    category("Electric field", ["V/m", "kV/m", "MV/m", "V/cm", "kV/cm", "V/mm"]),
    category("Current", ["A", "mA", "μA", "nA", "kA"]),
    category("Charge", ["C", "mC", "μC", "nC", "pC", "A*h", "mA*h"]),
    category("Magnetic field", ["T", "mT", "μT", "nT", "Gauss"]),
    category("Angle", ["°", "rad", "mrad"]),
    category("Photon λ ν E", ["nm", "μm", "pm", "Å", "eV", "keV", "MeV", "J", "THz", "Hz", "cm^-1"], photon_equivalent),
]

"Whether `category` can show `x` (right dimension, or a photon quantity for Photon)."
accepts(category, x) = try category.convert(parse_unit(first(category.units)), x); true catch; false end

"`x` in every unit of `category`, in list order."
convert_all(category, x) = Any[category.convert(parse_unit(u), x) for u in category.units]
