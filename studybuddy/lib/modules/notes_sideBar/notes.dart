import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// import 'package:url_launcher/url_launcher.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
class NotesSidebar extends StatefulWidget {
  final String apiBase;
  const NotesSidebar({super.key, required this.apiBase});

  @override
  State<NotesSidebar> createState() => _NotesSidebarState();
}

class _NotesSidebarState extends State<NotesSidebar> {
  List notes = [];
  bool isLoading = false;
  String query = '';
  
  @override
  void initState() {
    super.initState();
    fetchNotes();
  }

  /// ✅ Fetch Notes
  Future<void> fetchNotes() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse("${widget.apiBase}/notes"));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() => notes = body['notes'] ?? []);
      }
    } catch (e) {
      debugPrint("❌ Error fetching notes: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// ✅ Delete Note
  Future<void> deleteNote(String id) async {
    try {
      final res = await http.delete(Uri.parse("${widget.apiBase}/notes/$id"));
      if (res.statusCode == 200) {
        setState(() {
          notes.removeWhere((n) => n['id'].toString() == id);
        });
      }
    } catch (e) {
      debugPrint("❌ Error deleting note: $e");
    }
  }

  /// ✅ Save Note (Add or Update)
  Future<void> saveNoteToApi({
    String? id,
    required String title,
    required String content,
  }) async {
    final url = id == null
        ? Uri.parse("${widget.apiBase}/notes")
        : Uri.parse("${widget.apiBase}/notes/$id");

    final body = jsonEncode({
      "title": title.isEmpty ? "" : title,
      "content": content.isEmpty ? "" : content,
    });

    try {
      final res = await (id == null
          ? http.post(
              url,
              headers: {"Content-Type": "application/json"},
              body: body,
            )
          : http.put(
              url,
              headers: {"Content-Type": "application/json"},
              body: body,
            ));

      if (res.statusCode == 200) {
        debugPrint("✅ Note saved! Response: ${res.body}");
        await fetchNotes(); // refresh list after saving
        setState(() {}); // rebuild UI
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text("✅ Note saved successfully")),
      } else {
        debugPrint("❌ Failed to save note: ${res.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Failed to save note (Code ${res.statusCode})"),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error saving note: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Network error while saving note")),
      );
    }
  }

  /// ✅ Dialog to Create/Edit Notes
  /// ✅ Dialog to Create/Edit Notes
  Future<void> showSaveNoteDialog(
    BuildContext context, {
    Map<String, dynamic>? existingNote,
  }) async {
    final titleController = TextEditingController(
      text: existingNote?['title'] ?? "",
    );
    final contentController = TextEditingController(
      text: existingNote?['content'] ?? "",
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existingNote == null ? "Save Note" : "Edit Note"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              cursorColor: Colors.white,
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            const SizedBox(height: 10),
            TextField(
              cursorColor: Colors.white,
              controller: contentController,
              maxLines: 6,
              decoration: const InputDecoration(labelText: "Content"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () async {
              await saveNoteToApi(
                id: existingNote?['id'],
                title: titleController.text,
                content: contentController.text,
              );

              // ✅ Show snackbar once, here in the UI context

              // ✅ Close dialog safely
              Future.microtask(() {
                if (Navigator.canPop(ctx)) Navigator.pop(ctx);
              });
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// ✅ Open a Note in Viewer
  void openNoteViewer(BuildContext context, Map<String, dynamic> note) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: SelectableText(note['title'] ?? "Untitled Note"),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  showSaveNoteDialog(context, existingNote: note);
                },
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: SelectableText(
                note['content']?.isNotEmpty == true
                    ? note['content']
                    : "No content",
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
final filteredNotes = query.trim().isEmpty
    ? notes
    : notes.where((n) {
        final title = (n['title'] ?? '').toString().toLowerCase();
        final content = (n['content'] ?? '').toString().toLowerCase();
        final q = query.toLowerCase();
        return title.contains(q) || content.contains(q);
      }).toList();

    return Scaffold(
      backgroundColor: dark ? Colors.black87 : Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "🗒️ Notes",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: TextField(
    cursorColor: Colors.white,
    decoration: InputDecoration(
      hintText: 'Search notes...',
      prefixIcon: const Icon(Icons.search),
      filled: true,
      fillColor: dark ? Colors.white10 : Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
    onChanged: (val) => setState(() => query = val),
  ),
),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : notes.isEmpty
                ? const Center(
                    child: Text(
                      "No notes saved yet",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: fetchNotes,
                    child: ListView.builder(
                      itemCount: filteredNotes.length,
                      itemBuilder: (context, idx) {
                        final n = filteredNotes[idx];
                        return ListTile(
                          leading: const Icon(Icons.note),
                          title: Text(
                            n['title'] ?? 'Untitled',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            n['created_at'] ?? '',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => deleteNote(n['id'].toString()),
                          ),
                          onTap: () => openNoteViewer(context, n),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showSaveNoteDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
