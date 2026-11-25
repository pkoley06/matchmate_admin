import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:matchmate_admin/app/admin_shell.dart';
import 'package:matchmate_admin/app/theme.dart';
import 'package:matchmate_admin/core/widgets/admin_image.dart';
import 'package:matchmate_admin/features/auth/domain/admin_session.dart';
import 'package:matchmate_admin/features/auth/presentation/admin_auth_controller.dart';
import 'package:matchmate_admin/features/community/data/admin_community_api.dart';
import 'package:matchmate_admin/features/community/domain/admin_community_models.dart';
import 'package:matchmate_admin/features/community/presentation/community_post_screen.dart';
import 'package:matchmate_admin/features/dashboard/domain/admin_dashboard_models.dart';
import 'package:matchmate_admin/features/dashboard/presentation/dashboard_providers.dart';
import 'package:matchmate_admin/features/dashboard/presentation/overview_screen.dart';
import 'package:matchmate_admin/features/reports/data/admin_reports_repository.dart';
import 'package:matchmate_admin/features/reports/domain/admin_report_models.dart';
import 'package:matchmate_admin/features/reports/presentation/reports_screen.dart';

Map<String, dynamic> _postJson({int pending = 2, String status = 'ACTIVE'}) => {
  'id': 'post-1',
  'category': 'MARKETPLACE',
  'title': 'Selling a Symphony air cooler',
  'content': 'Used for one summer, works perfectly.',
  'priceAmount': 3500,
  'localityName': 'Salt Lake Sector V',
  'city': 'Kolkata',
  'imageUrls': ['https://cdn.example/a.jpg', 'https://cdn.example/b.jpg'],
  'likesCount': 24,
  'commentsCount': 3,
  'isPinned': false,
  'status': status,
  'createdAt': '2026-11-25T08:00:00Z',
  'authorId': 'author-1',
  'authorName': 'Ananya Ghosh',
  'pendingReports': pending,
};

Map<String, dynamic> _reportJson({
  String type = 'POST',
  String id = 'rep-1',
  String? commentId,
}) => {
  'id': id,
  'reporterId': 'u9',
  'reporterName': 'Rahul',
  'reportedUserId': 'author-1',
  'reportedUserName': 'Ananya Ghosh',
  'reportedPostId': type == 'POST' ? 'post-1' : null,
  'reportedPostTitle': type == 'POST' ? 'Selling a Symphony air cooler' : null,
  'reportedCommentId': commentId,
  'contextPostId': 'post-1',
  'contentPreview': type == 'POST'
      ? 'Selling a Symphony air cooler\n\nUsed for one summer'
      : 'DM me on WhatsApp',
  'contentMediaUrl': type == 'POST' ? 'https://cdn.example/a.jpg' : null,
  'contentAvailable': true,
  'reportType': type,
  'reason': type == 'POST' ? 'SCAM' : 'SPAM',
  'status': 'PENDING',
  'createdAt': '2026-11-25T09:00:00Z',
};

AdminPostDetail _detail() => AdminPostDetail.fromJson({
  'post': _postJson(),
  'comments': [
    {
      'id': 'c1',
      'postId': 'post-1',
      'authorId': 'u2',
      'authorName': 'Kunal',
      'content': 'DM me on WhatsApp for a cheaper deal',
      'depth': 0,
      'likesCount': 1,
      'pendingReports': 1,
      'createdAt': '2026-11-25T09:10:00Z',
    },
    {
      'id': 'c2',
      'postId': 'post-1',
      'parentId': 'c1',
      'authorId': 'author-1',
      'authorName': 'Ananya Ghosh',
      'byPostAuthor': true,
      'content': 'Please keep it here.',
      'depth': 1,
      'replyToName': 'Kunal',
      'createdAt': '2026-11-25T09:20:00Z',
    },
    {
      'id': 'c3',
      'postId': 'post-1',
      'authorId': 'u3',
      'authorName': 'Meera',
      'content': 'Is it still available?',
      'depth': 0,
      'createdAt': '2026-11-25T09:30:00Z',
    },
  ],
  'reports': [
    _reportJson(),
    _reportJson(type: 'COMMENT', id: 'rep-2', commentId: 'c1'),
  ],
  'author': {'postsCount': 4, 'liveStatuses': 1, 'listingsCount': 0},
});

class _FakeCommunityApi extends AdminCommunityApi {
  _FakeCommunityApi() : super(Dio());

  final calls = <String>[];

  @override
  Future<AdminPostDetail> getPost(String id) async => _detail();

  @override
  Future<AdminCommunityPost> removePhoto(String id, String url) async {
    calls.add('removePhoto $url');
    return AdminCommunityPost.fromJson(_postJson());
  }

  @override
  Future<AdminCommunityPost> setStatus(String id, String status) async {
    calls.add('status $status');
    return AdminCommunityPost.fromJson(_postJson(status: status));
  }

  @override
  Future<void> deleteComment(String id) async => calls.add('deleteComment $id');

  @override
  Future<void> dismissPostReports(String id) async => calls.add('dismiss $id');
}

class _FakeReports implements AdminReportsRepository {
  final resolved = <String>[];

  @override
  Future<
    ({
      List<AdminReport> content,
      int totalElements,
      int totalPages,
      bool isLast,
    })
  >
  getReports({
    String? status,
    String? type,
    int page = 0,
    int size = 20,
  }) async {
    final all = [
      AdminReport.fromJson(_reportJson()),
      AdminReport.fromJson(
        _reportJson(type: 'COMMENT', id: 'rep-2', commentId: 'c1'),
      ),
    ];
    final list = type == null
        ? all
        : all.where((r) => r.reportType == type).toList();
    return (
      content: list,
      totalElements: list.length,
      totalPages: 1,
      isLast: true,
    );
  }

  @override
  Future<AdminReport> resolveReport(
    String id,
    AdminReportResolveRequest request,
  ) async {
    resolved.add('$id ${request.action}');
    return AdminReport.fromJson(_reportJson());
  }
}

const _stats = AdminDashboardStats(
  totalUsers: 1248,
  activeUsers: 1200,
  completedOnboardingUsers: 1000,
  totalListings: 312,
  availableListings: 281,
  newUsersThisWeek: 36,
  communityPosts: 540,
  activeCommunityPosts: 530,
  liveStatuses: 47,
  liveStatusAuthors: 39,
  pendingReports: 8,
  newReportsToday: 2,
);

class _SignedIn extends AdminAuthController {
  @override
  AdminAuthState build() => const AdminAuthenticated(
    AdminSession(
      accessToken: 't',
      expiresInMs: 1000000,
      adminId: 1,
      username: 'admin',
      displayName: 'Admin',
    ),
  );
}

Future<void> _setSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _wrap(Widget child, {List overrides = const []}) => ProviderScope(
  overrides: [
    dashboardStatsProvider.overrideWith((ref) async => _stats),
    ...overrides.cast(),
  ],
  child: MaterialApp(theme: AppTheme.light, home: child),
);

void main() {
  group('models', () {
    test('a post report reads its snapshot and context post', () {
      final r = AdminReport.fromJson(_reportJson());
      expect(r.kindLabel, 'Post');
      expect(r.headline, 'Selling a Symphony air cooler');
      expect(r.contextPostId, 'post-1');
      expect(r.isCommunity, isTrue);
      final c = AdminReport.fromJson(
        _reportJson(type: 'COMMENT', commentId: 'c1'),
      );
      expect(c.headline, '“DM me on WhatsApp”');
    });

    test('a status is live until it expires when the server does not say', () {
      final s = AdminUserStatus.fromJson({
        'id': 's1',
        'createdAt': DateTime.now().toIso8601String(),
        'expiresAt': DateTime.now()
            .add(const Duration(hours: 3))
            .toIso8601String(),
      });
      expect(s.isLive, isTrue);
      expect(
        AdminUserStatus.fromJson({
          'id': 's2',
          'expiresAt': DateTime.now().toIso8601String(),
          'live': false,
        }).isLive,
        isFalse,
      );
    });

    test('older servers without pendingReports still parse', () {
      final p = AdminCommunityPost.fromJson({'id': 'p', 'status': 'ACTIVE'});
      expect(p.pendingReports, 0);
      expect(p.isFlagged, isFalse);
      expect(communityCategoryLabel('MARKETPLACE'), 'Buy & Sell');
    });
  });

  group('post page', () {
    testWidgets('shows photos, comments in thread order and reports', (
      tester,
    ) async {
      await _setSize(tester, const Size(1400, 1000));
      final api = _FakeCommunityApi();
      await tester.pumpWidget(
        _wrap(
          const CommunityPostScreen(postId: 'post-1'),
          overrides: [adminCommunityApiProvider.overrideWithValue(api)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Selling a Symphony air cooler'), findsWidgets);
      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.text('Comments (3)'), findsOneWidget);
      expect(find.text('Reports (2)'), findsOneWidget);
      expect(find.text('Post author'), findsOneWidget);
      expect(find.text('Replying to Kunal'), findsOneWidget);
      expect(
        find.textContaining('Keep post, dismiss 2 reports'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('removes the photo on screen after confirming', (tester) async {
      await _setSize(tester, const Size(1400, 1000));
      final api = _FakeCommunityApi();
      await tester.pumpWidget(
        _wrap(
          const CommunityPostScreen(postId: 'post-1'),
          overrides: [adminCommunityApiProvider.overrideWithValue(api)],
        ),
      );
      await tester.pumpAndSettle();

      // Main photo, then the two thumbnails.
      await tester.tap(find.byType(AdminNetworkImage).at(2));
      await tester.pumpAndSettle();
      expect(find.text('2 / 2'), findsOneWidget);
      await tester.tap(find.text('Remove photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Remove photo').last);
      await tester.pumpAndSettle();
      expect(api.calls, ['removePhoto https://cdn.example/b.jpg']);
    });

    testWidgets('deleting a comment says how many replies go with it', (
      tester,
    ) async {
      await _setSize(tester, const Size(1400, 1000));
      final api = _FakeCommunityApi();
      await tester.pumpWidget(
        _wrap(
          const CommunityPostScreen(postId: 'post-1'),
          overrides: [adminCommunityApiProvider.overrideWithValue(api)],
        ),
      );
      await tester.pumpAndSettle();

      final delete = find.widgetWithText(TextButton, 'Delete').first;
      await tester.ensureVisible(delete);
      await tester.pumpAndSettle();
      await tester.tap(delete);
      await tester.pumpAndSettle();
      expect(find.textContaining('the 1 reply under it'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(api.calls, ['deleteComment c1']);
    });

    testWidgets('hiding asks first, then archives the post', (tester) async {
      await _setSize(tester, const Size(1400, 1000));
      final api = _FakeCommunityApi();
      await tester.pumpWidget(
        _wrap(
          const CommunityPostScreen(postId: 'post-1'),
          overrides: [adminCommunityApiProvider.overrideWithValue(api)],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hide post'));
      await tester.pumpAndSettle();
      expect(find.text('Hide this post?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Hide post'));
      await tester.pumpAndSettle();
      expect(api.calls, ['status ARCHIVED']);
    });

    testWidgets('fits a phone screen', (tester) async {
      await _setSize(tester, const Size(360, 780));
      await tester.pumpWidget(
        _wrap(
          const CommunityPostScreen(postId: 'post-1'),
          overrides: [
            adminCommunityApiProvider.overrideWithValue(_FakeCommunityApi()),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Moderation'), findsOneWidget);
    });
  });

  group('reports', () {
    testWidgets('a post report shows the saved copy and can hide the post', (
      tester,
    ) async {
      await _setSize(tester, const Size(1200, 1000));
      final reports = _FakeReports();
      await tester.pumpWidget(
        _wrap(
          const ReportsScreen(),
          overrides: [
            adminReportsRepositoryProvider.overrideWithValue(reports),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Selling a Symphony air cooler'), findsOneWidget);
      expect(find.text('Posted by Ananya Ghosh'), findsNWidgets(2));
      expect(find.text('Delete comment'), findsOneWidget);
      expect(find.text('Suspend Ananya Ghosh'), findsNWidgets(2));

      await tester.tap(find.widgetWithText(OutlinedButton, 'Hide post'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Hide post'));
      await tester.pumpAndSettle();
      expect(reports.resolved, ['rep-1 CONTENT_REMOVED']);
    });

    testWidgets('fits a phone screen', (tester) async {
      await _setSize(tester, const Size(360, 780));
      await tester.pumpWidget(
        _wrap(
          const ReportsScreen(),
          overrides: [
            adminReportsRepositoryProvider.overrideWithValue(_FakeReports()),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('overview', () {
    for (final size in [const Size(1400, 1000), const Size(360, 780)]) {
      testWidgets('shows the numbers at ${size.width.toInt()}px', (
        tester,
      ) async {
        await _setSize(tester, size);
        await tester.pumpWidget(_wrap(const OverviewScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('1,248'), findsOneWidget);
        expect(find.text('+36 this week'), findsOneWidget);
        expect(find.text('2 new today'), findsOneWidget);
        expect(find.text('from 39 people'), findsOneWidget);
      });
    }
  });

  group('shell', () {
    GoRouter router() => GoRouter(
      initialLocation: '/b0',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => AdminShell(navigationShell: shell),
          branches: [
            for (var i = 0; i < adminDestinations.length; i++)
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/b$i',
                    builder: (_, _) => Scaffold(body: Text('page $i')),
                  ),
                ],
              ),
          ],
        ),
      ],
    );

    Widget app() => ProviderScope(
      overrides: [
        dashboardStatsProvider.overrideWith((ref) async => _stats),
        adminAuthControllerProvider.overrideWith(_SignedIn.new),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router()),
    );

    testWidgets('wide screens get the grouped sidebar with the reports badge', (
      tester,
    ) async {
      await _setSize(tester, const Size(1400, 900));
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('MODERATION'), findsOneWidget);
      expect(find.text('CONTENT'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      await tester.tap(find.text('Community'));
      await tester.pumpAndSettle();
      expect(find.text('page 6'), findsOneWidget);
    });

    testWidgets('phones get a top bar and a slide-out menu', (tester) async {
      await _setSize(tester, const Size(360, 780));
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('MODERATION'), findsNothing);
      expect(find.text('MateEazy Admin'), findsOneWidget);

      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();
      expect(find.text('MODERATION'), findsOneWidget);
      await tester.tap(find.text('Reports'));
      await tester.pumpAndSettle();
      expect(find.text('page 1'), findsOneWidget);
      expect(find.text('MODERATION'), findsNothing, reason: 'drawer closes');
    });
  });
}
