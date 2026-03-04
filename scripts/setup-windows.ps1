# Setup script for Parler on Windows 11
# Run this script in PowerShell as Administrator before building

Write-Host "=== Parler Windows 11 Setup ===" -ForegroundColor Cyan

# Check prerequisites
$missing = @()

# Check Bun
if (-not (Get-Command bun -ErrorAction SilentlyContinue)) {
    $missing += "Bun (https://bun.sh/)"
}

# Check Rust/Cargo
if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
    $missing += "Rust (https://rustup.rs/)"
}

# Check LLVM/libclang
if (-not (Test-Path "C:\Program Files\LLVM\bin\libclang.dll")) {
    Write-Host "Installing LLVM..." -ForegroundColor Yellow
    winget install LLVM.LLVM --accept-package-agreements --accept-source-agreements
}

# Check Vulkan SDK
$vulkanPath = Get-ChildItem "C:\VulkanSDK\" -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
if (-not $vulkanPath) {
    Write-Host "Installing Vulkan SDK..." -ForegroundColor Yellow
    winget install KhronosGroup.VulkanSDK --accept-package-agreements --accept-source-agreements
    $vulkanPath = Get-ChildItem "C:\VulkanSDK\" | Sort-Object Name -Descending | Select-Object -First 1
}

if ($missing.Count -gt 0) {
    Write-Host "`nPlease install the following prerequisites first:" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}

# Set environment variables permanently for the user
$vulkanSdk = "C:\VulkanSDK\$($vulkanPath.Name)"
$llvmBin = "C:\Program Files\LLVM\bin"

[System.Environment]::SetEnvironmentVariable("LIBCLANG_PATH", $llvmBin, "User")
[System.Environment]::SetEnvironmentVariable("VULKAN_SDK", $vulkanSdk, "User")

# Add LLVM to PATH if not already there
$currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*LLVM*") {
    [System.Environment]::SetEnvironmentVariable("PATH", "$currentPath;$llvmBin", "User")
}

Write-Host "`nEnvironment variables set:" -ForegroundColor Green
Write-Host "  LIBCLANG_PATH = $llvmBin"
Write-Host "  VULKAN_SDK    = $vulkanSdk"

# Set for current session
$env:LIBCLANG_PATH = $llvmBin
$env:VULKAN_SDK = $vulkanSdk
$env:PATH = "$env:PATH;$llvmBin"

# Download Silero VAD model if missing
$modelPath = "src-tauri\resources\models\silero_vad_v4.onnx"
if (-not (Test-Path $modelPath)) {
    Write-Host "`nDownloading Silero VAD model..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path "src-tauri\resources\models" | Out-Null
    Invoke-WebRequest -Uri "https://blob.handy.computer/silero_vad_v4.onnx" -OutFile $modelPath
    Write-Host "Model downloaded." -ForegroundColor Green
} else {
    Write-Host "`nSilero VAD model already present." -ForegroundColor Green
}

# Install JS dependencies
Write-Host "`nInstalling JS dependencies..." -ForegroundColor Yellow
bun install

Write-Host "`n=== Setup complete! ===" -ForegroundColor Green
Write-Host "You can now run: bun run tauri dev" -ForegroundColor Cyan
Write-Host "Note: Restart your terminal for PATH changes to take effect." -ForegroundColor Yellow
