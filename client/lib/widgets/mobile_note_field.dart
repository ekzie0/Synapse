import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:synapse/database/models/note_model.dart';
import 'package:synapse/providers/folder_provider.dart';

class MobileNoteField extends StatelessWidget {
  final TextEditingController controller;
  final int? currentNoteId;
  final VoidCallback onChanged;
  final TextStyle? style;

  const MobileNoteField({
    Key? key,
    required this.controller,
    required this.currentNoteId,
    required this.onChanged,
    this.style,
  }) : super(key: key);

  void _showMobileNotePicker(BuildContext context) {
    final provider = Provider.of<FolderProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Выберите заметку для ссылки', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.allNotes.length,
                  itemBuilder: (context, index) {
                    final note = provider.allNotes[index];
                    if (note.id == currentNoteId) return const SizedBox.shrink(); 
                    
                    return ListTile(
                      leading: const Icon(Icons.link),
                      title: Text(note.title),
                      onTap: () {
                        final text = controller.text;
                        final selection = controller.selection;
                        final link = '[[${note.title}]]';
                        
                        final newText = text.replaceRange(
                          selection.start >= 0 ? selection.start : text.length,
                          selection.end >= 0 ? selection.end : text.length,
                          link,
                        );
                        
                        controller.text = newText;
                        controller.selection = TextSelection.collapsed(
                          offset: (selection.start >= 0 ? selection.start : text.length) + link.length,
                        );
                        
                        Navigator.pop(context); 
                        onChanged();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: style,
      maxLines: null,
      expands: true,
      decoration: const InputDecoration(
        hintText: 'Начните писать... Используйте [[ для вставки ссылки',
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      onChanged: (value) {
        onChanged();
        if (value.endsWith('[[')) {
          _showMobileNotePicker(context);
        }
      },
    );
  }
}