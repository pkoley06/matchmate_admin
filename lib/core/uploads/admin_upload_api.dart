import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import '../network/dio_providers.dart';

/// An image chosen from the admin's computer, ready to upload.
class PickedImage {
  const PickedImage({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

/// Opens the browser / OS file dialog for images. A provider so tests can
/// swap it for canned bytes.
final imagePickerProvider = Provider<AdminImagePicker>(
  (_) => const AdminImagePicker(),
);

class AdminImagePicker {
  const AdminImagePicker();

  /// Empty when the dialog was dismissed.
  Future<List<PickedImage>> pick({bool multiple = false}) async {
    final List<PlatformFile> files;
    if (multiple) {
      files = await FilePicker.pickFiles(type: FileType.image);
    } else {
      final file = await FilePicker.pickFile(type: FileType.image);
      files = [?file];
    }
    // Read through the file object rather than a path: the admin panel runs
    // in the browser, where a picked file has none.
    return [
      for (final file in files)
        PickedImage(name: file.name, bytes: await file.readAsBytes()),
    ];
  }
}

/// Which branding slot an image is for — decides how the server stores it
/// (the logo and the UPI QR stay lossless PNG, the splash banner is a JPEG).
enum BrandingImageKind {
  logo('logo'),
  splash('splash'),
  qr('qr');

  const BrandingImageKind(this.apiValue);
  final String apiValue;
}

final adminUploadApiProvider = Provider<AdminUploadApi>(
  (ref) => AdminUploadApi(ref.watch(apiDioProvider)),
);

/// `/api/v1/admin/uploads` — puts images in the same storage bucket the app
/// uses and returns their public URLs. Saving a URL on a user, a room or the
/// branding record is a separate call.
class AdminUploadApi {
  AdminUploadApi(this._dio);

  final Dio _dio;

  static const _base = '/api/v1/admin/uploads';

  /// Photos are recompressed server-side, which can take a moment.
  static final _options = Options(receiveTimeout: const Duration(seconds: 90));

  /// [userId] files the photo under that user; omit it while the user is
  /// still being created.
  Future<String> uploadProfilePhoto(PickedImage image, {String? userId}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_base/profile-photo',
        data: FormData.fromMap({'file': _part(image), 'userId': ?userId}),
        options: _options,
      );
      return response.data!['url'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Up to ten photos per call; the URLs come back in the order sent.
  Future<List<String>> uploadListingPhotos(
    List<PickedImage> images, {
    String? hostUserId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_base/listing-photos',
        data: FormData.fromMap({
          'files': [for (final image in images) _part(image)],
          'hostUserId': ?hostUserId,
        }),
        options: _options,
      );
      return (response.data!['urls'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<String> uploadBrandingImage(
    PickedImage image,
    BrandingImageKind kind,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_base/branding-image',
        data: FormData.fromMap({'file': _part(image), 'kind': kind.apiValue}),
        options: _options,
      );
      return response.data!['url'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  static MultipartFile _part(PickedImage image) =>
      MultipartFile.fromBytes(image.bytes, filename: image.name);
}
