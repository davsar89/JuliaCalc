#!/usr/bin/env bash
# Run JuliaCalc from source in debug mode: no build or install needed.
#   ./dev.sh                     open the window
#   ./dev.sh "100 km/h to mph"   evaluate in the terminal instead
# Every evaluation, its hints and full stack traces are printed to this terminal.
dir="$(dirname "$(readlink -f "$0")")"
exec julia --project="$dir" --startup-file=no -e 'using JuliaCalc; exit(JuliaCalc.julia_main())' -- --debug "$@"
