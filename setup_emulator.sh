#!/bin/bash
# Android模拟器网络配置脚本
# 用途：设置端口转发，让模拟器通过localhost访问宿主机服务

ADB_PATH="/Users/lynn/SoftWare/Android/sdk/platform-tools/adb"

echo "📱 检查Android模拟器连接状态..."
$ADB_PATH devices

echo ""
echo "🔧 配置端口转发（模拟器 → 宿主机）..."
$ADB_PATH reverse tcp:8000 tcp:8000

if [ $? -eq 0 ]; then
    echo "✅ 端口转发配置成功！"
    echo ""
    echo "📋 当前配置："
    echo "   - 模拟器访问: http://localhost:8000"
    echo "   - 实际转发到: 宿主机 localhost:8000"
    echo ""
    echo "💡 提示："
    echo "   1. 确保后端服务运行在宿主机 8000 端口"
    echo "   2. Flutter应用配置为: http://localhost:8000"
    echo "   3. 模拟器重启后需要重新执行此脚本"
else
    echo "❌ 端口转发配置失败，请检查："
    echo "   1. Android模拟器是否正在运行"
    echo "   2. adb路径是否正确"
fi

echo ""
echo "🔍 查看当前端口转发列表:"
$ADB_PATH reverse --list

