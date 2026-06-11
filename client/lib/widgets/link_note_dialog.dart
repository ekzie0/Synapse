import 'package:flutter/material.dart';
import 'package:synapse/database/models/note_model.dart';

class LinkNoteDialog extends StatefulWidget {
  final List<Note> allNotes;

  const LinkNoteDialog({Key? key, required this.allNotes}) : super(key: key);

  @override
  State<LinkNoteDialog> createState() => _LinkNoteDialogState();
}

class _LinkNoteDialogState extends State<LinkNoteDialog> {
  String _query = '';
  late List<Note> _filteredNotes;

  @override
  void initState() {
    super.initState();
    _filteredNotes = widget.allNotes;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        // 🔥 Исправлено: теперь компилятор не будет ругаться
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Связать с заметкой', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  _query = value;
                  _filteredNotes = widget.allNotes
                      .where((n) => n.title.toLowerCase().contains(_query.toLowerCase()))
                      .toList();
                });
              },
              decoration: InputDecoration(
                hintText: 'Поиск заметки...',
                prefixIcon: const Icon(Icons.search, size: 18),
                fillColor: theme.colorScheme.brightness == Brightness.dark 
                    ? Colors.grey[800] 
                    : Colors.grey[100],
                filled: true,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), 
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              child: _filteredNotes.isNotEmpty
                  ? ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredNotes.length,
                      itemBuilder: (context, index) {
                        final note = _filteredNotes[index];
                        return ListTile(
                          leading: const Icon(Icons.link, size: 18, color: Colors.blueAccent),
                          title: Text(note.title, style: const TextStyle(fontSize: 14)),
                          onTap: () {
                            Navigator.pop(context, note.title); 
                          },
                        );
                      },
                    )
                  : const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('Заметки не найдены', style: TextStyle(color: Colors.grey)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}