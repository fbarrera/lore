import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/character.dart';
import '../models/skill.dart';
import '../services/character_service.dart';
import '../services/auth_service.dart';

class CharacterCreationScreen extends StatefulWidget {
  final Character? character;
  const CharacterCreationScreen({super.key, this.character});

  @override
  State<CharacterCreationScreen> createState() =>
      _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _characterService = CharacterService();

  // Form controllers
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _genderController;
  late final TextEditingController _raceController;
  late final TextEditingController _occupationController;
  late final TextEditingController _personalityController;
  late final TextEditingController _storyController;
  late final TextEditingController _appearanceController;

  // Skills list
  final List<Skill> _skills = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.character?.name);
    _ageController = TextEditingController(
      text: widget.character?.age.toString(),
    );
    _genderController = TextEditingController(text: widget.character?.gender);
    _raceController = TextEditingController(text: widget.character?.race);
    _occupationController = TextEditingController(
      text: widget.character?.occupation,
    );
    _personalityController = TextEditingController(
      text: widget.character?.personality,
    );
    _storyController = TextEditingController(text: widget.character?.story);
    _appearanceController = TextEditingController(
      text: widget.character?.appearance,
    );
    if (widget.character != null) {
      _skills.addAll(widget.character!.skills);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _raceController.dispose();
    _occupationController.dispose();
    _personalityController.dispose();
    _storyController.dispose();
    _appearanceController.dispose();
    super.dispose();
  }

  void _addSkill() {
    showDialog(
      context: context,
      builder: (context) => _AddSkillDialog(
        onAdd: (skill) {
          setState(() {
            _skills.add(skill);
          });
        },
      ),
    );
  }

  void _removeSkill(int index) {
    setState(() {
      _skills.removeAt(index);
    });
  }

  Future<void> _saveCharacter() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to save a character.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final characterId =
          widget.character?.id ??
          FirebaseFirestore.instance.collection('characters').doc().id;
      final character = Character(
        id: characterId,
        name: _nameController.text,
        age: int.tryParse(_ageController.text) ?? 0,
        gender: _genderController.text,
        race: _raceController.text,
        occupation: _occupationController.text,
        personality: _personalityController.text,
        story: _storyController.text,
        appearance: _appearanceController.text,
        skills: _skills,
        creatorId: authService.user!.uid,
        createdAt: widget.character?.createdAt ?? DateTime.now(),
      );

      if (widget.character != null) {
        await _characterService.updateCharacter(character);
      } else {
        await _characterService.createCharacter(character);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.character != null
                  ? 'Character updated successfully!'
                  : 'Character saved successfully!',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving character: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.character != null ? 'Edit Character' : 'Create Character',
        ),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _saveCharacter),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Basic Information'),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(labelText: 'Age *'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        if (int.tryParse(value!) == null)
                          return 'Must be a number';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _genderController,
                      decoration: const InputDecoration(labelText: 'Gender *'),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _raceController,
                decoration: const InputDecoration(labelText: 'Race *'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _occupationController,
                decoration: const InputDecoration(labelText: 'Occupation *'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Details'),
              TextFormField(
                controller: _personalityController,
                decoration: const InputDecoration(labelText: 'Personality'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _storyController,
                decoration: const InputDecoration(
                  labelText: 'Story/Background',
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _appearanceController,
                decoration: const InputDecoration(labelText: 'Appearance'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Skills'),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: _addSkill,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
              if (_skills.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'No skills added yet.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _skills.length,
                  itemBuilder: (context, index) {
                    final skill = _skills[index];
                    return Card(
                      child: ListTile(
                        title: Text(skill.name),
                        subtitle: Text(
                          '${skill.category} - Level: ${skill.currentLevel}/${skill.maxPotential}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeSkill(index),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCharacter,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Save Character',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildPreviewSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Character Preview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildPreviewRow('Name', _nameController),
            _buildPreviewRow('Age', _ageController),
            _buildPreviewRow('Gender', _genderController),
            _buildPreviewRow('Race', _raceController),
            _buildPreviewRow('Occupation', _occupationController),
            const SizedBox(height: 8),
            _buildPreviewArea('Personality', _personalityController),
            _buildPreviewArea('Story', _storyController),
            _buildPreviewArea('Appearance', _appearanceController),
            if (_skills.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Skills:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ..._skills.map(
                (s) => Text('• ${s.name} (${s.proficiencyTier.name})'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewRow(String label, TextEditingController controller) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, _) {
        if (value.text.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            children: [
              Text(
                '$label: ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(child: Text(value.text)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreviewArea(String label, TextEditingController controller) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, _) {
        if (value.text.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                value.text,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AddSkillDialog extends StatefulWidget {
  final Function(Skill) onAdd;

  const _AddSkillDialog({required this.onAdd});

  @override
  State<_AddSkillDialog> createState() => _AddSkillDialogState();
}

class _AddSkillDialogState extends State<_AddSkillDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _levelController = TextEditingController(text: '1');
  final _maxController = TextEditingController(text: '10');
  ProficiencyTier _tier = ProficiencyTier.novice;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _levelController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Skill'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Skill Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _levelController,
                      decoration: const InputDecoration(
                        labelText: 'Current Level',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          int.tryParse(value ?? '') == null ? 'Invalid' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxController,
                      decoration: const InputDecoration(
                        labelText: 'Max Potential',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          int.tryParse(value ?? '') == null ? 'Invalid' : null,
                    ),
                  ),
                ],
              ),
              DropdownButtonFormField<ProficiencyTier>(
                value: _tier,
                decoration: const InputDecoration(
                  labelText: 'Proficiency Tier',
                ),
                items: ProficiencyTier.values.map((tier) {
                  return DropdownMenuItem(
                    value: tier,
                    child: Text(tier.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _tier = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final skill = Skill(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: _nameController.text,
                category: _categoryController.text,
                currentLevel: int.parse(_levelController.text),
                maxPotential: int.parse(_maxController.text),
                proficiencyTier: _tier,
              );
              widget.onAdd(skill);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
