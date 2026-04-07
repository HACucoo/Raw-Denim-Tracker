import 'dart:io';
import 'package:flutter/material.dart';
import 'package:raw_denim_tracker/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/item.dart';
import '../../providers/item_providers.dart';

class ItemFormScreen extends ConsumerStatefulWidget {
  final String? itemId;
  const ItemFormScreen({super.key, this.itemId});

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _sizeController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _firstWearDate = DateTime.now();
  String? _photoPath;
  ItemCategory? _category;
  Item? _existingItem;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.itemId != null) _loadItem();
  }

  Future<void> _loadItem() async {
    final item = await ref.read(itemRepositoryProvider).getById(widget.itemId!);
    if (item != null && mounted) {
      // Validate that the photo file still exists (may be gone after migration).
      final validPhotoPath = item.photoPath != null && await File(item.photoPath!).exists()
          ? item.photoPath
          : null;
      setState(() {
        _existingItem = item;
        _brandController.text = item.brand;
        _modelController.text = item.model;
        _sizeController.text = item.size;
        _notesController.text = item.notes ?? '';
        _firstWearDate = item.firstWearDate;
        _photoPath = validPhotoPath;
        _category = item.category;
      });
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _sizeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(AppLocalizations.of(context)!.camera),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(AppLocalizations.of(context)!.gallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await picker.pickImage(source: source, imageQuality: 90);
    if (file == null) return;

    // Show crop UI — square aspect ratio to match how photos are displayed.
    final cropped = await ImageCropper().cropImage(
      sourcePath: file.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '',
          hideBottomControls: true,
          lockAspectRatio: true,
        ),
      ],
    );
    if (cropped == null || !mounted) return;

    // Copy to app's internal storage so the path stays valid across app updates.
    final appDir = await getApplicationDocumentsDirectory();
    final dest = '${appDir.path}/photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(cropped.path).copy(dest);
    if (mounted) setState(() => _photoPath = dest);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _firstWearDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _firstWearDate = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final notifier = ref.read(itemsProvider.notifier);
      if (_existingItem == null) {
        await notifier.addItem(
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          size: _sizeController.text.trim(),
          firstWearDate: _firstWearDate,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          photoPath: _photoPath,
          category: _category,
        );
      } else {
        await notifier.updateItem(_existingItem!.copyWith(
          brand: _brandController.text.trim(),
          model: _modelController.text.trim(),
          size: _sizeController.text.trim(),
          firstWearDate: _firstWearDate,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          photoPath: _photoPath,
          category: _category,
        ));
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _existingItem != null;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l10n.editItem : l10n.addItem),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photo
            GestureDetector(
              onTap: _pickImage,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 160,
                    height: 160,
                    child: _photoPath != null
                        ? Image.file(
                            File(_photoPath!),
                            fit: BoxFit.cover,
                            cacheWidth: 480,
                            cacheHeight: 480,
                            errorBuilder: (_, __, ___) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) setState(() => _photoPath = null);
                              });
                              return const SizedBox.shrink();
                            },
                          )
                        : Container(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined,
                                    size: 40,
                                    color: Theme.of(context).colorScheme.outline),
                                const SizedBox(height: 8),
                                Text(l10n.addPhoto,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.outline,
                                        )),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _brandController,
              decoration: InputDecoration(
                labelText: l10n.brand,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _modelController,
              decoration: InputDecoration(
                labelText: l10n.model,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => v == null || v.trim().isEmpty ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _sizeController,
              decoration: InputDecoration(
                labelText: l10n.size,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<ItemCategory?>(
              value: _category,
              decoration: InputDecoration(
                labelText: l10n.category,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.categoryAll)),
                DropdownMenuItem(value: ItemCategory.jeans, child: Text(l10n.categoryJeans)),
                DropdownMenuItem(value: ItemCategory.hemd, child: Text(l10n.categoryHemd)),
                DropdownMenuItem(value: ItemCategory.jacke, child: Text(l10n.categoryJacke)),
                DropdownMenuItem(value: ItemCategory.hose, child: Text(l10n.categoryHose)),
                DropdownMenuItem(value: ItemCategory.sonstiges, child: Text(l10n.categorySonstiges)),
              ],
              onChanged: (val) => setState(() => _category = val),
            ),
            const SizedBox(height: 12),

            // First wear date
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.firstWearDate,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                child: Text(DateFormat.yMMMMd(Localizations.localeOf(context).languageCode).format(_firstWearDate)),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: l10n.notes,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }
}
