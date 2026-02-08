import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/character.dart';
import '../../core/services/character_service.dart';
import '../../core/services/ai_service.dart';
import '../theme/lore_theme.dart';
import '../widgets/lore_notification.dart';

/// Character creation/editing screen with AI-assisted generation.
/// Accessible with semantic labels throughout.
class CharacterBuilderScreen extends StatefulWidget {
  final Character? character;

  const CharacterBuilderScreen({super.key, this.character});

  @override
  State<CharacterBuilderScreen> createState() => _CharacterBuilderScreenState();
}

class _CharacterBuilderScreenState extends State<CharacterBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _characterService = CharacterService();
  final _aiService = AIService();

  int _currentStep = 0;
  bool _isLoading = false;
  bool get _isEditing => widget.character != null;

  final _nameController = TextEditingController();
  final _raceController = TextEditingController();
  final _occupationController = TextEditingController();
  final _personalityController = TextEditingController();
  final _backstoryController = TextEditingController();

  late Map<String, Skill> _skills;

  @override
  void initState() {
    super.initState();
    // Initialize skills from character data if editing, otherwise default
    if (widget.character != null) {
      _skills = Map.from(widget.character!.skills);
      _nameController.text = widget.character!.name;
      _raceController.text = widget.character!.race;
      _occupationController.text = widget.character!.occupation;
      _personalityController.text = widget.character!.personality;
      _backstoryController.text = widget.character!.backstory;
    } else {
      _skills = {
        'Strength': Skill(name: 'Strength', currentLevel: 0, maxPotential: 6),
        'Agility': Skill(name: 'Agility', currentLevel: 0, maxPotential: 6),
        'Intelligence': Skill(
          name: 'Intelligence',
          currentLevel: 0,
          maxPotential: 6,
        ),
        'Willpower': Skill(name: 'Willpower', currentLevel: 0, maxPotential: 6),
        'Charisma': Skill(name: 'Charisma', currentLevel: 0, maxPotential: 6),
        'Perception': Skill(
          name: 'Perception',
          currentLevel: 0,
          maxPotential: 6,
        ),
        'Luck': Skill(name: 'Luck', currentLevel: 0, maxPotential: 6),
      };
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _raceController.dispose();
    _occupationController.dispose();
    _personalityController.dispose();
    _backstoryController.dispose();
    super.dispose();
  }

  Future<void> _consultOracle() async {
    final prompt = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: LoreTheme.inkBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: LoreTheme.warmBrown.withOpacity(0.3)),
          ),
          title: Text(
            'Consult the Oracle',
            style: LoreTheme.sectionTitle(fontSize: 18),
          ),
          content: Semantics(
            textField: true,
            label: 'Describe your character idea',
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Describe your character idea...',
                hintStyle: TextStyle(
                  color: LoreTheme.warmBrown.withOpacity(0.4),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: LoreTheme.warmBrown.withOpacity(0.3),
                  ),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: LoreTheme.goldAccent),
                ),
              ),
              style: const TextStyle(
                color: LoreTheme.parchment,
                fontFamily: LoreTheme.serifFont,
              ),
              maxLines: 3,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: LoreTheme.warmBrown.withOpacity(0.6)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: LoreTheme.goldAccent,
                foregroundColor: LoreTheme.inkBlack,
              ),
              child: const Text('Invoke'),
            ),
          ],
        );
      },
    );

    if (prompt == null || prompt.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final response = await _aiService.generateCharacterDetails(prompt);
      final cleanJson = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final data = jsonDecode(cleanJson);

      setState(() {
        _nameController.text = data['name'] ?? '';
        _raceController.text = data['race'] ?? '';
        _occupationController.text = data['occupation'] ?? '';
        _personalityController.text = data['personality'] ?? '';
        _backstoryController.text = data['backstory'] ?? '';

        if (data['skills'] != null) {
          final aiSkills = data['skills'] as Map<String, dynamic>;
          aiSkills.forEach((key, value) {
            if (_skills.containsKey(key)) {
              _skills[key] = Skill(
                name: key,
                currentLevel: value['currentLevel'] ?? 0,
                maxPotential: value['maxPotential'] ?? 6,
              );
            }
          });
        }
      });
    } catch (e) {
      if (mounted) {
        LoreNotification.show(
          context,
          'The Oracle is silent: $e',
          isError: true,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCharacter() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final character = Character(
      id: _isEditing ? widget.character!.id : const Uuid().v4(),
      name: _nameController.text,
      race: _raceController.text,
      occupation: _occupationController.text,
      personality: _personalityController.text,
      backstory: _backstoryController.text,
      skills: _skills,
      relationships: _isEditing ? widget.character!.relationships : const {},
    );

    try {
      if (_isEditing) {
        await _characterService.updateCharacter('dummy_user', character);
        if (mounted) {
          LoreNotification.show(context, '${character.name} has been updated.');
          Navigator.pop(context, true);
        }
      } else {
        await _characterService.createCharacter('dummy_user', character);
        if (mounted) {
          LoreNotification.show(
            context,
            'Character forged in the annals of history.',
          );
          setState(() {
            _currentStep = 0;
            _nameController.clear();
            _raceController.clear();
            _occupationController.clear();
            _personalityController.clear();
            _backstoryController.clear();
            _skills.forEach((key, value) {
              _skills[key] = Skill(name: key, currentLevel: 0, maxPotential: 6);
            });
          });
        }
      }
    } catch (e) {
      if (mounted) {
        LoreNotification.show(
          context,
          'Failed to save character: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            _isEditing ? 'EDIT SOUL' : 'THE FORGE OF SOULS',
            style: LoreTheme.sectionTitle(fontSize: 18),
          ),
        ),
        centerTitle: true,
        leading: _isEditing
            ? Semantics(
                button: true,
                label: 'Go back',
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: LoreTheme.lightBrown,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              )
            : null,
        actions: [
          if (!_isEditing)
            Semantics(
              button: true,
              label: 'Consult the Oracle for AI-generated character',
              child: IconButton(
                icon: const Icon(
                  Icons.auto_awesome,
                  color: LoreTheme.goldAccent,
                ),
                onPressed: _isLoading ? null : _consultOracle,
                tooltip: 'Consult the Oracle',
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.dark(
                primary: LoreTheme.goldAccent,
                secondary: LoreTheme.warmBrown,
              ),
            ),
            child: Form(
              key: _formKey,
              child: Stepper(
                type: StepperType.vertical,
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep < 2) {
                    setState(() => _currentStep += 1);
                  } else {
                    _saveCharacter();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep -= 1);
                  }
                },
                steps: [
                  Step(
                    title: Text(
                      'IDENTITY',
                      style: LoreTheme.sectionTitle(fontSize: 14),
                    ),
                    isActive: _currentStep >= 0,
                    content: Column(
                      children: [
                        _buildTextField(
                          _nameController,
                          'Name',
                          'Who are they?',
                        ),
                        _buildTextField(
                          _raceController,
                          'Race',
                          'What is their bloodline?',
                        ),
                        _buildTextField(
                          _occupationController,
                          'Occupation',
                          'How do they survive?',
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: Text(
                      'ESSENCE',
                      style: LoreTheme.sectionTitle(fontSize: 14),
                    ),
                    isActive: _currentStep >= 1,
                    content: Column(
                      children: [
                        _buildTextField(
                          _personalityController,
                          'Personality',
                          'What drives them?',
                          maxLines: 3,
                        ),
                        _buildTextField(
                          _backstoryController,
                          'Backstory',
                          'What scars do they carry?',
                          maxLines: 5,
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: Text(
                      'PROWESS',
                      style: LoreTheme.sectionTitle(fontSize: 14),
                    ),
                    isActive: _currentStep >= 2,
                    content: Column(
                      children: _skills.keys
                          .map((skillName) => _buildSkillSlider(skillName))
                          .toList(),
                    ),
                  ),
                ],
                controlsBuilder: (context, details) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Row(
                      children: [
                        Semantics(
                          button: true,
                          label: _currentStep == 2
                              ? (_isEditing
                                    ? 'Save changes'
                                    : 'Forge character')
                              : 'Continue to next step',
                          child: ElevatedButton(
                            onPressed: details.onStepContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LoreTheme.goldAccent,
                              foregroundColor: LoreTheme.inkBlack,
                            ),
                            child: Text(
                              _currentStep == 2
                                  ? (_isEditing ? 'SAVE' : 'FORGE')
                                  : 'CONTINUE',
                            ),
                          ),
                        ),
                        if (_currentStep > 0)
                          Semantics(
                            button: true,
                            label: 'Go back to previous step',
                            child: TextButton(
                              onPressed: details.onStepCancel,
                              child: Text(
                                'BACK',
                                style: TextStyle(
                                  color: LoreTheme.warmBrown.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: LoreTheme.goldAccent),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Semantics(
        textField: true,
        label: label,
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(
            color: LoreTheme.parchment,
            fontFamily: LoreTheme.serifFont,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: LoreTheme.goldAccent.withOpacity(0.7)),
            hintText: hint,
            hintStyle: TextStyle(
              color: LoreTheme.warmBrown.withOpacity(0.4),
              fontSize: 12,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: LoreTheme.warmBrown.withOpacity(0.3),
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: LoreTheme.goldAccent),
            ),
          ),
          validator: (value) => value == null || value.isEmpty
              ? 'This field cannot be empty'
              : null,
        ),
      ),
    );
  }

  Widget _buildSkillSlider(String skillName) {
    final skill = _skills[skillName]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              skillName,
              style: const TextStyle(
                color: LoreTheme.parchment,
                fontSize: 14,
                fontFamily: LoreTheme.serifFont,
              ),
            ),
            Text(
              _getTierName(skill.currentLevel),
              style: TextStyle(
                color: LoreTheme.goldAccent.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Semantics(
          label:
              '$skillName: ${_getTierName(skill.currentLevel)}, '
              'level ${skill.currentLevel} of 6',
          slider: true,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: LoreTheme.goldAccent,
              inactiveTrackColor: LoreTheme.deepBrown,
              thumbColor: LoreTheme.parchment,
              overlayColor: LoreTheme.goldAccent.withOpacity(0.2),
              valueIndicatorColor: LoreTheme.deepBrown,
              valueIndicatorTextStyle: const TextStyle(
                color: LoreTheme.parchment,
              ),
            ),
            child: Slider(
              value: skill.currentLevel.toDouble(),
              min: 0,
              max: 6,
              divisions: 6,
              label: _getTierName(skill.currentLevel),
              onChanged: (value) {
                setState(() {
                  _skills[skillName] = Skill(
                    name: skillName,
                    currentLevel: value.toInt(),
                    maxPotential: 6,
                  );
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  String _getTierName(int level) {
    const tiers = [
      'Null',
      'Novice',
      'Apprentice',
      'Skilled',
      'Expert',
      'Master',
      'Divine',
    ];
    if (level >= 0 && level < tiers.length) return tiers[level];
    return 'Unknown';
  }
}
