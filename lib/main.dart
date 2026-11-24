import 'package:flutter/material.dart';

void main() {
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Заметки',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const NotesPage(),
    );
  }
}

class Note {
  final int id;
  String text;
  bool isImportant;

  Note({required this.id, required this.text, this.isImportant = false});
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<Note> _notes = [];

  int _nextId = 0;
  Note? _editingNote;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _saveNote() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      if (_editingNote != null) {
        _editingNote!.text = text;
        _editingNote = null;
      } else {
        _notes.add(Note(id: _nextId++, text: text));
      }
      _controller.clear();
    });
  }

  void _deleteNote(Note note) {
    setState(() {
      _notes.remove(note);
      if (_editingNote == note) {
        _editingNote = null;
        _controller.clear();
      }
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Заметка удалена')));
  }

  void _startEditing(Note note) {
    setState(() {
      _editingNote = note;
      _controller.text = note.text;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
    _focusNode.requestFocus();
  }

  void _cancelEditing() {
    setState(() {
      _editingNote = null;
      _controller.clear();
    });
  }

  void _toggleImportant(Note note) {
    setState(() => note.isImportant = !note.isImportant);
  }

  void _resetImportant(Note note) {
    setState(() => note.isImportant = false);
  }

  void _openNote(Note note) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NoteViewPage(note: note)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _editingNote != null;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Заметки')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Введите текст заметки',
                border: const OutlineInputBorder(),
                suffixIcon: isEditing
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Отменить редактирование',
                        onPressed: _cancelEditing,
                      )
                    : null,
              ),
              onSubmitted: (_) => _saveNote(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveNote,
                child: Text(isEditing ? 'Обновить' : 'Сохранить'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Тап — открыть • Двойной тап — важная • Долгое нажатие — редактировать\n'
              'Свайп влево — удалить • Свайп вправо — снять «важную»',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _notes.isEmpty
                  ? const Center(child: Text('Заметок пока нет'))
                  : ListView.builder(
                      itemCount: _notes.length,
                      itemBuilder: (context, index) {
                        final note = _notes[index];

                        Color? cardColor;
                        if (note == _editingNote) {
                          cardColor = scheme.primaryContainer;
                        } else if (note.isImportant) {
                          cardColor = Colors.amber.shade100;
                        }

                        return Dismissible(
                          key: ValueKey(note.id),
                          direction: DismissDirection.horizontal,
                          background: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.star_border,
                                color: Colors.white),
                          ),
                          secondaryBackground: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            alignment: Alignment.centerRight,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              if (note.isImportant) {
                                _resetImportant(note);
                              }
                              return false;
                            }
                            return true;
                          },
                          onDismissed: (direction) {
                            if (direction == DismissDirection.endToStart) {
                              _deleteNote(note);
                            }
                          },
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _openNote(note),
                            onDoubleTap: () => _toggleImportant(note),
                            onLongPress: () => _startEditing(note),
                            child: Card(
                              color: cardColor,
                              child: ListTile(
                                title: Text(
                                  note.text,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: note.isImportant
                                    ? const Icon(Icons.star,
                                        color: Colors.orange)
                                    : null,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoteViewPage extends StatelessWidget {
  final Note note;

  const NoteViewPage({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заметка'),
        actions: [
          if (note.isImportant)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.star, color: Colors.orange),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: Text(
            note.text,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
