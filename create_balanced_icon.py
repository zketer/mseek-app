#!/usr/bin/env python3
"""
创建平衡的应用图标
既保证粉色部分足够大，又保留适当白边
"""

from PIL import Image
import os

def create_balanced_icon(source_path, output_path, content_ratio=0.90):
    """
    创建平衡的图标：粉色内容大，同时保留白边
    
    参数:
        source_path: 源图片路径
        output_path: 输出图片路径  
        content_ratio: 内容占比（默认0.90，即90%）
    """
    print(f"📷 处理: {source_path}")
    
    # 打开原始图标
    original = Image.open(source_path)
    size = 1024  # 标准尺寸
    
    # 如果原图不是1024x1024，先调整
    if original.size != (size, size):
        original = original.resize((size, size), Image.Resampling.LANCZOS)
    
    # 创建白色背景
    new_img = Image.new('RGBA', (size, size), (255, 255, 255, 255))
    
    # 计算内容尺寸（保留在安全区域）
    content_size = int(size * content_ratio)
    margin = (size - content_size) // 2
    
    # 将原图缩小到指定比例
    resized_original = original.resize((content_size, content_size), Image.Resampling.LANCZOS)
    
    # 居中粘贴
    new_img.paste(resized_original, (margin, margin), resized_original if resized_original.mode == 'RGBA' else None)
    
    # 保存
    new_img.save(output_path, 'PNG', quality=100, optimize=True)
    print(f"   ✅ 内容占比: {int(content_ratio * 100)}%")
    print(f"   ✅ 白边宽度: {margin}px (每边{int((1-content_ratio)*100/2)}%)")
    print(f"   ✅ 已保存: {output_path}")

def main():
    """主函数"""
    print("🎨 创建平衡的应用图标（粉色大+有白边）...")
    print()
    
    source_file = "assets/icons/big_copy.png"
    icons_dir = "assets/icons"
    
    # 检查源文件
    if not os.path.exists(source_file):
        print(f"❌ 源文件不存在: {source_file}")
        return
    
    # 备份
    print("💾 备份当前图标...")
    for filename in ['app_icon.png', 'app_icon_foreground.png']:
        current_path = f"{icons_dir}/{filename}"
        if os.path.exists(current_path):
            backup_path = f"{icons_dir}/{filename}.backup"
            img = Image.open(current_path)
            img.save(backup_path, 'PNG')
            print(f"   ✅ 已备份: {backup_path}")
    
    print()
    
    # 生成主图标（iOS，55%匹配开屏页）
    print("📱 生成主应用图标（iOS）...")
    create_balanced_icon(
        source_file,
        f"{icons_dir}/app_icon.png",
        content_ratio=0.55  # 55%，匹配开屏页比例（64/120≈53%）
    )
    print()
    
    # 生成Android自适应图标前景（55%，统一比例）
    print("🤖 生成Android自适应图标前景...")
    create_balanced_icon(
        source_file,
        f"{icons_dir}/app_icon_foreground.png",
        content_ratio=0.55  # 55%，与开屏页一致
    )
    print()
    
    print("🎉 图标生成完成！")
    print()
    print("📝 下一步操作：")
    print("1. 运行: dart run flutter_launcher_icons")
    print("2. 重新构建应用查看效果")
    print()
    print("💡 匹配开屏页（55%比例）：")
    print("   ✅ iOS: 粉色内容占55%，留45%白边")
    print("   ✅ Android: 粉色内容占55%，留45%白边")
    print("   ✅ 与开屏页Logo保持一致（64/120≈53%）")
    print("   ✅ 大量留白，简洁优雅的视觉风格")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"❌ 生成图标时出错: {e}")
        import traceback
        traceback.print_exc()

