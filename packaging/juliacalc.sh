#!/bin/sh
# Installed as /usr/bin/juliacalc. Runs the app through Julia's own `julia` binary (built
# against an old glibc, unlike PackageCompiler's launcher) with the app's system image.
# The bundled depot in /opt is read-only for users, so a per-user depot goes first: Gtk4
# writes its image-loader cache there on the first start.
app=/opt/juliacalc
export JULIA_DEPOT_PATH="${XDG_CACHE_HOME:-$HOME/.cache}/juliacalc:$app/share/julia"
export JULIA_LOAD_PATH="$app/share/julia"
# -O1: expressions compiled at run time (new unit combinations) compile ~30% faster; the
# app's own code is already compiled into the image.
exec "$app/bin/julia" --sysimage="$app/lib/julia/sys.so" --startup-file=no --history-file=no -O1 \
    -e 'using JuliaCalc; exit(JuliaCalc.julia_main())' -- "$@"
