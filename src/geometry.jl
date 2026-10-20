# Geometry helpers. Lengths may be plain numbers or Unitful quantities (results follow
# their units). Angles must carry a unit here (90°, 1.571rad): only the trig families
# have a documented meaning for a plain number.

function angle_rad(name, θ)
    θ isa Quantity && dimension(θ) == NoDims && return float(ustrip(NoUnits, θ))
    throw(ArgumentError("$name: give the angle with a unit, e.g. $(fmt_number(θ))° or $(fmt_number(θ))rad"))
end

"circle(r): radius → diameter, circumference, area"
circle(r) = (r = r, d = 2r, circumference = 2π * r, area = π * r^2)

"sphere(r): radius → diameter, surface area, volume"
sphere(r) = (r = r, d = 2r, area = 4π * r^2, volume = 4π * r^3 / 3)

"cylinder(r, h): radius, height → lateral area, total area, volume"
cylinder(r, h) = (lateral = 2π * r * h, area = 2π * r * (r + h), volume = π * r^2 * h)

"cone(r, h): radius, height → slant height, lateral area, total area, volume"
function cone(r, h)
    s = hypot(r, h)
    return (slant = s, lateral = π * r * s, area = π * r * (r + s), volume = π * r^2 * h / 3)
end

"rectangle(a, b): sides → area, perimeter, diagonal"
rectangle(a, b) = (area = a * b, perimeter = 2(a + b), diagonal = hypot(a, b))

"box(a, b, c): edges → volume, surface area, space diagonal"
box(a, b, c) = (volume = a * b * c, area = 2(a * b + b * c + a * c), diagonal = hypot(a, b, c))

"arc(r, θ): radius, angle with unit (60°) → arc length, chord, sector area, segment area"
function arc(r, θ)
    t = angle_rad("arc", θ)
    return (length = r * t, chord = 2r * Base.sin(t / 2), sector = r^2 * t / 2,
            segment = r^2 * (t - Base.sin(t)) / 2)
end

"polar(x, y): cartesian point → distance r and angle θ (shown in ° and rad)"
polar(x, y) = (r = hypot(x, y), θ = atand(y, x))

"cart(r, θ): distance r, angle with unit (30°) → cartesian x, y"
function cart(r, θ)
    t = angle_rad("cart", θ)
    return (x = r * Base.cos(t), y = r * Base.sin(t))
end

"dist(p, q): distance between points given as tuples, e.g. dist((0, 0), (3, 4))"
dist(p, q) = hypot((p .- q)...)

"""
triangle(; a, b, c, A, B, C): give any 3 values incl. a side; angles need a unit (C = 90°)

Side `a` is opposite angle `A`, and so on. Handles SSS, SAS, ASA, AAS and SSA; the
ambiguous SSA case returns the acute solution and reports the other as a hint.
"""
function triangle(; a = nothing, b = nothing, c = nothing, A = nothing, B = nothing, C = nothing)
    s = Any[a, b, c]
    α = Any[x === nothing ? nothing : angle_rad("triangle", x) for x in (A, B, C)]
    ns, nα = count(!isnothing, s), count(!isnothing, α)
    ns + nα == 3 && ns >= 1 ||
        throw(ArgumentError("triangle: give exactly 3 values, at least one of them a side (a, b, c)"))
    others(i) = filter(!=(i), 1:3)

    if nα == 2                                   # ASA / AAS: third angle, then law of sines
        i = findfirst(isnothing, α)
        α[i] = π - sum(α[j] for j in others(i))
        α[i] > 0 || throw(ArgumentError("triangle: the angles add up to 180° or more"))
        k = findfirst(!isnothing, s)
        s = [s[k] * Base.sin(α[j]) / Base.sin(α[k]) for j in 1:3]
    elseif nα == 1                               # two sides and one angle
        i = findfirst(!isnothing, α)
        if s[i] === nothing                      # SAS: the angle lies between the known sides
            j, k = others(i)
            s[i] = sqrt(s[j]^2 + s[k]^2 - 2s[j] * s[k] * Base.cos(α[i]))
        else                                     # SSA: law of sines, 0, 1 or 2 solutions
            j = findfirst(j -> j != i && s[j] !== nothing, 1:3)
            k = only(filter(!in((i, j)), 1:3))
            sinj = s[j] * Base.sin(α[i]) / s[i]
            sinj <= 1 || throw(ArgumentError("triangle: no triangle has these values"))
            α[j] = Base.asin(sinj)
            alt = π - α[j]
            if α[i] + alt < π && !isapprox(alt, α[j])
                altk = π - α[i] - alt
                push!(HINTS, "SSA is ambiguous; the other triangle has " *
                             "$("abc"[k]) = $(short(s[i] * Base.sin(altk) / Base.sin(α[i]))), " *
                             "$("ABC"[j]) = $(short(Base.rad2deg(alt) * °)), $("ABC"[k]) = $(short(Base.rad2deg(altk) * °))")
            end
            α[k] = π - α[i] - α[j]
            s[k] = s[i] * Base.sin(α[k]) / Base.sin(α[i])
        end
    end
    if any(isnothing, α)                         # SSS (also finishes SAS): law of cosines
        for i in 1:3
            j, k = others(i)
            s[i] < s[j] + s[k] || throw(ArgumentError("triangle: side $("abc"[i]) is too long for the other two"))
        end
        α = [Base.acos((s[j]^2 + s[k]^2 - s[i]^2) / (2s[j] * s[k])) for (i, (j, k)) in enumerate(others.(1:3))]
    end
    deg(x) = Base.rad2deg(x) * °
    return (a = s[1], b = s[2], c = s[3], A = deg(α[1]), B = deg(α[2]), C = deg(α[3]),
            area = s[1] * s[2] * Base.sin(α[3]) / 2, perimeter = s[1] + s[2] + s[3])
end
