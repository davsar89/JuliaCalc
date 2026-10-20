# Build dist/juliacalc_<version>_amd64.deb: a self-contained app (Julia runtime, GTK 4 and a
# precompiled system image) that runs on Ubuntu 20.04+ without a Julia install.
# From the repository root (Xvfb gives the precompile workload a display to draw on):
#   xvfb-run -a julia --project=packaging packaging/build_deb.jl
# Add --package-only to reuse build/app from the last run (icon or desktop-entry changes).
using PackageCompiler, TOML

root = dirname(@__DIR__)
version = TOML.parsefile(joinpath(root, "Project.toml"))["version"]
app = joinpath(root, "build", "app")
"--package-only" in ARGS ||
    create_app(root, app; executables = ["juliacalc" => "julia_main"],
               precompile_execution_file = joinpath(@__DIR__, "precompile.jl"),   # GUI, separate process
               script = joinpath(@__DIR__, "warmup.jl"),                           # unit code, in-process
               include_lazy_artifacts = true, filter_stdlibs = true, force = true)

pkg = joinpath(root, "build", "deb")
rm(pkg; recursive = true, force = true)
install(src, dst) = (mkpath(dirname(dst)); cp(src, dst))
install(app, joinpath(pkg, "opt", "juliacalc"))
rm(joinpath(pkg, "opt", "juliacalc", "bin", "juliacalc"))   # needs the build host's glibc; juliacalc.sh replaces it
install(joinpath(@__DIR__, "juliacalc.sh"), joinpath(pkg, "usr", "bin", "juliacalc"))
install(joinpath(@__DIR__, "juliacalc.desktop"), joinpath(pkg, "usr", "share", "applications", "org.juliacalc.JuliaCalc.desktop"))
for px in (256, 512)
    install(joinpath(@__DIR__, "icons", "juliacalc-$px.png"),
            joinpath(pkg, "usr", "share", "icons", "hicolor", "$(px)x$px", "apps", "juliacalc.png"))
end
run(`chmod -R u=rwX,go=rX $pkg`)                   # root-owned and not group-writable once installed

installed_kb = split(read(`du -sk $pkg`, String))[1]
mkpath(joinpath(pkg, "DEBIAN"))
write(joinpath(pkg, "DEBIAN", "control"), """
    Package: juliacalc
    Version: $version
    Section: math
    Priority: optional
    Architecture: amd64
    Installed-Size: $installed_kb
    Maintainer: David <17025345+davsar89@users.noreply.github.com>
    Description: calculator and unit converter with explicit angle units
     sin/cos/tan take radians, sind/cosd/tand take degrees, and angles with a unit
     (30°, 0.5rad) work in both. Unit conversion by Unitful.jl, geometry helpers and
     a triangle solver. Self-contained: bundles Julia and GTK 4.
    """)

# xz, not the zstd default of newer dpkg: older dpkg releases cannot read zstd archives.
# dist/ keeps only this build, so `apt install ./dist/juliacalc_*_amd64.deb` names one package.
dist = joinpath(root, "dist")
rm(dist; recursive = true, force = true)
deb = joinpath(mkpath(dist), "juliacalc_$(version)_amd64.deb")
run(`dpkg-deb -Zxz --root-owner-group --build $pkg $deb`)
println("built ", deb)
