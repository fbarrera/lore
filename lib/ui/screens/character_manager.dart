import 'package:flutter/material.dart';
import '../../core/models/character.dart';
import '../../core/services/character_service.dart';
import '../theme/lore_theme.dart';
import '../theme/responsive.dart';
import '../widgets/lore_notification.dart';
import 'character_builder.dart';
import 'character_progression.dart';

/// Character library screen: lists all saved characters with navigation
/// to the builder (create) and progression (view/edit) screens.
class CharacterManagerScreen extends StatefulWidget {
  const CharacterManagerScreen({super.key});

  @override
  State<CharacterManagerScreen> createState() => _CharacterManagerScreenState();
}

class _CharacterManagerScreenState extends State<CharacterManagerScreen> {
  final _characterService = CharacterService();
  final String _dummyUserId = 'dummy_user';
  bool _isLoading = false;
  List<Character> _characters = [];

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    setState(() => _isLoading = true);
    try {
      final characters = await _characterService.getCharacters(_dummyUserId);
      setState(() => _characters = characters);
    } catch (e) {
      if (mounted) {
        LoreNotification.show(
          context,
          'Failed to load characters: $e',
          isError: true,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCharacter(Character character) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LoreTheme.inkBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: LoreTheme.warmBrown.withValues(alpha: 0.3)),
        ),
        title: Text(
          'ERASE FROM HISTORY?',
          style: LoreTheme.sectionTitle(fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to permanently remove ${character.name}? '
          'This cannot be undone.',
          style: TextStyle(
            color: LoreTheme.parchment.withValues(alpha: 0.8),
            fontFamily: LoreTheme.serifFont,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'SPARE THEM',
              style: TextStyle(
                color: LoreTheme.warmBrown.withValues(alpha: 0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              foregroundColor: LoreTheme.parchment,
            ),
            child: const Text('ERASE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete from Firestore
        await _characterService.deleteCharacter(_dummyUserId, character.id);
        setState(() => _characters.removeWhere((c) => c.id == character.id));
        if (mounted) {
          LoreNotification.show(
            context,
            '${character.name} has been erased from history.',
          );
        }
      } catch (e) {
        if (mounted) {
          LoreNotification.show(
            context,
            'Failed to delete character: $e',
            isError: true,
          );
        }
      }
    }
  }

  String _getTopSkill(Character character) {
    if (character.skills.isEmpty) return 'No skills';
    final top = character.skills.values.reduce(
      (a, b) => a.currentLevel > b.currentLevel ? a : b,
    );
    if (top.currentLevel == 0) return 'Untrained';
    return '${top.name} Lv.${top.currentLevel}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Semantics(
          header: true,
          child: Text(
            'THE FORGE OF SOULS',
            style: LoreTheme.sectionTitle(fontSize: 18),
          ),
        ),
        centerTitle: true,
        actions: [
          Semantics(
            button: true,
            label: 'Refresh character list',
            child: IconButton(
              icon: Icon(
                Icons.refresh,
                color: LoreTheme.goldAccent.withValues(alpha: 0.7),
              ),
              onPressed: _loadCharacters,
            ),
          ),
        ],
      ),
      floatingActionButton: Semantics(
        button: true,
        label: 'Create a new character',
        child: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CharacterBuilderScreen()),
            );
            _loadCharacters(); // Refresh after returning
          },
          backgroundColor: LoreTheme.goldAccent,
          foregroundColor: LoreTheme.inkBlack,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text(
            'NEW CHARACTER',
            style: TextStyle(
              fontFamily: LoreTheme.serifFont,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: LoreTheme.goldAccent),
            )
          : _characters.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadCharacters,
              color: LoreTheme.goldAccent,
              child: ContentConstraint(
                child: ListView.builder(
                  padding: Responsive.contentPadding(context),
                  itemCount: _characters.length,
                  itemBuilder: (context, index) {
                    return _buildCharacterCard(_characters[index]);
                  },
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: LoreTheme.warmBrown.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No souls have been forged yet.',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: LoreTheme.warmBrown.withValues(alpha: 0.6),
              fontFamily: LoreTheme.serifFont,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to create your first character.',
            style: TextStyle(
              color: LoreTheme.warmBrown.withValues(alpha: 0.4),
              fontFamily: LoreTheme.serifFont,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterCard(Character character) {
    return Semantics(
      button: true,
      label:
          '${character.name}, ${character.race} ${character.occupation}. '
          'Tap to view progression.',
      child: Card(
        color: LoreTheme.deepBrown.withValues(alpha: 0.3),
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: LoreTheme.warmBrown.withValues(alpha: 0.2)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CharacterProgressionScreen(character: character),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Hero(
                  tag: 'character_${character.id}',
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: LoreTheme.deepBrown,
                    child: Text(
                      character.name.isNotEmpty
                          ? character.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: LoreTheme.goldAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: LoreTheme.serifFont,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        character.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: LoreTheme.serifFont,
                          color: LoreTheme.parchment,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${character.race} · ${character.occupation}',
                        style: TextStyle(
                          color: LoreTheme.lightBrown.withValues(alpha: 0.7),
                          fontFamily: LoreTheme.serifFont,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getTopSkill(character),
                        style: TextStyle(
                          color: LoreTheme.goldAccent.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Edit button
                Semantics(
                  button: true,
                  label: 'Edit ${character.name}',
                  child: IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: LoreTheme.warmBrown.withValues(alpha: 0.6),
                      size: 20,
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CharacterBuilderScreen(character: character),
                        ),
                      );
                      if (result == true) {
                        _loadCharacters(); // Refresh if saved
                      }
                    },
                  ),
                ),
                // Delete button
                Semantics(
                  button: true,
                  label: 'Delete ${character.name}',
                  child: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: LoreTheme.warmBrown.withValues(alpha: 0.4),
                      size: 20,
                    ),
                    onPressed: () => _deleteCharacter(character),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
