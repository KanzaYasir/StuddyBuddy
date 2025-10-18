import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studybuddy/config/api_config.dart';
import 'package:url_launcher/url_launcher.dart';

class FileManager extends StatefulWidget {
  final Function(String fileName, String? docId) onFileSelected;
  final String? pickedFileName;
  final String apiBase;

  const FileManager({
    required this.onFileSelected,
    this.pickedFileName,
    this.apiBase = ApiConfig.baseUrl,
    Key? key,
  }) : super(key: key);

  @override
  State<FileManager> createState() => _FileManagerState();
}

class _FileManagerState extends State<FileManager> {
  List<Map<String, dynamic>> files = [];
  Set<String> pinnedFiles = {};
  bool loading = false;
  String? selectedDocId;
  PlatformFile? _pickedFile;
  bool uploading = false;
  String _query = '';
  bool showAll = false;

  @override
  void initState() {
    super.initState();
    _fetchFiles();
    _loadPinnedFiles();
  }

  Future<void> _loadPinnedFiles() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      pinnedFiles = prefs.getStringList('pinned_files')?.toSet() ?? {};
    });
  }

  Future<void> _savePinnedFiles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('pinned_files', pinnedFiles.toList());
  }

  Future<void> _fetchFiles() async {
    setState(() => loading = true);
    try {
      final res = await http.get(Uri.parse('${widget.apiBase}/files'));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          files = List<Map<String, dynamic>>.from(body['files'] ?? []);
        });
      } else {
        Fluttertoast.showToast(msg: 'Could not load files: ${res.statusCode}');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error fetching files: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  IconData _iconForFilename(String name) {
    final ext = name.split('.').last.toLowerCase();
    if (ext == 'pdf') return Icons.picture_as_pdf;
    if (ext == 'docx' || ext == 'doc') return Icons.description;
    if (ext == 'pptx' || ext == 'ppt') return Icons.slideshow;
    return Icons.insert_drive_file;
  }

  String _formatUploadedAt(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}  '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  Future<void> _pickAndUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'pptx'],
        withData: true,
      );
      if (result == null) {
        Fluttertoast.showToast(msg: "No file selected");
        return;
      }
      _pickedFile = result.files.first;
      setState(() => uploading = true);

      final uploadUrl = '${widget.apiBase}/upload';
      var req = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      req.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _pickedFile!.bytes!,
          filename: _pickedFile!.name,
        ),
      );

      final resp = await req.send();
      final respStr = await resp.stream.bytesToString();

      if (resp.statusCode == 200) {
        final data = jsonDecode(respStr);
        Fluttertoast.showToast(msg: 'Uploaded: ${_pickedFile!.name}');
        await _fetchFiles();
        setState(() => selectedDocId = data['doc_id']);
        widget.onFileSelected(_pickedFile!.name, data['doc_id']);
      } else {
        Fluttertoast.showToast(msg: 'Upload error: $respStr');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Upload failed: $e');
    } finally {
      setState(() => uploading = false);
    }
  }

  Future<void> _deleteFile(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Delete file?'),
        content: const Text(
          'This will remove the file permanently from your local backend.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white),),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final res = await http.delete(
        Uri.parse('${widget.apiBase}/files/$docId'),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true) {
          Fluttertoast.showToast(msg: 'Deleted');
          if (selectedDocId == docId) {
            setState(() => selectedDocId = null);
            widget.onFileSelected('', null);
          }
          await _fetchFiles();
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Delete error: $e');
    }
  }

  Future<void> _openFile(String filename) async {
    final url = '${widget.apiBase}/uploads/$filename';
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        Fluttertoast.showToast(msg: 'Could not launch file');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Open failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final q = _query.trim();

    List<Map<String, dynamic>> filteredFiles = (q.isNotEmpty)
        ? files.where((f) {
            final name = (f['filename'] ?? '').toString().toLowerCase();
            return name.contains(q.toLowerCase());
          }).toList()
        : files;

    filteredFiles.sort((a, b) {
      final aPinned = pinnedFiles.contains(a['filename']);
      final bPinned = pinnedFiles.contains(b['filename']);
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      return 0;
    });

    final displayFiles = showAll
        ? filteredFiles
        : filteredFiles.take(10).toList();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: dark ? Colors.black : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Flexible(
                    child: const Text(
                      "📂 File Manager",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: uploading
                        ? const CircularProgressIndicator()
                        : const Icon(Icons.upload_file),
                    onPressed: uploading ? null : _pickAndUpload,
                    tooltip: "Upload File",
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: 'Search files...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: dark ? Colors.white10 : Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (q) => setState(() => _query = q),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : displayFiles.isEmpty
                  ? const Center(child: Text('No files found'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: displayFiles.length,
                      itemBuilder: (context, index) {
                        final f = displayFiles[index];
                        final filename = f['filename'] ?? '';
                        final docId = f['doc_id'] ?? filename;
                        final isSelected = selectedDocId == docId;
                        final pinned = pinnedFiles.contains(filename);

                        return Card(
                          color: isSelected
                              ? (dark
                                    ? Colors.blueGrey[800]
                                    : Colors.blue.shade50)
                              : (dark ? Colors.grey[900] : Colors.white),
                          elevation: isSelected ? 4 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            leading: Icon(
                              _iconForFilename(filename),
                              color: pinned
                                  ? Colors.amberAccent
                                  : (dark ? Colors.white70 : Colors.grey[800]),
                            ),
                            title: Text(
                              filename,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              _formatUploadedAt(f['uploaded_at']),
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () {
                              setState(() => selectedDocId = docId);
                              widget.onFileSelected(filename, docId);
                            },
                            trailing: PopupMenuButton<String>(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                
                              ),
                              elevation: 6,
                              icon: const Icon(Icons.more_vert),
                              onSelected: (val) async {
                                switch (val) {
                                  case 'pin':
                                    setState(() {
                                      if (pinnedFiles.contains(filename)) {
                                        pinnedFiles.remove(filename);
                                      } else {
                                        pinnedFiles.add(filename);
                                      }
                                      _savePinnedFiles();
                                    });
                                    break;
                                  case 'open':
                                    _openFile(filename);
                                    break;
                                  case 'delete':
                                    _deleteFile(docId);
                                    break;
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'pin',
                                  child: Row(
                                    children: [
                                      Icon(
                                        pinned
                                            ? Icons.push_pin
                                            : Icons.push_pin_outlined,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 5),
                                      Expanded(child: Text(pinned ? 'Unpin File' : 'Pin File')),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'open',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.open_in_new,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 5),

                                      Expanded(child: Text('Download')),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 5),
                                      Expanded(child: Text('Delete')),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (files.length > 10)
              TextButton(
                onPressed: () => setState(() => showAll = !showAll),
                child: Text(showAll ? "Show Less" : "Show All"),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
