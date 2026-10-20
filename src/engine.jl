# Evaluation of one input line inside a session.

"When true (`--debug`), every evaluation and full stack traces are printed to stderr."
const DEBUG = Ref(false)

"A private module holding the user's variables, `ans` and the units used so far."
struct Session
    mod::Module
end

function Session()
    mod = Module(:Workspace)
    for name in names(Space)              # explicit bindings take priority over Base's sin, +, ...
        name === :Space || Core.eval(mod, Expr(:(=), name, getfield(Space, name)))
    end
    return Session(mod)
end

# "100 km/h to mph" → ("100*km/h", "mph"). A space between a number and a name multiplies,
# so units can be written the way people write them.
implicit_mul(s) = replace(s, r"(?<=[\d.])\s+(?=[^\W\d_]|°)" => "*")
function split_input(input)
    parts = split(input, r"\s+to\s+")
    length(parts) == 1 && return implicit_mul(input), nothing
    return implicit_mul(join(parts[1:end-1], " to ")), implicit_mul(parts[end])
end

# Bind each unknown name that is a unit or physical constant into the session, so `5km`
# works while the user's own variables keep priority. `min` means minutes only where it is
# used as a value: `90min` is a duration, `min(3, 4)` is still the function.
bind_unit!(mod, name) = isdefined(mod, name) || (u = lookup_unit(name)) === nothing || Core.eval(mod, Expr(:(=), name, u))
resolve_names!(mod, ex::Symbol) = (bind_unit!(mod, ex); ex)
resolve_names!(mod, ex) = ex
function resolve_names!(mod, ex::Expr)
    for (i, a) in enumerate(ex.args)
        if a === :min && !(ex.head === :call && i == 1) && getglobal(mod, :min) === Base.min
            ex.args[i] = ALIASES[:min]
        elseif a isa Symbol
            i == 1 && ex.head in (:kw, :(=)) || bind_unit!(mod, a)   # not keyword or assignment targets
        else
            resolve_names!(mod, a)
        end
    end
    return ex
end

function run!(session::Session, src)
    ex = Meta.parse(src; raise = false)
    if ex isa Expr && ex.head in (:error, :incomplete)
        msg = ex.args[1] isa Exception ? sprint(showerror, ex.args[1]) : string(ex.args[1])
        detail = match(r"── *([^\n]+)", msg)                 # JuliaSyntax puts the reason after "──"
        throw(ArgumentError("syntax error: " * (detail === nothing ? replace(msg, r"\s+" => " ") : detail[1])))
    end
    if ex isa Expr && ex.head === :(=) && ex.args[1] isa Symbol && lookup_unit(ex.args[1]) !== nothing
        push!(Space.HINTS, "`$(ex.args[1])` now holds your value and hides the unit $(ex.args[1]) in this session")
    end
    return Core.eval(session.mod, resolve_names!(session.mod, ex))
end

convert_to(u::Unitful.Units, x) = uconvert(u, x)
convert_to(u, x) = throw(ArgumentError("`to` needs a unit on its right, got $(short(u))"))

describe_error(e::ArgumentError) = e.msg
describe_error(e::UndefVarError) = "unknown name `$(e.var)`: not a variable, function or unit"
describe_error(e::Unitful.DimensionError) =
    "units don't match: $(short(e.x)) ($(dimension(e.x))) vs $(short(e.y)) ($(dimension(e.y)))"
describe_error(e) = first(replace(first(split(sprint(showerror, e), "\n\n")), r"\s+" => " "), 300)

"""
    evaluate(session, input) -> (; ok, value, text, hints)

Run one line such as `sind(30)`, `x = 2m`, `100 km/h to mph`. `text` is the formatted result
or a plain-language error; `hints` are warnings such as "sin takes radians".
"""
function evaluate(session::Session, input::AbstractString)
    input = strip(input)
    isempty(input) && return (ok = true, value = nothing, text = "", hints = String[])
    empty!(Space.HINTS)
    result = try
        src, target = split_input(input)
        value = run!(session, src)
        target === nothing || (value = convert_to(run!(session, target), value))
        Core.eval(session.mod, Expr(:(=), :ans, QuoteNode(value)))
        (ok = true, value = value, text = format_value(value))
    catch err
        DEBUG[] && (showerror(stderr, err, catch_backtrace()); println(stderr))
        (ok = false, value = nothing, text = describe_error(err))
    end
    result = (; result..., hints = copy(Space.HINTS))
    DEBUG[] && println(stderr, "calc> ", input, "\n", result.text, join("\n  hint: " .* result.hints))
    return result
end
