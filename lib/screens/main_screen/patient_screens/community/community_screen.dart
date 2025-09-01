import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hemophilia_manager/widgets/offline_indicator.dart';
import '../../../../services/community_service.dart';
import 'community_feed_tab.dart';
import 'community_groups_tab.dart';
import 'community_events_tab.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CommunityService _communityService = CommunityService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Check for navigation arguments in the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNavigationArguments();
    });
  }

  void _handleNavigationArguments() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('openPostId')) {
      final postId = args['openPostId'] as String;
      _openSpecificPost(postId);
    }
  }

  void _openSpecificPost(String postId) async {
    try {
      // Get the specific post by ID
      final post = await _communityService.getPostById(postId);
      if (post != null) {
        // Navigate to the post detail screen
        _expandPost(post);
      } else {
        print('Post not found: $postId');
        // Show a snackbar or toast if post is not found
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post not found')));
      }
    } catch (e) {
      print('Error opening specific post: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error loading post')));
    }
  }

  void _expandPost(Map<String, dynamic> post) {
    // This method would be implemented in the feed tab
    // For now, we'll just print a debug message
    print('Expanding post: ${post['id']}');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text('Community',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.redAccent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(FontAwesomeIcons.arrowLeft, size: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade100, width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.redAccent,
              labelColor: Colors.redAccent,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorWeight: 3,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              tabs: const [
                Tab(text: 'Feed'),
                Tab(text: 'Groups'),
                Tab(text: 'Events'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: SafeArea(
              child: TabBarView(
                controller: _tabController,
                children: [
                  CommunityFeedTab(communityService: _communityService),
                  const CommunityGroupsTab(),
                  const CommunityEventsTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
