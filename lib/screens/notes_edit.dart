import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart'; // Updated package

import '../models/note.dart';
import '../models/notes_database.dart';
import '../theme/note_colors.dart';

const c1 = Color(0xFFFDFFFC), c2 = Color(0xFFFF595E), c3 = Color(0xFF374B4A), c4 = Color(0xFF00B1CC), c5 = Color(0xFFFFD65C), c6 = Color(0xFFB9CACA), c7 = Color(0x80374B4A);

class NotesEdit extends StatefulWidget {
  final dynamic args;

  const NotesEdit(this.args);

  @override
  _NotesEditState createState() => _NotesEditState();
}

class _NotesEditState extends State<NotesEdit> {
  String noteTitle = '';
  String noteContent = '';
  String noteColor = 'blue';

  final TextEditingController _titleTextController = TextEditingController();
  final TextEditingController _contentTextController = TextEditingController();

  void onSelectAppBarPopupMenuItem(BuildContext currentContext, String optionName) {
    switch (optionName) {
      case 'Color':
        handleColor(currentContext);
        break;
      case 'Sort by A-Z':
        handleNoteSort('ascending');
        break;
      case 'Sort by Z-A':
        handleNoteSort('descending');
        break;
      case 'Share':
        handleNoteShare();
        break;
      case 'Delete':
        handleNoteDelete();
        break;
    }
  }

  void handleColor(BuildContext currentContext) {
    showDialog(
      context: currentContext,
      builder: (context) => ColorPalette(parentContext: currentContext),
    ).then((colorName) {
      if (colorName != null) {
        setState(() {
          noteColor = colorName;
        });
      }
    });
  }

  void handleNoteSort(String sortOrder) {
    List<String> sortedContentList;
    if (sortOrder == 'ascending') {
      sortedContentList = noteContent.trim().split('\n')..sort();
    } else {
      sortedContentList = noteContent.trim().split('\n')..sort((a, b) => b.compareTo(a));
    }
    String sortedContent = sortedContentList.join('\n');
    setState(() {
      noteContent = sortedContent;
    });
    _contentTextController.text = sortedContent;
  }

  void handleNoteShare() async {
    await Share.share(noteContent, subject: noteTitle);
  }

  void handleNoteDelete() async {
    if (widget.args[0] == 'update') {
      try {
        NotesDatabase notesDb = NotesDatabase();
        await notesDb.initDatabase();
        await notesDb.deleteNote(widget.args[1]['id']);
        await notesDb.closeDatabase();
      } catch (e) {
        // Handle error
      } finally {
        Navigator.pop(context);
      }
    } else {
      Navigator.pop(context);
    }
  }

  void handleTitleTextChange() {
    setState(() {
      noteTitle = _titleTextController.text.trim();
    });
  }

  void handleNoteTextChange() {
    setState(() {
      noteContent = _contentTextController.text.trim();
    });
  }

  Future<void> _insertNote(Note note) async {
    NotesDatabase notesDb = NotesDatabase();
    await notesDb.initDatabase();
    await notesDb.insertNote(note);
    await notesDb.closeDatabase();
  }

  Future<void> _updateNote(Note note) async {
    NotesDatabase notesDb = NotesDatabase();
    await notesDb.initDatabase();
    await notesDb.updateNote(note);
    await notesDb.closeDatabase();
  }

  void handleBackButton() async {
    if (noteTitle.isEmpty) {
      // Go Back without saving
      if (noteContent.isEmpty) {
        Navigator.pop(context);
        return;
      } else {
        String title = noteContent.split('\n')[0];
        if (title.length > 31) {
          title = title.substring(0, 31);
        }
        setState(() {
          noteTitle = title;
        });
      }
    }

    // Save New note
    if (widget.args[0] == 'new') {
      Note noteObj = Note(
        title: noteTitle,
        content: noteContent,
        noteColor: noteColor,
      );
      try {
        await _insertNote(noteObj);
      } catch (e) {
        // Handle error
      } finally {
        Navigator.pop(context);
      }
    }
    // Update Note
    else if (widget.args[0] == 'update') {
      Note noteObj = Note(
        id: widget.args[1]['id'],
        title: noteTitle,
        content: noteContent,
        noteColor: noteColor,
      );
      try {
        await _updateNote(noteObj);
      } catch (e) {
        // Handle error
      } finally {
        Navigator.pop(context);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    noteTitle = (widget.args[0] == 'new' ? '' : widget.args[1]['title']);
    noteContent = (widget.args[0] == 'new' ? '' : widget.args[1]['content']);
    noteColor = (widget.args[0] == 'new' ? 'indigo' : widget.args[1]['noteColor']);

    _titleTextController.text = (widget.args[0] == 'new' ? '' : widget.args[1]['title']);
    _contentTextController.text = (widget.args[0] == 'new' ? '' : widget.args[1]['content']);
    _titleTextController.addListener(handleTitleTextChange);
    _contentTextController.addListener(handleNoteTextChange);
  }

  @override
  void dispose() {
    _titleTextController.dispose();
    _contentTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        handleBackButton();
        return true;
      },
      child: Scaffold(
        backgroundColor: Color(NoteColors[this.noteColor]['l']),
        appBar: AppBar(
          backgroundColor: Color(NoteColors[this.noteColor]['b']),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: c1,
            ),
            tooltip: 'Back',
            onPressed: handleBackButton,
          ),
          title: NoteTitleEntry(_titleTextController),
          actions: [
            appBarPopMenu(
              parentContext: context,
              onSelectPopupmenuItem: onSelectAppBarPopupMenuItem,
            ),
          ],
        ),
        body: NoteEntry(_contentTextController),
      ),
    );
  }
}

class NoteTitleEntry extends StatefulWidget {
  final TextEditingController textFieldController;

  NoteTitleEntry(this.textFieldController);

  @override
  _NoteTitleEntryState createState() => _NoteTitleEntryState();
}

class _NoteTitleEntryState extends State<NoteTitleEntry> with WidgetsBindingObserver {
  FocusNode _textFieldFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
  }

  @override
  void dispose() {
    _textFieldFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.textFieldController,
      focusNode: _textFieldFocusNode,
      decoration: InputDecoration(
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        contentPadding: EdgeInsets.all(0),
        counter: null,
        counterText: "",
        hintText: 'Title',
        hintStyle: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.normal,
          height: 1.5,
          color: c3,
        ),
      ),
      maxLength: 31,
      maxLines: 1,
      style: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.bold,
        height: 1.5,
        color: c1,
      ),
      textCapitalization: TextCapitalization.words,
    );
  }
}

class NoteEntry extends StatefulWidget {
  final TextEditingController textFieldController;

  NoteEntry(this.textFieldController);

  @override
  _NoteEntryState createState() => _NoteEntryState();
}

class _NoteEntryState extends State<NoteEntry> with WidgetsBindingObserver {
  FocusNode _textFieldFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
  }

  @override
  void dispose() {
    _textFieldFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        controller: widget.textFieldController,
        focusNode: _textFieldFocusNode,
        maxLines: null,
        textCapitalization: TextCapitalization.sentences,
        decoration: null,
        style: TextStyle(
          fontSize: 19,
          height: 1.5,
        ),
      ),
    );
  }
}

class ColorPalette extends StatelessWidget {
  final BuildContext parentContext;

  const ColorPalette({required this.parentContext});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: c1,
      clipBehavior: Clip.hardEdge,
      insetPadding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2),
      ),
      child: Container(
        padding: EdgeInsets.all(8),
        child: Wrap(
          alignment: WrapAlignment.start,
          spacing: MediaQuery.of(context).size.width * 0.02,
          runSpacing: MediaQuery.of(context).size.width * 0.02,
          children: NoteColors.entries.map((entry) {
            return GestureDetector(
              onTap: () => Navigator.of(context).pop(entry.key),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.12,
                height: MediaQuery.of(context).size.width * 0.12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.06),
                  color: Color(entry.value['b']),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class appBarPopMenu extends StatelessWidget {
  final Map<int, Map<String, dynamic>> popupMenuButtonItems = const {
    1: {'name': 'Color', 'icon': Icons.color_lens},
    2: {'name': 'Sort by A-Z', 'icon': Icons.sort_by_alpha},
    3: {'name': 'Sort by Z-A', 'icon': Icons.sort_by_alpha},
    4: {'name': 'Share', 'icon': Icons.share},
    5: {'name': 'Delete', 'icon': Icons.delete},
  };
  final BuildContext parentContext;
  final void Function(BuildContext, String) onSelectPopupmenuItem;

  appBarPopMenu({required this.parentContext, required this.onSelectPopupmenuItem});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: Icon(
        Icons.more_vert,
        color: c1,
      ),
      color: c1,
      itemBuilder: (context) {
        return popupMenuButtonItems.entries.map((entry) {
          return PopupMenuItem(
            child: Container(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width * 0.3,
              ),
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(
                      entry.value['icon'],
                      color: c3,
                    ),
                  ),
                  Text(
                    entry.value['name'],
                    style: TextStyle(
                      color: c3,
                    ),
                  ),
                ],
              ),
            ),
            value: entry.key,
          );
        }).toList();
      },
      onSelected: (value) {
        onSelectPopupmenuItem(parentContext, popupMenuButtonItems[value]!['name']);
      },
    );
  }
}
