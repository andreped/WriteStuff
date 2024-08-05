class Note {
  int? id;
  String title;
  String content;
  String noteColor;

  Note({
    this.id, // `id` can be null
    this.title = "Note",
    this.content = "Text",
    this.noteColor = 'red',
  });

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (id != null) {
      data['id'] = id;
    }
    data['title'] = title;
    data['content'] = content;
    data['noteColor'] = noteColor;
    return data;
  }

  @override
  String toString() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'noteColor': noteColor,
    }.toString();
  }
}
