import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

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
  final bool hasEmbeddedImages;
  final int? originalWidth;
  final int? originalHeight;
  final int? compressedWidth;
  final int? compressedHeight;

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
    this.hasEmbeddedImages = false,
    this.originalWidth,
    this.originalHeight,
    this.compressedWidth,
    this.compressedHeight,
  });

  double get savingsPercent {
    if (originalSize == 0) return 0.0;
    final diff = originalSize - compressedSize;
    if (diff <= 0) return 0.0;
    return (diff / originalSize) * 100.0;
  }

  String get originalSizeFormatted => formatFileSize(originalSize);
  String get compressedSizeFormatted => formatFileSize(compressedSize);
  String get savingsFormatted => '-${savingsPercent.toStringAsFixed(0)}%';

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
    return ['jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif', 'tiff', 'heic', 'jfif'].contains(ext);
  }

  static bool isPdf(String fileName) {
    return fileName.toLowerCase().endsWith('.pdf');
  }

  static bool isCompressible(String fileName) {
    return isImage(fileName) || isPdf(fileName);
  }

  static Future<CompressionResult?> compressFile({
    required Uint8List bytes,
    required String fileName,
    int quality = 70,
    int maxDimension = 2048,
    ProgressCallback? onProgress,
  }) async {
    if (isPdf(fileName)) {
      return compressPdf(
        bytes: bytes,
        fileName: fileName,
        quality: quality,
        maxDimension: maxDimension,
        onProgress: onProgress,
      );
    } else if (isImage(fileName)) {
      return compressImage(
        bytes: bytes,
        fileName: fileName,
        quality: quality,
        maxDimension: maxDimension,
        onProgress: onProgress,
      );
    }
    return null;
  }

  // ================= IMAGE COMPRESSION =================
  static Future<CompressionResult?> compressImage({
    required Uint8List bytes,
    required String fileName,
    int quality = 70,
    int maxDimension = 2048,
    ProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call(0.15, 'Reading image data...');
      await Future.delayed(const Duration(milliseconds: 30));

      AppLogger.info('COMPRESSOR', 'Starting image compression: $fileName (Quality: $quality%, MaxDim: $maxDimension px)');
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) {
        AppLogger.warning('COMPRESSOR', 'Failed to decode image bytes for $fileName');
        return null;
      }

      onProgress?.call(0.45, 'Resizing & optimizing resolution...');
      await Future.delayed(const Duration(milliseconds: 30));

      final origWidth = decodedImage.width;
      final origHeight = decodedImage.height;

      img.Image processedImage = decodedImage;
      if (origWidth > maxDimension || origHeight > maxDimension) {
        if (origWidth >= origHeight) {
          processedImage = img.copyResize(decodedImage, width: maxDimension);
        } else {
          processedImage = img.copyResize(decodedImage, height: maxDimension);
        }
      }

      onProgress?.call(0.75, 'Encoding JPEG with $quality% quality...');
      await Future.delayed(const Duration(milliseconds: 30));

      final compressedBytes = Uint8List.fromList(
        img.encodeJpg(processedImage, quality: quality),
      );

      final baseName = fileName.contains('.') ? fileName.substring(0, fileName.lastIndexOf('.')) : fileName;
      final compName = '$baseName.jpg';

      onProgress?.call(1.0, 'Compression complete!');
      await Future.delayed(const Duration(milliseconds: 20));

      AppLogger.info(
        'COMPRESSOR',
        'Compressed image $fileName: ${bytes.length} B -> ${compressedBytes.length} B '
        '(-${(((bytes.length - compressedBytes.length) / bytes.length) * 100).toStringAsFixed(1)}% savings)',
      );

      return CompressionResult(
        originalBytes: bytes,
        compressedBytes: compressedBytes,
        originalSize: bytes.length,
        compressedSize: compressedBytes.length,
        fileName: fileName,
        compressedFileName: compName,
        mimeType: 'image/jpeg',
        quality: quality,
        isPdf: false,
        hasEmbeddedImages: true,
        originalWidth: origWidth,
        originalHeight: origHeight,
        compressedWidth: processedImage.width,
        compressedHeight: processedImage.height,
      );
    } catch (e, st) {
      AppLogger.error('COMPRESSOR', 'Exception during image compression: $e', error: e, stackTrace: st);
      return null;
    }
  }

  // ================= PDF COMPRESSION & STREAM OPTIMIZATION =================
  static Future<CompressionResult?> compressPdf({
    required Uint8List bytes,
    required String fileName,
    int quality = 70,
    int maxDimension = 2048,
    ProgressCallback? onProgress,
  }) async {
    try {
      AppLogger.info('COMPRESSOR', 'Starting PDF compression on $fileName (${bytes.length} bytes, Quality: $quality%)');

      onProgress?.call(0.20, 'Analyzing PDF structure & fonts...');
      await Future.delayed(const Duration(milliseconds: 30));

      // 1. First Pass: Syncfusion PDF structural optimization
      Uint8List workingPdfBytes = bytes;
      try {
        final pdfDoc = PdfDocument(inputBytes: bytes);
        pdfDoc.compressionLevel = PdfCompressionLevel.best;
        pdfDoc.fileStructure.incrementalUpdate = false;
        final resavedBytes = Uint8List.fromList(pdfDoc.saveSync());
        pdfDoc.dispose();

        if (resavedBytes.isNotEmpty && resavedBytes.length < bytes.length) {
          workingPdfBytes = resavedBytes;
        }
      } catch (e) {
        AppLogger.warning('COMPRESSOR', 'Syncfusion PDF initial pass note: $e');
      }

      onProgress?.call(0.50, 'Scanning embedded streams & images ($quality% quality)...');
      await Future.delayed(const Duration(milliseconds: 30));

      // 2. Second Pass: Xref-safe embedded JPEG stream optimization
      final optResult = await _optimizePdfStreamsWithXref(
        workingPdfBytes,
        quality: quality,
        maxDimension: maxDimension,
        onProgress: onProgress,
      );

      onProgress?.call(0.90, 'Finalizing xref tables & calculating size...');
      await Future.delayed(const Duration(milliseconds: 30));

      Uint8List finalPdfBytes = optResult.bytes;
      if (finalPdfBytes.length > bytes.length && workingPdfBytes.length <= bytes.length) {
        finalPdfBytes = workingPdfBytes;
      }

      final savings = bytes.isNotEmpty
          ? ((bytes.length - finalPdfBytes.length) / bytes.length) * 100
          : 0.0;

      onProgress?.call(1.0, 'Optimization complete!');
      await Future.delayed(const Duration(milliseconds: 20));

      AppLogger.info(
        'COMPRESSOR',
        'PDF Optimization complete for $fileName: ${bytes.length} B -> ${finalPdfBytes.length} B '
        '(-${savings.toStringAsFixed(1)}% savings, hasEmbeddedImages: ${optResult.hasEmbeddedImages})',
      );

      return CompressionResult(
        originalBytes: bytes,
        compressedBytes: finalPdfBytes,
        originalSize: bytes.length,
        compressedSize: finalPdfBytes.length,
        fileName: fileName,
        compressedFileName: fileName,
        mimeType: 'application/pdf',
        quality: quality,
        isPdf: true,
        hasEmbeddedImages: optResult.hasEmbeddedImages,
      );
    } catch (e, st) {
      AppLogger.error('COMPRESSOR', 'Exception during PDF compression: $e', error: e, stackTrace: st);
      return null;
    }
  }

  static Future<_PdfOptInternalResult> _optimizePdfStreamsWithXref(
    Uint8List pdfData, {
    required int quality,
    required int maxDimension,
    ProgressCallback? onProgress,
  }) async {
    try {
      final streamMarker = ascii.encode('stream');
      final endStreamMarker = ascii.encode('endstream');
      final objMarker = ascii.encode('obj');
      final endObjMarker = ascii.encode('endobj');

      final output = BytesBuilder();
      final headerEnd = pdfData.contains(10) ? pdfData.indexOf(10) + 1 : 15;
      output.add(pdfData.sublist(0, headerEnd));

      final objectOffsets = <int, int>{};
      int maxObjNum = 0;
      int replacedStreamsCount = 0;
      bool foundAnyImages = false;

      int currentIndex = headerEnd;
      final objRegex = RegExp(r'(\d+)\s+(\d+)\s+obj');

      while (currentIndex < pdfData.length) {
        final nextObjPos = _findPattern(pdfData, objMarker, currentIndex);
        if (nextObjPos == -1) break;

        int lineStart = nextObjPos;
        while (lineStart > currentIndex && pdfData[lineStart - 1] != 10 && pdfData[lineStart - 1] != 13) {
          lineStart--;
        }

        final objDeclStr = latin1.decode(pdfData.sublist(lineStart, nextObjPos + 3));
        final match = objRegex.firstMatch(objDeclStr);
        if (match == null) {
          currentIndex = nextObjPos + 3;
          continue;
        }

        final objNum = int.parse(match.group(1)!);
        if (objNum > maxObjNum) maxObjNum = objNum;

        final nextEndObjPos = _findPattern(pdfData, endObjMarker, nextObjPos + 3);
        if (nextEndObjPos == -1) break;

        final objFullEnd = nextEndObjPos + endObjMarker.length;
        final objBytes = pdfData.sublist(lineStart, objFullEnd);

        // Scan for streams inside this object
        final streamPosInObj = _findPattern(objBytes, streamMarker, 0);
        if (streamPosInObj != -1) {
          int streamDataStart = streamPosInObj + streamMarker.length;
          if (streamDataStart < objBytes.length && objBytes[streamDataStart] == 13) streamDataStart++;
          if (streamDataStart < objBytes.length && objBytes[streamDataStart] == 10) streamDataStart++;

          final endStreamPosInObj = _findPattern(objBytes, endStreamMarker, streamDataStart);
          if (endStreamPosInObj != -1) {
            int streamDataEnd = endStreamPosInObj;
            if (streamDataEnd > streamDataStart && objBytes[streamDataEnd - 1] == 10) streamDataEnd--;
            if (streamDataEnd > streamDataStart && objBytes[streamDataEnd - 1] == 13) streamDataEnd--;

            final streamData = objBytes.sublist(streamDataStart, streamDataEnd);

            // Detect JPEG (magic bytes 0xFF, 0xD8, 0xFF)
            if (streamData.length > 4 && streamData[0] == 0xFF && streamData[1] == 0xD8 && streamData[2] == 0xFF) {
              foundAnyImages = true;
              onProgress?.call(0.70, 'Re-encoding embedded image stream #$objNum ($quality% quality)...');
              await Future.delayed(const Duration(milliseconds: 10));

              try {
                final decoded = img.decodeJpg(streamData);
                if (decoded != null) {
                  img.Image processed = decoded;
                  if (decoded.width > maxDimension || decoded.height > maxDimension) {
                    if (decoded.width >= decoded.height) {
                      processed = img.copyResize(decoded, width: maxDimension);
                    } else {
                      processed = img.copyResize(decoded, height: maxDimension);
                    }
                  }

                  final compressed = Uint8List.fromList(img.encodeJpg(processed, quality: quality));
                  if (compressed.length < streamData.length) {
                    var dictStr = latin1.decode(objBytes.sublist(0, streamDataStart));
                    final lengthRegex = RegExp(r'/Length\s+(\d+)');
                    if (lengthRegex.hasMatch(dictStr)) {
                      dictStr = dictStr.replaceFirst(lengthRegex, '/Length ${compressed.length}');
                    }

                    final newObjOffset = output.length;
                    objectOffsets[objNum] = newObjOffset;
                    output.add(latin1.encode(dictStr));
                    output.add(compressed);
                    output.add(latin1.encode('\nendstream\nendobj\n'));
                    currentIndex = objFullEnd;
                    replacedStreamsCount++;
                    continue;
                  }
                }
              } catch (_) {}
            }
          }
        }

        final newObjOffset = output.length;
        objectOffsets[objNum] = newObjOffset;
        output.add(objBytes);
        output.add(latin1.encode('\n'));
        currentIndex = objFullEnd;
      }

      if (replacedStreamsCount == 0) {
        return _PdfOptInternalResult(pdfData, foundAnyImages);
      }

      // Rebuild trailer and xref
      final trailerMarker = ascii.encode('trailer');
      final trailerPos = _findPattern(pdfData, trailerMarker, 0);
      String trailerStr = 'trailer\n<< /Size ${maxObjNum + 1} /Root 1 0 R >>';
      if (trailerPos != -1) {
        final startXrefMarker = ascii.encode('startxref');
        final startXrefPos = _findPattern(pdfData, startXrefMarker, trailerPos);
        if (startXrefPos != -1) {
          trailerStr = latin1.decode(pdfData.sublist(trailerPos, startXrefPos)).trim();
          final sizeRegex = RegExp(r'/Size\s+(\d+)');
          if (sizeRegex.hasMatch(trailerStr)) {
            trailerStr = trailerStr.replaceFirst(sizeRegex, '/Size ${maxObjNum + 1}');
          }
        }
      }

      final startXrefOffset = output.length;
      final xrefBuffer = StringBuffer();
      xrefBuffer.writeln('xref');
      xrefBuffer.writeln('0 ${maxObjNum + 1}');
      xrefBuffer.writeln('0000000000 65535 f ');

      for (int i = 1; i <= maxObjNum; i++) {
        final offset = objectOffsets[i] ?? 0;
        if (offset > 0) {
          final padded = offset.toString().padLeft(10, '0');
          xrefBuffer.writeln('$padded 00000 n ');
        } else {
          xrefBuffer.writeln('0000000000 65535 f ');
        }
      }

      xrefBuffer.writeln(trailerStr);
      xrefBuffer.writeln('startxref');
      xrefBuffer.writeln(startXrefOffset);
      xrefBuffer.writeln('%%EOF');

      output.add(latin1.encode(xrefBuffer.toString()));
      return _PdfOptInternalResult(output.toBytes(), foundAnyImages);
    } catch (e) {
      return _PdfOptInternalResult(pdfData, false);
    }
  }

  static int _findPattern(Uint8List source, List<int> pattern, int startIndex) {
    if (pattern.isEmpty || startIndex >= source.length) return -1;
    final limit = source.length - pattern.length;
    for (int i = startIndex; i <= limit; i++) {
      bool match = true;
      for (int j = 0; j < pattern.length; j++) {
        if (source[i + j] != pattern[j]) {
          match = false;
          break;
        }
      }
      if (match) return i;
    }
    return -1;
  }
}

class _PdfOptInternalResult {
  final Uint8List bytes;
  final bool hasEmbeddedImages;
  _PdfOptInternalResult(this.bytes, this.hasEmbeddedImages);
}
