# The window. All maths goes through `evaluate`, `format_value` and `parse_unit`; this file
# only lays out widgets, styles them and moves text around.

const SANS = "\"Inter\", \"Cantarell\", \"Ubuntu\", \"Noto Sans\", sans-serif"
const MONO = "\"JetBrains Mono\", \"Fira Mono\", \"Noto Sans Mono\", \"DejaVu Sans Mono\", monospace"

# Colour tokens per theme. The stylesheet refers only to these names.
const THEMES = Dict(
    :dark => (bg = "#14161c", card = "#1c1f27", raised = "#262a34", border = "#2b303b", fg = "#e8eaf0",
              muted = "#8a91a4", accent = "#7b91ff", rad = "#6cb0ff", deg = "#ffa35a", geo = "#c29cff",
              konst = "#5fd3a0", unit = "#5cc9d0", warn = "#f0c050", err = "#ff7676"),
    :light => (bg = "#f2f3f7", card = "#ffffff", raised = "#e3e6ee", border = "#dfe2ea", fg = "#1b1f2e",
               muted = "#666d82", accent = "#3d5be0", rad = "#1c62cf", deg = "#c4500a", geo = "#7743cc",
               konst = "#11804b", unit = "#0b7c80", warn = "#8f5e00", err = "#c42727"),
)

const STYLE = """
window.background { background-color: @bg; color: @fg; font-family: $SANS; }
headerbar { background: @bg; box-shadow: none; border-bottom: 1px solid @border; }
.card { background: @card; border: 1px solid @border; border-radius: 16px; }
stackswitcher { background: alpha(@fg, 0.06); border-radius: 11px; padding: 3px; }
stackswitcher > button { background: none; border: none; box-shadow: none; border-radius: 8px;
                         padding: 3px 16px; color: @muted; font-weight: 600; }
stackswitcher > button:hover { color: @fg; }
stackswitcher > button:checked { background: @card; color: @fg; box-shadow: 0 1px 3px alpha(#000000, 0.18); }

.tape-row { padding: 10px 18px; border-bottom: 1px solid alpha(@border, 0.7); }
.tape-row:hover { background: alpha(@fg, 0.025); }
.echo { font-family: $MONO; font-size: 11pt; color: @muted; }
.result { font-family: $MONO; font-size: 18pt; font-weight: 600; }
.kv-key { font-family: $MONO; font-size: 12pt; color: @muted; }
.kv-val { font-family: $MONO; font-size: 13.5pt; font-weight: 600; }
.pill { border-radius: 10px; padding: 6px 12px; font-size: 10.5pt; }
.pill.hint { background: alpha(@warn, 0.13); color: @warn; }
.pill.error { background: alpha(@err, 0.12); color: @err; }
button.copy { opacity: 0.4; min-height: 22px; min-width: 22px; padding: 2px; }
button.copy:hover { opacity: 1; }

.empty-title { font-size: 16pt; font-weight: 700; }
.empty-note { color: @muted; }
button.chip { background: @raised; color: @fg; border: none; box-shadow: none; border-radius: 18px;
              padding: 6px 14px; font-family: $MONO; font-size: 11pt; }
button.chip:hover { background: mix(@raised, @accent, 0.2); }

.display { background: @card; border: 1px solid @border; border-radius: 16px; padding: 6px; }
.display:focus-within { border-color: alpha(@accent, 0.75); box-shadow: 0 0 0 3px alpha(@accent, 0.15); }
entry.bare { background: none; border: none; box-shadow: none; outline: none; color: @fg;
             caret-color: @accent; font-family: $MONO; padding: 0 10px; }
entry.calc-entry { font-size: 20pt; min-height: 52px; }
entry.value-entry { font-size: 18pt; min-height: 48px; }
entry.target-entry { font-size: 14pt; min-height: 40px; }
.target-result { font-family: $MONO; font-size: 15pt; font-weight: 600; }
button.equals { background: @accent; color: #ffffff; border: none; box-shadow: none; border-radius: 12px;
                min-width: 64px; min-height: 52px; font-size: 20pt; font-weight: 700; }
button.equals:hover { background: mix(@accent, #ffffff, 0.12); }
button.equals:active { background: mix(@accent, #000000, 0.15); }
.signature { color: @muted; font-size: 10.5pt; padding: 0 8px; }
.signature.rad { color: @rad; }
.signature.deg { color: @deg; }

.family { border-radius: 14px; padding: 10px 12px; background: alpha(@fg, 0.025); border: 1px solid @border; }
.family.rad { background: alpha(@rad, 0.05); border-color: alpha(@rad, 0.25); }
.family.deg { background: alpha(@deg, 0.05); border-color: alpha(@deg, 0.25); }
.section { font-size: 8.5pt; font-weight: 800; letter-spacing: 1px; color: @muted; }
.family.rad .section { color: @rad; }
.family.deg .section { color: @deg; }
.section-note { font-size: 9pt; color: @muted; }

button.key { background: @raised; color: @fg; border: none; box-shadow: none; border-radius: 10px;
             min-height: 34px; padding: 0 12px; font-family: $MONO; font-size: 12pt; }
button.key:hover { background: mix(@raised, @fg, 0.08); }
button.key:active { background: mix(@raised, @fg, 0.16); }
$(join(("button.key.$c { background: alpha(@$c, 0.13); color: @$c; }\n" *
        "button.key.$c:hover { background: alpha(@$c, 0.24); }\n" for c in ("rad", "deg", "geo", "konst", "unit"))))
flowboxchild { padding: 0; }

list.sidebar { background: transparent; }
list.sidebar row { border-radius: 10px; padding: 9px 14px; margin: 1px 0; }
list.sidebar row:selected { background: alpha(@accent, 0.16); color: @fg; font-weight: 600; }
list.units { background: @card; border: 1px solid @border; border-radius: 16px; }
list.units row { padding: 8px 16px; border-bottom: 1px solid alpha(@border, 0.7); }
list.units row:hover { background: alpha(@fg, 0.03); }
list.units row.from { background: alpha(@accent, 0.12); }
.unit-name { font-size: 12pt; color: @muted; }
row.from .unit-name { color: @accent; font-weight: 700; }
.unit-value { font-family: $MONO; font-size: 15pt; font-weight: 600; }
dropdown.unit-pick > button { font-family: $MONO; font-size: 13pt; border-radius: 10px; }
.note { color: @muted; font-size: 10pt; }
.toast { background: @fg; color: @bg; border-radius: 18px; padding: 8px 18px; margin-bottom: 22px; font-weight: 600; }
"""

stylesheet(theme) = join("@define-color $k $v;\n" for (k, v) in pairs(THEMES[theme])) * STYLE

# Palette tabs: (title, [(CSS class, button label, text inserted at the cursor)]).
buttons(class, items...) = [(class, text, insert) for (text, insert) in items]
calls(class, fs...) = buttons(class, ((f, "$f(") for f in fs)...)
same(class, xs...) = buttons(class, ((x, x) for x in xs)...)
const PALETTE = [
    ("Math", buttons("", "√" => "sqrt(", "x²" => "^2", "xʸ" => "^", "π" => "π", "e" => "e", "ln" => "log(",
                  "log10" => "log10(", "exp" => "exp(", "abs" => "abs(", "(" => "(", ")" => ")", "ans" => "ans")),
    ("Units", [same("unit", "°", "rad", "m", "km", "cm", "mm", "ft", "inch", "mi", "kg", "g", "lb", "s",
                    "min", "h", "degC", "degF", "K", "L", "gal", "N", "J", "W", "Pa", "bar", "psi");
               ("unit", "to", " to ")]),
    ("Geometry", calls("geo", "circle", "sphere", "cylinder", "cone", "rectangle", "box", "triangle", "arc",
                       "polar", "cart", "dist", "hypot")),
    ("Physics", [calls("konst", "photon"); same("konst", "c0", "gn", "G", "k", "Na", "q", "me", "mp", "R", "planck",
                                                 "ε0", "μ0", "σ", "eV", "keV", "MeV", "nm", "THz")]),
]
const RADIAN_FUNCS = ["sin", "cos", "tan", "asin", "acos", "atan"]
const EXAMPLES = ["sind(30)", "100 km/h to mph", "triangle(a=3, b=4, C=90°)", "atand(1)", "circle(2m)",
                  "100 degF to degC"]
const HELP = "<b>sin cos tan</b> take radians   ·   <b>sind cosd tand</b> take degrees   ·   " *
             "<b>30°</b> or <b>0.5rad</b> work in both"

escape(s) = replace(string(s), "&" => "&amp;", "<" => "&lt;", ">" => "&gt;")

"One-line description of a name: its docstring signature, or the unit/constant it means."
function describe_name(name)
    sym = Symbol(name)
    docs = get(Base.Docs.meta(Space), Base.Docs.Binding(Space, sym), nothing)   # raw text, no REPL needed
    docs === nothing || return strip(first(split(join(first(values(docs.docs)).text), '\n')))
    u = lookup_unit(sym)
    return u === nothing ? nothing : "$name = $(format_value(u))   [$(dimension(u))]"
end

"The function whose argument list `text` ends inside, else the last name typed."
function current_name(text)
    stack = Union{Nothing,String}[]
    for m in eachmatch(r"([^\W\d]\w*)?\(|\)", text)
        m.match == ")" ? (isempty(stack) || pop!(stack)) : push!(stack, m.captures[1])
    end
    i = findlast(!isnothing, stack)
    i === nothing || return stack[i]
    m = match(r"([^\W\d]\w*)$", text)
    return m === nothing ? nothing : m.captures[1]
end

"Pango markup for a value: angles show their other unit in a quieter style."
function value_markup(v)
    alt = other_angle(v)
    alt === nothing && return escape(format_value(v))
    return escape(short(v)) * "  <span alpha=\"55%\" size=\"small\" weight=\"normal\">= " * escape(short(alt)) * "</span>"
end

function label(text, classes...; xalign = 0, wrap = true, markup = false)
    l = GtkLabel("")
    markup ? Gtk4.markup(l, text) : (l.label = text)
    l.xalign = xalign
    l.wrap = wrap
    foreach(c -> add_css_class(l, c), classes)
    return l
end

function hbox(children...; spacing = 8)
    b = GtkBox(:h, spacing)
    foreach(c -> push!(b, c), children)
    return b
end

function vbox(children...; spacing = 8)
    b = GtkBox(:v, spacing)
    foreach(c -> push!(b, c), children)
    return b
end

function margins!(w, m)
    w.margin_start = w.margin_end = w.margin_top = w.margin_bottom = m
    return w
end

function icon_button(icon, tooltip, classes...)
    b = GtkButton()
    b.icon_name = icon
    add_css_class(b, "flat")
    foreach(c -> add_css_class(b, c), classes)
    Gtk4.G_.set_tooltip_text(b, tooltip)
    return b
end

function key_button(class, text, insert, entry)
    b = GtkButton(text)
    add_css_class(b, "key")
    isempty(class) || add_css_class(b, class)
    Gtk4.G_.set_tooltip_text(b, describe_name(strip(insert, ['(', ' '])))
    signal_connect(_ -> insert_at_cursor(entry, insert), b, "clicked")
    return b
end

function insert_at_cursor(entry, text)
    Gtk4.G_.grab_focus_without_selecting(entry)
    pos = Gtk4.G_.insert_text(entry, text, -1, Gtk4.G_.get_position(entry))
    Gtk4.G_.set_position(entry, pos)
end

copy_text(widget, text) = Gtk4.set_text(Gtk4.G_.get_clipboard(widget), text)

"A card for one trig family: a coloured title, what a plain number means, and its keys."
function family_card(class, title, note, items, entry; columns = 3)
    grid = GtkGrid()
    grid.column_homogeneous = true
    grid.row_spacing = grid.column_spacing = 6
    for (i, (c, text, insert)) in enumerate(items)
        b = key_button(c, text, insert, entry)
        b.hexpand = true
        grid[mod1(i, columns), cld(i, columns)] = b
    end
    card = vbox(hbox(label(title, "section"; wrap = false), label(note, "section-note"; wrap = false)), grid)
    add_css_class(card, "family")
    isempty(class) || add_css_class(card, class)
    return card
end

function palette(entry)
    tabs = GtkStack()
    tabs.transition_type = Gtk4.StackTransitionType_CROSSFADE
    rad = family_card("rad", "RADIANS", "plain x is rad", calls("rad", RADIAN_FUNCS...), entry)
    deg = family_card("deg", "DEGREES", "plain x is °", calls("deg", (RADIAN_FUNCS .* "d")...), entry)
    rad.hexpand = deg.hexpand = true
    trig = hbox(rad, deg, family_card("", "ANGLE UNITS", "work in both",
                                      [same("unit", "°", "rad"); calls("", "deg2rad", "rad2deg")], entry;
                                      columns = 2); spacing = 10)
    Gtk4.G_.add_titled(tabs, trig, "trig", "Trigonometry")
    for (title, items) in PALETTE
        flow = GtkFlowBox()
        flow.selection_mode = Gtk4.SelectionMode_NONE
        flow.min_children_per_line = 6
        flow.max_children_per_line = 30
        flow.row_spacing = flow.column_spacing = 6
        flow.valign = Gtk4.Align_START
        foreach(((c, t, i),) -> push!(flow, key_button(c, t, i, entry)), items)
        Gtk4.G_.add_titled(tabs, flow, lowercase(title), title)
    end
    switcher = GtkStackSwitcher()
    Gtk4.G_.set_stack(switcher, tabs)
    switcher.halign = Gtk4.Align_CENTER
    return vbox(switcher, tabs; spacing = 10)
end

"One evaluated line on the tape: the input (click to reuse), the result, then hints."
function tape_row(input, r, recall, toast)
    echo = label(input, "echo")
    echo.hexpand = true
    click = GtkGestureClick(echo)
    signal_connect((_...) -> recall(input), click, "pressed")
    top = hbox(echo)
    if r.ok
        copy = icon_button("edit-copy-symbolic", "Copy result", "copy")
        signal_connect(b -> (copy_text(b, r.text); toast("Copied  " * first(split(r.text, '\n')))), copy, "clicked")
        push!(top, copy)
    end
    row = vbox(top; spacing = 4)
    add_css_class(row, "tape-row")
    if !r.ok
        push!(row, label("✕  " * r.text, "pill", "error"))
    elseif r.value isa NamedTuple                     # geometry: a small key/value table
        grid = GtkGrid()
        grid.column_spacing = 14
        grid.row_spacing = 2
        grid.halign = Gtk4.Align_END
        for (i, (k, v)) in enumerate(pairs(r.value))
            grid[1, i] = label(string(k), "kv-key"; xalign = 1, wrap = false)
            val = label(value_markup(v), "kv-val"; markup = true, wrap = false)
            val.selectable = true
            grid[2, i] = val
        end
        push!(row, grid)
    else
        result = label(value_markup(r.value), "result"; xalign = 1, markup = true)
        result.selectable = true
        push!(row, result)
    end
    foreach(h -> push!(row, label("⚠  " * h, "pill", "hint")), r.hints)
    return row
end

const KEY_UP, KEY_DOWN, KEY_ESCAPE = 0xff52, 0xff54, 0xff1b   # GDK key values

function calculator_page(toast)
    session = Ref(Session())
    inputs = String[]
    cursor = Ref(1)                                # position in `inputs` while browsing history

    entry = GtkEntry()
    foreach(c -> add_css_class(entry, c), ("bare", "calc-entry"))
    entry.hexpand = true
    entry.placeholder_text = "Type an expression"
    run_button = GtkButton("=")
    add_css_class(run_button, "equals")
    display = hbox(entry, run_button)
    add_css_class(display, "display")
    signature = label(HELP, "signature"; markup = true)

    history = vbox(; spacing = 0)
    scroll = GtkScrolledWindow()
    scroll[] = history
    adj = Gtk4.G_.get_vadjustment(scroll)          # keep the newest result in view, once laid out
    signal_connect(adj, "notify::upper") do a, _
        Gtk4.GLib.g_idle_add(() -> (a.value = a.upper - a.page_size; false))
        nothing
    end
    chip_rows = [hbox(; spacing = 8) for _ in 1:2]   # fixed rows: wrapping layouts here made GTK loop
    foreach(r -> r.halign = Gtk4.Align_CENTER, chip_rows)
    empty = vbox(label("Ready when you are", "empty-title"; xalign = 0.5, wrap = false),
                 label("Type below, use the keys, or try an example:", "empty-note"; xalign = 0.5, wrap = false),
                 chip_rows...,
                 label("Enter runs  ·  ↑ ↓ recall  ·  Esc clears  ·  click a past input to reuse it",
                       "note"; xalign = 0.5, wrap = false); spacing = 12)
    empty.valign = Gtk4.Align_CENTER
    tape = GtkStack()
    tape.vexpand = true
    tape.overflow = Gtk4.Overflow_HIDDEN           # clip rows to the rounded card
    add_css_class(tape, "card")
    Gtk4.G_.add_named(tape, empty, "empty")
    Gtk4.G_.add_named(tape, scroll, "tape")

    recall(text) = (entry.text = text; insert_at_cursor(entry, ""); Gtk4.G_.set_position(entry, -1))
    function run_input()
        input = strip(entry.text)
        isempty(input) && return
        push!(history, tape_row(input, evaluate(session[], input), recall, toast))
        Gtk4.G_.set_visible_child_name(tape, "tape")
        push!(inputs, input)
        cursor[] = length(inputs) + 1
        entry.text = ""
    end
    function clear()
        empty!(history)
        session[] = Session()
        Gtk4.G_.set_visible_child_name(tape, "empty")
    end
    for (i, ex) in enumerate(EXAMPLES)
        b = GtkButton(ex)
        add_css_class(b, "chip")
        signal_connect(_ -> (entry.text = ex; run_input()), b, "clicked")
        push!(chip_rows[cld(i, 3)], b)
    end
    signal_connect(_ -> run_input(), entry, "activate")
    signal_connect(_ -> run_input(), run_button, "clicked")
    signal_connect(entry, "changed") do e
        name = current_name(e.text)
        line = name === nothing ? nothing : describe_name(name)
        family = name in RADIAN_FUNCS ? "rad" : name in RADIAN_FUNCS .* "d" ? "deg" : nothing
        foreach(c -> remove_css_class(signature, c), ("rad", "deg"))
        family === nothing || add_css_class(signature, family)
        if line === nothing
            Gtk4.markup(signature, HELP)
        else
            head, rest = occursin(": ", line) ? split(line, ": "; limit = 2) : (line, "")
            Gtk4.markup(signature, "<b>$(escape(head))</b>   $(escape(rest))")
        end
    end
    keyctl = GtkEventControllerKey(entry)
    keyctl.propagation_phase = Gtk4.PropagationPhase_CAPTURE
    signal_connect(keyctl, "key-pressed") do _, keyval, _, _
        if keyval == KEY_ESCAPE
            entry.text = ""
        elseif keyval in (KEY_UP, KEY_DOWN) && !isempty(inputs)
            cursor[] = clamp(cursor[] + (keyval == KEY_UP ? -1 : 1), 1, length(inputs) + 1)
            recall(cursor[] > length(inputs) ? "" : inputs[cursor[]])
        else
            return false
        end
        return true
    end
    page = margins!(vbox(tape, display, signature, palette(entry); spacing = 12), 16)
    return page, entry, clear
end

function converter_page(toast)
    session = Session()                            # the value may be an expression: 1/3, 2^10, 5 kV/m
    sidebar = GtkListBox()
    add_css_class(sidebar, "sidebar")
    foreach(c -> push!(sidebar, label(c.name; wrap = false)), CATEGORIES)
    value = GtkEntry()
    foreach(c -> add_css_class(value, c), ("bare", "value-entry"))
    value.text = "1"
    value.hexpand = true
    value.placeholder_text = "value, e.g. 1/3 or 5 kV/m"
    from = GtkDropDown(superscripts.(first(CATEGORIES).units))
    add_css_class(from, "unit-pick")
    from.valign = Gtk4.Align_CENTER
    display = hbox(value, from)
    add_css_class(display, "display")
    target = GtkEntry()                             # free conversion to any unit
    foreach(c -> add_css_class(target, c), ("bare", "target-entry"))
    target.hexpand = true
    target.placeholder_text = "any unit, e.g. V/cm, MeV, ft/s"
    target_result = label("", "target-result"; xalign = 1, wrap = false)
    target_result.selectable = true
    target_copy = icon_button("edit-copy-symbolic", "Copy", "copy")
    any_unit = hbox(label("to", "section"; wrap = false), target, target_result, target_copy; spacing = 10)
    add_css_class(any_unit, "display")
    list = GtkListBox()
    list.selection_mode = Gtk4.SelectionMode_NONE
    add_css_class(list, "units")
    list.valign = Gtk4.Align_START
    current = Ref(1)                               # index into CATEGORIES
    quantity = Ref{Any}(nothing)                   # the value being shown, with its unit
    converted = Ref{Vector{Any}}([])

    function update_target()
        q, text = quantity[], strip(target.text)
        target_result.label = ""
        (q === nothing || isempty(text)) && return
        target_result.label = try
            cat = CATEGORIES[current[]]
            short((accepts(cat, q) ? cat.convert : uconvert)(parse_unit(text), q))
        catch err
            err isa Unitful.DimensionError ? "different dimension" : "unknown unit"
        end
    end
    function update()
        Gtk4.G_.remove_all(list)
        quantity[] = nothing
        cat = CATEGORIES[current[]]
        k = Int(from.selected) + 1                 # "no selection" is typemax(UInt32)
        if k <= length(cat.units) && !isempty(strip(value.text))
            try
                r = evaluate(session, value.text)
                r.ok || error(r.text)
                has_unit = r.value isa Unitful.Quantity && dimension(r.value) != Unitful.NoDims
                from.sensitive = !has_unit         # a typed unit (5 kV/m) wins over the drop-down
                q = has_unit ? r.value : r.value * parse_unit(cat.units[k])
                if !accepts(cat, q)                # jump to the category that fits the typed unit
                    j = findfirst(c -> accepts(c, q), CATEGORIES)
                    j === nothing && (quantity[] = q; error("no category for $(dimension(q)); use the \"to\" field above"))
                    return Gtk4.G_.select_row(sidebar, Gtk4.G_.get_row_at_index(sidebar, j - 1))
                end
                quantity[] = q
                converted[] = convert_all(cat, q)
            catch err
                push!(list, label(describe_error(err), "pill", "error"))
                update_target()
                return
            end
            for (i, (u, x)) in enumerate(zip(cat.units, converted[]))
                text = fmt_number(ustrip(x))
                name = label(superscripts(u), "unit-name"; wrap = false)
                name.hexpand = true
                copy = icon_button("edit-copy-symbolic", "Copy", "copy")
                signal_connect(b -> (copy_text(b, "$text $u"); toast("Copied  $text $u")), copy, "clicked")
                push!(list, hbox(name, label(text, "unit-value"; xalign = 1, wrap = false), copy; spacing = 12))
                unit(x) == unit(quantity[]) && add_css_class(Gtk4.G_.get_row_at_index(list, i - 1), "from")
            end
        end
        update_target()
    end
    signal_connect(sidebar, "row-selected") do _, row
        row === nothing && return
        current[] = Gtk4.G_.get_index(row) + 1
        m = Gtk4.model(from)
        empty!(m)
        foreach(u -> push!(m, superscripts(u)), CATEGORIES[current[]].units)
        from.selected = 0
        update()
    end
    signal_connect(list, "row-activated") do _, row      # clicking a unit converts from it
        i = Gtk4.G_.get_index(row) + 1
        i <= length(converted[]) || return
        text = fmt_number(ustrip(converted[][i]))
        from.selected = i - 1
        value.text = text
    end
    signal_connect((_, _) -> update(), from, "notify::selected")
    signal_connect(_ -> update(), value, "changed")
    signal_connect(_ -> update_target(), target, "changed")
    signal_connect(target_copy, "clicked") do b
        isempty(target_result.label) || (copy_text(b, target_result.label); toast("Copied  " * target_result.label))
    end
    Gtk4.G_.select_row(sidebar, Gtk4.G_.get_row_at_index(sidebar, 0))

    scroll = GtkScrolledWindow()
    scroll[] = list
    scroll.vexpand = true
    side = GtkScrolledWindow()
    side[] = sidebar
    side.width_request = 180
    right = vbox(display, any_unit,
                 label("Type a number or a value with its unit (5 kV/m). Click a unit to convert from it.", "note"),
                 scroll; spacing = 12)
    right.hexpand = true
    update()
    return margins!(hbox(side, right; spacing = 16), 16)
end

theme_file() = joinpath(get(ENV, "XDG_CONFIG_HOME", joinpath(homedir(), ".config")), "juliacalc", "theme")

"The saved theme, else the desktop's light/dark preference."
function initial_theme()
    saved = try strip(read(theme_file(), String)) catch; "" end
    saved in ("dark", "light") && return Symbol(saved)
    # Gtk4 points XDG_DATA_DIRS at its own data; gsettings also needs the system schemas.
    dirs = get(ENV, "XDG_DATA_DIRS", "") * ":/usr/local/share:/usr/share"
    scheme = try read(addenv(`gsettings get org.gnome.desktop.interface color-scheme`, "XDG_DATA_DIRS" => dirs), String) catch; "" end
    return occursin("dark", scheme) ? :dark : :light
end

const CSS_PROVIDER = Ref{Any}(nothing)
function set_theme!(theme)
    display = Gtk4.GdkDisplay()
    CSS_PROVIDER[] === nothing || delete!(display, CSS_PROVIDER[])
    CSS_PROVIDER[] = GtkCssProvider(stylesheet(theme))
    push!(display, CSS_PROVIDER[])
    settings = convert(GtkSettings, ccall((:gtk_settings_get_default, Gtk4.libgtk4), Ptr{Gtk4.GLib.GObject}, ()))
    settings.gtk_application_prefer_dark_theme = theme === :dark   # popovers, scrollbars, tooltips
    return theme
end

"Fill `win`: header bar, calculator and converter. Returns the widgets scripts need to drive it."
function build_ui!(win)
    theme = Ref(set_theme!(initial_theme()))
    overlay = GtkOverlay()
    toast_label = label("", "toast"; wrap = false)
    revealer = GtkRevealer()
    revealer.transition_type = Gtk4.RevealerTransitionType_SLIDE_UP
    revealer.halign = Gtk4.Align_CENTER
    revealer.valign = Gtk4.Align_END
    revealer[] = toast_label
    shown = Ref(0)
    function toast(text)
        toast_label.label = text
        revealer.reveal_child = true
        n = shown[] += 1
        Gtk4.GLib.g_timeout_add(() -> (shown[] == n && (revealer.reveal_child = false); false), 1600)
    end

    calc, entry, clear = calculator_page(toast)
    pages = GtkStack()
    pages.transition_type = Gtk4.StackTransitionType_CROSSFADE
    Gtk4.G_.add_titled(pages, calc, "calculator", "Calculator")
    Gtk4.G_.add_titled(pages, converter_page(toast), "converter", "Converter")
    overlay[] = pages
    Gtk4.G_.add_overlay(overlay, revealer)

    header = GtkHeaderBar()
    switcher = GtkStackSwitcher()
    Gtk4.G_.set_stack(switcher, pages)
    Gtk4.G_.set_title_widget(header, switcher)
    clear_button = icon_button("edit-clear-all-symbolic", "Clear the history and forget variables")
    signal_connect(_ -> clear(), clear_button, "clicked")
    signal_connect(pages, "notify::visible-child-name") do _, _
        clear_button.visible = Gtk4.G_.get_visible_child_name(pages) == "calculator"
        nothing
    end
    theme_button = icon_button(theme[] === :dark ? "weather-clear-symbolic" : "weather-clear-night-symbolic",
                               "Switch between light and dark")
    signal_connect(theme_button, "clicked") do b
        theme[] = set_theme!(theme[] === :dark ? :light : :dark)
        b.icon_name = theme[] === :dark ? "weather-clear-symbolic" : "weather-clear-night-symbolic"
        try mkpath(dirname(theme_file())); write(theme_file(), string(theme[])) catch end
    end
    Gtk4.G_.pack_start(header, clear_button)
    Gtk4.G_.pack_end(header, theme_button)
    Gtk4.G_.set_titlebar(win, header)
    win[] = overlay
    Gtk4.G_.grab_focus(entry)
    return (; entry, pages)
end

"Open the window and return once it is closed. `GtkApplication.run` owns the GLib main loop,
so nothing touches GTK after the window is gone and the process exits cleanly."
function gui()
    Gtk4.GLib.G_.set_prgname("juliacalc")          # Gtk4 sets "julia"; the desktop entry matches this
    Gtk4.G_.set_default_icon_name("juliacalc")
    app = GtkApplication("org.juliacalc.JuliaCalc", Gtk4.GLib.ApplicationFlags_NON_UNIQUE)
    signal_connect(app, :activate) do app
        win = GtkApplicationWindow(app, "JuliaCalc")
        win.default_width, win.default_height = 900, 940
        build_ui!(win)
        show(win)
    end
    Gtk4.GLib.run(app)
    return nothing
end
