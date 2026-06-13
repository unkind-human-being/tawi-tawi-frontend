import 'dart:convert';
import 'package:http/http.dart' as http;

/// Book discovery via Open Library (https://openlibrary.org).
///
/// - [browse] uses the Subjects API to preload Discover with featured
///   public-domain classics (so the tab is ready instantly).
/// - [search] uses the Search API for free-text queries.
/// - [resolveArchivePdf] finds the real downloadable PDF on the Internet
///   Archive for public-domain books.
///
/// Only public-domain books (`ebook_access == "public"` / `status == "open"`)
/// have a downloadable PDF; everything else is read-online only.
class OpenLibraryService {
  static const _searchUrl = 'https://openlibrary.org/search.json';
  static const _coverBase = 'https://covers.openlibrary.org/b/id';
  static const _headers = {'User-Agent': 'TDLF-Educ/1.0'};

  /// Featured browse via the Subjects API (default: classic literature).
  Future<List<Map<String, dynamic>>> browse({
    String subject = 'classic_literature',
    int limit = 30,
  }) async {
    final uri = Uri.parse('https://openlibrary.org/subjects/$subject.json')
        .replace(queryParameters: {'limit': '$limit', 'ebooks': 'true'});
    final res =
        await http.get(uri, headers: _headers).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('Open Library returned ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final works = (body['works'] as List?) ?? const [];

    return works.map<Map<String, dynamic>>((w) {
      final work = w as Map<String, dynamic>;
      final ia = work['ia']?.toString();
      final av = (work['availability'] as Map?)?.cast<String, dynamic>() ?? const {};
      final isOpen =
          work['public_scan'] == true || (av['status'] ?? '') == 'open';
      final authors = (work['authors'] as List?)?.cast<dynamic>();
      final authorNames = authors
          ?.map((a) => (a as Map)['name']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      return _normalize(
        ia: (ia != null && ia.isNotEmpty) ? ia : null,
        title: (work['title'] as String?) ?? 'Untitled',
        author: (authorNames != null && authorNames.isNotEmpty)
            ? authorNames.take(2).join(', ')
            : 'Unknown author',
        coverUrl:
            work['cover_id'] != null ? '$_coverBase/${work['cover_id']}-M.jpg' : '',
        downloadable: isOpen && ia != null && ia.isNotEmpty,
        key: (work['key'] as String?) ?? '',
      );
    }).toList();
  }

  /// Free-text search via the Search API.
  Future<List<Map<String, dynamic>>> search(String query, {int limit = 24}) async {
    final uri = Uri.parse(_searchUrl).replace(queryParameters: {
      'q': query,
      'fields': 'key,title,author_name,cover_i,ia,ebook_access',
      'limit': '$limit',
    });
    final res =
        await http.get(uri, headers: _headers).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('Open Library returned ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final docs = (body['docs'] as List?) ?? const [];

    return docs.map<Map<String, dynamic>>((d) {
      final doc = d as Map<String, dynamic>;
      final iaList = (doc['ia'] as List?)?.cast<dynamic>();
      final ia =
          (iaList != null && iaList.isNotEmpty) ? iaList.first.toString() : null;
      final access = (doc['ebook_access'] as String?) ?? 'no_ebook';
      final authors = (doc['author_name'] as List?)?.cast<dynamic>();
      return _normalize(
        ia: ia,
        title: (doc['title'] as String?) ?? 'Untitled',
        author: (authors != null && authors.isNotEmpty)
            ? authors.take(2).join(', ')
            : 'Unknown author',
        coverUrl: doc['cover_i'] != null
            ? '$_coverBase/${doc['cover_i']}-M.jpg'
            : '',
        downloadable: access == 'public' && ia != null,
        key: (doc['key'] as String?) ?? '',
      );
    }).toList();
  }

  Map<String, dynamic> _normalize({
    required String? ia,
    required String title,
    required String author,
    required String coverUrl,
    required bool downloadable,
    required String key,
  }) {
    return {
      'id': ia ?? (key.isNotEmpty ? key.replaceAll('/', '_') : title),
      'ia': ia,
      'title': title,
      'author': author,
      'cover_url': coverUrl,
      'downloadable': downloadable,
      'read_url': ia != null
          ? 'https://archive.org/details/$ia'
          : 'https://openlibrary.org$key',
    };
  }

  /// Finds the Internet Archive item's real downloadable PDF file and returns
  /// its direct data-node URL, or null if there's no PDF derivative
  /// (read-online only). Hitting the data node avoids the slow redirect path.
  Future<String?> resolveArchivePdf(String iaId) async {
    try {
      final res = await http
          .get(Uri.parse('https://archive.org/metadata/$iaId'), headers: _headers)
          .timeout(const Duration(seconds: 25));
      if (res.statusCode != 200) return null;

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final files = (body['files'] as List?) ?? const [];
      if (files.isEmpty) return null;

      Map<String, dynamic>? best;
      for (final f in files) {
        final m = f as Map<String, dynamic>;
        if ((m['format'] ?? '').toString() == 'Text PDF') {
          best = m;
          break;
        }
      }
      best ??= () {
        for (final f in files) {
          final m = f as Map<String, dynamic>;
          final fmt = (m['format'] ?? '').toString().toLowerCase();
          final name = (m['name'] ?? '').toString().toLowerCase();
          if (fmt.contains('pdf') || name.endsWith('.pdf')) return m;
        }
        return null;
      }();
      if (best == null) return null;

      final name = Uri.encodeComponent(best['name'].toString());
      final server = (body['server'] ?? body['d1'] ?? '').toString();
      final dir = (body['dir'] ?? '').toString();
      if (server.isNotEmpty && dir.isNotEmpty) {
        return 'https://$server$dir/$name';
      }
      return 'https://archive.org/download/$iaId/$name';
    } catch (_) {
      return null;
    }
  }
}
