# Build dist/JuliaCalc-<version>-setup.exe: a per-user Windows installer (Inno Setup 6) for the
# self-contained app (Julia runtime, GTK 4 and a precompiled system image).
# From the repository root, with Julia 1.11 (the version the manifests were resolved with):
#   julia --project=packaging packaging/build_windows.jl
# The precompile workload opens a JuliaCalc window for a few seconds; leave it alone.
# Add --package-only to reuse build/app from the last run (juliacalc.iss or icon changes).
# ISCC.exe is taken from ENV["ISCC"], else PATH, else the default Inno Setup 6 folders.
using PackageCompiler, TOML

root = dirname(@__DIR__)
version = TOML.parsefile(joinpath(root, "Project.toml"))["version"]
app = joinpath(root, "build", "app")
"--package-only" in ARGS ||
    create_app(root, app; executables = ["juliacalc" => "julia_main"],
               precompile_execution_file = joinpath(@__DIR__, "precompile.jl"),   # GUI, separate process
               script = joinpath(@__DIR__, "warmup.jl"),                           # unit code, in-process
               include_lazy_artifacts = true, filter_stdlibs = true, force = true)

# Julia's startup (Base.Linking) looks for lld and dsymutil next to itself, else on PATH with
# Sys.which, which throws on a PATH entry it cannot stat, and the app dies before its window: e.g.
# a user-made junction (fnm puts one on PATH) when Inno Setup starts the app, as Setup blocks
# following those. The app never links code; the bundled copies only stop that PATH search.
for tool in ("lld.exe", "dsymutil.exe")
    dst = normpath(app, "bin", Base.PRIVATE_LIBEXECDIR, tool)
    cp(joinpath(Sys.BINDIR, Base.PRIVATE_LIBEXECDIR, tool), (mkpath(dirname(dst)); dst); force = true)
end
paths = readchomp(addenv(`$(joinpath(app, "bin", "julia.exe")) --startup-file=no -e
                          "print(Base.Linking.lld_path[], ';', Base.Linking.dsymutil_path[])"`,
                         # a scratch depot for Gtk4's cache, then the app's own (its artifacts)
                         "JULIA_DEPOT_PATH" => mktempdir() * ";" * joinpath(app, "share", "julia")))
all(startswith(app), split(paths, ';')) || error("the app does not find its bundled lld and dsymutil: $paths")

# Embed the app icon in the launcher, or Explorer and the taskbar (until GTK sets the window's icon)
# show a generic one: each image of the .ico becomes an RT_ICON resource, listed by an RT_GROUP_ICON.
function set_icon(exe, ico)
    b = read(ico)
    u16(i) = Int(ltoh(reinterpret(UInt16, b[i:i+1])[1]))
    u32(i) = Int(ltoh(reinterpret(UInt32, b[i:i+3])[1]))
    group = IOBuffer(b[1:6]; write = true, append = true)       # ICONDIR header: reserved, type 1, count
    h = ccall((:BeginUpdateResourceW, "kernel32"), Ptr{Cvoid}, (Cwstring, Cint), exe, false)
    h == C_NULL && error("BeginUpdateResource failed on $exe")
    update(type, id, data) = ccall((:UpdateResourceW, "kernel32"), Cint,
                                   (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, UInt16, Ptr{UInt8}, UInt32),
                                   h, Ptr{Cvoid}(type), Ptr{Cvoid}(id), 0, data, length(data)) != 0 ||
                                error("UpdateResource failed on $exe")
    for i in 1:u16(5)
        e = 7 + 16(i - 1)                                       # ICONDIRENTRY i: size at +8, offset at +12
        update(3, i, b[u32(e+12)+1:u32(e+12)+u32(e+8)])         # RT_ICON
        write(group, b[e:e+11], UInt16(i))                      # GRPICONDIRENTRY: same fields, then the id
    end
    update(14, 1, take!(group))                                 # RT_GROUP_ICON
    ccall((:EndUpdateResourceW, "kernel32"), Cint, (Ptr{Cvoid}, Cint), h, false) != 0 ||
        error("EndUpdateResource failed on $exe")
end
set_icon(joinpath(app, "bin", "juliacalc.exe"), joinpath(@__DIR__, "icons", "juliacalc.ico"))
run(`$(joinpath(app, "bin", "juliacalc.exe")) 1+1`)            # still starts after the resource edit

# juliacalc.exe is a console program, so `juliacalc "expr"` prints in a terminal, but started from
# the Start menu it would also open a console window. juliacalcw.exe (like python/pythonw) is the
# same file with the PE header's Subsystem field changed from CONSOLE (3) to WINDOWS (2).
exe = read(joinpath(app, "bin", "juliacalc.exe"))
pe = Int(ltoh(reinterpret(UInt32, exe[0x3d:0x40])[1]))     # e_lfanew: file offset of "PE\0\0"
subsystem = pe + 4 + 20 + 68 + 1                           # signature, COFF header, optional header field; 1-based
exe[pe+1:pe+4] == b"PE\0\0" && exe[subsystem:subsystem+1] == [0x03, 0x00] ||
    error("bin/juliacalc.exe is not a console PE executable")
exe[subsystem] = 0x02
write(joinpath(app, "bin", "juliacalcw.exe"), exe)

isccs = [get(ENV, "ISCC", ""); something(Sys.which("ISCC"), "");
         [joinpath(dir, "Inno Setup 6", "ISCC.exe") for dir in (joinpath(get(ENV, "LOCALAPPDATA", ""), "Programs"),
                                                              get(ENV, "ProgramFiles(x86)", ""), get(ENV, "ProgramFiles", ""))]]
iscc = findfirst(isfile, isccs)
iscc === nothing && error("Inno Setup 6 not found: `winget install JRSoftware.InnoSetup`, or set ENV[\"ISCC\"] to ISCC.exe")
dist = joinpath(root, "dist")
run(`$(isccs[iscc]) /Qp /DAppVersion=$version /DAppDir=$app /O$dist $(joinpath(@__DIR__, "juliacalc.iss"))`)
println("built ", joinpath(dist, "JuliaCalc-$version-setup.exe"))
