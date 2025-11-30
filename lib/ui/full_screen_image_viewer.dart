import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:autonitor/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

class FullScreenImageViewer extends StatefulWidget {
  final ImageProvider imageProvider;
  final String heroTag;
  final String imageUrl;
  final String localFilePath;

  const FullScreenImageViewer({
    super.key,
    required this.imageProvider,
    required this.heroTag,
    required this.imageUrl,
    required this.localFilePath,
  });

  static void show(
    BuildContext context, {
    required ImageProvider imageProvider,
    required String heroTag,
    required String imageUrl,
    required String localFilePath,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImageViewer(
          imageProvider: imageProvider,
          heroTag: heroTag,
          imageUrl: imageUrl,
          localFilePath: localFilePath,
        ),
      ),
    );
  }

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  Offset _offset = Offset.zero;
  bool _isInitialScale = true;
  int _pointerCount = 0;
  bool _isSaving = false;

  Future<({Uint8List bytes, String extension})> _getImageData() async {
    final provider = widget.imageProvider;

    // 1. 如果是本地文件，直接读取原始文件字节 (最原汁原味)
    if (provider is FileImage) {
      final bytes = await provider.file.readAsBytes();
      final ext = p.extension(provider.file.path).replaceAll('.', '');
      return (bytes: bytes, extension: ext.isEmpty ? 'png' : ext);
    }

    // 2. 如果是内存图片，直接使用原始字节
    if (provider is MemoryImage) {
      return (bytes: provider.bytes, extension: 'png');
    }

    // 3. 如果是网络图片或其他，且不能发起网络请求
    // 只能从渲染引擎中提取已解码的图像数据并转为 PNG
    // 这不是屏幕截图(RepaintBoundary)，而是直接提取图片对象的像素数据
    final Completer<ui.Image> completer = Completer<ui.Image>();
    final ImageStream stream = provider.resolve(ImageConfiguration.empty);

    final listener = ImageStreamListener((ImageInfo info, bool _) {
      if (!completer.isCompleted) {
        completer.complete(info.image);
      }
    });

    stream.addListener(listener);
    final ui.Image image = await completer.future;
    stream.removeListener(listener);

    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return (bytes: byteData!.buffer.asUint8List(), extension: 'png');
  }

  Future<void> _saveImage() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      // 获取图片 bytes
      Uint8List bytes;
      String fileName;

      // 优先使用本地文件
      if (widget.localFilePath.isNotEmpty) {
        final file = File(widget.localFilePath);

        bytes = await file.readAsBytes();
        fileName = p.basename(widget.localFilePath);
      } else {
        // 网络图片或其他 ImageProvider
        final data = await _getImageData();
        bytes = data.bytes;
        fileName =
            'image_${DateTime.now().millisecondsSinceEpoch}.${data.extension}';
      }

      // 调用 FilePicker saveFile，全平台统一
      final outputFile = await FilePicker.platform.saveFile(
        fileName: fileName,
        type: FileType.image,
        bytes: bytes, // 必须提供
      );

      if (outputFile != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.image_saved,
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.save_error}$e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(102),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 40),
              enabled: !_isSaving,
              onSelected: (value) {
                if (value == 'save') {
                  _saveImage();
                }
                if (value == 'open_in_browser') {
                  launchUrl(Uri.parse(widget.imageUrl));
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(102),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.more_vert, color: Colors.white),
                ),
              ),
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'open_in_browser',
                  child: Row(
                    children: [
                      Icon(Icons.open_in_browser, size: 20),
                      SizedBox(width: 8),
                      Text(l10n.open_in_browser),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'save',
                  child: Row(
                    children: [
                      Icon(Icons.save_alt, size: 20),
                      SizedBox(width: 8),
                      Text(l10n.save),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Listener(
        onPointerDown: (_) => setState(() => _pointerCount++),
        onPointerUp: (_) {
          setState(() => _pointerCount--);
          if (_pointerCount == 0) {
            if (_isInitialScale && _offset.dy.abs() > 150) {
              Navigator.pop(context);
            } else {
              setState(() {
                _offset = Offset.zero;
              });
            }
          }
        },
        onPointerCancel: (_) {
          setState(() => _pointerCount--);
          if (_pointerCount == 0) {
            setState(() => _offset = Offset.zero);
          }
        },
        onPointerMove: (event) {
          if (_pointerCount == 1 && _isInitialScale) {
            setState(() {
              _offset += Offset(0, event.delta.dy);
            });
          }
        },
        child: Transform.translate(
          offset: _offset,
          child: Center(
            child: PhotoView(
              imageProvider: widget.imageProvider,
              heroAttributes: PhotoViewHeroAttributes(tag: widget.heroTag),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2.5,
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              scaleStateChangedCallback: (state) {
                setState(() {
                  _isInitialScale = state == PhotoViewScaleState.initial;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
