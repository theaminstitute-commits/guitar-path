# Builds the Guitar Path test APK without Gradle, using Android Studio's bundled JDK and the SDK build tools.
# Usage (PowerShell, from anywhere):  .\android\build-apk.ps1 -Version 0.7 -Code 7
# Output: dist\GuitarPath-v<Version>-test.apk, signed with the local debug key (~\.android\debug.keystore).
# Code must go up with every release so phones accept it as an update.
param(
  [Parameter(Mandatory = $true)][string]$Version,
  [Parameter(Mandatory = $true)][int]$Code
)
$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
$Android = $PSScriptRoot
$Sdk = "$env:LOCALAPPDATA\Android\Sdk"
$BuildTools = "$Sdk\build-tools\36.0.0"
$AndroidJar = "$Sdk\platforms\android-36\android.jar"
$Jdk = 'C:\Program Files\Android\Android Studio\jbr'
$env:JAVA_HOME = $Jdk
function Check($what) { if ($LASTEXITCODE -ne 0) { throw "$what failed (exit $LASTEXITCODE)" } }

# 1. Page into android\assets (also refreshes index.html and the Linux bundle).
node "$Root\tools\build.js" | Out-Host; Check 'tools/build.js'

$B = "$Android\build"
if (Test-Path $B) { Remove-Item $B -Recurse -Force }
New-Item -ItemType Directory "$B\gen", "$B\classes", "$B\dex" | Out-Null

# 2. Resources + manifest -> base APK (and R.java).
& "$BuildTools\aapt2.exe" compile --dir "$Android\res" -o "$B\res.zip"; Check 'aapt2 compile'
& "$BuildTools\aapt2.exe" link -I $AndroidJar --manifest "$Android\AndroidManifest.xml" -A "$Android\assets" "$B\res.zip" `
  --java "$B\gen" --min-sdk-version 26 --target-sdk-version 36 --version-code $Code --version-name "$Version-test" -o "$B\base.apk"
Check 'aapt2 link'

# 3. Java -> classes.dex, added to the APK.
$java = @("$B\gen\com\guitarpath\app\R.java") + (Get-ChildItem "$Android\src" -Recurse -Filter *.java | ForEach-Object FullName)
& "$Jdk\bin\javac.exe" -Xlint:-options --release 11 -classpath $AndroidJar -d "$B\classes" $java; Check 'javac'
$classes = Get-ChildItem "$B\classes" -Recurse -Filter *.class | ForEach-Object FullName
& "$BuildTools\d8.bat" --release --min-api 26 --lib $AndroidJar --output "$B\dex" $classes; Check 'd8'
Copy-Item "$B\base.apk" "$B\unaligned.apk"
Push-Location "$B\dex"; & "$Jdk\bin\jar.exe" -uf "$B\unaligned.apk" classes.dex; Pop-Location; Check 'jar'

# 4. Align and sign. (apksigner prints harmless Java warnings on stderr, so it runs through cmd.)
& "$BuildTools\zipalign.exe" -f -p 4 "$B\unaligned.apk" "$B\aligned.apk"; Check 'zipalign'
New-Item -ItemType Directory -Force "$Root\dist" | Out-Null
$Apk = "$Root\dist\GuitarPath-v$Version-test.apk"
cmd /c "`"$BuildTools\apksigner.bat`" sign --ks `"%USERPROFILE%\.android\debug.keystore`" --ks-pass pass:android --key-pass pass:android --ks-key-alias androiddebugkey --out `"$Apk`" `"$B\aligned.apk`" 2>nul"
Check 'apksigner sign'
cmd /c "`"$BuildTools\apksigner.bat`" verify `"$Apk`" 2>nul"; Check 'apksigner verify'
Remove-Item "$Apk.idsig" -ErrorAction SilentlyContinue
Write-Host "Built $Apk ($((Get-Item $Apk).Length) bytes, versionCode $Code)"
