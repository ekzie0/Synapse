import 'package:flutter/material.dart';

class TagPicker extends StatefulWidget {
  final List<String> selectedTags;
  final Function(List<String>) onTagsChanged;
  final List<String> availableTags;

  const TagPicker({
    super.key,
    required this.selectedTags,
    required this.onTagsChanged,
    required this.availableTags,
  });

  @override
  State<TagPicker> createState() => _TagPickerState();
}

class _TagPickerState extends State<TagPicker> {
  final TextEditingController _newTagController = TextEditingController();

  void _addTag(String tag) {
    if (tag.trim().isEmpty) return;
    if (widget.selectedTags.contains(tag)) return;
    
    final newTags = List<String>.from(widget.selectedTags)..add(tag.trim());
    widget.onTagsChanged(newTags);
    _newTagController.clear();
  }

  void _removeTag(String tag) {
    final newTags = List<String>.from(widget.selectedTags)..remove(tag);
    widget.onTagsChanged(newTags);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Существующие теги
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...widget.selectedTags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tag,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _removeTag(tag),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Добавление нового тега
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newTagController,
                decoration: const InputDecoration(
                  hintText: 'Новый тег',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ),
                onSubmitted: _addTag,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _addTag(_newTagController.text),
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        
        // Доступные теги (предложения)
        if (widget.availableTags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Популярные теги:', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            children: widget.availableTags
                .where((tag) => !widget.selectedTags.contains(tag))
                .map((tag) => ActionChip(
                  label: Text(tag, style: const TextStyle(fontSize: 11)),
                  onPressed: () => _addTag(tag),
                ))
                .toList(),
          ),
        ],
      ],
    );
  }
}