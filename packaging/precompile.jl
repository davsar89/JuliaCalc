# Workload that PackageCompiler records in a separate process (`precompile_execution_file`):
# it drives the real launch path (julia_main → GtkApplication window) so the GUI code is
# compiled into the app. Unit-typed code is warmed by warmup.jl instead, because recorded
# statements that mention Unitful types cannot be replayed.
using JuliaCalc, Gtk4
const G = Gtk4.G_

function find_widget(pred, w)
    pred(w) && return w
    c = G.get_first_child(w)
    while c !== nothing
        found = find_widget(pred, c)
        found === nothing || return found
        c = G.get_next_sibling(c)
    end
    return nothing
end
has_class(w, class) = class in css_classes(w)

Gtk4.GLib.g_timeout_add(1500) do
    win = only(filter(w -> w isa GtkApplicationWindow, collect(Gtk4.toplevels())))
    entry = find_widget(w -> w isa GtkEntry && has_class(w, "calc-entry"), win)
    for input in ("sind(30)", "sin(30)", "100 km/h to mph", "triangle(a=3, b=4, C=90°)", "45° + 10", "photon(500nm)")
        entry.text = input
        Gtk4.GLib.signal_emit(entry, "activate", Nothing)
    end
    entry.text = "tand("                              # live signature line
    Gtk4.GLib.signal_emit(find_widget(w -> w isa GtkButton && has_class(w, "copy"), win), "clicked", Nothing)
    pages = find_widget(w -> w isa GtkStack && G.get_visible_child_name(w) == "calculator", win)
    G.set_visible_child_name(pages, "converter")
    find_widget(w -> w isa GtkEntry && has_class(w, "value-entry"), win).text = "5 kV/m"
    find_widget(w -> w isa GtkEntry && has_class(w, "target-entry"), win).text = "V/cm"
    Gtk4.GLib.g_timeout_add(() -> (close(win); false), 1000)
    false
end
JuliaCalc.julia_main()
