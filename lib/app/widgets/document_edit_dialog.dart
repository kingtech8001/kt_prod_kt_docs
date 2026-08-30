import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kt_prod_kt_docs/app/data/models/document_model.dart';
import 'package:kt_prod_kt_docs/core/values/app_colors.dart';

class DocumentEditDialog extends StatefulWidget {
  final DocumentModel document;
  final Future<void> Function({
    required String title,
    String? description,
    String? documentNumber,
  })
  onSave;

  const DocumentEditDialog({
    super.key,
    required this.document,
    required this.onSave,
  });

  static void show({
    required DocumentModel document,
    required Future<void> Function({
      required String title,
      String? description,
      String? documentNumber,
    })
    onSave,
  }) {
    Get.dialog(DocumentEditDialog(document: document, onSave: onSave));
  }

  @override
  State<DocumentEditDialog> createState() => _DocumentEditDialogState();
}

class _DocumentEditDialogState extends State<DocumentEditDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _documentNumberController;
  final _isSaving = false.obs;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.document.title);
    _descriptionController = TextEditingController(
      text: widget.document.description ?? '',
    );
    _documentNumberController = TextEditingController(
      text: widget.document.documentNumber ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _documentNumberController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      Get.snackbar('Title Required', 'Enter a document title before saving.');
      return;
    }

    _isSaving.value = true;
    try {
      await widget.onSave(
        title: title,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        documentNumber: _documentNumberController.text.trim().isEmpty
            ? null
            : _documentNumberController.text.trim(),
      );
      if (Get.isDialogOpen ?? false) Get.back();
    } finally {
      _isSaving.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Document Details'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _documentNumberController,
                decoration: const InputDecoration(
                  labelText: 'Invoice / document number',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                minLines: 3,
                maxLines: 5,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        Obx(
          () => ElevatedButton(
            onPressed: _isSaving.value ? null : _save,
            child: Text(_isSaving.value ? 'Saving...' : 'Save Changes'),
          ),
        ),
      ],
    );
  }
}

class DocumentDeleteDialog extends StatelessWidget {
  final String documentTitle;
  final Future<void> Function() onConfirm;

  const DocumentDeleteDialog({
    super.key,
    required this.documentTitle,
    required this.onConfirm,
  });

  static void show({
    required String documentTitle,
    required Future<void> Function() onConfirm,
  }) {
    Get.dialog(
      DocumentDeleteDialog(documentTitle: documentTitle, onConfirm: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Move Document to Trash?'),
      content: Text(
        '"$documentTitle" will be moved to the trash. You can restore it later.',
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () async {
            await onConfirm();
            if (Get.isDialogOpen ?? false) Get.back();
          },
          child: const Text('Move to Trash'),
        ),
      ],
    );
  }
}
