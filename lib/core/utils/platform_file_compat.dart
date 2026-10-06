import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Extension methods to maintain backwards compatibility with file_picker 8.x properties
/// across the kt_docs codebase while on file_picker 13.x.
extension PlatformFileCompat on PlatformFile {
  /// The file size in bytes, synchronous if available, or fallback to 0.
  int get size => lengthSync() ?? 0;
}

/// An in-memory cache to store loaded bytes for [PlatformFile] instances
/// synchronously accessible where UI / widgets need fast synchronous reads.
final Expando<Uint8List> _platformFileBytesCache = Expando<Uint8List>('platformFileBytes');

extension PlatformFileBytesExtension on PlatformFile {
  /// Gets cached bytes synchronously, or null if not yet cached.
  Uint8List? get bytes => _platformFileBytesCache[this];

  /// Sets cached bytes for this PlatformFile instance.
  set bytes(Uint8List? data) {
    if (data != null) {
      _platformFileBytesCache[this] = data;
    }
  }

  /// Ensures bytes are loaded and returns them, caching them on the instance.
  Future<Uint8List> loadBytes() async {
    final cached = _platformFileBytesCache[this];
    if (cached != null) return cached;
    final loaded = await readAsBytes();
    _platformFileBytesCache[this] = loaded;
    return loaded;
  }
}
