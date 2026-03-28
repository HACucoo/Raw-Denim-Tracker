import 'dart:io';
import 'package:flutter/material.dart';

/// Displays a garment photo from a local file path.
///
/// • Decodes the image only at the required pixel size (cacheWidth/cacheHeight)
///   so full-resolution camera photos don't stall the UI thread.
/// • Fades in smoothly instead of popping in.
/// • Falls back to an icon placeholder when no photo is set.
class GarmentPhoto extends StatelessWidget {
  final String? photoPath;
  final double size;
  final double borderRadius;

  const GarmentPhoto({
    super.key,
    required this.photoPath,
    required this.size,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: photoPath != null
            ? Image.file(
                File(photoPath!),
                fit: BoxFit.cover,
                // Decode at 3× the logical size — sufficient for the densest
                // Android screens while being ~100× cheaper than full-res.
                // Only constrain width — height scales proportionally so the
                // aspect ratio is preserved before BoxFit.cover clips to square.
                cacheWidth: (size * 3).ceil(),
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) {
                    // Already in cache — show immediately with no animation.
                    return child;
                  }
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: frame == null
                        ? Container(
                            key: const ValueKey('placeholder'),
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.checkroom_outlined,
                                color: colorScheme.outline,
                                size: size * 0.45),
                          )
                        : SizedBox(key: const ValueKey('image'), child: child),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.broken_image_outlined,
                      color: colorScheme.outline, size: size * 0.45),
                ),
              )
            : Container(
                color: colorScheme.surfaceContainerHighest,
                child: Icon(Icons.checkroom_outlined,
                    color: colorScheme.outline, size: size * 0.45),
              ),
      ),
    );
  }
}
