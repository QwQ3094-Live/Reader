import 'package:flutter/material.dart';
import 'package:epubx/epubx.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:typed_data';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  List<EpubBook> _books = [];
  bool _isLoading = false;
  String? _errorMessage;

Future<void> _pickAndReadEpub() async {
  try {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Request storage permission (for Android)
    /*if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        setState(() {
          _errorMessage = 'Storage permission denied';
        });
        return;
      }
    }*/

    // Pick EPUB file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
      allowMultiple: false,
    );

    if (result == null) return; // User canceled

    PlatformFile file = result.files.first;
    if (file.path == null && file.bytes == null) {
      setState(() {
        _errorMessage = 'No file data available';
      });
      return;
    }

    Uint8List epubBytes;
    if (file.bytes != null) {
      // Use bytes directly if available
      epubBytes = file.bytes!;
    } else {
      // Fallback to file path reading
      try {
        epubBytes = await File(file.path!).readAsBytes();
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to read file: ${e.toString()}';
        });
        return;
      }
    }

    // Parse EPUB
    try {
      EpubBook epubBook = await EpubReader.readBook(epubBytes);
      setState(() {
        _books.add(epubBook);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid EPUB file: ${e.toString()}';
      });
    }
  } catch (e) {
    setState(() {
      _errorMessage = 'Error: ${e.toString()}';
    });
    debugPrint('Error in _pickAndReadEpub: $e');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

Future<Uint8List?> _getFileBytes(String path) async {
  try {
    if (path.startsWith('content://')) {
      // Handle content URI for Android
      final file = File(path);
      return await file.readAsBytes();
    } else {
      // Regular file path
      return await File(path).readAsBytes();
    }
  } catch (e) {
    debugPrint('File reading error: $e');
    return null;
  }
}

  Widget _buildBookItem(EpubBook book) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              book.Title ?? '未知书名',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            if (book.Author != null)
              Text(
                book.Author!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _listView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: _books.length,
      itemBuilder: (context, index) {
        return _buildBookItem(_books[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('书籍'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndReadEpub,
        tooltip: 'Add',
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _books.isEmpty
                  ? const Center(child: Text('暂无书籍'))
                  : _listView(),
    );
  }
}