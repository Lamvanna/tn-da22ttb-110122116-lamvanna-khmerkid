@echo off
REM ════════════════════════════════════════════════════
REM  Kiem tra dung luong build/ va .dart_tool/
REM  Double-click file nay de chay
REM ════════════════════════════════════════════════════
echo.
echo === Workspace size check ===
echo.
powershell -NoProfile -Command "@('build','.dart_tool','android\.gradle') | ForEach-Object { if (Test-Path $_) { $s = (Get-ChildItem $_ -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum; Write-Host ('{0,-25} {1,8} MB' -f $_, [math]::Round($s/1MB,1)) } else { Write-Host ('{0,-25} (not found)' -f $_) } }"
echo.
echo Tip: chay 'flutter clean' khi tong > 2000 MB
pause
