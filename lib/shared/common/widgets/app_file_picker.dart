import 'dart:io';
import 'package:dineroo_mobile/shared/common/widgets/app_snackbar.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class AppFilePicker extends StatefulWidget {
  final void Function(File? file, String? fileName) onFileSelected;
  final String? label;
  final bool enabled;

  const AppFilePicker({
    super.key,
    required this.onFileSelected,
    this.label,
    this.enabled = true,
  });

  @override
  State<AppFilePicker> createState() => _AppFilePickerState();
}

class _AppFilePickerState extends State<AppFilePicker> {
  File? _selectedFile;
  String? _fileName;

  static const double _fileIconSize = 80;
  static const double _fileNameWidth = 200;

  final List<String> allowedExtensions = ['png', 'pdf', 'jpg', 'jpeg'];
  final double maxFileSizeInMB = 10;

  Future<void> _pickFile() async {
    if (!widget.enabled) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final name = result.files.single.name;

      final ext = name.split('.').last.toLowerCase();
      if (!allowedExtensions.contains(ext)) {
        _showError("Type de fichier non autorisé ($ext).");
        return;
      }

      final file = File(path);
      final fileSizeInMB = await file.length() / (1024 * 1024);

      if (fileSizeInMB > maxFileSizeInMB) {
        _showError("Fichier trop volumineux (max $maxFileSizeInMB Mo).");
        return;
      }

      setState(() {
        _selectedFile = file;
        _fileName = name;
      });

      widget.onFileSelected(file, name);
    }
  }

  void _removeFile() {
    if (!widget.enabled) return;

    setState(() {
      _selectedFile = null;
      _fileName = null;
    });

    widget.onFileSelected(null, null);
  }

  void _showError(String message) {
    AppSnackbar.error(context, message);
  }

  bool get isImage {
    if (_fileName == null) return false;
    final lower = _fileName!.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive BOX: 85% screen width, max 320px
    double boxSize = screenWidth * 0.85;
    if (boxSize > 320) boxSize = 320;

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null && widget.label!.isNotEmpty) ...[
            Text(
              widget.label!.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontFamily: 'Sen',
                color: Color(0xFF32343E),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Center(
            child: GestureDetector(
              onTap: widget.enabled && _selectedFile == null ? _pickFile : null,
              child: DottedBorder(
                color: const Color(0xFFF2F6FF),
                borderType: BorderType.RRect,
                radius: const Radius.circular(8),
                dashPattern: const [6, 4],
                strokeWidth: 1,
                child: Container(
                  width: boxSize,
                  height: boxSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      _selectedFile == null
                          ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/app_add_file.png',
                                width: 50,
                                height: 50,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Ajouter",
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "${allowedExtensions.join(', ')} (max ${maxFileSizeInMB.toStringAsFixed(0)} Mo)",
                                style: TextStyle(color: Colors.grey.shade600),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                          : Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child:
                                    isImage
                                        ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: Image.file(
                                            _selectedFile!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                        )
                                        : Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.picture_as_pdf,
                                                size: _fileIconSize,
                                                color: Colors.red,
                                              ),
                                              const SizedBox(height: 8),
                                              SizedBox(
                                                width: _fileNameWidth,
                                                child: Text(
                                                  _fileName ??
                                                      "Fichier sélectionné",
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 2,
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                              ),
                              if (widget.enabled)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: InkWell(
                                    onTap: _removeFile,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black54,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
