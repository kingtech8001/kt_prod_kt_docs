import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/document_preview_dataset.dart';
import 'package:kt_prod_kt_docs/core/utils/app_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';

class ImagePreviewController extends GetxController {
  ImagePreviewController(
    this._dataset, {
    required this.title,
    this.imageUrl,
    this.imageBytes,
    this.fileName,
    this.filePath,
    this.onDownload,
  });
  final DocumentPreviewDataset _dataset;
  final String title;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final String? fileName;
  final String? filePath;
  final VoidCallback? onDownload;

  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final Rxn<Uint8List> loadedBytes = Rxn<Uint8List>();
  final RxInt quarterTurns = 0.obs;

  @override
  void onInit() {
    super.onInit();

    if (imageBytes != null && imageBytes!.isNotEmpty) {
      loadedBytes.value = imageBytes;
      isLoading.value = false;
    } else if ((imageUrl != null && imageUrl!.trim().isNotEmpty) ||
        (filePath != null && filePath!.trim().isNotEmpty)) {
      loadImageBytesViaApi();
    } else {
      errorMessage.value = 'No image URL or binary data was provided.';
      isLoading.value = false;
    }
  }

  Future<void> present(Widget dialog, String tag) async {
    try {
      await AppDialog.show(dialog, barrierColor: const Color(0xDD000000));
    } catch (error, stackTrace) {
      AppLogger.error(
        'PREVIEW_CONTROLLER',
        'Could not show preview.',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      Get.delete<ImagePreviewController>(tag: tag);
    }
  }

  Future<void> loadImageBytesViaApi() async {
    isLoading.value = true;
    errorMessage.value = '';

    AppLogger.debug(
      'IMAGE_LIGHTBOX',
      'Loading image bytes via API: title="$title", url=$imageUrl, path=$filePath',
    );

    try {
      final candidateUrl = imageUrl?.trim() ?? '';
      final candidatePath = filePath?.trim() ?? '';

      Uint8List? bytes;

      if (candidateUrl.startsWith('http://') ||
          candidateUrl.startsWith('https://')) {
        try {
          final fetched = await _dataset.fetchBytes(candidateUrl);
          if (fetched.isNotEmpty) {
            bytes = fetched;
          }
        } catch (fetchErr) {
          AppLogger.warning(
            'IMAGE_LIGHTBOX',
            'Direct image URL fetch failed: $fetchErr. Attempting storage fallback.',
          );
        }
      }

      if (bytes == null) {
        final storagePath =
            candidatePath.isNotEmpty && !candidatePath.startsWith('http')
            ? candidatePath
            : (candidateUrl.isNotEmpty && !candidateUrl.startsWith('http')
                  ? candidateUrl
                  : null);

        if (storagePath != null) {
          final cleanPath = storagePath.startsWith('/')
              ? storagePath.substring(1)
              : storagePath;

          try {
            AppLogger.info(
              'IMAGE_LIGHTBOX',
              'Downloading image directly from Supabase storage: "$cleanPath"',
            );
            final downloaded = await _dataset.download(cleanPath);
            if (downloaded.isNotEmpty) {
              bytes = downloaded;
            }
          } catch (storageErr) {
            AppLogger.warning(
              'IMAGE_LIGHTBOX',
              'Direct Supabase storage image download notice: $storageErr',
            );
          }

          if (bytes == null) {
            try {
              final freshSignedUrl = await _dataset.createSignedUrl(cleanPath);
              final fetched = await _dataset.fetchBytes(freshSignedUrl);
              if (fetched.isNotEmpty) {
                bytes = fetched;
              }
            } catch (signedErr) {
              AppLogger.warning(
                'IMAGE_LIGHTBOX',
                'Fresh signed image URL fetch notice: $signedErr',
              );
            }
          }
        }
      }

      if (bytes == null || bytes.isEmpty) {
        throw Exception(
          'Unable to retrieve image data. Please check network connection or verify image storage.',
        );
      }

      loadedBytes.value = bytes;
      isLoading.value = false;
      AppLogger.info(
        'IMAGE_LIGHTBOX',
        'Image bytes successfully loaded via API (${bytes.length} bytes).',
      );
    } catch (error, st) {
      AppLogger.error(
        'IMAGE_LIGHTBOX',
        'Failed to load image via API: $error',
        error: error,
        stackTrace: st,
      );
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
      isLoading.value = false;
    }
  }

  void rotateClockwise() {
    quarterTurns.value = (quarterTurns.value + 1) % 4;
  }

  void rotateCounterClockwise() {
    quarterTurns.value = (quarterTurns.value - 1 + 4) % 4;
  }

  Future<void> handleDownload() async {
    try {
      final name = fileName?.isNotEmpty == true ? fileName! : '$title.jpg';
      final data = loadedBytes.value;
      if (data != null && data.isNotEmpty) {
        await _dataset.downloadBytes(data, name, 'image/jpeg');
      } else if (onDownload != null) {
        onDownload!();
      } else if (imageUrl != null) {
        await _dataset.downloadUrl(imageUrl!, name, 'image/jpeg');
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'PREVIEW_CONTROLLER',
        'Download failed.',
        error: error,
        stackTrace: stackTrace,
      );
      errorMessage.value = error.toString();
    }
  }
}
