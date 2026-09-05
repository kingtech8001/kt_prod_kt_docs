import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
import 'package:mime/mime.dart';

typedef ProgressCallback = void Function(double progress, String message);

class CompressionResult {
  final Uint8List originalBytes;
  final Uint8List compressedBytes;
  final int originalSize;
  final int compressedSize;
  final String fileName;
  final String compressedFileName;
  final String mimeType;
  final int quality;
  final bool isPdf;
  final String? pdfLevel;
  final String engine;
  final double? apiSavedPercent;
  final int? pageCount;
  final int? savedBytes;
  final String? level;
  final int? dpi;
  final int? maxDimension;
  final int? targetSizeKb;
  final bool? isGrayscale;
  final bool? isMetadataStripped;

  CompressionResult({
    required this.originalBytes,
    required this.compressedBytes,
    required this.originalSize,
    required this.compressedSize,
    required this.fileName,
    required this.compressedFileName,
    required this.mimeType,
    required this.quality,
    this.isPdf = false,
    this.pdfLevel,
    this.engine = 'King Technology Media Engine',
    this.apiSavedPercent,
    this.pageCount,
    this.savedBytes,
    this.level,
    this.dpi,
    this.maxDimension,
    this.targetSizeKb,
    this.isGrayscale,
    this.isMetadataStripped,
  });

  double get savingsPercent {
    if (apiSavedPercent != null && apiSavedPercent! > 0) {
      return apiSavedPercent!;
    }
    if (originalSize == 0) return 0.0;
    final diff = originalSize - compressedSize;
    if (diff <= 0) return 0.0;
    return (diff / originalSize) * 100.0;
  }

  int get totalSavedBytes => savedBytes ?? (originalSize - compressedSize);

  String get originalSizeFormatted => formatFileSize(originalSize);
  String get compressedSizeFormatted => formatFileSize(compressedSize);
  String get savingsFormatted => '-${savingsPercent.toStringAsFixed(1)}%';
  bool get hasSizeReduction =>
      compressedSize < originalSize && compressedBytes.isNotEmpty;

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class FileCompressor {
  FileCompressor._();

  static bool isImage(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    return [
      'jpg',
      'jpeg',
      'png',
      'webp',
      'bmp',
      'gif',
      'tiff',
      'heic',
      'jfif',
      'avif',
    ].contains(ext);
  }

  static bool isPdf(String fileName) {
    return fileName.toLowerCase().endsWith('.pdf');
  }

  static bool isCompressible(String fileName) {
    return isImage(fileName) || isPdf(fileName);
  }

  /// Compresses a file using King Technology Media Engine API.
  /// No local Flutter raster processing is performed.
  static Future<CompressionResult?> compressFile({
    required Uint8List bytes,
    required String fileName,
    String level = 'recommended',
    int? quality,
    int? dpi,
    int? maxDimension,
    int? targetSizeKb,
    bool grayscale = false,
    bool stripMetadata = true,
    ProgressCallback? onProgress,
  }) async {
    if (isPdf(fileName)) {
      return compressPdfViaApi(
        bytes: bytes,
        fileName: fileName,
        level: level,
        dpi: dpi,
        quality: quality ?? 72,
        targetSizeKb: targetSizeKb,
        grayscale: grayscale,
        stripMetadata: stripMetadata,
        onProgress: onProgress,
      );
    } else if (isImage(fileName)) {
      return compressImageViaApi(
        bytes: bytes,
        fileName: fileName,
        level: level,
        quality: quality ?? 75,
        maxDimension: maxDimension,
        targetSizeKb: targetSizeKb,
        grayscale: grayscale,
        stripMetadata: stripMetadata,
        onProgress: onProgress,
      );
    }
    return null;
  }

  // ================= IMAGE COMPRESSION VIA API =================
  /// Compresses an image file by sending it to King Technology Media Engine:
  /// POST https://apiengine.kingtechnology.in/api/image/compress
  static Future<CompressionResult?> compressImageViaApi({
    required Uint8List bytes,
    required String fileName,
    String level = 'recommended',
    int quality = 75,
    int? maxDimension,
    int? targetSizeKb,
    bool grayscale = false,
    bool stripMetadata = true,
    ProgressCallback? onProgress,
    Duration timeout = const Duration(seconds: 40),
  }) async {
    final stopwatch = Stopwatch()..start();
    final endpoint =
        '${AppConstants.apiEngineBaseUrl}${AppConstants.apiEngineImageCompressEndpoint}';
    final detectedMime = lookupMimeType(fileName) ?? 'image/jpeg';
    final formattedOriginal = CompressionResult.formatFileSize(bytes.length);

    try {
      AppLogger.info(
        'KT_MEDIA_ENGINE',
        '┌──────────────────────────────────────────────────────────────────\n'
        '│ 🚀 [IMAGE COMPRESS START]\n'
        '│ 📄 File Name: $fileName\n'
        '│ ⚖️  Original Size: ${bytes.length} bytes ($formattedOriginal)\n'
        '│ 🎚️  Preset Level: $level\n'
        '│ 🎛️  Target Quality: $quality%\n'
        '│ 📐  Max Dimension: ${maxDimension != null ? "${maxDimension}px" : "Auto"}\n'
        '│ 🎯  Target Size: ${targetSizeKb != null ? "${targetSizeKb}KB" : "Auto"}\n'
        '│ 🎨  Grayscale: $grayscale\n'
        '│ 🧹  Strip Metadata: $stripMetadata\n'
        '│ 🏷️  Detected MIME: $detectedMime\n'
        '│ 🌐 Target API: $endpoint\n'
        '└──────────────────────────────────────────────────────────────────',
      );

      onProgress?.call(
        0.15,
        'Connecting to King Technology Media Engine API...',
      );

      final mediaType = MediaType.parse(detectedMime);
      final uri = Uri.parse(endpoint);

      AppLogger.info(
        'KT_MEDIA_ENGINE',
        '⏳ [STEP 1/4] Preparing multipart POST request to $uri with level=$level, quality=$quality...',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['level'] = level
        ..fields['quality'] = quality.clamp(10, 100).toString();

      if (maxDimension != null && maxDimension > 0) {
        request.fields['maxDimension'] = maxDimension.toString();
      }
      if (targetSizeKb != null && targetSizeKb > 0) {
        request.fields['targetSizeKb'] = targetSizeKb.toString();
      }
      if (grayscale) {
        request.fields['grayscale'] = 'true';
      }
      if (!stripMetadata) {
        request.fields['stripMetadata'] = 'false';
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: mediaType,
        ),
      );

      onProgress?.call(
        0.40,
        'Streaming binary to King Technology Media Engine...',
      );

      AppLogger.info(
        'KT_MEDIA_ENGINE',
        '📤 [STEP 2/4] Uploading image binary (${bytes.length} bytes) to Media Engine...',
      );

      final streamedResponse = await request.send().timeout(
        timeout,
        onTimeout: () {
          AppLogger.error(
            'KT_MEDIA_ENGINE',
            '⏱️ [IMAGE TIMEOUT] API request timed out after ${timeout.inSeconds}s!',
          );
          throw TimeoutException(
            'Connection to King Technology Media Engine timed out after ${timeout.inSeconds} seconds. Check network connectivity.',
          );
        },
      );

      AppLogger.info(
        'KT_MEDIA_ENGINE',
        '📥 [STEP 3/4] Response headers received in ${stopwatch.elapsedMilliseconds}ms. '
        'Status: ${streamedResponse.statusCode} (${streamedResponse.reasonPhrase})',
      );

      onProgress?.call(
        0.75,
        'Cloud engine processing & optimizing buffers in RAM...',
      );

      final response = await http.Response.fromStream(streamedResponse);

      AppLogger.info(
        'KT_MEDIA_ENGINE',
        '📦 [STEP 4/4] Binary stream fully received (${response.bodyBytes.length} bytes). '
        'Parsing metadata headers...',
      );

      if (response.statusCode != 200) {
        final bodySnippet = response.body.length > 400
            ? '${response.body.substring(0, 400)}...'
            : response.body;
        AppLogger.error(
          'KT_MEDIA_ENGINE',
          '❌ [API ERROR] HTTP Status ${response.statusCode} (${response.reasonPhrase})\n'
          'Response Headers: ${response.headers}\n'
          'Response Body: $bodySnippet',
        );
        throw Exception(
          'API Engine responded with status ${response.statusCode}: ${response.reasonPhrase}',
        );
      }

      final compressedBytes = response.bodyBytes;
      if (compressedBytes.isEmpty) {
        AppLogger.error(
          'KT_MEDIA_ENGINE',
          '❌ [EMPTY BUFFER] Media Engine returned an empty byte stream',
        );
        throw Exception('API Engine returned empty binary buffer');
      }

      onProgress?.call(0.95, 'Finalizing optimized image...');

      // Parse metadata from response headers
      final origSizeHeader = int.tryParse(
            response.headers['x-original-size'] ?? '',
          ) ??
          bytes.length;
      final outputSizeHeader = int.tryParse(
            response.headers['x-output-size'] ?? '',
          ) ??
          compressedBytes.length;
      final savedBytesHeader = int.tryParse(
        response.headers['x-saved-bytes'] ?? '',
      );
      final savedPercentHeader = double.tryParse(
        response.headers['x-saved-percent'] ?? '',
      );

      // Extract filename from content-disposition if present
      String compFileName = fileName;
      final disposition = response.headers['content-disposition'];
      if (disposition != null && disposition.contains('filename=')) {
        final match = RegExp(r'filename="?([^"]+)"?').firstMatch(disposition);
        if (match != null && match.group(1) != null) {
          compFileName = match.group(1)!;
        }
      }

      final respMimeType =
          response.headers['content-type']?.split(';').first.trim() ??
          detectedMime;

      final diff = origSizeHeader - outputSizeHeader;
      final calcSavings = origSizeHeader > 0 ? (diff / origSizeHeader) * 100 : 0.0;
      final effectiveSavings = savedPercentHeader ?? calcSavings;

      onProgress?.call(1.0, 'Optimization complete!');

      AppLogger.info(
        'KT_MEDIA_ENGINE',
        '┌──────────────────────────────────────────────────────────────────\n'
        '│ ✅ [IMAGE COMPRESSION COMPLETE] Total Time: ${stopwatch.elapsedMilliseconds}ms\n'
        '│ 📄 Output File: $compFileName\n'
        '│ 📊 Original Size: $origSizeHeader bytes ($formattedOriginal)\n'
        '│ 📉 Compressed Size: $outputSizeHeader bytes (${CompressionResult.formatFileSize(outputSizeHeader)})\n'
        '│ 🔥 Savings: ${effectiveSavings.toStringAsFixed(1)}% (${CompressionResult.formatFileSize(diff)} saved)\n'
        '│ 📋 Headers: X-Original-Size=$origSizeHeader, X-Output-Size=$outputSizeHeader, X-Saved-Percent=$savedPercentHeader, X-Saved-Bytes=$savedBytesHeader\n'
        '└──────────────────────────────────────────────────────────────────',
      );

      return CompressionResult(
        originalBytes: bytes,
        compressedBytes: compressedBytes,
        originalSize: origSizeHeader,
        compressedSize: outputSizeHeader,
        fileName: fileName,
        compressedFileName: compFileName,
        mimeType: respMimeType,
        quality: quality,
        isPdf: false,
        level: level,
        maxDimension: maxDimension,
        targetSizeKb: targetSizeKb,
        isGrayscale: grayscale,
        isMetadataStripped: stripMetadata,
        savedBytes: savedBytesHeader,
        engine: 'King Technology Media Engine',
        apiSavedPercent: savedPercentHeader,
      );
    } catch (e, st) {
      AppLogger.error(
        'KT_MEDIA_ENGINE',
        '💥 [IMAGE COMPRESSION FAILED/STUCK] Failed after ${stopwatch.elapsedMilliseconds}ms: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  // ================= PDF COMPRESSION VIA API =================
  /// Compresses a PDF file by sending it to King Technology Media Engine:
  /// POST https://apiengine.kingtechnology.in/api/pdf/compress
  static Future<CompressionResult?> compressPdfViaApi({
    required Uint8List bytes,
    required String fileName,
    String level = 'recommended',
    int? dpi,
    int quality = 72,
    int? targetSizeKb,
    bool grayscale = false,
    bool stripMetadata = true,
    ProgressCallback? onProgress,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final stopwatch = Stopwatch()..start();
    final endpoint =
        '${AppConstants.apiEngineBaseUrl}${AppConstants.apiEnginePdfCompressEndpoint}';
    final formattedOriginal = CompressionResult.formatFileSize(bytes.length);

    try {
      AppLogger.info(
        'KT_MEDIA_ENGINE',
        '┌──────────────────────────────────────────────────────────────────\n'
        '│ 🚀 [PDF COMPRESS START]\n'
        '│ 📄 File Name: $fileName\n'
        '│ ⚖️  Original Size: ${bytes.length} bytes ($formattedOriginal)\n'
        '│ 🎚️  Preset Level: $level\n'
        '│ 🎛️  Target Quality: $quality%\n'
        '│ 🔍  Target DPI: ${dpi != null ? "$dpi DPI" : "Default"}\n'
        '│ 🎯  Target Size: ${targetSizeKb != null ? "${targetSizeKb}KB" : "Auto"}\n'
        '│ 🎨  Grayscale: $grayscale\n'
        '│ 🧹  Strip Metadata: $stripMetadata\n'
        '│ 🌐 Target API: $endpoint\n'
        '└──────────────────────────────────────────────────────────────────',
      );

      onProgress?.call(
        0.15,
        'Connecting to King Technology Media Engine API...',
      );

      final uri = Uri.parse(endpoint);

      AppLogger.info(
        'KT_MEDIA_ENGINE',
        '⏳ [STEP 1/4] Preparing multipart POST request to $uri with level=$level, dpi=$dpi, quality=$quality...',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['level'] = level
        ..fields['quality'] = quality.clamp(10, 100).toString();

      if (dpi != null && dpi > 0) {
        request.fields['dpi'] = dpi.toString();
      }
      if (targetSizeKb != null && targetSizeKb > 0) {
        request.fields['targetSizeKb'] = targetSizeKb.toString();
      }
      if (grayscale) {
        request.fields['grayscale'] = 'true';
      }
      if (!stripMetadata) {
        request.fields['stripMetadata'] = 'false';
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: MediaType('application', 'pdf'),
        ),
      );

      onProgress?.call(
        0.40,
        'Streaming PDF binary to King Technology Media Engine...',
      );

      AppLogger.info(
        'KT_MEDIA_ENGINE',
        '📤 [STEP 2/4] Uploading PDF binary (${bytes.length} bytes) to Media Engine...',
      );

      final streamedResponse = await request.send().timeout(
        timeout,
        onTimeout: () {
          AppLogger.error(
            'KT_MEDIA_ENGINE',
            '⏱️ [PDF TIMEOUT] API request timed out after ${timeout.inSeconds}s!',
          );
          throw TimeoutException(
            'Connection to King Technology Media Engine timed out after ${timeout.inSeconds} seconds. Check network connectivity.',
          );
        },
      );

      AppLogger.info(
        'KT_MEDIA_ENGINE',
        '📥 [STEP 3/4] Response headers received in ${stopwatch.elapsedMilliseconds}ms. '
        'Status: ${streamedResponse.statusCode} (${streamedResponse.reasonPhrase})',
      );

      onProgress?.call(
        0.75,
        'Cloud engine compressing PDF streams & graphics in RAM...',
      );

      final response = await http.Response.fromStream(streamedResponse);

      AppLogger.info(
        'KT_MEDIA_ENGINE',
        '📦 [STEP 4/4] PDF binary stream fully received (${response.bodyBytes.length} bytes). '
        'Parsing metadata headers...',
      );

      if (response.statusCode != 200) {
        final bodySnippet = response.body.length > 400
            ? '${response.body.substring(0, 400)}...'
            : response.body;
        AppLogger.error(
          'KT_MEDIA_ENGINE',
          '❌ [API ERROR] HTTP Status ${response.statusCode} (${response.reasonPhrase})\n'
          'Response Headers: ${response.headers}\n'
          'Response Body: $bodySnippet',
        );
        throw Exception(
          'API Engine responded with status ${response.statusCode}: ${response.reasonPhrase}',
        );
      }

      final compressedBytes = response.bodyBytes;
      if (compressedBytes.isEmpty) {
        AppLogger.error(
          'KT_MEDIA_ENGINE',
          '❌ [EMPTY BUFFER] Media Engine returned an empty byte stream',
        );
        throw Exception('API Engine returned empty binary stream');
      }

      onProgress?.call(0.95, 'Finalizing optimized PDF...');

      // Parse metadata from response headers
      final origSizeHeader = int.tryParse(
            response.headers['x-original-size'] ?? '',
          ) ??
          bytes.length;
      final outputSizeHeader = int.tryParse(
            response.headers['x-output-size'] ?? '',
          ) ??
          compressedBytes.length;
      final savedBytesHeader = int.tryParse(
        response.headers['x-saved-bytes'] ?? '',
      );
      final savedPercentHeader = double.tryParse(
        response.headers['x-saved-percent'] ?? '',
      );
      final pageCountHeader = int.tryParse(
        response.headers['x-page-count'] ?? '',
      );

      // Extract filename from content-disposition if present
      String compFileName = fileName;
      final disposition = response.headers['content-disposition'];
      if (disposition != null && disposition.contains('filename=')) {
        final match = RegExp(r'filename="?([^"]+)"?').firstMatch(disposition);
        if (match != null && match.group(1) != null) {
          compFileName = match.group(1)!;
        }
      }

      final diff = origSizeHeader - outputSizeHeader;
      final calcSavings = origSizeHeader > 0 ? (diff / origSizeHeader) * 100 : 0.0;
      final effectiveSavings = savedPercentHeader ?? calcSavings;

      onProgress?.call(1.0, 'Optimization complete!');

      AppLogger.info(
        'KT_MEDIA_ENGINE',
        '┌──────────────────────────────────────────────────────────────────\n'
        '│ ✅ [PDF COMPRESSION COMPLETE] Total Time: ${stopwatch.elapsedMilliseconds}ms\n'
        '│ 📄 Output File: $compFileName\n'
        '│ 📊 Original Size: $origSizeHeader bytes ($formattedOriginal)\n'
        '│ 📉 Compressed Size: $outputSizeHeader bytes (${CompressionResult.formatFileSize(outputSizeHeader)})\n'
        '│ 🔥 Savings: ${effectiveSavings.toStringAsFixed(1)}% (${CompressionResult.formatFileSize(diff)} saved)\n'
        '│ 📋 Headers: X-Original-Size=$origSizeHeader, X-Output-Size=$outputSizeHeader, X-Saved-Percent=$savedPercentHeader, X-Saved-Bytes=$savedBytesHeader, X-Page-Count=$pageCountHeader\n'
        '└──────────────────────────────────────────────────────────────────',
      );

      return CompressionResult(
        originalBytes: bytes,
        compressedBytes: compressedBytes,
        originalSize: origSizeHeader,
        compressedSize: outputSizeHeader,
        fileName: fileName,
        compressedFileName: compFileName,
        mimeType: 'application/pdf',
        quality: quality,
        isPdf: true,
        pdfLevel: level,
        level: level,
        dpi: dpi,
        targetSizeKb: targetSizeKb,
        isGrayscale: grayscale,
        isMetadataStripped: stripMetadata,
        pageCount: pageCountHeader,
        savedBytes: savedBytesHeader,
        engine: 'King Technology Media Engine',
        apiSavedPercent: savedPercentHeader,
      );
    } catch (e, st) {
      AppLogger.error(
        'KT_MEDIA_ENGINE',
        '💥 [PDF COMPRESSION FAILED/STUCK] Failed after ${stopwatch.elapsedMilliseconds}ms: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
