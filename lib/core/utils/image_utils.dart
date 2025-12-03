// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'permission_helper.dart';

/// 图片处理工具类
/// 
/// 提供统一的图片选择、压缩、处理等方法，包括：
/// - 从相机拍照
/// - 从相册选择
/// - 多图选择
/// - 图片压缩
/// - 图片缓存管理
/// 
/// 使用示例：
/// ```dart
/// // 拍照
/// final file = await ImageUtils.takePhoto(context);
/// 
/// // 从相册选择
/// final file = await ImageUtils.pickFromGallery(context);
/// 
/// // 显示选择对话框
/// final file = await ImageUtils.showImageSourceDialog(context);
/// 
/// // 多图选择
/// final files = await ImageUtils.pickMultiple(context, maxImages: 9);
/// ```
class ImageUtils {
  static final ImagePicker _picker = ImagePicker();

  /// 从相机拍照
  /// 
  /// [context] BuildContext
  /// [imageQuality] 图片质量（0-100），默认85
  /// [maxWidth] 最大宽度
  /// [maxHeight] 最大高度
  /// 
  /// 返回：图片文件，null表示取消或失败
  static Future<File?> takePhoto(
    BuildContext context, {
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    // 检查相机权限
    final hasPermission = await PermissionHelper.requestCamera(context);
    if (!hasPermission) {
      return null;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      debugPrint('📷 拍照失败: $e');
      return null;
    }
  }

  /// 从相册选择图片
  /// 
  /// [context] BuildContext
  /// [imageQuality] 图片质量（0-100），默认85
  /// [maxWidth] 最大宽度
  /// [maxHeight] 最大高度
  /// 
  /// 返回：图片文件，null表示取消或失败
  static Future<File?> pickFromGallery(
    BuildContext context, {
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    // 检查相册权限
    final hasPermission = await PermissionHelper.requestPhotos(context);
    if (!hasPermission) {
      return null;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      debugPrint('📷 选择图片失败: $e');
      return null;
    }
  }

  /// 选择多张图片
  /// 
  /// [context] BuildContext
  /// [maxImages] 最多选择张数，默认9张
  /// [imageQuality] 图片质量（0-100），默认85
  /// [maxWidth] 最大宽度
  /// [maxHeight] 最大高度
  /// 
  /// 返回：图片文件列表
  static Future<List<File>> pickMultiple(
    BuildContext context, {
    int maxImages = 9,
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    // 检查相册权限
    final hasPermission = await PermissionHelper.requestPhotos(context);
    if (!hasPermission) {
      return [];
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      // 限制数量
      final limitedImages = images.take(maxImages).toList();
      
      return limitedImages.map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      debugPrint('📷 选择多张图片失败: $e');
      return [];
    }
  }

  /// 显示图片来源选择对话框
  /// 
  /// [context] BuildContext
  /// [imageQuality] 图片质量（0-100），默认85
  /// [maxWidth] 最大宽度
  /// [maxHeight] 最大高度
  /// 
  /// 返回：图片文件，null表示取消或失败
  static Future<File?> showImageSourceDialog(
    BuildContext context, {
    int imageQuality = 85,
    double? maxWidth,
    double? maxHeight,
  }) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('取消'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );

    if (source == null) return null;

    if (source == ImageSource.camera) {
      return takePhoto(
        context,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
    } else {
      return pickFromGallery(
        context,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
    }
  }

  /// 获取图片文件大小（MB）
  /// 
  /// [file] 图片文件
  /// 
  /// 返回：文件大小（MB）
  static Future<double> getImageSize(File file) async {
    final bytes = await file.length();
    return bytes / (1024 * 1024);
  }

  /// 获取图片的宽高
  /// 
  /// [file] 图片文件
  /// 
  /// 返回：Size(width, height)
  static Future<Size> getImageDimensions(File file) async {
    final bytes = await file.readAsBytes();
    final image = await decodeImageFromList(bytes);
    return Size(image.width.toDouble(), image.height.toDouble());
  }

  /// 保存图片到临时目录
  /// 
  /// [file] 原始图片文件
  /// [filename] 文件名，默认使用时间戳
  /// 
  /// 返回：保存后的文件
  static Future<File> saveToTempDirectory(
    File file, {
    String? filename,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final name = filename ?? '${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
    final targetPath = path.join(tempDir.path, name);
    
    return file.copy(targetPath);
  }

  /// 保存图片到应用目录
  /// 
  /// [file] 原始图片文件
  /// [filename] 文件名，默认使用时间戳
  /// 
  /// 返回：保存后的文件
  static Future<File> saveToAppDirectory(
    File file, {
    String? filename,
  }) async {
    final appDir = await getApplicationDocumentsDirectory();
    final name = filename ?? '${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
    final targetPath = path.join(appDir.path, 'images', name);
    
    // 确保目录存在
    final directory = Directory(path.dirname(targetPath));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    return file.copy(targetPath);
  }

  /// 删除图片文件
  /// 
  /// [file] 要删除的文件
  static Future<void> deleteImage(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('🗑️ 删除图片失败: $e');
    }
  }

  /// 批量删除图片文件
  /// 
  /// [files] 要删除的文件列表
  static Future<void> deleteImages(List<File> files) async {
    for (final file in files) {
      await deleteImage(file);
    }
  }

  /// 清理临时图片缓存
  /// 
  /// 删除临时目录中的所有图片文件
  static Future<void> clearTempImages() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final imageDir = Directory(path.join(tempDir.path));
      
      if (await imageDir.exists()) {
        final files = imageDir.listSync();
        for (final file in files) {
          if (file is File) {
            final ext = path.extension(file.path).toLowerCase();
            if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext)) {
              await file.delete();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('🗑️ 清理临时图片失败: $e');
    }
  }

  /// 检查文件是否是图片
  /// 
  /// [file] 要检查的文件
  /// 
  /// 返回：true=是图片，false=不是图片
  static bool isImageFile(File file) {
    final ext = path.extension(file.path).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].contains(ext);
  }

  /// 验证图片文件大小
  /// 
  /// [file] 图片文件
  /// [maxSizeMB] 最大文件大小（MB），默认10MB
  /// 
  /// 返回：true=大小合法，false=超过限制
  static Future<bool> validateImageSize(
    File file, {
    double maxSizeMB = 10.0,
  }) async {
    final sizeMB = await getImageSize(file);
    return sizeMB <= maxSizeMB;
  }

  /// 验证图片尺寸
  /// 
  /// [file] 图片文件
  /// [maxWidth] 最大宽度
  /// [maxHeight] 最大高度
  /// 
  /// 返回：true=尺寸合法，false=超过限制
  static Future<bool> validateImageDimensions(
    File file, {
    double? maxWidth,
    double? maxHeight,
  }) async {
    final size = await getImageDimensions(file);
    
    if (maxWidth != null && size.width > maxWidth) {
      return false;
    }
    
    if (maxHeight != null && size.height > maxHeight) {
      return false;
    }
    
    return true;
  }

  /// 生成唯一的图片文件名
  /// 
  /// [prefix] 文件名前缀，默认'IMG'
  /// [extension] 文件扩展名，默认'.jpg'
  /// 
  /// 返回：唯一文件名
  static String generateUniqueFilename({
    String prefix = 'IMG',
    String extension = '.jpg',
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_$timestamp$extension';
  }

  /// 将图片文件编码为Base64字符串
  ///
  /// [file] 图片文件
  ///
  /// 返回：Base64编码的字符串，包含data:image前缀，null表示编码失败
  static Future<String?> encodeImageToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);

      // 获取文件扩展名来确定MIME类型
      final extension = path.extension(file.path).toLowerCase();
      String mimeType = 'image/jpeg'; // 默认JPEG

      switch (extension) {
        case '.png':
          mimeType = 'image/png';
          break;
        case '.gif':
          mimeType = 'image/gif';
          break;
        case '.webp':
          mimeType = 'image/webp';
          break;
        case '.bmp':
          mimeType = 'image/bmp';
          break;
        default:
          mimeType = 'image/jpeg';
      }

      return 'data:$mimeType;base64,$base64String';
    } catch (e) {
      debugPrint('🖼️ 图片转Base64失败: $e');
      return null;
    }
  }

  /// 解码Base64字符串为图片字节数据
  /// 
  /// [base64String] Base64编码的图片字符串
  /// 
  /// 返回：图片字节数据，null表示解码失败
  static Uint8List? decodeBase64Image(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      debugPrint('🖼️ Base64图片解码失败: $e');
      return null;
    }
  }

  /// 构建Base64图片Widget
  /// 
  /// [base64String] Base64编码的图片字符串
  /// [fit] 图片填充方式，默认BoxFit.contain
  /// [width] 图片宽度
  /// [height] 图片高度
  /// [errorWidget] 解码失败时显示的Widget
  /// 
  /// 返回：图片Widget
  static Widget buildBase64Image(
    String base64String, {
    BoxFit fit = BoxFit.contain,
    double? width,
    double? height,
    Widget? errorWidget,
  }) {
    final imageBytes = decodeBase64Image(base64String);
    
    if (imageBytes == null) {
      return errorWidget ?? const Icon(Icons.error, color: Colors.red);
    }

    return Image.memory(
      imageBytes,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? const Icon(Icons.broken_image, color: Colors.grey);
      },
    );
  }
}

