import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cloud data access via Supabase (Postgres tables), plus a Dio client used
/// only to download book PDFs from their public URLs.
///
/// Read methods (`getBooks`, `getQuizzes`) intentionally let network errors
/// propagate so callers can fall back to their local SQLite cache when offline.
/// Write methods swallow errors and report success/failure via their return.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  final Dio _dio = Dio();

  factory ApiService() => _instance;

  ApiService._internal();

  SupabaseClient get _sb => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getBooks() async {
    final data = await _sb.from('books').select();
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getQuizzes() async {
    final data = await _sb.from('quizzes').select();
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getCourses() async {
    final data = await _sb.from('courses').select();
    return List<Map<String, dynamic>>.from(data);
  }

  /// Adds a course (teachers only — enforced by Supabase RLS).
  Future<bool> addCourse(Map<String, dynamic> data) async {
    try {
      await _sb.from('courses').insert(data);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCourse(String courseId) async {
    try {
      await _sb.from('courses').delete().eq('id', courseId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Renames/edits a course (teachers only — enforced by Supabase RLS).
  Future<bool> updateCourse(String courseId, Map<String, dynamic> data) async {
    try {
      await _sb.from('courses').update(data).eq('id', courseId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Downloads a book PDF and returns the local file path, or null on failure.
  ///
  /// [onProgress] reports (received, total) bytes. When [validatePdf] is true the
  /// saved file is checked for the `%PDF` header and discarded if it's actually
  /// an HTML error page (common when an Archive.org file isn't really available).
  Future<String?> downloadBook(
    String bookId,
    String url, {
    String ext = 'pdf',
    void Function(int received, int total)? onProgress,
    bool validatePdf = false,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final booksDir = Directory(p.join(dir.path, 'books'));
      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }
      final savePath = p.join(booksDir.path, '$bookId.$ext');
      final response = await _dio.download(
        url,
        savePath,
        onReceiveProgress: onProgress,
        options: Options(
          // Allow large scans, but fail if the stream stalls (no data for 60s).
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
          followRedirects: true,
          maxRedirects: 5,
          headers: const {'User-Agent': 'TDLF-Educ/1.0'},
          validateStatus: (s) => s != null && s >= 200 && s < 400,
        ),
      );
      if (response.statusCode == 200) {
        if (validatePdf && !await _looksLikePdf(savePath)) {
          try {
            await File(savePath).delete();
          } catch (_) {}
          return null;
        }
        return savePath;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Checks the first bytes for the `%PDF` magic number.
  Future<bool> _looksLikePdf(String path) async {
    try {
      final raf = await File(path).open();
      final bytes = await raf.read(5);
      await raf.close();
      return bytes.length >= 4 &&
          bytes[0] == 0x25 && // %
          bytes[1] == 0x50 && // P
          bytes[2] == 0x44 && // D
          bytes[3] == 0x46; // F
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> addBook(Map<String, dynamic> data) async {
    try {
      final res = await _sb.from('books').insert(data).select().single();
      return Map<String, dynamic>.from(res);
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteBook(String bookId) async {
    try {
      await _sb.from('books').delete().eq('book_id', bookId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Edits an existing book (teachers only — enforced by Supabase RLS).
  /// Only the keys present in [data] are changed.
  Future<bool> updateBook(String bookId, Map<String, dynamic> data) async {
    try {
      await _sb.from('books').update(data).eq('book_id', bookId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> addQuiz(Map<String, dynamic> data) async {
    try {
      final res = await _sb.from('quizzes').insert(data).select().single();
      return Map<String, dynamic>.from(res);
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteQuiz(String quizId) async {
    try {
      await _sb.from('quizzes').delete().eq('quiz_id', quizId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Edits an existing quiz (teachers only — enforced by Supabase RLS).
  /// Only the keys present in [data] are changed.
  Future<bool> updateQuiz(String quizId, Map<String, dynamic> data) async {
    try {
      await _sb.from('quizzes').update(data).eq('quiz_id', quizId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> submitQuizResults(Map<String, dynamic> data) async {
    try {
      await _sb.from('quiz_results').insert(data);
      return true;
    } catch (_) {
      // Fallback for projects whose quiz_results table doesn't have the
      // course_id column yet — submission must still succeed.
      if (data.containsKey('course_id')) {
        try {
          final copy = Map<String, dynamic>.from(data)..remove('course_id');
          await _sb.from('quiz_results').insert(copy);
          return true;
        } catch (_) {}
      }
      return false;
    }
  }

  /// All submitted quiz results (teacher "monitor students" view).
  Future<List<Map<String, dynamic>>> getStudents() async {
    try {
      final data = await _sb.from('quiz_results').select();
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  /// One student's own quiz results from the cloud — lets the profile's stats
  /// (accuracy, answers) sync across devices instead of starting from zero.
  Future<List<Map<String, dynamic>>> getMyResults(String studentId) async {
    try {
      final data = await _sb
          .from('quiz_results')
          .select()
          .eq('student_id', studentId)
          .order('submitted_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  /// Saves per-question attempts to the cloud so the History tab syncs across
  /// devices / the embedded app. Best-effort: if the table doesn't exist yet
  /// (SQL not run), it silently no-ops and history stays local.
  Future<void> submitAttempts(List<Map<String, dynamic>> attempts) async {
    if (attempts.isEmpty) return;
    try {
      await _sb.from('quiz_attempts').insert(attempts);
    } catch (_) {}
  }

  /// One student's own per-question attempts (the History tab). Throws if the
  /// cloud is unreachable / the table is missing, so callers can fall back to
  /// the local cache.
  Future<List<Map<String, dynamic>>> getMyAttempts(String studentId) async {
    final data = await _sb
        .from('quiz_attempts')
        .select()
        .eq('student_id', studentId)
        .order('submitted_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }
}
