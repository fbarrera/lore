import 'package:flutter/material.dart';
import '../models/character.dart';
import '../models/relationship.dart';
import '../models/skill.dart';
import '../services/character_service.dart';
import '../services/relationship_service.dart';
import 'responsive_layout.dart';

class CharacterProgressionScreen extends StatefulWidget {
  final String characterId;

  const CharacterProgressionScreen({super.key, required this.characterId});

  @override
  State<CharacterProgressionScreen> createState() =>
      _CharacterProgressionScreenState();
}

class _CharacterProgressionScreenState
    extends State<CharacterProgressionScreen> {
  final CharacterService _characterService = CharacterService();
  final RelationshipService _relationshipService = RelationshipService();

  Future<Map<String, dynamic>> _loadData() async {
    final character = await _characterService.getCharacter(widget.characterId);
    if (character == null) throw Exception('Character not found');

    final relationships = await _relationshipService
        .getRelationshipsForCharacter(widget.characterId);

    // Fetch names for other characters in relationships
    final Map<String, String> characterNames = {};
    for (var rel in relationships) {
      final otherId = rel.characterAId == widget.characterId
          ? rel.characterBId
          : rel.characterAId;
      if (!characterNames.containsKey(otherId)) {
        final otherChar = await _characterService.getCharacter(otherId);
        characterNames[otherId] = otherChar?.name ?? 'Unknown';
      }
    }

    return {
      'character': character,
      'relationships': relationships,
      'characterNames': characterNames,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Character Progression')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final character = snapshot.data!['character'] as Character;
          final relationships =
              snapshot.data!['relationships'] as List<Relationship>;
          final characterNames =
              snapshot.data!['characterNames'] as Map<String, String>;

          return ResponsiveLayout(
            mobile: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCharacterStats(character),
                  const SizedBox(height: 24),
                  _buildProgressionTimeline(character, relationships),
                  const SizedBox(height: 24),
                  _buildSkills(character.skills),
                  const SizedBox(height: 24),
                  _buildRelationships(relationships, characterNames),
                ],
              ),
            ),
            desktop: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 350,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildCharacterStats(character),
                        const SizedBox(height: 24),
                        _buildProgressionTimeline(character, relationships),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSkills(character.skills),
                        const SizedBox(height: 24),
                        _buildRelationships(relationships, characterNames),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressionTimeline(
    Character character,
    List<Relationship> relationships,
  ) {
    // Combine various events into a timeline
    final List<Map<String, dynamic>> events = [];

    // Add skill "last used" events
    for (var skill in character.skills) {
      if (skill.lastUsedAt != null) {
        events.add({
          'date': skill.lastUsedAt,
          'title': 'Used ${skill.name}',
          'description':
              'Level ${skill.currentLevel} (${skill.proficiencyTier.name})',
          'icon': Icons.bolt,
          'color': _getTierColor(skill.proficiencyTier),
        });
      }
    }

    // Add relationship history events (mocking dates if not present, or just using order)
    for (var rel in relationships) {
      for (var entry in rel.history) {
        events.add({
          'date': DateTime.now().subtract(
            const Duration(hours: 1),
          ), // Placeholder date
          'title': 'Relationship Update',
          'description': entry,
          'icon': Icons.people,
          'color': _getAffinityColor(rel.affinity),
        });
      }
    }

    // Sort by date (descending)
    events.sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Progression',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No recent progression events.'),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: events.length.clamp(0, 10),
              itemBuilder: (context, index) {
                final event = events[index];
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                event['icon'],
                                size: 16,
                                color: event['color'],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  event['title'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            event['description'],
                            style: const TextStyle(fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(event['date']),
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildCharacterStats(Character character) {
    return Semantics(
      label: 'Character statistics for ${character.name}',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                character.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Divider(),
              const SizedBox(height: 8),
              _buildStatRow(
                Icons.favorite,
                'Health',
                '${(character.health * 100).toInt()}%',
                color: Colors.red,
              ),
              _buildStatRow(
                Icons.emoji_emotions,
                'Mood',
                character.mood,
                color: Colors.orange,
              ),
              _buildStatRow(
                Icons.location_on,
                'Location',
                character.location,
                color: Colors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Semantics(
      label: '$label: $value',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(value),
          ],
        ),
      ),
    );
  }

  Widget _buildSkills(List<Skill> skills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Skills', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...skills.map(
          (skill) => Semantics(
            label:
                'Skill: ${skill.name}, Level ${skill.currentLevel}, ${skill.proficiencyTier.name}',
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              skill.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              skill.category,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getTierColor(
                              skill.proficiencyTier,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getTierColor(skill.proficiencyTier),
                            ),
                          ),
                          child: Text(
                            'Lvl ${skill.currentLevel} - ${skill.proficiencyTier.name.toUpperCase()}',
                            style: TextStyle(
                              color: _getTierColor(skill.proficiencyTier),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      label:
                          'Progress: ${(skill.experience / skill.xpToNextLevel * 100).toInt()}% to next level',
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: skill.experience / skill.xpToNextLevel,
                              minHeight: 12,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getTierColor(skill.proficiencyTier),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'XP: ${skill.experience} / ${skill.xpToNextLevel}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Max Potential: ${skill.maxPotential}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getTierColor(ProficiencyTier tier) {
    switch (tier) {
      case ProficiencyTier.nullTier:
        return Colors.grey;
      case ProficiencyTier.novice:
        return Colors.brown;
      case ProficiencyTier.apprentice:
        return Colors.green;
      case ProficiencyTier.skilled:
        return Colors.blue;
      case ProficiencyTier.expert:
        return Colors.purple;
      case ProficiencyTier.master:
        return Colors.orange;
      case ProficiencyTier.divine:
        return Colors.amber;
    }
  }

  Widget _buildRelationships(
    List<Relationship> relationships,
    Map<String, String> characterNames,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Relationships', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (relationships.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No relationships yet.'),
            ),
          )
        else
          ...relationships.map((rel) {
            final otherId = rel.characterAId == widget.characterId
                ? rel.characterBId
                : rel.characterAId;
            final otherName = characterNames[otherId] ?? 'Unknown';
            final affinityPercent = (rel.affinity + 100) / 200;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: _getAffinityColor(rel.affinity),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  otherName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: affinityPercent.clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getAffinityColor(rel.affinity),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${rel.affinity}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getAffinityColor(rel.affinity),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _getAffinityLabel(rel.affinity),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'History',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Divider(),
                        if (rel.history.isEmpty)
                          const Text('No history recorded.')
                        else
                          ...rel.history.reversed
                              .take(5)
                              .map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.history,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          entry,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        if (rel.tags.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: rel.tags
                                .map(
                                  (tag) => Chip(
                                    label: Text(
                                      tag,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Color _getAffinityColor(int affinity) {
    if (affinity >= 50) return Colors.green;
    if (affinity >= 10) return Colors.lightGreen;
    if (affinity > -10) return Colors.blue;
    if (affinity > -50) return Colors.orange;
    return Colors.red;
  }

  String _getAffinityLabel(int affinity) {
    if (affinity >= 80) return 'Soulmates';
    if (affinity >= 50) return 'Close Friends';
    if (affinity >= 20) return 'Friendly';
    if (affinity >= -10) return 'Neutral';
    if (affinity >= -40) return 'Unfriendly';
    if (affinity >= -70) return 'Hostile';
    return 'Archnemesis';
  }
}
