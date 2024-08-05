import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart'; // Updated import for the latest Share package

import '../models/note.dart';
import '../models/notes_database.dart';
import '../theme/note_colors.dart';

const c1 = 0xFFFDFFFC, c2 = 0xFFFF595E, c3 = 0xFF374B4A, c4 = 0xFF00B1CC, c5 = 0xFFFFD65C, c6 = 0xFFB9CACA,
      c7 = 0x80374B4A, c8 = 0x3300B1CC, c9 = 0xCCFF595E, c10 = 0xFFE1BEE7, c11 = 0xFFBA68C8,
      c12 = 0xFFC5CAE9, c13 = 0xFF7986CB, c14 = 0xFFCFD8DC, c15 = 0xFF90A4AE,
      c16 = 0xFFBBDEFB, c17 = 0xFF64B5F6, c18 = 0xFFD1C4E9, c19 = 0xFF9575CD;

/*
* Read all notes stored in database and sort them based on name
*/
Future<List<Map<String, dynamic>>> readDatabase() async {
  try {
    NotesDatabase notesDb = NotesDatabase();
    await notesDb.initDatabase();
    List<Map> notesList = await notesDb.getAllNotes();
    await notesDb.closeDatabase();
    List<Map<String, dynamic>> notesData = List<Map<String, dynamic>>.from(notesList);
    notesData.sort((a, b) => (a['title']).compareTo(b['title']));
    return notesData;
  } catch (e) {
    return [{}];
  }
}

// Home Screen
class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Map<String, dynamic>> notesData = [];
  List<int> selectedNoteIds = [];

  void afterNavigatorPop() {
    setState(() {});
  }

  void handleNoteListLongPress(int id) {
    setState(() {
      if (!selectedNoteIds.contains(id)) {
        selectedNoteIds.add(id);
      }
    });
  }

  void handleNoteListTapAfterSelect(int id) {
    setState(() {
      if (selectedNoteIds.contains(id)) {
        selectedNoteIds.remove(id);
      }
    });
  }

  Future<void> handleDelete() async {
    try {
      NotesDatabase notesDb = NotesDatabase();
      await notesDb.initDatabase();
      for (int id in selectedNoteIds) {
        await notesDb.deleteNote(id);
      }
      await notesDb.closeDatabase();
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        selectedNoteIds = [];
      });
    }
  }

  Future<void> handleShare() async {
    String content = '';
    try {
      NotesDatabase notesDb = NotesDatabase();
      await notesDb.initDatabase();
      for (int id in selectedNoteIds) {
        dynamic notes = await notesDb.getNotes(id);
        if (notes != null) {
          content += notes['title'] + '\n' + notes['content'] + '\n\n';
        }
      }
      await notesDb.closeDatabase();
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        selectedNoteIds = [];
      });
    }
    await Share.share(content.trim(), subject: content.split('\n')[0]);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(c12),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(c13),
        systemOverlayStyle: SystemUiOverlayStyle.light, // Updated from brightness
        leading: (selectedNoteIds.isNotEmpty
            ? IconButton(
                onPressed: () {
                  setState(() {
                    selectedNoteIds = [];
                  });
                },
                icon: Icon(
                  Icons.close,
                  color: Color(c5),
                ),
              )
            : Container()),
        title: Text(
          selectedNoteIds.isNotEmpty
              ? 'Selected ${selectedNoteIds.length}/${notesData.length}'
              : 'WriteStuff',
          style: TextStyle(
            color: const Color(c1),
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          if (selectedNoteIds.isNotEmpty)
            IconButton(
              onPressed: () {
                setState(() {
                  selectedNoteIds = notesData.map((item) => item['id'] as int).toList();
                });
              },
              icon: Icon(
                Icons.done_all,
                color: Color(c5),
              ),
            )
        ],
      ),
      floatingActionButton: selectedNoteIds.isEmpty
          ? FloatingActionButton(
              child: const Icon(
                Icons.add,
                color: const Color(c1),
              ),
              tooltip: 'New Notes',
              backgroundColor: const Color(c13),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/notes_edit',
                  arguments: [
                    'new',
                    [{}],
                  ],
                ).then((dynamic value) {
                  afterNavigatorPop();
                });
                return;
              },
            )
          : null,
      body: FutureBuilder(
        future: readDatabase(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            notesData = snapshot.data!;
            return Stack(
              children: <Widget>[
                // Display Notes
                AllNoteLists(
                  snapshot.data,
                  selectedNoteIds,
                  afterNavigatorPop,
                  handleNoteListLongPress,
                  handleNoteListTapAfterSelect,
                ),
                // Bottom Action Bar when Long Pressed
                if (selectedNoteIds.isNotEmpty)
                  BottomActionBar(
                    handleDelete: handleDelete,
                    handleShare: handleShare,
                  ),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error loading notes'),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(
                backgroundColor: Color(c3),
              ),
            );
          }
        },
      ),
    );
  }
}

// Display all notes
class AllNoteLists extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final List<int> selectedNoteIds;
  final VoidCallback afterNavigatorPop;
  final Function(int) handleNoteListLongPress;
  final Function(int) handleNoteListTapAfterSelect;

  AllNoteLists(
    this.data,
    this.selectedNoteIds,
    this.afterNavigatorPop,
    this.handleNoteListLongPress,
    this.handleNoteListTapAfterSelect,
  );

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        dynamic item = data[index];
        return DisplayNotes(
          item,
          selectedNoteIds,
          selectedNoteIds.contains(item['id']),
          afterNavigatorPop,
          handleNoteListLongPress,
          handleNoteListTapAfterSelect,
        );
      },
    );
  }
}

// A Note view showing title, first line of note and color
class DisplayNotes extends StatelessWidget {
  final Map<String, dynamic> notesData;
  final List<int> selectedNoteIds;
  final bool selectedNote;
  final VoidCallback callAfterNavigatorPop;
  final Function(int) handleNoteListLongPress;
  final Function(int) handleNoteListTapAfterSelect;

  DisplayNotes(
    this.notesData,
    this.selectedNoteIds,
    this.selectedNote,
    this.callAfterNavigatorPop,
    this.handleNoteListLongPress,
    this.handleNoteListTapAfterSelect,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: Material(
        elevation: 1,
        color: selectedNote ? Color(c8) : Color(c1),
        clipBehavior: Clip.hardEdge,
        borderRadius: BorderRadius.circular(5.0),
        child: InkWell(
          onTap: () {
            if (!selectedNote) {
              if (selectedNoteIds.isEmpty) {
                Navigator.pushNamed(
                  context,
                  '/notes_edit',
                  arguments: [
                    'update',
                    notesData,
                  ],
                ).then((dynamic value) {
                  callAfterNavigatorPop();
                });
                return;
              } else {
                handleNoteListLongPress(notesData['id']);
              }
            } else {
              handleNoteListTapAfterSelect(notesData['id']);
            }
          },
          onLongPress: () {
            handleNoteListLongPress(notesData['id']);
          },
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selectedNote
                              ? Color(c6)
                              : Color(NoteColors[notesData['noteColor']]['b']),
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: selectedNote
                              ? Icon(
                                  Icons.check,
                                  color: Color(c1),
                                  size: 21,
                                )
                              : Text(
                                  notesData['title'][0],
                                  style: TextStyle(
                                    color: Color(c1),
                                    fontSize: 21,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        notesData['title'] ?? "",
                        style: TextStyle(
                          color: Color(c3),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        height: 3,
                      ),
                      Text(
                        notesData['content']?.split('\n')[0] ?? "",
                        style: TextStyle(
                          color: Color(c6),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// BottomAction bar contains options like Delete, Share...
class BottomActionBar extends StatelessWidget {
  final VoidCallback handleDelete;
  final VoidCallback handleShare;

  BottomActionBar({
    required this.handleDelete,
    required this.handleShare,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      child: Container(
        width: MediaQuery.of(context).size.width,
        child: Material(
          elevation: 2,
          color: Color(c7),
          clipBehavior: Clip.hardEdge,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                InkResponse(
                  onTap: handleDelete,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.delete,
                        color: Color(c1),
                        semanticLabel: 'Delete',
                      ),
                      Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: Color(c1),
                        ),
                      ),
                    ],
                  ),
                ),
                InkResponse(
                  onTap: handleShare,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.share,
                        color: Color(c1),
                        semanticLabel: 'Share',
                      ),
                      Text(
                        'Share',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: Color(c1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
