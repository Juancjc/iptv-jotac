import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Reports incremental progress for an in-flight download.
typedef DownloadProgressCallback = void Function(int receivedBytes, int? totalBytes);

/// Handles the actual file transfer for a single VOD download. Queueing,
/// concurrency limits and persistence live in the download providers; this
/// class only knows how to move bytes from a URL to a local file.
class DownloadManager {
  final Dio _dio;

  DownloadManager({Dio? dio}) : _dio = dio ?? Dio();

  /// Directory where downloaded content is stored, created on first use.
  Future<Directory> getDownloadsDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'IPTV Jotac', 'Downloads'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Builds a filesystem-safe file name from a content title and extension.
  String buildFileName(String title, String? extension) {
    final sanitized = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    final ext = (extension == null || extension.isEmpty) ? 'mp4' : extension;
    return '$sanitized.$ext';
  }

  /// Downloads [url] into the downloads directory under [fileName],
  /// reporting progress via [onProgress]. Returns the absolute path of the
  /// resulting file.
  Future<String> download({
    required String url,
    required String fileName,
    required DownloadProgressCallback onProgress,
    CancelToken? cancelToken,
  }) async {
    final dir = await getDownloadsDirectory();
    final savePath = p.join(dir.path, fileName);

    await _dio.download(
      url,
      savePath,
      cancelToken: cancelToken,
      onReceiveProgress: onProgress,
      deleteOnError: true,
    );

    return savePath;
  }
}
