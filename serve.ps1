$ErrorActionPreference = "Stop"

$root = Join-Path $PSScriptRoot "pwa"
if (-not (Test-Path (Join-Path $root "index.html"))) {
    Write-Host "找不到 pwa\index.html，请确认文件夹完整。" -ForegroundColor Red
    Read-Host "按回车退出"
    exit 1
}

$python = "C:\Users\11623\.dsh\dsh-runtimes\dsh-primary-runtime\dependencies\python\python.exe"
if (-not (Test-Path $python)) {
    $python = "python"
}

$port = 8766

$ip = $null
try {
    $conf = Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null } | Select-Object -First 1
    if ($conf) { $ip = $conf.IPv4Address.IPAddress }
} catch { }
if (-not $ip) { $ip = "你的电脑IP" }

Write-Host ""
Write-Host "  Money 已启动" -ForegroundColor Cyan
Write-Host "  ------------------------------------------"
Write-Host "  手机（同一 Wi-Fi）打开：" -ForegroundColor Green
Write-Host "      http://$ip`:$port" -ForegroundColor Yellow
Write-Host "  电脑打开：" -ForegroundColor Green
Write-Host "      http://127.0.0.1:$port" -ForegroundColor Yellow
Write-Host "  ------------------------------------------"
Write-Host "  先让手机 Safari 打开上面的地址，再 分享 -> 添加到主屏幕。"
Write-Host "  这个窗口不要关；关掉服务就停了。"
Write-Host ""

& $python -m http.server $port --bind 0.0.0.0 --directory $root
