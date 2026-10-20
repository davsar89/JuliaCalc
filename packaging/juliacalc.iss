; Inno Setup 6 script of the Windows installer. Build it with packaging/build_windows.jl, which
; passes /DAppVersion=<Project.toml version> /DAppDir=<build\app> /O<dist>.
; It installs for the current user only (no admin prompt), in %LOCALAPPDATA%\Programs\JuliaCalc:
; Gtk4 writes a cache into the app's depot (share\julia) on the first start, so the app folder has
; to be writable, and Program Files is not.

#ifndef AppVersion
  #error Build with packaging/build_windows.jl, which defines AppVersion and AppDir
#endif

[Setup]
; Keep AppId: it is how a newer installer finds and replaces the installed version.
AppId={{2D4F9574-97BD-4467-BD60-6E465D1834B8}
AppName=JuliaCalc
AppVersion={#AppVersion}
AppPublisher=David
AppPublisherURL=https://github.com/davsar89/JuliaCalc
AppComments=Calculator and unit converter with explicit angle units
PrivilegesRequired=lowest
DefaultDirName={autopf}\JuliaCalc
DisableProgramGroupPage=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputBaseFilename=JuliaCalc-{#AppVersion}-setup
SetupIconFile=icons\juliacalc-setup.ico
UninstallDisplayIcon={app}\juliacalc.ico
WizardStyle=modern
Compression=lzma2/max
SolidCompression=yes
LZMAUseSeparateProcess=yes

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[InstallDelete]
; Remove the previous version first: artifact folders are named by content hash, so an older
; build's files would otherwise stay next to the new ones.
Type: filesandordirs; Name: "{app}\bin"
Type: filesandordirs; Name: "{app}\lib"
Type: filesandordirs; Name: "{app}\libexec"
Type: filesandordirs; Name: "{app}\share"

[Files]
; Leave out what a test run of build\app wrote: its loader cache names build\app paths.
Source: "{#AppDir}\*"; DestDir: "{app}"; Excludes: "\share\julia\scratchspaces,\share\julia\logs"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "icons\juliacalc.ico"; DestDir: "{app}"; Flags: ignoreversion
; Window and taskbar icon: gui() adds {app}\share\icons to GTK's icon search path on Windows.
Source: "icons\juliacalc-256.png"; DestDir: "{app}\share\icons\hicolor\256x256\apps"; DestName: "juliacalc.png"; Flags: ignoreversion
Source: "icons\juliacalc-512.png"; DestDir: "{app}\share\icons\hicolor\512x512\apps"; DestName: "juliacalc.png"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\JuliaCalc"; Filename: "{app}\bin\juliacalcw.exe"; IconFilename: "{app}\juliacalc.ico"; Comment: "Calculator and unit converter"
Name: "{autodesktop}\JuliaCalc"; Filename: "{app}\bin\juliacalcw.exe"; IconFilename: "{app}\juliacalc.ico"; Tasks: desktopicon

[Run]
; Build Gtk4's gdk-pixbuf loader cache now, with the console hidden. Otherwise the app's first
; start runs gdk-pixbuf-query-loaders.exe, a console program, and a terminal window flashes up.
Filename: "{app}\bin\juliacalc.exe"; Parameters: "1+1"; StatusMsg: "Preparing JuliaCalc..."; Flags: runhidden
Filename: "{app}\bin\juliacalcw.exe"; Description: "{cm:LaunchProgram,JuliaCalc}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Written by the app at run time (Gtk4's gdk-pixbuf loader cache, Scratch's usage log).
Type: filesandordirs; Name: "{app}\share\julia\scratchspaces"
Type: filesandordirs; Name: "{app}\share\julia\logs"
