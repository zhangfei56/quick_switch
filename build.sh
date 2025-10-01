#!/bin/bash

# Quick Switch 构建脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目配置
PROJECT_NAME="QuickSwitch"
SCHEME_NAME="QuickSwitch"
CONFIGURATION="Debug"
BUILD_DIR="build"

# 打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 检查 Xcode 是否安装
check_xcode() {
    if ! command -v xcodebuild &> /dev/null; then
        print_message $RED "错误: 未找到 Xcode 或 xcodebuild 命令"
        print_message $YELLOW "请确保已安装 Xcode 并配置了命令行工具"
        exit 1
    fi
}

# 清理构建目录
clean_build() {
    print_message $BLUE "清理构建目录..."
    rm -rf $BUILD_DIR
    xcodebuild clean -project $PROJECT_NAME.xcodeproj -scheme $SCHEME_NAME
}

# 构建项目
build_project() {
    print_message $BLUE "构建项目..."
    xcodebuild build \
        -project $PROJECT_NAME.xcodeproj \
        -scheme $SCHEME_NAME \
        -configuration $CONFIGURATION \
        -derivedDataPath $BUILD_DIR
}

# 运行测试
run_tests() {
    print_message $BLUE "运行测试..."
    xcodebuild test \
        -project $PROJECT_NAME.xcodeproj \
        -scheme $SCHEME_NAME \
        -configuration $CONFIGURATION \
        -derivedDataPath $BUILD_DIR
}

# 代码分析
analyze_code() {
    print_message $BLUE "进行代码分析..."
    xcodebuild analyze \
        -project $PROJECT_NAME.xcodeproj \
        -scheme $SCHEME_NAME \
        -configuration $CONFIGURATION \
        -derivedDataPath $BUILD_DIR
}

# 显示帮助信息
show_help() {
    echo "Quick Switch 构建脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  build     构建项目 (默认)"
    echo "  clean     清理构建目录"
    echo "  test      运行测试"
    echo "  analyze   代码分析"
    echo "  all       执行所有操作 (清理、构建、测试、分析)"
    echo "  help      显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 build"
    echo "  $0 clean"
    echo "  $0 all"
}

# 主函数
main() {
    local action=${1:-build}
    
    print_message $GREEN "Quick Switch 构建脚本"
    print_message $GREEN "===================="
    
    check_xcode
    
    case $action in
        "build")
            build_project
            print_message $GREEN "构建完成!"
            ;;
        "clean")
            clean_build
            print_message $GREEN "清理完成!"
            ;;
        "test")
            build_project
            run_tests
            print_message $GREEN "测试完成!"
            ;;
        "analyze")
            build_project
            analyze_code
            print_message $GREEN "代码分析完成!"
            ;;
        "all")
            clean_build
            build_project
            run_tests
            analyze_code
            print_message $GREEN "所有操作完成!"
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_message $RED "错误: 未知选项 '$action'"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
