using Test, Unitful, JuliaCalc
using JuliaCalc: Session, evaluate, CATEGORIES, parse_unit, current_name, describe_name, accepts, photon_equivalent
using Unitful: °, rad, m

calc(s, input) = evaluate(s, input)
value(input) = calc(Session(), input).value
hints(input) = calc(Session(), input).hints
failed(input) = !calc(Session(), input).ok

@testset "angle contract" begin
    @test value("sind(30)") == 0.5
    @test value("sin(30°)") == 0.5
    @test value("sin(180°)") == 0                          # degree inputs stay exact
    @test value("sind(π/6*rad)") ≈ 0.5
    @test value("sin(π/6)") ≈ 0.5
    @test value("tand(45)") == 1
    @test value("tan(45deg)") == 1
    @test value("cosd(0.5rad)") ≈ cos(0.5)
    @test value("atand(1)") == 45°
    @test value("atan(1)") ≈ π / 4 * rad
    @test value("atand(1, -1)") ≈ 135°
    @test value("atan(1m, 1m)") ≈ π / 4 * rad              # two-argument form with lengths
    @test value("sin(asin(0.5))") ≈ 0.5                     # tagged rad round-trips
    @test value("sind(asind(0.5))") ≈ 0.5
    @test value("rad2deg(π)") ≈ 180°
    @test value("1 to deg") ≈ 180 / π * °                   # a plain number is radians (SI)
    @test failed("sin(5m)")
    @test failed("45° + 10")                                # plain number would silently be rad
    @test value("45° + 10°") == 55°
    @test value("atan(1) + 1") ≈ (π / 4 + 1) * rad          # rad + plain number is SI-consistent
end

@testset "misuse hints" begin
    @test only(hints("sin(30)")) == "sin takes radians; 30 looks like degrees: use sind(30) or sin(30°)"
    @test only(hints("sind(π/4)")) == "sind takes degrees; π/4 looks like radians: use sin(π/4) or sind(45)"
    @test isempty(hints("sin(0.5)"))
    @test isempty(hints("sind(45)"))
    @test isempty(hints("sin(30°)"))
end

@testset "units and conversion" begin
    @test ustrip(value("100 km/h to mph")) ≈ 62.13711922
    @test unit(value("100 km/h to mph")) == parse_unit("mph")
    @test ustrip(value("100 degF to degC")) ≈ 37.7777777778
    @test ustrip(value("0 degC to K")) ≈ 273.15
    @test value("1 nmi to m") == 1852m
    @test ustrip(value("1 gal to L")) ≈ 3.785411784
    @test ustrip(value("90 min to h")) == 1.5
    @test value("min(3, 4)") == 3                           # still the function
    @test ustrip(value("3 ft + 2 inch to cm")) ≈ 96.52
    @test ustrip(value("1 kWh to J")) == 3.6e6
    @test ustrip(value("5km |> mi")) ≈ 3.10685596
    @test ustrip(value("c0 to km/s")) ≈ 299792.458
    @test ustrip(value("5 kV/m to V/cm")) ≈ 50
    @test ustrip(value("1 MeV to J")) ≈ 1.602176634e-13
    @test ustrip(value("1 J to keV")) ≈ 6.241509074e15
    r = calc(Session(), "5 m to s")
    @test !r.ok && occursin("units don't match", r.text)
end

@testset "geometry" begin
    t = value("triangle(a=3, b=4, c=5)")
    @test t.C ≈ 90° && t.area ≈ 6 && t.perimeter ≈ 12
    @test value("triangle(a=3, b=4, C=90°)").c ≈ 5
    t = value("triangle(a=1, B=60°, C=60°)")                # ASA: equilateral
    @test t.b ≈ 1 && t.c ≈ 1 && t.A ≈ 60°
    r = calc(Session(), "triangle(a=6, b=8, A=30°)")        # SSA with two solutions
    @test r.value.A + r.value.B + r.value.C ≈ 180°
    @test occursin("ambiguous", only(r.hints))
    @test failed("triangle(C=90)")                          # angle without a unit
    @test failed("triangle(a=1, b=1, c=3)")                 # triangle inequality
    @test failed("triangle(a=1, b=5, A=60°)")               # SSA without a solution
    @test value("circle(2m)").area ≈ 4π * m^2
    @test value("sphere(1)").volume ≈ 4π / 3
    @test value("arc(1m, 90°)").length ≈ π / 2 * m
    @test value("cart(2, 30°)").x ≈ sqrt(3)
    @test value("polar(1, 1)").θ ≈ 45°
    @test value("dist((0, 0), (3, 4))") ≈ 5
    @test value("cone(3m, 4m)").slant ≈ 5m
end

@testset "session" begin
    s = Session()
    @test calc(s, "x = 3").value == 3
    @test calc(s, "x^2").value == 9
    @test calc(s, "ans + 1").value == 10
    @test calc(s, "f(y) = 2y; f(4)").value == 8
    r = calc(s, "m = 5")
    @test r.value == 5 && occursin("hides the unit", only(r.hints))
    @test calc(s, "2m").value == 10                         # the user's variable wins
    @test calc(Session(), "0.1 + 0.2").text == "0.3"
    @test calc(Session(), "atand(1)").text == "45°   (= 0.785398163397 rad)"
    @test startswith(calc(Session(), "3 +").text, "syntax error")
    @test calc(Session(), "foo").text == "unknown name `foo`: not a variable, function or unit"
end

@testset "photon equivalence" begin
    p = value("photon(500nm)")                              # E = h c / λ
    @test p.E ≈ 2.479683969 * u"eV" && p.ν ≈ 599.584916 * u"THz" && p.k ≈ 20000 * u"cm^-1"
    @test unit(value("photon(1MeV)").λ) == u"pm"            # readable unit for gamma rays
    @test ustrip(u"pm", value("photon(1MeV)").λ) ≈ 1.239841984
    @test unit(value("photon(1THz)").ν) == u"THz"
    @test photon_equivalent(u"nm", photon_equivalent(u"eV", 532u"nm")) ≈ 532u"nm"
    @test failed("photon(3)")
    @test failed("500 nm to eV")                            # plain `to` never applies physics
end

@testset "converter categories" begin
    for c in CATEGORIES
        @test allunique(c.units)
        @test all(u -> accepts(c, 1 * parse_unit(first(c.units))) && c.convert(parse_unit(u), 1 * parse_unit(first(c.units))) isa Unitful.Quantity, c.units)
        c.convert === uconvert && @test all(u -> dimension(parse_unit(u)) == dimension(parse_unit(first(c.units))), c.units)
    end
    find(x) = CATEGORIES[findfirst(c -> accepts(c, x), CATEGORIES)].name
    @test find(5u"kV/m") == "Electric field"                 # the converter jumps to this category
    @test find(2u"MeV") == "Energy"
    @test find(1u"GHz") == "Frequency"
end

@testset "signature help" begin
    @test current_name("2 + sind(") == "sind"
    @test current_name("sin((1+") == "sin"
    @test current_name("sin(1) + cosd") == "cosd"
    @test startswith(describe_name("sin"), "sin(x): x in radians")
    @test startswith(describe_name("tand"), "tand(x): x in degrees")
    @test occursin("hr", describe_name("h"))
end
