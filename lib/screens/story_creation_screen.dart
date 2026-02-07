import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/story.dart';
import '../models/character.dart';
import '../services/character_service.dart';
import '../services/story_management_service.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoryCreationScreen extends StatefulWidget {
  final Story? story;
  const StoryCreationScreen({super.key, this.story});

  @override
  State<StoryCreationScreen> createState() => _StoryCreationScreenState();
}

class _StoryCreationScreenState extends State<StoryCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagsController;

  String _visibility = 'Public';
  final List<Character> _assignedCharacters = [];
  List<Character> _availableCharacters = [];
  bool _isLoadingCharacters = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.story?.title);
    _descriptionController = TextEditingController(
      text: widget.story?.description,
    );
    _tagsController = TextEditingController(
      text: widget.story?.tags.join(', '),
    );
    _visibility = widget.story?.visibility ?? 'Public';
    _fetchCharacters();
  }

  Future<void> _fetchCharacters() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final characterService = CharacterService();

    if (authService.user != null) {
      try {
        final characters = await characterService.getCharactersByCreator(
          authService.user!.uid,
        );
        setState(() {
          _availableCharacters = characters;
          _isLoadingCharacters = false;
          if (widget.story != null) {
            _assignedCharacters.addAll(
              _availableCharacters.where(
                (c) => widget.story!.characterIds.contains(c.id),
              ),
            );
          }
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching characters: $e')),
          );
        }
        setState(() {
          _isLoadingCharacters = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _saveStory() async {
    if (_formKey.currentState!.validate()) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final storyService = StoryManagementService();

      if (authService.user == null) return;

      final storyId =
          widget.story?.id ??
          FirebaseFirestore.instance.collection('stories').doc().id;
      final now = DateTime.now();

      final story = Story(
        id: storyId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        creatorId: authService.user!.uid,
        characterIds: _assignedCharacters.map((c) => c.id).toList(),
        visibility: _visibility,
        tags: _tagsController.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
        createdAt: widget.story?.createdAt ?? now,
        updatedAt: now,
      );

      try {
        if (widget.story != null) {
          await storyService.updateStory(story);
        } else {
          await storyService.createStory(story);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.story != null
                    ? 'Story updated successfully!'
                    : 'Story saved successfully!',
              ),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to save story: $e')));
        }
      }
    }
  }

  void _addCharacter(Character character) {
    if (!_assignedCharacters.any((c) => c.id == character.id)) {
      setState(() {
        _assignedCharacters.add(character);
      });
    }
  }

  void _removeCharacter(String characterId) {
    setState(() {
      _assignedCharacters.removeWhere((c) => c.id == characterId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.story != null ? 'Edit Story' : 'Create New Story'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma-separated)',
                  border: OutlineInputBorder(),
                  hintText: 'fantasy, adventure, magic',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _visibility,
                decoration: const InputDecoration(
                  labelText: 'Visibility',
                  border: OutlineInputBorder(),
                ),
                items: ['Public', 'Private', 'Unlisted']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _visibility = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Assigned Characters',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _isLoadingCharacters
                        ? null
                        : _showCharacterSelectionDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_assignedCharacters.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'No characters assigned yet. Add characters to include them in your story.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _assignedCharacters.map((character) {
                    return Chip(
                      avatar: CircleAvatar(child: Text(character.name[0])),
                      label: Text(character.name),
                      onDeleted: () => _removeCharacter(character.id),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _saveStory,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Story',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCharacterSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Character'),
          content: SizedBox(
            width: double.maxFinite,
            child: _availableCharacters.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No characters found. Create some characters first to assign them to your story.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _availableCharacters.length,
                    itemBuilder: (context, index) {
                      final character = _availableCharacters[index];
                      final isAssigned = _assignedCharacters.any(
                        (c) => c.id == character.id,
                      );

                      return ListTile(
                        leading: CircleAvatar(child: Text(character.name[0])),
                        title: Text(character.name),
                        subtitle: Text(character.race),
                        trailing: isAssigned
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        onTap: isAssigned
                            ? null
                            : () {
                                _addCharacter(character);
                                Navigator.pop(context);
                              },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
