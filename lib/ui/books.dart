import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as fw;
import 'package:epubx/epubx.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:crypto/crypto.dart'; // 加入依赖：crypto: ^3.0.3
import 'dart:convert';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  Map<String, EpubBook> books = {};
  Map<String, String> coverImagePaths = {};
  bool isLoading = false;
  String? errorMessage;

  String computeHash(Uint8List bytes) {
    return sha1.convert(bytes).toString();
  }

  Future<void> pickAndReadEpub() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
      );
      if (result == null) return;

      final file = result.files.first;
      final epubBytes = file.bytes ?? await File(file.path!).readAsBytes();
      final hash = computeHash(epubBytes);

      if (books.containsKey(hash)) {
        setState(() {
          errorMessage = '该书已导入';
        });
        return;
      }

      final epubBook = await EpubReader.readBook(epubBytes);
      final coverImagePath = await _saveCoverImage(epubBook, hash);

      setState(() {
        books[hash] = epubBook;
        coverImagePaths[hash] = coverImagePath;
      });
    } catch (e) {
      setState(() => errorMessage = 'Error: ${e.toString()}');
      debugPrint('Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<String> _saveCoverImage(EpubBook book, String hash) async {
    try {
      final img.Image? coverImage = book.CoverImage;
      if (coverImage == null) return '';

      final appDir = await getApplicationDocumentsDirectory();
      final coversDir = Directory(path.join(appDir.path, 'covers'));

      if (!await coversDir.exists()) {
        await coversDir.create(recursive: true);
      }

      final filename = 'cover_$hash.jpg';
      final filePath = path.join(coversDir.path, filename);
      final file = File(filePath);

      if (await file.exists()) {
        return filePath; // 如果文件已存在，不再重复写入
      }

      final encodedBytes = Uint8List.fromList(img.encodeJpg(coverImage));
      await file.writeAsBytes(encodedBytes);

      return filePath;
    } catch (e) {
      debugPrint('Error saving cover image: $e');
      return '';
    }
  }

  Widget buildBookItem(EpubBook book, String coverPath) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (coverPath.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              ),
              child: fw.Image.file(
                File(coverPath),
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 160,
                  color: Colors.grey[200],
                  child: const Icon(Icons.book, size: 60),
                ),
              ),
            )
          else
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
              ),
              child: const Center(child: Icon(Icons.book, size: 60)),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.Title ?? '未知书名',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (book.Author != null)
                  Text(
                    book.Author!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('书籍')),
      floatingActionButton: FloatingActionButton(
        onPressed: pickAndReadEpub,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : books.isEmpty
                  ? const Center(child: Text('暂无书籍'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.65,
                      ),
                      itemCount: books.length,
                      itemBuilder: (_, index) {
                        final hash = books.keys.elementAt(index);
                        final book = books[hash]!;
                        final coverPath = coverImagePaths[hash]!;
                        return buildBookItem(book, coverPath);
                      },
                    ),
    );
  }
}
