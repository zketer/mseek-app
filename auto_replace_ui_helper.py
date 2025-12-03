#!/usr/bin/env python3
"""
自动替换SnackBar为UIHelper的脚本
"""

import os
import re
from pathlib import Path

# 项目路径
PROJECT_ROOT = "/Users/lynn/StudyStation/博物馆打卡项目/museum-management/MuseumSeek/web-frontend/mseek"
LIB_SCREENS = f"{PROJECT_ROOT}/lib/screens"

# 需要处理的文件列表（排除已处理的）
FILES_TO_PROCESS = [
    "core/search_screen.dart",
    "discovery/region/city_detail_screen.dart",
    "discovery/exhibition/exhibition_detail_screen.dart",
    "discovery/museum/museum_list_screen.dart",
    "discovery/museum/museum_detail_screen.dart",
    "profile/favorites_screen.dart",
    "profile/settings_screen.dart",
    "profile/about_screen.dart",
    "profile/feedback_screen.dart",
    "checkin/checkin_action_screen.dart",
    "checkin/draft_list_screen.dart",
    "checkin/checkin_screen.dart",
    "checkin/checkin_history_screen.dart",
    "legal/qualification_screen.dart",
]

def get_depth_to_core(file_path):
    """计算文件到lib目录的深度，用于确定import路径"""
    parts = file_path.split('/')
    # screens下的层级深度
    depth = len(parts) - 1
    return '../' * depth

def add_import_if_missing(content, file_path):
    """如果文件没有UIHelper import，则添加"""
    import_line = "import '" + get_depth_to_core(file_path) + "../core/utils/ui_helper.dart';"
    
    # 检查是否已有import
    if 'ui_helper.dart' in content:
        return content, False
    
    # 找到最后一个import的位置
    import_pattern = r"import\s+['\"].*?['\"];"
    matches = list(re.finditer(import_pattern, content))
    
    if matches:
        last_import = matches[-1]
        insert_pos = last_import.end()
        content = content[:insert_pos] + '\n' + import_line + content[insert_pos:]
        return content, True
    
    return content, False

def replace_snackbar_patterns(content):
    """替换各种SnackBar模式为UIHelper调用"""
    replaced_count = 0
    
    # 模式1: 成功提示 (绿色背景)
    pattern1 = r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\('([^']*)'\),\s*backgroundColor:\s*Colors\.green,?\s*\),?\s*\)"
    def replace1(match):
        nonlocal replaced_count
        replaced_count += 1
        return f"UIHelper.showSuccess(context, '{match.group(1)}')"
    content = re.sub(pattern1, replace1, content, flags=re.MULTILINE)
    
    # 模式2: 错误提示 (红色背景)
    pattern2 = r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\('([^']*)'\),\s*backgroundColor:\s*Colors\.red,?\s*\),?\s*\)"
    def replace2(match):
        nonlocal replaced_count
        replaced_count += 1
        return f"UIHelper.showError(context, '{match.group(1)}')"
    content = re.sub(pattern2, replace2, content, flags=re.MULTILINE)
    
    # 模式3: 警告提示 (橙色背景)
    pattern3 = r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*const\s+SnackBar\(\s*content:\s*Text\('([^']*)'\),\s*backgroundColor:\s*Colors\.orange,?\s*\),?\s*\)"
    def replace3(match):
        nonlocal replaced_count
        replaced_count += 1
        return f"UIHelper.showWarning(context, '{match.group(1)}')"
    content = re.sub(pattern3, replace3, content, flags=re.MULTILINE)
    
    # 模式4: 简单提示 (无背景色或const)
    pattern4 = r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*const\s+SnackBar\(\s*content:\s*Text\('([^']*)'\),?\s*\),?\s*\)"
    def replace4(match):
        nonlocal replaced_count
        replaced_count += 1
        return f"UIHelper.showInfo(context, '{match.group(1)}')"
    content = re.sub(pattern4, replace4, content, flags=re.MULTILINE)
    
    return content, replaced_count

def process_file(file_path):
    """处理单个文件"""
    full_path = os.path.join(LIB_SCREENS, file_path)
    
    if not os.path.exists(full_path):
        print(f"⚠️  文件不存在: {file_path}")
        return False, 0
    
    # 读取文件
    with open(full_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 检查是否包含ScaffoldMessenger
    if 'ScaffoldMessenger.of(context).showSnackBar' not in content:
        print(f"✓ 跳过（无需处理）: {file_path}")
        return False, 0
    
    print(f"📝 处理文件: {file_path}")
    
    # 添加import
    content, import_added = add_import_if_missing(content, file_path)
    if import_added:
        print(f"   ✓ 添加了UIHelper import")
    
    # 替换SnackBar
    content, replaced = replace_snackbar_patterns(content)
    
    if replaced > 0:
        # 备份原文件
        backup_path = full_path + '.bak'
        with open(backup_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        # 写入新内容
        with open(full_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"   ✓ 替换了 {replaced} 处SnackBar")
        return True, replaced
    else:
        print(f"   ⚠️  未找到可自动替换的模式")
        return False, 0

def main():
    """主函数"""
    print("🔄 开始自动替换SnackBar为UIHelper...")
    print()
    
    total_files = 0
    total_replaced = 0
    
    for file_path in FILES_TO_PROCESS:
        success, count = process_file(file_path)
        if success:
            total_files += 1
            total_replaced += count
    
    print()
    print("✅ 自动替换完成！")
    print(f"   处理文件数: {total_files}")
    print(f"   替换总数: {total_replaced}")
    print()
    print("⚠️  注意：")
    print("   1. 部分复杂的SnackBar可能需要手动替换")
    print("   2. 原文件已备份为 .bak 文件")
    print("   3. 请运行 flutter analyze 检查是否有错误")

if __name__ == '__main__':
    main()

