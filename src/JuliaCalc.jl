"Calculator and unit converter with explicit angle units, built on Unitful and Gtk4."
module JuliaCalc

using Printf
using Unitful
using Gtk4

include("format.jl")
include("units.jl")
include("space.jl")
include("engine.jl")
include("gui.jl")

"""
Entry point of the `juliacalc` executable and of `./dev.sh`.
Without arguments it opens the window; otherwise it evaluates each argument in one session
and prints the results. `--debug` prints every evaluation and full stack traces to stderr.
"""
function julia_main()::Cint
    args = filter(!=("--debug"), ARGS)
    DEBUG[] = length(args) < length(ARGS)
    isempty(args) && (gui(); return 0)
    session = Session()
    ok = true
    for arg in args
        r = evaluate(session, arg)
        println(r.text)
        foreach(h -> println("  hint: ", h), r.hints)
        ok &= r.ok
    end
    return ok ? 0 : 1
end

end
