import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/datasets/folder_dataset.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/app/data/models/folder_model.dart';
import 'package:kt_prod_kt_docs/app/routes/app_routes.dart';
import 'package:kt_prod_kt_docs/app/widgets/app_shimmer.dart';
import 'package:kt_prod_kt_docs/app/widgets/document_edit_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/image_lightbox_dialog.dart';
import 'package:kt_prod_kt_docs/app/widgets/pdf_viewer_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_dialog.dart';
import 'package:kt_prod_kt_docs/core/utils/app_logger.dart';
import 'package:kt_prod_kt_docs/core/utils/app_snackbar.dart';
import 'package:kt_prod_kt_docs/core/utils/file_api_helper.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';
import 'package:kt_prod_kt_docs/core/values/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class FoldersController extends GetxController {
  final FolderDataset _dataset;

  FoldersController(this._dataset);

  // General Loading & State
  final isLoading = true.obs;
  final folders = <FolderModel>[].obs;
  final selectedFolder = Rxn<FolderModel>();

  // Inside Folder State
  final folderDocuments = <DocumentModel>[].obs;
  final isFolderDocsLoading = false.obs;

  // Search Filters
  final folderSearchQuery = ''.obs;
  final folderDocSearchQuery = ''.obs;
  final searchController = TextEditingController();
  final docSearchController = TextEditingController();

  // Dialog Form State (Inline validation compliant)
  final folderNameController = TextEditingController();
  final folderDescController = TextEditingController();
  final selectedColor = '#2563EB'.obs;
  final dialogErrorMessage = ''.obs;
  final isDialogSubmitting = false.obs;

  // Document Assignment Modal State
  final availableDocuments = <DocumentModel>[].obs;
  final selectedDocIdsToAdd = <String>{}.obs;
  final isLoadingAvailableDocs = false.obs;

  static const List<String> folderColorPresets = [
    '#2563EB', // Blue
    '#4F46E5', // Indigo
    '#7C3AED', // Violet
    '#059669', // Emerald
    '#D97706', // Amber
    '#E11D48', // Rose
    '#0891B2', // Cyan
    '#64748B', // Slate
  ];

  // Computed Properties
  List<FolderModel> get filteredFolders {
    final query = folderSearchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return folders;
    return folders.where((f) {
      return f.name.toLowerCase().contains(query) ||
          (f.description != null && f.description!.toLowerCase().contains(query));
    }).toList();
  }

  List<DocumentModel> get filteredFolderDocuments {
    final query = folderDocSearchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return folderDocuments;
    return folderDocuments.where((doc) {
      return doc.title.toLowerCase().contains(query) ||
          doc.fileName.toLowerCase().contains(query) ||
          (doc.documentNumber != null &&
              doc.documentNumber!.toLowerCase().contains(query));
    }).toList();
  }

  int get totalOrganizedDocsCount {
    var sum = 0;
    for (var f in folders) {
      sum += f.documentCount;
    }
    return sum;
  }

  @override
  void onInit() {
    super.onInit();
    loadFolders();
  }

  @override
  void onClose() {
    folderNameController.dispose();
    folderDescController.dispose();
    searchController.dispose();
    docSearchController.dispose();
    super.onClose();
  }

  // ================= LOAD FOLDERS =================
  Future<void> loadFolders() async {
    AppLogger.debug('FOLDERS_CTRL', 'Loading folders from dataset...');
    isLoading.value = true;
    try {
      final list = await _dataset.getFolders();
      folders.assignAll(list);

      // Check if folderId parameter is provided via deep-link / navigation
      final paramFolderId = Get.parameters['folderId'];
      if (paramFolderId != null && paramFolderId.isNotEmpty) {
        final match = folders.firstWhereOrNull((f) => f.id == paramFolderId);
        if (match != null) {
          selectFolder(match);
        }
      }
      AppLogger.info('FOLDERS_CTRL', 'Loaded ${list.length} folders.');
    } catch (e, st) {
      AppLogger.error('FOLDERS_CTRL', 'Error loading folders: $e', error: e, stackTrace: st);
      AppSnackbar.showError('Error Loading Folders', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ================= FOLDER SELECTION & DRILL-DOWN =================
  Future<void> selectFolder(FolderModel folder) async {
    selectedFolder.value = folder;
    folderDocSearchQuery.value = '';
    docSearchController.clear();
    await loadFolderDocuments(folder.id);
  }

  void clearSelectedFolder() {
    selectedFolder.value = null;
    folderDocuments.clear();
    folderDocSearchQuery.value = '';
    docSearchController.clear();
    loadFolders(); // Refresh counts
  }

  Future<void> loadFolderDocuments(String folderId) async {
    AppLogger.debug('FOLDERS_CTRL', 'Loading documents for folder: $folderId');
    isFolderDocsLoading.value = true;
    try {
      final docs = await _dataset.getFolderDocuments(folderId);
      folderDocuments.assignAll(docs);

      // Update active folder document count
      final index = folders.indexWhere((f) => f.id == folderId);
      if (index != -1) {
        folders[index] = folders[index].copyWith(documentCount: docs.length);
        if (selectedFolder.value?.id == folderId) {
          selectedFolder.value = folders[index];
        }
      }
      AppLogger.info('FOLDERS_CTRL', 'Loaded ${docs.length} documents in folder $folderId.');
    } catch (e, st) {
      AppLogger.error('FOLDERS_CTRL', 'Error loading folder documents: $e', error: e, stackTrace: st);
      AppSnackbar.showError('Error Loading Documents', e.toString());
    } finally {
      isFolderDocsLoading.value = false;
    }
  }

  // ================= CREATE FOLDER DIALOG =================
  void openCreateFolderDialog() {
    folderNameController.clear();
    folderDescController.clear();
    selectedColor.value = '#2563EB';
    dialogErrorMessage.value = '';
    isDialogSubmitting.value = false;

    AppDialog.show(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMedium)),
        title: const Row(
          children: [
            Icon(Icons.create_new_folder_outlined, color: AppColors.primary),
            SizedBox(width: AppConstants.paddingSmall),
            Text('Create New Folder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // In-context error display (Rule 3.B)
                Obx(() {
                  if (dialogErrorMessage.value.isEmpty) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(AppConstants.paddingSmall + 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dialogErrorMessage.value,
                            style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const Text('Folder Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: folderNameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Legal Contracts, Branch Invoices, Tax Records',
                  ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),

                const Text('Description (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: folderDescController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Brief description of documents stored in this folder',
                  ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),

                const Text('Folder Color Tag', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Obx(() => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: folderColorPresets.map((hex) {
                        final isSelected = selectedColor.value == hex;
                        final colorVal = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                        return InkWell(
                          onTap: () => selectedColor.value = hex,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: colorVal,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: colorVal.withValues(alpha: 0.6),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          Obx(() => ElevatedButton(
                onPressed: isDialogSubmitting.value ? null : _submitCreateFolder,
                child: isDialogSubmitting.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create Folder'),
              )),
        ],
      ),
    );
  }

  Future<void> _submitCreateFolder() async {
    final name = folderNameController.text.trim();
    if (name.isEmpty) {
      dialogErrorMessage.value = 'Please enter a valid folder name.';
      return;
    }

    isDialogSubmitting.value = true;
    dialogErrorMessage.value = '';
    try {
      final newFolder = await _dataset.createFolder(
        name: name,
        description: folderDescController.text.trim().isNotEmpty
            ? folderDescController.text.trim()
            : null,
        color: selectedColor.value,
      );

      Get.back();
      AppSnackbar.showSuccess('Folder Created', 'Folder "$name" created successfully.');
      folders.insert(0, newFolder);
    } catch (e) {
      dialogErrorMessage.value = e.toString();
    } finally {
      isDialogSubmitting.value = false;
    }
  }

  // ================= EDIT / RENAME FOLDER DIALOG =================
  void openEditFolderDialog(FolderModel folder) {
    folderNameController.text = folder.name;
    folderDescController.text = folder.description ?? '';
    selectedColor.value = folder.color;
    dialogErrorMessage.value = '';
    isDialogSubmitting.value = false;

    AppDialog.show(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMedium)),
        title: const Row(
          children: [
            Icon(Icons.edit_outlined, color: AppColors.primary),
            SizedBox(width: AppConstants.paddingSmall),
            Text('Edit Folder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() {
                  if (dialogErrorMessage.value.isEmpty) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(AppConstants.paddingSmall + 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dialogErrorMessage.value,
                            style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const Text('Folder Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: folderNameController,
                  decoration: const InputDecoration(hintText: 'Folder name'),
                ),
                const SizedBox(height: AppConstants.paddingMedium),

                const Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: folderDescController,
                  maxLines: 2,
                  decoration: const InputDecoration(hintText: 'Folder description'),
                ),
                const SizedBox(height: AppConstants.paddingMedium),

                const Text('Folder Color Tag', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Obx(() => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: folderColorPresets.map((hex) {
                        final isSelected = selectedColor.value == hex;
                        final colorVal = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                        return InkWell(
                          onTap: () => selectedColor.value = hex,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: colorVal,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          Obx(() => ElevatedButton(
                onPressed: isDialogSubmitting.value ? null : () => _submitEditFolder(folder),
                child: isDialogSubmitting.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Changes'),
              )),
        ],
      ),
    );
  }

  Future<void> _submitEditFolder(FolderModel folder) async {
    final name = folderNameController.text.trim();
    if (name.isEmpty) {
      dialogErrorMessage.value = 'Please enter a valid folder name.';
      return;
    }

    isDialogSubmitting.value = true;
    dialogErrorMessage.value = '';
    try {
      final updated = await _dataset.updateFolder(
        id: folder.id,
        name: name,
        description: folderDescController.text.trim().isNotEmpty
            ? folderDescController.text.trim()
            : null,
        color: selectedColor.value,
      );

      Get.back();
      AppSnackbar.showSuccess('Folder Updated', 'Folder "$name" updated.');

      final index = folders.indexWhere((f) => f.id == folder.id);
      if (index != -1) {
        folders[index] = updated.copyWith(documentCount: folders[index].documentCount);
      }
      if (selectedFolder.value?.id == folder.id) {
        selectedFolder.value = updated.copyWith(documentCount: folderDocuments.length);
      }
    } catch (e) {
      dialogErrorMessage.value = e.toString();
    } finally {
      isDialogSubmitting.value = false;
    }
  }

  // ================= DELETE FOLDER CONFIRMATION =================
  void confirmDeleteFolder(FolderModel folder) {
    AppDialog.show(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMedium)),
        backgroundColor: AppColors.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Delete Folder?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Are you sure you want to delete folder "${folder.name}"?',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Documents inside this folder will NOT be deleted. They will simply be unassigned from this folder and remain safely accessible in All Documents.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: AppConstants.paddingSmall),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      onPressed: () async {
                        Get.back();
                        await _executeDeleteFolder(folder);
                      },
                      child: const Text('Delete Folder', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _executeDeleteFolder(FolderModel folder) async {
    try {
      await _dataset.deleteFolder(folder.id);
      folders.removeWhere((f) => f.id == folder.id);

      if (selectedFolder.value?.id == folder.id) {
        clearSelectedFolder();
      }

      AppSnackbar.showWarning('Folder Deleted', 'Folder "${folder.name}" was removed.');
    } catch (e, st) {
      AppLogger.error('FOLDERS_CTRL', 'Error deleting folder: $e', error: e, stackTrace: st);
      AppSnackbar.showError('Error', e.toString());
    }
  }

  // ================= ADD DOCUMENTS TO FOLDER =================
  Future<void> openAddDocumentsDialog() async {
    final activeFolder = selectedFolder.value;
    if (activeFolder == null) return;

    selectedDocIdsToAdd.clear();
    isLoadingAvailableDocs.value = true;

    AppDialog.show(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusMedium)),
        title: Row(
          children: [
            const Icon(Icons.note_add_outlined, color: AppColors.primary),
            const SizedBox(width: AppConstants.paddingSmall),
            Expanded(
              child: Text(
                'Add Files to "${activeFolder.name}"',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 480),
          child: Obx(() {
            if (isLoadingAvailableDocs.value) {
              return AppShimmer(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) => const DocumentListTileSkeleton(),
                ),
              );
            }

            if (availableDocuments.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppConstants.paddingLarge),
                  child: Text(
                    'No available documents to add.\nUpload documents first or add existing files.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              );
            }

            return ListView.separated(
              itemCount: availableDocuments.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final doc = availableDocuments[index];
                return Obx(() {
                  final isChecked = selectedDocIdsToAdd.contains(doc.id);
                  return CheckboxListTile(
                    value: isChecked,
                    onChanged: (val) {
                      if (val == true) {
                        selectedDocIdsToAdd.add(doc.id);
                      } else {
                        selectedDocIdsToAdd.remove(doc.id);
                      }
                    },
                    title: Text(
                      doc.title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${doc.fileName} • ${doc.categoryName ?? "General"}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    dense: true,
                  );
                });
              },
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          Obx(() => ElevatedButton(
                onPressed: selectedDocIdsToAdd.isEmpty
                    ? null
                    : () async {
                        final ids = selectedDocIdsToAdd.toList();
                        Get.back();
                        await _submitAddDocumentsToFolder(activeFolder.id, ids);
                      },
                child: Text('Add (${selectedDocIdsToAdd.length}) Selected'),
              )),
        ],
      ),
    );

    try {
      final available = await _dataset.getAvailableDocumentsForFolder(activeFolder.id);
      availableDocuments.assignAll(available);
    } catch (e, st) {
      AppLogger.error('FOLDERS_CTRL', 'Error loading available docs: $e', error: e, stackTrace: st);
    } finally {
      isLoadingAvailableDocs.value = false;
    }
  }

  Future<void> _submitAddDocumentsToFolder(String folderId, List<String> docIds) async {
    try {
      await _dataset.addDocumentsToFolder(folderId: folderId, documentIds: docIds);
      AppSnackbar.showSuccess('Documents Added', '${docIds.length} files added to folder.');
      loadFolderDocuments(folderId);
    } catch (e, st) {
      AppLogger.error('FOLDERS_CTRL', 'Error adding documents: $e', error: e, stackTrace: st);
      AppSnackbar.showError('Error', e.toString());
    }
  }

  Future<void> removeDocumentFromFolder(DocumentModel doc) async {
    final activeFolder = selectedFolder.value;
    if (activeFolder == null) return;

    try {
      await _dataset.removeDocumentFromFolder(doc.id);
      folderDocuments.removeWhere((d) => d.id == doc.id);

      final index = folders.indexWhere((f) => f.id == activeFolder.id);
      if (index != -1) {
        folders[index] = folders[index].copyWith(documentCount: folderDocuments.length);
        selectedFolder.value = folders[index];
      }

      AppSnackbar.showInfo('Removed', '${doc.title} removed from folder.');
    } catch (e, st) {
      AppLogger.error('FOLDERS_CTRL', 'Error removing document: $e', error: e, stackTrace: st);
      AppSnackbar.showError('Error', e.toString());
    }
  }

  // ================= DOCUMENT ACTIONS INSIDE FOLDER =================
  Future<void> previewDocument(DocumentModel doc) async {
    AppLogger.debug('FOLDERS_CTRL', 'Previewing document: ${doc.title}');
    try {
      final resolvedUrl = (doc.isGoogleAttachment ||
              doc.filePath.startsWith('gdrive://') ||
              doc.filePath.startsWith('http://') ||
              doc.filePath.startsWith('https://'))
          ? (doc.googleAttachmentUrl ??
              (doc.filePath.startsWith('gdrive://')
                  ? 'https://drive.google.com/file/d/${doc.filePath.replaceFirst("gdrive://", "")}/preview'
                  : doc.filePath))
          : await _dataset.getSignedPreviewUrl(doc.filePath);

      if (doc.isImage) {
        ImageLightboxDialog.show(
          title: doc.title,
          imageUrl: resolvedUrl,
          fileName: doc.fileName,
          onDownload: () => downloadDocument(doc),
        );
      } else {
        PdfViewerDialog.show(
          title: doc.title,
          filePath: doc.filePath,
          signedPdfUrl: resolvedUrl,
          fileName: doc.fileName,
          onDownload: () => downloadDocument(doc),
        );
      }
    } catch (e, st) {
      AppLogger.error('FOLDERS_CTRL', 'Preview failed: $e', error: e, stackTrace: st);
      AppSnackbar.showError('Preview Failed', e.toString());
    }
  }

  Future<void> downloadDocument(DocumentModel doc) async {
    AppLogger.debug('FOLDERS_CTRL', 'Downloading document: ${doc.title}');
    try {
      if (doc.isGoogleAttachment ||
          doc.filePath.startsWith('gdrive://') ||
          doc.filePath.startsWith('http://') ||
          doc.filePath.startsWith('https://')) {
        final gUrl = doc.googleAttachmentUrl ??
            (doc.filePath.startsWith('gdrive://')
                ? 'https://drive.google.com/file/d/${doc.filePath.replaceFirst("gdrive://", "")}/view?usp=sharing'
                : doc.filePath);
        final uri = Uri.tryParse(gUrl);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }
      final signedUrl = await _dataset.getSignedPreviewUrl(doc.filePath, download: true);
      await FileApiHelper.downloadFileFromUrl(
        url: signedUrl,
        fileName: doc.fileName,
        mimeType: doc.mimeType,
      );
      AppSnackbar.showSuccess('Download Started', '${doc.fileName} is downloading.');
    } catch (e, st) {
      AppLogger.error('FOLDERS_CTRL', 'Download failed: $e', error: e, stackTrace: st);
      try {
        final fallbackUrl = await _dataset.getSignedPreviewUrl(doc.filePath, download: true);
        final uri = Uri.parse(fallbackUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {
        AppSnackbar.showError('Download Failed', e.toString());
      }
    }
  }

  Future<void> toggleFavorite(DocumentModel doc) async {
    AppLogger.debug('FOLDERS_CTRL', 'Toggling favorite: ${doc.title}');
    try {
      final isFav = await _dataset.toggleFavorite(doc.id, doc.isFavorite);
      final index = folderDocuments.indexWhere((d) => d.id == doc.id);
      if (index != -1) {
        folderDocuments[index] = folderDocuments[index].copyWith(isFavorite: isFav);
      }
    } catch (e, st) {
      AppLogger.error('FOLDERS_CTRL', 'Favorite toggle failed: $e', error: e, stackTrace: st);
      AppSnackbar.showError('Error', e.toString());
    }
  }

  Future<void> moveToTrash(DocumentModel doc) async {
    AppLogger.debug('FOLDERS_CTRL', 'Moving doc to trash: ${doc.title}');
    try {
      await _dataset.softDeleteDocument(doc.id);
      folderDocuments.removeWhere((d) => d.id == doc.id);

      final activeFolder = selectedFolder.value;
      if (activeFolder != null) {
        final index = folders.indexWhere((f) => f.id == activeFolder.id);
        if (index != -1) {
          folders[index] = folders[index].copyWith(documentCount: folderDocuments.length);
          selectedFolder.value = folders[index];
        }
      }

      AppSnackbar.showWarning('Moved to Trash', '${doc.title} moved to trash bin.');
    } catch (e, st) {
      AppLogger.error('FOLDERS_CTRL', 'Move to trash failed: $e', error: e, stackTrace: st);
      AppSnackbar.showError('Error', e.toString());
    }
  }

  void confirmMoveToTrash(DocumentModel doc) {
    DocumentDeleteDialog.show(
      documentTitle: doc.title,
      onConfirm: () => moveToTrash(doc),
    );
  }

  void navigateToUpload() {
    final activeFolder = selectedFolder.value;
    if (activeFolder != null) {
      Get.toNamed('${AppRoutes.UPLOAD}?folderId=${activeFolder.id}');
    } else {
      Get.toNamed(AppRoutes.UPLOAD);
    }
  }
}
