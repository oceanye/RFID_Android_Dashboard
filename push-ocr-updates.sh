#!/bin/bash

# Git Push Script for OCR功能更新
# 使用说明：当网络连接正常时运行此脚本推送所有更新

echo "🚀 准备推送OCR智能拍照功能更新到GitHub..."
echo ""

# 显示当前状态
echo "📊 检查当前git状态："
git status
echo ""

# 显示待推送的提交
echo "📝 待推送的提交列表："
git log --oneline origin/master..HEAD
echo ""

# 显示远程仓库
echo "🔗 远程仓库配置："
git remote -v
echo ""

# 推送到远程仓库
echo "🚀 开始推送..."
git push origin master

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 成功推送所有更新到GitHub！"
    echo ""
    echo "📸 本次更新包括："
    echo "  - 智能拍照OCR功能"
    echo "  - 双模式图像裁剪"
    echo "  - 应用稳定性修复"
    echo "  - 完整技术文档"
    echo ""
    echo "🎉 更新已发布！"
else
    echo ""
    echo "❌ 推送失败，可能原因："
    echo "  - 网络连接问题"
    echo "  - GitHub访问限制"
    echo "  - 认证信息过期"
    echo ""
    echo "🔧 解决方案："
    echo "  1. 检查网络连接"
    echo "  2. 配置代理或VPN"
    echo "  3. 更新Git凭据"
    echo "  4. 稍后重新运行此脚本"
fi