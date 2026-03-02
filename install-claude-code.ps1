# ============================================
# Claude Code 自动安装脚本 (Windows)
# ============================================
# 使用方法: 右键 -> 使用 PowerShell 运行
# 或者: powershell -ExecutionPolicy Bypass -File install-claude-code.ps1
# ============================================

param(
    [switch]$SkipNodeCheck,
    [switch]$UseApiKey
)

# 颜色输出函数
function Write-Success { Write-Host "[OK] $args" -ForegroundColor Green }
function Write-Error { Write-Host "[ERROR] $args" -ForegroundColor Red }
function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Cyan }
function Write-Warn { Write-Host "[WARN] $args" -ForegroundColor Yellow }
function Write-Step { Write-Host "`n==> $args" -ForegroundColor Magenta }

# 检测管理员权限
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 检测包管理器
function Get-PackageManager {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        return "winget"
    }
    elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        return "choco"
    }
    elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
        return "scoop"
    }
    return $null
}

# 安装 Node.js
function Install-NodeJS {
    $pkgManager = Get-PackageManager

    if (-not $pkgManager) {
        Write-Warn "未检测到包管理器，请先安装以下之一:"
        Write-Host "  - winget (Windows 自带)"
        Write-Host "  - Chocolatey: https://chocolatey.org/"
        Write-Host "  - Scoop: https://scoop.sh/"
        Write-Host ""

        $download = Read-Host "是否直接下载 Node.js 安装包? (y/n)"
        if ($download -eq 'y') {
            Start-Process "https://nodejs.org/en/download/"
            Write-Info "请在浏览器中下载并安装 Node.js LTS 版本，安装完成后重新运行此脚本"
            exit 0
        }
        return $false
    }

    Write-Info "使用 $pkgManager 安装 Node.js..."

    switch ($pkgManager) {
        "winget" {
            winget install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
        }
        "choco" {
            choco install nodejs-lts -y
        }
        "scoop" {
            scoop install nodejs-lts
        }
    }

    # 刷新环境变量
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

    return $true
}

# 验证 Node.js 安装
function Test-NodeJS {
    try {
        $nodeVersion = node -v
        $npmVersion = npm -v

        # 检查版本号 (需要 v18+)
        $versionNum = $nodeVersion -replace 'v(\d+)\..*', '$1'
        if ([int]$versionNum -lt 18) {
            Write-Error "Node.js 版本过低: $nodeVersion (需要 v18+)"
            return $false
        }

        Write-Success "Node.js: $nodeVersion"
        Write-Success "npm: $npmVersion"
        return $true
    }
    catch {
        return $false
    }
}

# 安装 Claude Code
function Install-ClaudeCode {
    Write-Info "正在安装 @anthropic-ai/claude-code..."

    npm install -g @anthropic-ai/claude-code

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Claude Code 安装成功!"
        return $true
    }
    else {
        Write-Error "Claude Code 安装失败"
        return $false
    }
}

# 验证 Claude Code 安装
function Test-ClaudeCode {
    try {
        $version = claude --version
        Write-Success "Claude Code: $version"
        return $true
    }
    catch {
        return $false
    }
}

# 配置 API Key
function Set-ApiKey {
    Write-Step "配置 Anthropic API Key"

    Write-Host "请输入你的 Anthropic API Key (格式: sk-ant-xxx):" -NoNewline
    $apiKey = Read-Host

    if ($apiKey -notmatch "^sk-ant-") {
        Write-Error "API Key 格式不正确，应以 'sk-ant-' 开头"
        return $false
    }

    # 设置用户级环境变量
    [System.Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $apiKey, "User")
    $env:ANTHROPIC_API_KEY = $apiKey

    Write-Success "API Key 已保存到系统环境变量"
    return $true
}

# 主程序
function Main {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "   Claude Code 自动安装脚本 (Windows)      " -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""

    # 步骤1: 检查 Node.js
    Write-Step "检查 Node.js 环境"

    if ($SkipNodeCheck) {
        Write-Info "跳过 Node.js 检查"
    }
    elseif (Test-NodeJS) {
        Write-Success "Node.js 环境正常"
    }
    else {
        Write-Warn "未检测到 Node.js 或版本过低"

        if (-not (Test-Administrator)) {
            Write-Warn "建议以管理员身份运行以便自动安装 Node.js"
            $continue = Read-Host "是否继续尝试安装? (y/n)"
            if ($continue -ne 'y') {
                exit 1
            }
        }

        if (-not (Install-NodeJS)) {
            Write-Error "Node.js 安装失败，请手动安装后重试"
            exit 1
        }

        # 重新检查
        if (-not (Test-NodeJS)) {
            Write-Error "Node.js 安装后仍无法检测，请重启终端后重试"
            Write-Info "可能需要重启 PowerShell 或重新登录 Windows"
            exit 1
        }
    }

    # 步骤2: 安装 Claude Code
    Write-Step "安装 Claude Code"

    if (Test-ClaudeCode) {
        Write-Info "Claude Code 已安装"
        $reinstall = Read-Host "是否重新安装? (y/n)"
        if ($reinstall -eq 'y') {
            npm uninstall -g @anthropic-ai/claude-code
            if (-not (Install-ClaudeCode)) {
                exit 1
            }
        }
    }
    else {
        if (-not (Install-ClaudeCode)) {
            exit 1
        }
    }

    # 步骤3: 配置认证
    Write-Step "配置认证"

    if ($UseApiKey) {
        Set-ApiKey
    }
    else {
        Write-Host "请选择认证方式:"
        Write-Host "  1. 交互式登录 (推荐，自动打开浏览器)"
        Write-Host "  2. API Key 方式"
        Write-Host ""

        $choice = Read-Host "请选择 (1/2)"

        if ($choice -eq '2') {
            Set-ApiKey
        }
    }

    # 完成
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "   安装完成!                              " -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "使用方法:" -ForegroundColor Yellow
    Write-Host "  1. 打开新的 PowerShell 窗口"
    Write-Host "  2. 输入 'claude' 启动"
    Write-Host "  3. 首次运行会引导你完成登录"
    Write-Host ""
    Write-Host "常用命令:" -ForegroundColor Yellow
    Write-Host "  claude          - 启动 Claude Code"
    Write-Host "  claude --help   - 查看帮助"
    Write-Host "  claude --version- 查看版本"
    Write-Host ""
}

# 执行主程序
Main
