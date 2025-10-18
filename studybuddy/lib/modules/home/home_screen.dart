import 'package:flutter/material.dart';
import 'package:studybuddy/config/api_config.dart';
import 'package:studybuddy/modules/Chat/chat_screen.dart';
import 'package:studybuddy/modules/file_manager/file_manager.dart';
import 'package:studybuddy/modules/notes_sideBar/notes.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkTheme;

  const HomeScreen({
    required this.toggleTheme,
    required this.isDarkTheme,
    Key? key,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? pickedFileName;
  String? docId;

  final Map<String, List<Map<String, dynamic>>> messages = {};
  double sideBarWidth = 300;

  void handleFileSelected(String fileName, String? newDocId) {
    setState(() {
      if (docId != newDocId) {
        pickedFileName = fileName;
        docId = newDocId;

        if (docId != null && !messages.containsKey(docId)) {
          messages[docId!] = <Map<String, dynamic>>[];
        }
      }
    });
  }

  void handleNewMessage(String text, bool isUser) {
    if (docId == null) return;
    setState(() {
      messages.putIfAbsent(docId!, () => <Map<String, dynamic>>[]);
      messages[docId]!.add({"text": text, "isUser": isUser});
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> currentMessages =
        (docId != null && messages.containsKey(docId))
            ? List<Map<String, dynamic>>.from(messages[docId]!)
            : <Map<String, dynamic>>[];

    final dark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Row(
        children: [
          // Sidebar with tabs
          SizedBox(
            width: sideBarWidth,
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  // 🔹 FIXED: Wrap TabBar in Material
                  Material(
                    color: dark ? Colors.grey[900] : Colors.grey[100],
                    child: const TabBar(
                      indicator: UnderlineTabIndicator(
                        borderSide: BorderSide(
                          width: 3,
                          color: Colors.blueAccent,
                        ),
                        insets: EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                      labelColor: Colors.blueAccent,
                      unselectedLabelColor: Colors.grey,
                      indicatorSize: TabBarIndicatorSize.label,
                      tabs: [
                        Tab(
                          icon: Icon(Icons.folder, size: 20),
                          text: "Files",
                        ),
                        Tab(
                          icon: Icon(Icons.notes, size: 20),
                          text: "Notes",
                        ),
                      ],
                    ),
                  ),
                  // Tab contents
                  Expanded(
                    child: TabBarView(
                      children: [
                        FileManager(
                          onFileSelected: handleFileSelected,
                          pickedFileName: pickedFileName,
                        ),
                        NotesSidebar(apiBase: ApiConfig.baseUrl),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sidebar resizer
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: (details) {
              setState(() {
                sideBarWidth += details.delta.dx;
                if (sideBarWidth < 350) sideBarWidth = 350;
                if (sideBarWidth > 500) sideBarWidth = 500;
              });
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: Container(width: 2, color: Colors.grey[800]),
            ),
          ),

          // Chat area
          Expanded(
            child: Scaffold(
              body: ChatScreen(
                messages: currentMessages,
                onNewMessage: handleNewMessage,
                docId: docId,
                fileName: pickedFileName,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
