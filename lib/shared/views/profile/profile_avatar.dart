import 'dart:io';
import 'package:dineroo_mobile/shared/common/config/logger.dart';
import 'package:dineroo_mobile/shared/common/helpers/url_helper.dart';
import 'package:dineroo_mobile/shared/common/network/dio_client.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_loader.dart';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';
import 'package:dineroo_mobile/shared/enums/file_type.dart';
import 'package:dineroo_mobile/shared/view_models/user/user_view_model.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfileAvatar extends StatefulWidget {
  final File? initialImage;
  final String userId;

  const ProfileAvatar({super.key, required this.userId, this.initialImage});

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  final ImagePicker _picker = ImagePicker();

  File? _image;
  int _cacheBuster = DateTime.now().millisecondsSinceEpoch;
  bool _isUploading = false;
  bool _retriedAuthHeadersAfterUnauthorized = false;
  Map<String, String>? _authHeaders;

  Future<void> _pickAndUploadImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final image = File(pickedFile.path);
    setState(() => _isUploading = true);

    try {
      if (!mounted) return;
      final userVM = context.read<UserViewModel>();
      await userVM.uploadUserFile(
        userId: widget.userId,
        file: image,
        fileType: FileType.profilePhoto.value,
      );

      if (!mounted) return;
      setState(() {
        _image = image;
        _cacheBuster = DateTime.now().millisecondsSinceEpoch;
        _isUploading = false;
      });

      AppSnackbar.success(
        context,
        'Photo de profil mise à jour.',
        bottomMargin: 100,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      AppSnackbar.error(
        context,
        e.toString().contains('timeout')
            ? 'Temps d’attente dépassé. Réessayez.'
            : 'Une erreur est survenue. Veuillez réessayer.',
        bottomMargin: 100,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _image = widget.initialImage;
    _loadAuthHeaders();
  }

  Future<void> _loadAuthHeaders() async {
    var token = AuthInterceptor.cachedAccessToken;
    if (token == null || token.isEmpty) {
      try {
        final authBox = await Hive.openBox('auth');
        token = authBox.get('accessToken') as String?;
      } catch (error, stackTrace) {
        logger.d(
          '[ProfileAvatar] Auth box unavailable while loading profile photo headers.',
          error: error,
          stackTrace: stackTrace,
        );
        token = null;
      }
    }

    if (!mounted || token == null || token.isEmpty) return;
    setState(() {
      _authHeaders = {'Authorization': 'Bearer $token'};
      _cacheBuster = DateTime.now().millisecondsSinceEpoch;
    });
  }

  void _retryAuthHeadersAfterUnauthorized() {
    if (_retriedAuthHeadersAfterUnauthorized || _authHeaders != null) return;
    _retriedAuthHeadersAfterUnauthorized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadAuthHeaders();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget avatarImage;

    if (_isUploading) {
      avatarImage = const CircleAvatar(
        radius: 60,
        backgroundColor: Color(0xFFFFE0D2),
        child: AppLoader(),
      );
    } else if (_image != null) {
      avatarImage = CircleAvatar(
        radius: 60,
        backgroundColor: const Color(0xFFFFE0D2),
        backgroundImage: FileImage(_image!),
      );
    } else {
      final imageUrl = '${getProfilePhotoUrl(widget.userId)}&t=$_cacheBuster';
      avatarImage = CircleAvatar(
        radius: 60,
        backgroundColor: const Color(0xFFFFE0D2),
        child: ClipOval(
          child: Image.network(
            imageUrl,
            headers: _authHeaders,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              if (error is NetworkImageLoadException &&
                  (error.statusCode == HttpStatus.notFound ||
                      error.statusCode == HttpStatus.unauthorized ||
                      error.statusCode == HttpStatus.forbidden)) {
                if (error.statusCode != HttpStatus.notFound) {
                  _retryAuthHeadersAfterUnauthorized();
                }
                return const Icon(Icons.person, size: 60, color: Colors.white);
              }

              logger.w(
                '[ProfileAvatar] Failed to load profile photo: $imageUrl',
                error: error,
                stackTrace: stackTrace,
              );
              return const Icon(Icons.person, size: 60, color: Colors.white);
            },
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _pickAndUploadImage,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          avatarImage,
          Container(
            decoration: const BoxDecoration(
              color: Colors.deepOrange,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(6),
            child: const Icon(Icons.edit, size: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
