import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:studybuddy/config/api_config.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:io' show File; // For mobile/desktop
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

class ChatScreen extends StatefulWidget {
  final List<Map<String, dynamic>> messages; // from HomeScreen
  final Function(String, bool) onNewMessage;
  final String? docId;
  final String? fileName;

  const ChatScreen({
    required this.messages,
    required this.onNewMessage,
    required this.docId,
    required this.fileName,
    Key? key,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final String apiBase = ApiConfig.baseUrl; // ✅ centralized config
  
  Future<void> askQuestion() async {
    if (widget.docId == null) {
      Fluttertoast.showToast(msg: "Upload a file first");
      return;
    }

    if (questionController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Enter a question");
      return;
    }

    String question = questionController.text.trim();
    widget.onNewMessage(question, true);
    questionController.clear();
    _scrollToBottom();

    try {
      var response = await http.post(
        Uri.parse('$apiBase/ask'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'doc_id': widget.docId, 'query': question}),
      );

      print("📡 Response status: ${response.statusCode}");
      print("📡 Response body: ${response.body}");

      var data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final answer = data['answer'] ?? 'Document not provide this information';
        widget.onNewMessage(answer, false);
        _scrollToBottom();
      } else {
        Fluttertoast.showToast(msg: "Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Fetch failed: $e");
      Fluttertoast.showToast(msg: "Request failed: $e");
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
 Future<void> exportChat(String type) async {
  try {
    if (widget.messages.isEmpty) {
      Fluttertoast.showToast(msg: "No chat messages to export");
      return;
    }

    final url = Uri.parse('$apiBase/export/$type');
    final messages = widget.messages
        .map((m) => {
              "sender": m['isUser'] ? "You" : "AI",
              "text": m['text'],
            })
        .toList();

    final body = jsonEncode({
      "filename": widget.fileName ?? "study_notes",
      "messages": messages,
    });

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      final fileName = "${widget.fileName ?? "study_notes"}.$type";

      if (kIsWeb) {
        // ✅ Handle web: trigger browser download
        final blob = html.Blob([response.bodyBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        Fluttertoast.showToast(msg: "File downloaded as $fileName");
      } else {
        // ✅ Handle mobile/desktop
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        Fluttertoast.showToast(msg: "Exported as $type successfully");
        await OpenFilex.open(filePath);
      }
    } else {
      Fluttertoast.showToast(msg: "Export failed: ${response.statusCode}");
    }
  } catch (e) {
    Fluttertoast.showToast(msg: "Error exporting chat: $e");
  }
}


Widget buildChatBubble(Map<String, dynamic> msg) {
  final isUser = msg['isUser'] as bool;

  return Align(
    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      decoration: BoxDecoration(
        gradient: isUser
            ? const LinearGradient(colors: [Colors.blueAccent, Colors.lightBlue])
            : const LinearGradient(colors: [Colors.grey, Colors.black45]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            msg['text'],
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),

          // ✅ Show save button only for bot responses
          if (!isUser) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: IconButton(
                icon: const Icon(Icons.bookmark_add_outlined, color: Colors.white70, size: 20),
                tooltip: "Save as Note",
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () async {
                  final responseText = msg['text'];
                  final res = await http.post(
                    Uri.parse("$apiBase/notes"),
                    headers: {"Content-Type": "application/json"},
                    body: jsonEncode({
                      "id": DateTime.now().millisecondsSinceEpoch.toString(),
                      "content": responseText,
                      "created_at": DateTime.now().toIso8601String(),
                    }),
                  );
                  if (res.statusCode == 200) {
                    Fluttertoast.showToast(msg: "Saved as Note");
                  } else {
                    Fluttertoast.showToast(msg: "Failed to save note");
                  }
                },
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
Container(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  decoration: BoxDecoration(
    color: Colors.black.withOpacity(0.05),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'StudyBuddy',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      Row(
        children: [
          Tooltip(
            message: "Export as PDF",
            child: IconButton(
              icon: const Icon(Icons.picture_as_pdf_rounded,
                  color: Colors.redAccent),
              onPressed: () => exportChat("pdf"),
            ),
          ),
          Tooltip(
            message: "Export as Word",
            child: IconButton(
              icon: const Icon(Icons.description_rounded,
                  color: Colors.blueAccent),
              onPressed: () => exportChat("word"),
            ),
          ),
        ],
      ),
    ],
  ),
),

        // Chat messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: widget.messages.length,
            itemBuilder: (context, index) {
              return buildChatBubble(widget.messages[index]);
            },
          ),
        ),
        // Question input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: questionController,
                  cursorColor: Colors.blueAccent,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black26,
                    hintText: "Ask a question...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: askQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16),
                ),
                child: const Icon(Icons.send, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
