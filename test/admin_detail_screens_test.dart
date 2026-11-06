import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matchmate_admin/core/uploads/admin_upload_api.dart';
import 'package:matchmate_admin/features/branding/data/admin_branding_repository.dart';
import 'package:matchmate_admin/features/branding/domain/admin_branding_models.dart';
import 'package:matchmate_admin/features/branding/presentation/branding_screen.dart';
import 'package:matchmate_admin/features/comments/data/admin_comments_repository.dart';
import 'package:matchmate_admin/features/comments/domain/admin_comment_models.dart';
import 'package:matchmate_admin/features/rooms/data/admin_rooms_repository.dart';
import 'package:matchmate_admin/features/rooms/domain/admin_room_models.dart';
import 'package:matchmate_admin/features/rooms/presentation/room_detail_screen.dart';
import 'package:matchmate_admin/features/rooms/presentation/room_form_dialog.dart';
import 'package:matchmate_admin/features/users/data/admin_users_repository.dart';
import 'package:matchmate_admin/features/users/domain/admin_user_models.dart';
import 'package:matchmate_admin/features/users/presentation/user_detail_screen.dart';

const _room = AdminRoomDetail(
  id: 'room-1',
  hostUserId: 'user-1',
  hostUserName: 'Asha Host',
  title: 'Sunny room in Koramangala',
  listingType: 'HAVE_ROOM',
  roomType: 'PRIVATE_ROOM',
  furnishingStatus: 'FULLY_FURNISHED',
  rentAmount: 15000,
  depositAmount: 30000,
  latitude: 12.9352,
  longitude: 77.6245,
  localityName: 'Koramangala',
  city: 'Bengaluru',
  description: 'Bright corner room.',
  photoUrls: ['https://bucket.example/listings/a.jpg'],
  amenities: ['WiFi'],
  isAvailable: true,
  likesCount: 4,
  commentsCount: 2,
);

AdminComment _comment(String id, String author, String text) => AdminComment(
  id: id,
  listingId: 'room-1',
  listingTitle: 'Sunny room in Koramangala',
  listingHostUserId: 'user-1',
  authorUserId: 'author-$id',
  authorName: author,
  content: text,
  createdAt: DateTime(2026, 11, 1, 10),
);

class _FakeRooms implements AdminRoomsRepository {
  AdminRoomDetail room = _room;
  final updates = <AdminRoomUpdateRequest>[];
  String? listedHostUserId;

  @override
  Future<AdminRoomDetail> getRoom(String id) async => room;

  @override
  Future<AdminRoomDetail> updateRoom(
    String id,
    AdminRoomUpdateRequest request,
  ) async {
    updates.add(request);
    return room;
  }

  @override
  Future<AdminRoomPage> listRooms({
    String? search,
    bool? available,
    String? hostUserId,
    int page = 0,
    int size = 20,
  }) async {
    listedHostUserId = hostUserId ?? listedHostUserId;
    return const AdminRoomPage(
      content: [
        AdminRoomSummary(
          id: 'room-1',
          title: 'Sunny room in Koramangala',
          hostUserId: 'user-1',
          isAvailable: true,
        ),
      ],
      page: 0,
      size: 20,
      totalElements: 1,
      totalPages: 1,
      isLast: true,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeComments implements AdminCommentsRepository {
  final comments = [
    _comment('c1', 'Ravi', 'Is the deposit negotiable?'),
    _comment('c2', 'Meera', 'Looks lovely!'),
  ];
  final deleted = <String>[];
  String? listedListingId;

  @override
  Future<AdminCommentPage> list({
    String? search,
    String? listingId,
    int page = 0,
    int size = 20,
  }) async {
    listedListingId = listingId;
    return AdminCommentPage(
      content: List.of(comments),
      page: 0,
      totalElements: comments.length,
      totalPages: 1,
      isLast: true,
    );
  }

  @override
  Future<void> delete(String id) async {
    deleted.add(id);
    comments.removeWhere((c) => c.id == id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUsers implements AdminUsersRepository {
  AdminUserDetail user = const AdminUserDetail(
    id: 'user-1',
    fullName: 'Asha Host',
    gender: 'FEMALE',
    dateOfBirth: '1996-04-02',
    isActive: true,
    onboardingCompleted: true,
  );
  final updates = <AdminUserUpdateRequest>[];

  @override
  Future<AdminUserDetail> getUser(String id) async => user;

  @override
  Future<AdminUserDetail> updateUser(
    String id,
    AdminUserUpdateRequest request,
  ) async {
    updates.add(request);
    final avatar = request.avatarUrl;
    if (avatar != null) {
      user = AdminUserDetail(
        id: user.id,
        fullName: user.fullName,
        gender: user.gender,
        dateOfBirth: user.dateOfBirth,
        avatarUrl: avatar.isEmpty ? null : avatar,
        isActive: true,
        onboardingCompleted: true,
      );
    }
    return user;
  }

  @override
  Future<AdminUserPage> listUsers({
    String? search,
    int page = 0,
    int size = 20,
  }) async => const AdminUserPage(
    content: [],
    page: 0,
    size: 20,
    totalElements: 0,
    totalPages: 0,
    isLast: true,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePicker extends AdminImagePicker {
  const _FakePicker(this.count);

  final int count;

  @override
  Future<List<PickedImage>> pick({bool multiple = false}) async => [
    for (var i = 0; i < (multiple ? count : 1); i++)
      PickedImage(name: 'pick-$i.jpg', bytes: Uint8List.fromList([1, 2, 3])),
  ];
}

class _FakeUploads implements AdminUploadApi {
  final profileUploads = <String?>[];
  final listingUploads = <int>[];
  final brandingUploads = <BrandingImageKind>[];

  @override
  Future<String> uploadProfilePhoto(PickedImage image, {String? userId}) async {
    profileUploads.add(userId);
    return 'https://bucket.example/profile/$userId/new.jpg';
  }

  @override
  Future<List<String>> uploadListingPhotos(
    List<PickedImage> images, {
    String? hostUserId,
  }) async {
    listingUploads.add(images.length);
    return [
      for (final image in images)
        'https://bucket.example/listings/${image.name}',
    ];
  }

  @override
  Future<String> uploadBrandingImage(
    PickedImage image,
    BrandingImageKind kind,
  ) async {
    brandingUploads.add(kind);
    return 'https://bucket.example/branding/${kind.apiValue}.png';
  }
}

class _FakeBranding implements AdminBrandingRepository {
  _FakeBranding(this.config);

  AdminBrandingConfig config;
  final updates = <AdminBrandingUpdateRequest>[];

  @override
  Future<AdminBrandingConfig> getBranding() async => config;

  @override
  Future<AdminBrandingConfig> updateBranding(
    AdminBrandingUpdateRequest request,
  ) async {
    updates.add(request);
    return config;
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  required _FakeRooms rooms,
  _FakeComments? comments,
  _FakeUsers? users,
  _FakeUploads? uploads,
  _FakeBranding? branding,
  int pickCount = 1,
}) async {
  tester.view.physicalSize = const Size(1600, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        adminRoomsRepositoryProvider.overrideWithValue(rooms),
        adminCommentsRepositoryProvider.overrideWithValue(
          comments ?? _FakeComments(),
        ),
        adminUsersRepositoryProvider.overrideWithValue(users ?? _FakeUsers()),
        adminUploadApiProvider.overrideWithValue(uploads ?? _FakeUploads()),
        imagePickerProvider.overrideWithValue(_FakePicker(pickCount)),
        if (branding != null)
          adminBrandingRepositoryProvider.overrideWithValue(branding),
      ],
      child: MaterialApp(home: home),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('room page shows photos, details and that room\'s comments', (
    tester,
  ) async {
    final comments = _FakeComments();
    await _pump(
      tester,
      const RoomDetailScreen(roomId: 'room-1'),
      rooms: _FakeRooms(),
      comments: comments,
    );

    expect(find.text('Sunny room in Koramangala'), findsOneWidget);
    expect(find.text('Photos (1)'), findsOneWidget);
    expect(find.text('Bright corner room.'), findsOneWidget);
    expect(find.text('Asha Host'), findsOneWidget);

    // Only this room's thread is requested, and it is shown in the page.
    expect(comments.listedListingId, 'room-1');
    expect(find.text('Comments (2)'), findsOneWidget);
    expect(find.text('Is the deposit negotiable?'), findsOneWidget);
    expect(find.text('Looks lovely!'), findsOneWidget);
  });

  testWidgets('a comment can be deleted from the room page', (tester) async {
    final comments = _FakeComments();
    await _pump(
      tester,
      const RoomDetailScreen(roomId: 'room-1'),
      rooms: _FakeRooms(),
      comments: comments,
    );

    await tester.tap(find.byTooltip('Delete comment').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(comments.deleted, ['c1']);
    expect(find.text('Is the deposit negotiable?'), findsNothing);
    expect(find.text('Comments (1)'), findsOneWidget);
  });

  testWidgets('editing a room uploads new photos and saves them', (
    tester,
  ) async {
    final rooms = _FakeRooms();
    final uploads = _FakeUploads();
    await _pump(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => RoomFormDialog.show(context, initial: _room),
            child: const Text('open form'),
          ),
        ),
      ),
      rooms: rooms,
      uploads: uploads,
      pickCount: 2,
    );

    await tester.tap(find.text('open form'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Room Listing'), findsOneWidget);
    expect(find.textContaining('1 / 10'), findsOneWidget);

    await tester.tap(find.text('Add photos'));
    await tester.pumpAndSettle();
    expect(uploads.listingUploads, [2]);
    expect(find.textContaining('3 / 10'), findsOneWidget);

    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(rooms.updates, hasLength(1));
    expect(rooms.updates.single.photoUrls, [
      'https://bucket.example/listings/a.jpg',
      'https://bucket.example/listings/pick-0.jpg',
      'https://bucket.example/listings/pick-1.jpg',
    ]);
    expect(rooms.updates.single.title, 'Sunny room in Koramangala');
    // The dialog closed with the saved listing.
    expect(find.text('Edit Room Listing'), findsNothing);
  });

  testWidgets('user page changes and removes the profile photo', (
    tester,
  ) async {
    final users = _FakeUsers();
    final uploads = _FakeUploads();
    final rooms = _FakeRooms();
    await _pump(
      tester,
      const UserDetailScreen(userId: 'user-1'),
      rooms: rooms,
      users: users,
      uploads: uploads,
    );

    expect(find.text('This user has no profile photo.'), findsOneWidget);
    // Their listings are fetched by host.
    expect(rooms.listedHostUserId, 'user-1');
    expect(find.text('Listings (1)'), findsOneWidget);

    await tester.tap(find.text('Upload photo'));
    await tester.pumpAndSettle();

    expect(uploads.profileUploads, ['user-1']);
    expect(
      users.updates.single.avatarUrl,
      'https://bucket.example/profile/user-1/new.jpg',
    );
    expect(find.text('Change photo'), findsOneWidget);

    await tester.tap(find.text('Remove photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
    await tester.pumpAndSettle();

    // An empty value is what clears the photo on the server.
    expect(users.updates.last.avatarUrl, '');
    expect(find.text('This user has no profile photo.'), findsOneWidget);
  });

  testWidgets('branding saves a blank UPI amount as "cleared" and uploads the '
      'QR to the bucket', (tester) async {
    final branding = _FakeBranding(
      const AdminBrandingConfig(
        id: 1,
        appName: 'MateEazy',
        primaryColor: '#6750A4',
        maintenanceMode: false,
        developerUpiId: 'dev@upi',
        developerUpiAmount: 50,
        developerUpiNote: 'Coffee',
      ),
    );
    final uploads = _FakeUploads();
    await _pump(
      tester,
      const BrandingScreen(),
      rooms: _FakeRooms(),
      uploads: uploads,
      branding: branding,
    );

    final amountField = find.widgetWithText(TextFormField, 'UPI Amount (₹)');
    await tester.ensureVisible(amountField);
    expect(
      tester.widget<TextFormField>(amountField).controller!.text,
      '50',
    );
    await tester.enterText(amountField, '');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'UPI Payment Note'),
      'Thanks for MateEazy',
    );

    // Third image field on the page is the payment QR.
    final uploadButtons = find.text('Upload image');
    expect(uploadButtons, findsNWidgets(3));
    await tester.ensureVisible(uploadButtons.last);
    await tester.tap(uploadButtons.last);
    await tester.pumpAndSettle();
    expect(uploads.brandingUploads, [BrandingImageKind.qr]);

    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    final saved = branding.updates.single;
    expect(saved.developerUpiAmount, 0);
    expect(saved.developerUpiNote, 'Thanks for MateEazy');
    expect(saved.developerQrCodeUrl, 'https://bucket.example/branding/qr.png');
    expect(saved.toJson()['developerUpiAmount'], 0);
  });
}
