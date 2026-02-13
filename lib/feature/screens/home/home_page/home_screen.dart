import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../story/story_provider.dart';
import 'home_page_provider.dart';
import 'home_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homePageProvider = context.watch<HomePageProvider>();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: HomeWidgets.buildAppBar(context),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<StoryProvider>().refresh();
        },
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            Builder(
              builder: (context) => HomeWidgets.buildStoriesSection(context),
            ),
            ...homePageProvider.posts.map(
              (post) => HomeWidgets.buildPost(post),
            ),
            const SizedBox(height: 100), // Bottom padding for navigation bar
          ],
        ),
      ),
    );
  }
}
