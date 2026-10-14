import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/app_exception.dart';
import '../../data/regive_repository.dart';
import '../../models/category.dart';
import '../../models/item.dart';
import '../../widgets/app_image.dart';

class ItemFormScreen extends StatefulWidget {
  final ThingItem? existingItem;

  const ItemFormScreen({super.key, this.existingItem});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _cityController;

  int? _categoryId;
  String _condition = ItemCondition.used;
  bool _isSubmitting = false;
  Uint8List? _imageBytes;

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _titleController = TextEditingController(text: item?.title ?? '');
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _cityController = TextEditingController(
      text: item?.city ?? context.read<SessionProvider>().user?.city ?? '',
    );
    _categoryId = item?.categoryId;
    _condition = item?.condition ?? ItemCondition.used;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 60,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _imageBytes = bytes);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Выберите категорию')));
      return;
    }
    if (!_isEditing && _imageBytes == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Добавьте фото вещи')));
      return;
    }

    setState(() => _isSubmitting = true);
    final repository = context.read<ReGiveRepository>();
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final city = _cityController.text.trim();

    try {
      if (_isEditing) {
        await repository.updateItem(
          widget.existingItem!.id,
          title: title,
          description: description,
          categoryId: _categoryId!,
          condition: _condition,
          city: city,
          imageBytes: _imageBytes,
        );
      } else {
        await repository.createItem(
          ownerName: context.read<SessionProvider>().user?.name ?? '',
          title: title,
          description: description,
          categoryId: _categoryId!,
          condition: _condition,
          city: city,
          imageBytes: _imageBytes!,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const categories = ItemCategory.all;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Изменить объявление' : 'Отдать вещь'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Фото вещи',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.leaf.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _imageBytes == null
                            ? AppColors.line
                            : AppColors.leaf,
                      ),
                    ),
                    child: _imageBytes == null
                        ? (_isEditing &&
                                  widget.existingItem!.imageUrl.isNotEmpty
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    AppImage(
                                      url: widget.existingItem!.imageUrl,
                                      placeholder: const SizedBox.shrink(),
                                    ),
                                    Positioned(
                                      right: 8,
                                      bottom: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.edit_outlined,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      color: AppColors.leafDark,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _isEditing
                                          ? 'Нажмите, чтобы заменить фото'
                                          : 'Добавьте фото (обязательно)',
                                      style: const TextStyle(
                                        color: AppColors.mutedInk,
                                      ),
                                    ),
                                  ],
                                ))
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(_imageBytes!, fit: BoxFit.cover),
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Название вещи'),
                  validator: (value) {
                    if (value == null || value.trim().length < 2) {
                      return 'Введите название (минимум 2 символа)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'Город'),
                ),
                const SizedBox(height: 18),
                Text(
                  'Категория',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in categories)
                      ChoiceChip(
                        label: Text(category.name),
                        avatar: Icon(category.icon, size: 16),
                        selected: _categoryId == category.id,
                        onSelected: (_) =>
                            setState(() => _categoryId = category.id),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Состояние',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _ConditionToggle(
                  condition: _condition,
                  onChanged: (value) => setState(() => _condition = value),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isEditing ? 'Сохранить' : 'Опубликовать'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConditionToggle extends StatelessWidget {
  final String condition;
  final ValueChanged<String> onChanged;

  const _ConditionToggle({required this.condition, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          _segment(label: 'В употреблении', value: ItemCondition.used),
          _segment(label: 'Новое', value: ItemCondition.newItem),
        ],
      ),
    );
  }

  Widget _segment({required String label, required String value}) {
    final selected = condition == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: double.infinity,
          decoration: BoxDecoration(
            color: selected ? AppColors.leaf : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.mutedInk,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
