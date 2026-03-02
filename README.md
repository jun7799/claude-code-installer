# Claude Code 自动安装脚本

[![GitHub stars](https://img.shields.io/github/stars/jun7799/claude-code-installer?style=social)](https://github.com/jun7799/claude-code-installer/stargazers)
[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)

一键安装 Claude Code 的自动化脚本，支持 Windows 和 Mac/Linux。

---

## 快速开始

### Windows

**方式一：右键运行**
```
右键 install-claude-code.ps1 -> 使用 PowerShell 运行
```

**方式二：命令行运行**
```powershell
powershell -ExecutionPolicy Bypass -File install-claude-code.ps1
```

**方式三：管理员模式（推荐）**
```powershell
# 以管理员身份打开 PowerShell，然后运行
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\install-claude-code.ps1
```

### Mac / Linux

**方式一：curl 一键安装**
```bash
# 如果你已经把脚本放到可访问的地方
curl -fsSL https://your-domain.com/install-claude-code.sh | bash
```

**方式二：本地运行**
```bash
chmod +x install-claude-code.sh
./install-claude-code.sh
```

---

## 脚本功能

| 功能 | Windows | Mac | Linux |
|------|---------|-----|-------|
| 检测 Node.js 版本 | ✅ | ✅ | ✅ |
| 自动安装 Node.js | ✅ | ✅ | ✅ |
| 安装 Claude Code | ✅ | ✅ | ✅ |
| 交互式认证配置 | ✅ | ✅ | ✅ |
| API Key 配置 | ✅ | ✅ | ✅ |

---

## 支持的包管理器

### Windows
- **winget** (Windows 自带)
- **Chocolatey**
- **Scoop**

### Mac
- **Homebrew** (推荐)
- **nvm** (Node 版本管理)

### Linux
- **apt** (Debian/Ubuntu)
- **yum/dnf** (RHEL/CentOS/Fedora)
- **pacman** (Arch Linux)
- **nvm** (通用)

---

## 命令行参数

### Windows (PowerShell)

```powershell
# 跳过 Node.js 检查（已安装的情况）
.\install-claude-code.ps1 -SkipNodeCheck

# 直接使用 API Key 方式认证
.\install-claude-code.ps1 -UseApiKey
```

### Mac / Linux

```bash
# 暂不支持命令行参数，按提示操作即可
./install-claude-code.sh
```

---

## 安装后验证

```bash
# 检查 Node.js 版本
node -v

# 检查 Claude Code 版本
claude --version

# 启动 Claude Code
claude
```

---

## 常见问题

### Windows: "无法运行脚本"

```powershell
# 临时允许脚本执行
powershell -ExecutionPolicy Bypass -File install-claude-code.ps1

# 或永久修改执行策略
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Mac: "xcode-select: error"

```bash
# 安装 Xcode Command Line Tools
xcode-select --install
```

### Mac: "brew: command not found"

```bash
# 安装 Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 通用: npm 全局安装权限问题

```bash
# 方式一：使用 sudo (不推荐)
sudo npm install -g @anthropic-ai/claude-code

# 方式二：修改 npm 全局目录（推荐）
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc  # 或 ~/.bashrc
source ~/.zshrc
```

---

## 手动安装

如果脚本无法正常工作，可以手动安装：

### 1. 安装 Node.js
- 下载地址：https://nodejs.org/
- 选择 **LTS** 版本
- 安装完成后验证：`node -v`

### 2. 安装 Claude Code
```bash
npm install -g @anthropic-ai/claude-code
```

### 3. 登录认证
```bash
claude
# 按提示完成登录
```

---

## 获取 API Key

1. 访问 [Anthropic Console](https://console.anthropic.com/)
2. 登录或注册账号
3. 进入 API Keys 页面
4. 点击 "Create Key" 创建新的 API Key
5. 复制 Key（格式：`sk-ant-xxx`）

---

## 相关链接

- [Claude Code 官方文档](https://docs.anthropic.com/claude-code)
- [Anthropic API 文档](https://docs.anthropic.com/)
- [Node.js 官网](https://nodejs.org/)
