$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Push-Location $PSScriptRoot
try {
    Push-Location app
    try {
        flutter pub get
        if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed.' }
        flutter build web --release --no-pub --no-web-resources-cdn
        if ($LASTEXITCODE -ne 0) { throw 'Flutter Web build failed.' }
    } finally { Pop-Location }

    # Keep the previous output for recovery; all generated files stay here.
    New-Item -ItemType Directory -Force artifacts | Out-Null
    $dist = Join-Path $PSScriptRoot 'dist'
    if (Test-Path -LiteralPath $dist) {
        $resolvedDist = (Resolve-Path -LiteralPath $dist).Path
        if ($resolvedDist -ne $dist -or (Get-Item -LiteralPath $dist).LinkType) {
            throw 'Refusing to move an unexpected deployment directory.'
        }
        Move-Item -LiteralPath $dist -Destination (Join-Path $PSScriptRoot "artifacts/dist-$([guid]::NewGuid())")
    }
    Copy-Item -LiteralPath app/build/web -Destination $dist -Recurse

    $export = Join-Path $PSScriptRoot "artifacts/source-$([guid]::NewGuid())"
    New-Item -ItemType Directory -Path "$export/app", "$export/packages/lightweight_liquid_glass" | Out-Null
    Copy-Item app/lib, app/web, app/assets, app/test, app/pubspec.yaml, app/pubspec.lock, app/analysis_options.yaml -Destination "$export/app" -Recurse
    Copy-Item packages/lightweight_liquid_glass/lib, packages/lightweight_liquid_glass/pubspec.yaml, packages/lightweight_liquid_glass/LICENSE -Destination "$export/packages/lightweight_liquid_glass" -Recurse
    Copy-Item README.md, VERIFICATION.md -Destination $export
    Compress-Archive -Path "$export/*" -DestinationPath "$dist/playground-source.zip" -Force

    foreach ($file in @('index.html', 'main.dart.js', 'flutter_bootstrap.js', 'canvaskit/canvaskit.wasm', 'playground-source.zip')) {
        if (-not (Test-Path -LiteralPath (Join-Path $dist $file))) { throw "Missing deployment asset: $file" }
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead("$dist/playground-source.zip")
    try {
        foreach ($entry in @('app/lib/main.dart', 'app/lib/editor_catalog.dart', 'app/lib/dialog_editor.dart', 'app/lib/motion_tryout.dart', 'app/lib/workbench_preview.dart', 'app/analysis_options.yaml', 'app/test/p0_workbench_test.dart', 'app/pubspec.yaml', 'packages/lightweight_liquid_glass/lib/lightweight_liquid_glass.dart')) {
            if ($zip.Entries.FullName.Replace('\', '/') -notcontains $entry) { throw "Missing source archive entry: $entry" }
        }
    } finally { $zip.Dispose() }
    Write-Output "Deployable static website: $dist"
} finally { Pop-Location }
