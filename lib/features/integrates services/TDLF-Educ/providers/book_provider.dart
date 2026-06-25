import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/open_library_service.dart';

class BookProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final DatabaseService _dbService = DatabaseService();
  final OpenLibraryService _openLibrary = OpenLibraryService();

  List<Map<String, dynamic>> _books = [];
  List<Map<String, dynamic>> _downloadedBooks = [];
  bool _isLoading = false;
  String? _errorMessage;
  final Set<String> _downloadingIds = {};
  final Set<String> _failedIds = {};

  // ── Open Library online search ──────────────────────────────────────────
  List<Map<String, dynamic>> _onlineResults = [];
  bool _onlineLoading = false;
  String? _onlineError;
  String _onlineQuery = '';
  final Map<String, double> _downloadProgress = {};

  List<Map<String, dynamic>> get books => _books;
  List<Map<String, dynamic>> get downloadedBooks => _downloadedBooks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool isDownloading(String id) => _downloadingIds.contains(id);
  bool hasFailed(String id) => _failedIds.contains(id);

  List<Map<String, dynamic>> get onlineResults => _onlineResults;
  bool get onlineLoading => _onlineLoading;
  String? get onlineError => _onlineError;
  String get onlineQuery => _onlineQuery;
  bool isBookDownloaded(String id) =>
      _downloadedBooks.any((b) => b['id'] == id);
  double? downloadProgress(String id) => _downloadProgress[id];

  // Guard against async callbacks calling notifyListeners() after the provider
  // is disposed (e.g. leaving the module while a fetch is still in flight).
  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  Future<void> fetchBooks() async {
    // Offline-first: show the local cache immediately…
    await _loadCachedBooks();
    _isLoading = _books.isEmpty;
    _errorMessage = null;
    notifyListeners();

    try {
      // …then refresh from the cloud and write through to the cache.
      final fetchedBooks = await _apiService.getBooks();
      final db = await _dbService.database;

      for (var book in fetchedBooks) {
        await db.rawInsert(
          '''INSERT INTO books (id, name, link, picture_url, course_id)
             VALUES (?, ?, ?, ?, ?)
             ON CONFLICT(id) DO UPDATE SET
               name = excluded.name,
               link = excluded.link,
               picture_url = excluded.picture_url,
               course_id = excluded.course_id''',
          [
            book['book_id'] ?? '',
            book['book_name'] ?? '',
            book['link'] ?? '',
            book['book_picture'] ?? '',
            book['course_id'] ?? '',
          ],
        );
      }

      _books = fetchedBooks;
      _errorMessage = null;
    } catch (e) {
      // Offline or fetch failed — keep the cached books we already loaded.
      if (_books.isEmpty) {
        _errorMessage = 'You are offline and have no cached books yet.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads books from the local SQLite cache and maps the columns back to the
  /// in-memory shape the UI expects (`book_id`, `book_name`, …).
  Future<void> _loadCachedBooks() async {
    try {
      final db = await _dbService.database;
      final rows = await db.query('books');
      _books = rows
          .map((r) => <String, dynamic>{
                'book_id': r['id'],
                'book_name': r['name'],
                'link': r['link'],
                'book_picture': r['picture_url'],
                'course_id': r['course_id'],
              })
          .toList();
    } catch (_) {
      // No cache yet.
    }
  }

  Future<void> loadDownloadedBooks() async {
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> result = await db.query(
        'books',
        where: 'is_downloaded = ?',
        whereArgs: [1],
      );
      _downloadedBooks = result;
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> downloadBook(String bookId, String bookUrl) async {
    _downloadingIds.add(bookId);
    _failedIds.remove(bookId);
    notifyListeners();
    try {
      final savedPath = await _apiService.downloadBook(bookId, bookUrl);
      _downloadingIds.remove(bookId);
      if (savedPath != null) {
        final db = await _dbService.database;
        await db.update(
          'books',
          {
            'is_downloaded': 1,
            'downloaded_path': savedPath,
            'downloaded_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [bookId],
        );
        await loadDownloadedBooks();
        return true;
      }
      _failedIds.add(bookId);
      notifyListeners();
      return false;
    } catch (e) {
      _downloadingIds.remove(bookId);
      _failedIds.add(bookId);
      _errorMessage = 'Error downloading book: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> addBook(Map<String, dynamic> data) async {
    try {
      final book = await _apiService.addBook(data);
      if (book != null) {
        _books.add(book);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) { return false; }
  }

  Future<bool> deleteBook(String bookId) async {
    try {
      final success = await _apiService.deleteBook(bookId);
      if (success) {
        _books.removeWhere((b) => b['book_id'] == bookId);
        notifyListeners();
      }
      return success;
    } catch (_) { return false; }
  }

  Future<bool> updateBook(String bookId, Map<String, dynamic> data) async {
    try {
      final success = await _apiService.updateBook(bookId, data);
      if (success) {
        final i = _books.indexWhere((b) => b['book_id'] == bookId);
        if (i != -1) {
          _books[i] = {..._books[i], ...data};
          notifyListeners();
        }
      }
      return success;
    } catch (_) { return false; }
  }

  List<Map<String, dynamic>> searchBooks(String query) {
    if (query.isEmpty) {
      return _books;
    }
    return _books
        .where((book) =>
            (book['book_name'] as String)
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            (book['book_id'] as String).toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // ── Open Library: discover books to read / download ──────────────────────

  /// Preloads Discover with featured public-domain classics so the tab is ready.
  Future<void> loadDiscoverDefault() async {
    if (_onlineQuery.isNotEmpty || _onlineResults.isNotEmpty) return;
    _onlineLoading = true;
    _onlineError = null;
    notifyListeners();
    try {
      _onlineResults = await _openLibrary.browse();
    } catch (_) {
      // Leave empty — the user can still search.
    } finally {
      _onlineLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchOnline(String query) async {
    _onlineQuery = query.trim();
    _onlineLoading = true;
    _onlineError = null;
    notifyListeners();
    try {
      if (_onlineQuery.isEmpty) {
        _onlineResults = await _openLibrary.browse();
      } else {
        _onlineResults = await _openLibrary.search(_onlineQuery);
        if (_onlineResults.isEmpty) {
          _onlineError = 'No books found for "$_onlineQuery".';
        }
      }
    } catch (_) {
      _onlineResults = [];
      _onlineError = 'Search failed. Check your internet connection.';
    } finally {
      _onlineLoading = false;
      notifyListeners();
    }
  }

  void clearOnlineSearch() {
    _onlineQuery = '';
    _onlineResults = [];
    _onlineError = null;
    notifyListeners();
    loadDiscoverDefault();
  }

  /// Downloads a public-domain book's PDF from the Internet Archive and stores
  /// it so it appears in the "Downloaded" tab and works offline.
  ///
  /// Returns [OnlineDownloadResult.noPdf] when the item has no downloadable PDF
  /// (read-online only) so the UI can fall back gracefully.
  Future<OnlineDownloadResult> downloadOnlineBook(
      Map<String, dynamic> book) async {
    final id = book['id'] as String;
    final ia = book['ia'] as String?;
    if (ia == null) return OnlineDownloadResult.noPdf;

    _downloadingIds.add(id);
    _failedIds.remove(id);
    _downloadProgress[id] = 0;
    notifyListeners();
    try {
      // Resolve the item's real PDF file (filename varies; may not exist).
      final url = await _openLibrary.resolveArchivePdf(ia);
      if (url == null) {
        _downloadingIds.remove(id);
        _downloadProgress.remove(id);
        notifyListeners();
        return OnlineDownloadResult.noPdf;
      }

      var lastPct = -1;
      final savedPath = await _apiService.downloadBook(
        id,
        url,
        validatePdf: true,
        onProgress: (received, total) {
          if (total > 0) {
            final pct = (received / total * 100).floor();
            if (pct != lastPct) {
              lastPct = pct;
              _downloadProgress[id] = received / total;
              notifyListeners();
            }
          }
        },
      );
      _downloadingIds.remove(id);
      _downloadProgress.remove(id);
      if (savedPath != null) {
        final db = await _dbService.database;
        await db.insert(
          'books',
          {
            'id': id,
            'name': book['title'],
            'link': url,
            'picture_url': book['cover_url'] ?? '',
            'course_id': '',
            'is_downloaded': 1,
            'downloaded_path': savedPath,
            'downloaded_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await loadDownloadedBooks();
        return OnlineDownloadResult.success;
      }
      _failedIds.add(id);
      notifyListeners();
      return OnlineDownloadResult.failed;
    } catch (_) {
      _downloadingIds.remove(id);
      _downloadProgress.remove(id);
      _failedIds.add(id);
      notifyListeners();
      return OnlineDownloadResult.failed;
    }
  }
}

/// Outcome of attempting to download a book discovered online.
enum OnlineDownloadResult { success, noPdf, failed }
