#!/bin/bash

# ============================================
# Claude Code 自动安装脚本 (Mac/Linux)
# ============================================
# 使用方法:
#   curl -fsSL https://your-url/install-claude-code.sh | bash
#   或者: chmod +x install-claude-code.sh && ./install-claude-code.sh
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# 输出函数
print_success() { echo -e "${GREEN}[OK]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_step() { echo -e "\n${MAGENTA}==>${NC} $1"; }

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "mac"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            echo "debian"
        elif command -v yum &> /dev/null; then
            echo "rhel"
        elif command -v pacman &> /dev/null; then
            echo "arch"
        else
            echo "linux"
        fi
    else
        echo "unknown"
    fi
}

# 检测包管理器
detect_package_manager() {
    if command -v brew &> /dev/null; then
        echo "brew"
    elif command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    else
        echo "none"
    fi
}

# 检查 Node.js
check_node() {
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node -v)
        NPM_VERSION=$(npm -v)

        # 检查版本号 (需要 v18+)
        VERSION_NUM=$(echo $NODE_VERSION | sed 's/v\([0-9]*\).*/\1/')

        if [ "$VERSION_NUM" -lt 18 ]; then
            print_error "Node.js 版本过低: $NODE_VERSION (需要 v18+)"
            return 1
        fi

        print_success "Node.js: $NODE_VERSION"
        print_success "npm: $NPM_VERSION"
        return 0
    else
        return 1
    fi
}

# 安装 Homebrew (Mac)
install_homebrew() {
    print_info "正在安装 Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # 配置 PATH (Apple Silicon Mac)
    if [[ $(uname -m) == 'arm64' ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
}

# 安装 Node.js
install_node() {
    local OS=$(detect_os)
    local PKG_MGR=$(detect_package_manager)

    print_info "检测到系统: $OS"
    print_info "包管理器: $PKG_MGR"

    # 检查是否使用 nvm
    read -p "是否使用 nvm 安装 Node.js? (推荐，方便管理版本) [y/N]: " USE_NVM

    if [[ "$USE_NVM" =~ ^[Yy]$ ]]; then
        install_via_nvm
        return $?
    fi

    case $PKG_MGR in
        brew)
            print_info "使用 Homebrew 安装 Node.js..."
            brew install node
            ;;
        apt)
            print_info "使用 apt 安装 Node.js..."
            # 添加 NodeSource 仓库 (获取最新版本)
            curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
            sudo apt-get install -y nodejs
            ;;
        yum|dnf)
            print_info "使用 yum/dnf 安装 Node.js..."
            curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo -E bash -
            sudo yum install -y nodejs
            ;;
        pacman)
            print_info "使用 pacman 安装 Node.js..."
            sudo pacman -S --noconfirm nodejs npm
            ;;
        *)
            print_error "未检测到支持的包管理器"
            print_info "请手动安装 Node.js: https://nodejs.org/"
            return 1
            ;;
    esac

    # 验证安装
    if check_node; then
        return 0
    else
        print_error "Node.js 安装失败"
        return 1
    fi
}

# 使用 nvm 安装
install_via_nvm() {
    print_info "正在安装 nvm..."

    # 安装 nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

    # 加载 nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # 安装 Node.js LTS
    print_info "正在安装 Node.js LTS..."
    nvm install --lts
    nvm use --lts

    # 验证
    if check_node; then
        print_success "通过 nvm 安装 Node.js 成功!"
        print_info "注意: 重启终端后 nvm 才会生效"
        return 0
    else
        return 1
    fi
}

# 安装 Claude Code
install_claude_code() {
    print_info "正在安装 @anthropic-ai/claude-code..."

    npm install -g @anthropic-ai/claude-code

    if [ $? -eq 0 ]; then
        print_success "Claude Code 安装成功!"
        return 0
    else
        print_error "Claude Code 安装失败"
        return 1
    fi
}

# 验证 Claude Code
check_claude_code() {
    if command -v claude &> /dev/null; then
        VERSION=$(claude --version 2>/dev/null || echo "unknown")
        print_success "Claude Code: $VERSION"
        return 0
    else
        return 1
    fi
}

# 配置 API Key
configure_api_key() {
    print_step "配置 Anthropic API Key"

    read -p "请输入你的 Anthropic API Key (格式: sk-ant-xxx): " API_KEY

    if [[ ! "$API_KEY" =~ ^sk-ant- ]]; then
        print_error "API Key 格式不正确，应以 'sk-ant-' 开头"
        return 1
    fi

    # 检测 shell 配置文件
    if [[ -f "$HOME/.zshrc" ]]; then
        SHELL_RC="$HOME/.zshrc"
    elif [[ -f "$HOME/.bashrc" ]]; then
        SHELL_RC="$HOME/.bashrc"
    else
        SHELL_RC="$HOME/.profile"
    fi

    # 添加环境变量
    echo "" >> "$SHELL_RC"
    echo "# Anthropic API Key for Claude Code" >> "$SHELL_RC"
    echo "export ANTHROPIC_API_KEY=\"$API_KEY\"" >> "$SHELL_RC"

    # 当前会话生效
    export ANTHROPIC_API_KEY="$API_KEY"

    print_success "API Key 已保存到 $SHELL_RC"
    return 0
}

# Mac 特定检查
check_mac_prerequisites() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # 检查 Xcode Command Line Tools
        if ! xcode-select -p &> /dev/null; then
            print_warn "未检测到 Xcode Command Line Tools"
            read -p "是否安装? (y/n): " INSTALL_XCODE

            if [[ "$INSTALL_XCODE" =~ ^[Yy]$ ]]; then
                xcode-select --install
                print_info "请等待 Xcode Command Line Tools 安装完成后重新运行此脚本"
                exit 0
            fi
        fi

        # 检查 Homebrew
        if ! command -v brew &> /dev/null; then
            print_warn "未检测到 Homebrew"
            read -p "是否安装 Homebrew? (推荐) [y/N]: " INSTALL_BREW

            if [[ "$INSTALL_BREW" =~ ^[Yy]$ ]]; then
                install_homebrew
            fi
        fi
    fi
}

# 主程序
main() {
    echo ""
    echo -e "${CYAN}============================================${NC}"
    echo -e "${CYAN}   Claude Code 自动安装脚本 (Mac/Linux)   ${NC}"
    echo -e "${CYAN}============================================${NC}"
    echo ""

    # 步骤0: Mac 特定检查
    if [[ "$OSTYPE" == "darwin"* ]]; then
        print_step "Mac 系统检查"
        check_mac_prerequisites
    fi

    # 步骤1: 检查 Node.js
    print_step "检查 Node.js 环境"

    if check_node; then
        print_success "Node.js 环境正常"
    else
        print_warn "未检测到 Node.js 或版本过低"

        if ! install_node; then
            print_error "Node.js 安装失败，请手动安装后重试"
            exit 1
        fi
    fi

    # 步骤2: 安装 Claude Code
    print_step "安装 Claude Code"

    if check_claude_code; then
        print_info "Claude Code 已安装"
        read -p "是否重新安装? (y/n): " REINSTALL

        if [[ "$REINSTALL" =~ ^[Yy]$ ]]; then
            npm uninstall -g @anthropic-ai/claude-code
            if ! install_claude_code; then
                exit 1
            fi
        fi
    else
        if ! install_claude_code; then
            exit 1
        fi
    fi

    # 步骤3: 配置认证
    print_step "配置认证"

    echo "请选择认证方式:"
    echo "  1. 交互式登录 (推荐，自动打开浏览器)"
    echo "  2. API Key 方式"
    echo ""

    read -p "请选择 (1/2): " AUTH_CHOICE

    if [[ "$AUTH_CHOICE" == "2" ]]; then
        configure_api_key
    fi

    # 完成
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}   安装完成!                              ${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo -e "${YELLOW}使用方法:${NC}"
    echo "  1. 打开新的终端窗口"
    echo "  2. 输入 'claude' 启动"
    echo "  3. 首次运行会引导你完成登录"
    echo ""
    echo -e "${YELLOW}常用命令:${NC}"
    echo "  claude          - 启动 Claude Code"
    echo "  claude --help   - 查看帮助"
    echo "  claude --version- 查看版本"
    echo ""

    # 提示重启终端
    if [[ "$USE_NVM" =~ ^[Yy]$ ]] || [[ "$AUTH_CHOICE" == "2" ]]; then
        print_warn "请重启终端或运行 'source ~/.zshrc' (或 ~/.bashrc) 使配置生效"
    fi
}

# 执行主程序
main
