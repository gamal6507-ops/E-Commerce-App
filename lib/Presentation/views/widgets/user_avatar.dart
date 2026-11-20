import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_commerce_app/core/localization/app_localizations.dart';
import 'package:e_commerce_app/core/utils/app_colors.dart';
import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';

class UserAvatar extends StatelessWidget {
  final String username;
  final String photoUrl;
  final double radius;
  final bool showEditBadge;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    required this.username,
    required this.photoUrl,
    this.radius = 32,
    this.showEditBadge = false,
    this.onTap,
  });

  Uint8List? _decodeBase64(String url) {
    if (!url.startsWith('data:image')) return null;
    final commaIndex = url.indexOf(',');
    if (commaIndex == -1 || commaIndex == url.length - 1) return null;
    try {
      return base64Decode(url.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }

  Widget _buildInitialAvatar() {
    final trimmed = username.trim();
    final initial = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : 'U';
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.accentColor, Color(0xFFD9483B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.white1,
          fontSize: radius * 0.78,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildAvatarImage() {
    final trimmed = photoUrl.trim();
    if (trimmed.isEmpty) {
      return _buildInitialAvatar();
    }

    final memoryBytes = _decodeBase64(trimmed);
    if (memoryBytes != null) {
      return ClipOval(
        child: Image.memory(
          memoryBytes,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialAvatar(),
        ),
      );
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: trimmed,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (_, __) => _buildInitialAvatar(),
          errorWidget: (_, __, ___) => _buildInitialAvatar(),
        ),
      );
    }

    return _buildInitialAvatar();
  }

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.white1.withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
          child: _buildAvatarImage(),
        ),
        if (showEditBadge)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 14,
                color: AppColors.primaryColor,
              ),
            ),
          ),
      ],
    );

    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}

Future<void> showProfilePhotoPickerSheet(
  BuildContext context, {
  required String currentPhotoUrl,
  required ValueChanged<String> onPhotoSelected,
}) async {
  final picker = ImagePicker();

  Future<void> pickFrom(ImageSource source, BuildContext sheetContext) async {
    Navigator.of(sheetContext).pop();
    try {
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 360,
        maxHeight: 360,
        imageQuality: 68,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final encoded = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      if (encoded.length > 140000) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Selected image is too large, please choose another.',
              ),
            ),
          );
        }
        return;
      }
      onPhotoSelected(encoded);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not pick image: $e')));
      }
    }
  }

  Future<void> enterImageUrl(BuildContext sheetContext) async {
    Navigator.of(sheetContext).pop();
    final ar = context.isArabic;
    final urlController = TextEditingController(
      text: currentPhotoUrl.startsWith('https://') ? currentPhotoUrl : '',
    );
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(ar ? 'رابط صورة الحساب' : 'Profile Image URL'),
          content: TextField(
            controller: urlController,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: ar ? 'رابط الصورة (HTTPS)' : 'Image URL (HTTPS)',
              hintText: 'https://example.com/avatar.jpg',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.tr('cancel')),
            ),
            TextButton(
              onPressed: () {
                final trimmed = urlController.text.trim();
                if (trimmed.isEmpty || !trimmed.startsWith('https://')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ar
                            ? 'أدخل رابط صورة يبدأ بـ https://'
                            : 'Enter a valid https:// image URL',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop();
                onPhotoSelected(trimmed);
              },
              child: Text(context.tr('save')),
            ),
          ],
        );
      },
    );
    urlController.dispose();
  }

  final isDark = Theme.of(context).brightness == Brightness.dark;
  final ar = context.isArabic;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: isDark ? AppColors.surfaceCardDark : AppColors.surfaceCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                ar ? 'صورة الملف الشخصي' : 'Profile Photo',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primaryColor,
                ),
                title: Text(ar ? 'اختر من المعرض' : 'Choose from Gallery'),
                onTap: () => pickFrom(ImageSource.gallery, sheetContext),
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.primaryColor,
                ),
                title: Text(ar ? 'التقاط صورة' : 'Take Photo'),
                onTap: () => pickFrom(ImageSource.camera, sheetContext),
              ),
              ListTile(
                leading: const Icon(
                  Icons.link_rounded,
                  color: AppColors.primaryColor,
                ),
                title: Text(ar ? 'استخدام رابط صورة' : 'Use Image URL'),
                onTap: () => enterImageUrl(sheetContext),
              ),
              if (currentPhotoUrl.isNotEmpty)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.red,
                  ),
                  title: Text(
                    ar ? 'إزالة الصورة الحالية' : 'Remove Current Photo',
                    style: const TextStyle(color: AppColors.red),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onPhotoSelected('');
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}
