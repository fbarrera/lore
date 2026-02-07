import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/story_management_service.dart';
import '../services/character_service.dart';
import '../models/story.dart';
import '../models/character.dart';
import 'story_creation_screen.dart';
import 'character_creation_screen.dart';

class CreatorDashboard extends StatefulWidget {
  const CreatorDashboard({super.key});

  @override
  State<CreatorDashboard> createState() => _CreatorDashboardState();
}

class _CreatorDashboardState extends State<CreatorDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Stories', icon: Icon(Icons.book)),
            Tab(text: 'My Characters', icon: Icon(Icons.person)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [const StoriesTab(), const CharactersTab()],
      ),
    );
  }
}

class StoriesTab extends StatelessWidget {
  const StoriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final storyService = Provider.of<StoryManagementService>(context);
    final userId = authService.user?.uid;

    if (userId == null) {
      return const Center(child: Text('Please log in to see your stories.'));
    }

    return Scaffold(
      body: FutureBuilder<List<Story>>(
        future: storyService.getStoriesByCreator(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final stories = snapshot.data ?? [];
          if (stories.isEmpty) {
            return const Center(child: Text('No stories created yet.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              childAspectRatio: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              return Semantics(
                label: 'Story: ${story.title}',
                hint: 'Double tap to edit story',
                child: Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    title: Text(story.title),
                    subtitle: Text(
                      story.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Chip(
                      label: Text(
                        story.visibility,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    onTap: () {
                      // Optional: Navigate to edit story
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StoryCreationScreen(story: story),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StoryCreationScreen(),
            ),
          );
        },
        heroTag: 'add_story',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CharactersTab extends StatelessWidget {
  const CharactersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final characterService = Provider.of<CharacterService>(context);
    final userId = authService.user?.uid;

    if (userId == null) {
      return const Center(child: Text('Please log in to see your characters.'));
    }

    return Scaffold(
      body: FutureBuilder<List<Character>>(
        future: characterService.getCharactersByCreator(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final characters = snapshot.data ?? [];
          if (characters.isEmpty) {
            return const Center(child: Text('No characters created yet.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              childAspectRatio: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: characters.length,
            itemBuilder: (context, index) {
              final character = characters[index];
              return Semantics(
                label: 'Character: ${character.name}',
                hint: 'Double tap to edit character',
                child: Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    title: Text(character.name),
                    subtitle: Text(
                      '${character.race} • ${character.occupation}',
                    ),
                    onTap: () {
                      // Optional: Navigate to edit character
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CharacterCreationScreen(character: character),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CharacterCreationScreen(),
            ),
          );
        },
        heroTag: 'add_character',
        child: const Icon(Icons.add),
      ),
    );
  }
}
