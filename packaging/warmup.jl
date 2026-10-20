# Runs inside the process that writes the app's system image (create_app `script`), so all
# code compiled here is stored in the app. This matters for Unitful: PackageCompiler's
# recorded `precompile(...)` statements cannot express unit types and are silently dropped.
# Must not create GTK objects: whatever this process holds is saved into the image, and GTK
# pointers would dangle when the app starts. precompile.jl drives the window instead.
using JuliaCalc, Unitful
# Module `__init__`s are deferred while an image is written (they run when the app starts), so
# register the extra units here, as ExtraUnits.__init__ will at run time.
Unitful.register(JuliaCalc.ExtraUnits)
using JuliaCalc: Session, evaluate, CATEGORIES, accepts, convert_all, parse_unit, fmt_number, short,
                 superscripts, format_value, describe_name, value_markup, current_name, PALETTE,
                 RADIAN_FUNCS, EXAMPLES

let session = Session()
    inputs = ["1+1", "2^10", "1/3", "0.1 + 0.2", "sqrt(2)", "sind(30)", "sin(30)", "sin(π/6)", "sin(30°)",
              "cosd(0.5rad)", "tand(45)", "tan(45deg)", "asin(0.5)", "asind(0.5)", "atan(1)", "atand(1)",
              "atand(1, -1)", "deg2rad(180)", "rad2deg(π)", "1 to deg", "45° + 10", "45° + 10°",
              "100 km/h to mph", "100 degF to degC", "0 degC to K", "5 kV/m to V/cm", "1 MeV to J",
              "1 J to keV", "3 ft + 2 inch to cm", "90 min to h", "1 kWh to J", "c0 to km/s", "5 m to s",
              "si(1mi)", "photon(500nm)", "photon(1MeV)", "photon(500nm).E to J", "circle(2m)", "sphere(1)",
              "cone(3m, 4m)", "arc(1m, 90°)", "polar(1, 1)", "cart(2, 30°)", "dist((0, 0), (3, 4))",
              "triangle(a=3, b=4, c=5)", "triangle(a=3, b=4, C=90°)", "triangle(a=6, b=8, A=30°)",
              "triangle(C=90)", "x = 3", "x^2", "ans + 1", "m = 5", "3 +", "foo"]
    for input in [inputs; EXAMPLES]
        r = evaluate(session, input)
        r.ok && r.value !== nothing && value_markup(r.value)
        r.value isa NamedTuple && foreach(value_markup, values(r.value))
    end
    for c in CATEGORIES, v in (1, 2.5)                      # what the converter tab computes
        q = v * parse_unit(first(c.units))
        accepts(c, q)
        for (u, x) in zip(c.units, convert_all(c, q))
            fmt_number(ustrip(x)), short(x), unit(x) == unit(q), superscripts(u), format_value(x)
        end
    end
    for (_, items) in PALETTE, (_, _, insert) in items       # button tooltips
        describe_name(strip(insert, ['(', ' ']))
    end
    foreach(describe_name, [RADIAN_FUNCS; RADIAN_FUNCS .* "d"; ["deg2rad", "rad2deg", "°", "rad"]])
    foreach(current_name, ["sind(", "2 + tand(3", "sin((1+", "km"])
end
