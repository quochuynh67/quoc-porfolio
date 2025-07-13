import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewer {
  ImageViewer(
      BuildContext context, {
        required List<String> images,
        int initialIndex = 0,
        bool isAsset = true,
      }) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black,
      barrierDismissible: true,
      barrierLabel: 'ImageViewer',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return _ImageViewerDialog(
          images: images,
          initialIndex: initialIndex,
          isAsset: isAsset,
        );
      },
    );
  }
}

class _ImageViewerDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final bool isAsset;

  const _ImageViewerDialog({
    Key? key,
    required this.images,
    required this.initialIndex,
    required this.isAsset,
  }) : super(key: key);

  @override
  State<_ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<_ImageViewerDialog> {
  late PageController _pageController;
  late int _currentIndex;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _nextImage() {
    if (_currentIndex < widget.images.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _previousImage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _nextImage();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _previousImage();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode..requestFocus(),
      onKey: _handleKey,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          alignment: Alignment.center,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                return Center(
                  child: Hero(
                    tag: 'IMAGEVIEW_$index',
                    child: PhotoView(
                      backgroundDecoration:
                      const BoxDecoration(color: Colors.black),
                      imageProvider: widget.isAsset
                          ? AssetImage(widget.images[index])
                          : NetworkImage(widget.images[index]) as ImageProvider,
                    ),
                  ),
                );
              },
            ),

            // ← Previous button
            Positioned(
              left: 16,
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios,
                    color: _currentIndex == 0
                        ? Colors.white38
                        : Colors.white),
                onPressed: _currentIndex == 0 ? null : _previousImage,
              ),
            ),

            // → Next button
            Positioned(
              right: 16,
              child: IconButton(
                icon: Icon(Icons.arrow_forward_ios,
                    color: _currentIndex == widget.images.length - 1
                        ? Colors.white38
                        : Colors.white),
                onPressed: _currentIndex == widget.images.length - 1
                    ? null
                    : _nextImage,
              ),
            ),

            // ✖ Close button
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),

            // 🔢 Image counter
            Positioned(
              bottom: 30,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.images.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}