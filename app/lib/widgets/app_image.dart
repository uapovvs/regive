import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

final _decoded = <String, Uint8List>{};

// Фото хранятся либо как data URI (base64 в Firestore), либо как обычный URL.
Uint8List _bytesOf(String dataUri) => _decoded.putIfAbsent(
  dataUri,
  () => base64Decode(dataUri.substring(dataUri.indexOf(',') + 1)),
);

bool _isDataUri(String url) => url.startsWith('data:');

ImageProvider appImageProvider(String url) => _isDataUri(url)
    ? MemoryImage(_bytesOf(url))
    : CachedNetworkImageProvider(url);

class AppImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final int? cacheWidth;
  final Widget placeholder;

  const AppImage({
    super.key,
    required this.url,
    required this.placeholder,
    this.fit = BoxFit.cover,
    this.cacheWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return placeholder;
    if (_isDataUri(url)) {
      return Image.memory(
        _bytesOf(url),
        fit: fit,
        cacheWidth: cacheWidth,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      memCacheWidth: cacheWidth,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
    );
  }
}
