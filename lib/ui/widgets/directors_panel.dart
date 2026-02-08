import 'package:flutter/material.dart';
import '../../core/models/story.dart';
import '../theme/lore_theme.dart';
import 'lore_notification.dart';

/// Callback for when the Director's Panel settings change.
typedef DirectorSettingsCallback =
    void Function({String? narrationStyle, String? worldNotes});

/// A sliding drawer panel for real-time narration style adjustments,
/// world notes editing, and preview of changes.
class DirectorsPanel extends StatefulWidget {
  final Story story;
  final DirectorSettingsCallback onSettingsChanged;
  final VoidCallback? onClose;

  const DirectorsPanel({
    super.key,
    required this.story,
    required this.onSettingsChanged,
    this.onClose,
  });

  @override
  State<DirectorsPanel> createState() => _DirectorsPanelState();

  /// Show the Director's Panel as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required Story story,
    required DirectorSettingsCallback onSettingsChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: LoreTheme.inkBlack,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: LoreTheme.goldAccent.withOpacity(0.3)),
              left: BorderSide(color: LoreTheme.goldAccent.withOpacity(0.1)),
              right: BorderSide(color: LoreTheme.goldAccent.withOpacity(0.1)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: DirectorsPanel(
            story: story,
            onSettingsChanged: onSettingsChanged,
            onClose: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }
}

class _DirectorsPanelState extends State<DirectorsPanel>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _styleController;
  late final TextEditingController _notesController;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  String _selectedTone = 'Neutral';
  double _paceValue = 0.5;
  bool _hasChanges = false;

  static const List<String> _tonePresets = [
    'Neutral',
    'Gritty Noir',
    'Epic Fantasy',
    'Cosmic Horror',
    'Whimsical',
    'Melancholic',
    'Suspenseful',
    'Romantic',
  ];

  @override
  void initState() {
    super.initState();
    _styleController = TextEditingController(text: widget.story.narrationStyle);
    _notesController = TextEditingController(text: widget.story.worldNotes);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    // Detect initial tone
    for (final tone in _tonePresets) {
      if (widget.story.narrationStyle.toLowerCase().contains(
        tone.toLowerCase(),
      )) {
        _selectedTone = tone;
        break;
      }
    }
  }

  @override
  void dispose() {
    _styleController.dispose();
    _notesController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  void _applyChanges() {
    widget.onSettingsChanged(
      narrationStyle: _styleController.text,
      worldNotes: _notesController.text,
    );
    setState(() => _hasChanges = false);
    LoreNotification.show(context, 'Director settings applied');
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Semantics(
        label: "Director's Panel - Adjust narration settings",
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHandle(),
              const SizedBox(height: 16),
              _buildHeader(),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildToneSelector(),
                      const SizedBox(height: 24),
                      _buildNarrationStyleField(),
                      const SizedBox(height: 24),
                      _buildPaceSlider(),
                      const SizedBox(height: 24),
                      _buildWorldNotesField(),
                      const SizedBox(height: 24),
                      _buildPreview(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              _buildActionBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Semantics(
        label: 'Drag handle',
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: LoreTheme.warmBrown.withOpacity(0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.movie_creation, color: LoreTheme.goldAccent, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text("DIRECTOR'S PANEL", style: LoreTheme.sectionTitle()),
        ),
        if (_hasChanges)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: LoreTheme.goldAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'UNSAVED',
              style: TextStyle(
                color: LoreTheme.goldAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildToneSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('NARRATIVE TONE', style: LoreTheme.labelStyle()),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tonePresets.map((tone) {
            final isSelected = _selectedTone == tone;
            return Semantics(
              label: '$tone tone${isSelected ? ", selected" : ""}',
              button: true,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTone = tone;
                    _styleController.text = tone;
                  });
                  _markChanged();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? LoreTheme.goldAccent.withOpacity(0.2)
                        : LoreTheme.deepBrown.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? LoreTheme.goldAccent
                          : LoreTheme.warmBrown.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    tone,
                    style: TextStyle(
                      color: isSelected
                          ? LoreTheme.goldAccent
                          : LoreTheme.lightBrown,
                      fontSize: 13,
                      fontFamily: LoreTheme.serifFont,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNarrationStyleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('NARRATION STYLE', style: LoreTheme.labelStyle()),
        const SizedBox(height: 8),
        Semantics(
          label: 'Narration style text field',
          textField: true,
          child: TextField(
            controller: _styleController,
            onChanged: (_) => _markChanged(),
            style: const TextStyle(
              color: LoreTheme.parchment,
              fontFamily: LoreTheme.serifFont,
            ),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'e.g., Gritty noir with poetic undertones',
              filled: true,
              fillColor: LoreTheme.deepBrown.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: LoreTheme.warmBrown.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: LoreTheme.warmBrown.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: LoreTheme.goldAccent),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaceSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('NARRATIVE PACE', style: LoreTheme.labelStyle()),
            Text(
              _paceLabel,
              style: TextStyle(
                color: LoreTheme.goldAccent,
                fontSize: 12,
                fontFamily: LoreTheme.serifFont,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          label: 'Narrative pace slider, currently $_paceLabel',
          slider: true,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: LoreTheme.goldAccent,
              inactiveTrackColor: LoreTheme.deepBrown,
              thumbColor: LoreTheme.parchment,
              overlayColor: LoreTheme.goldAccent.withOpacity(0.2),
            ),
            child: Slider(
              value: _paceValue,
              onChanged: (v) {
                setState(() => _paceValue = v);
                _markChanged();
              },
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Contemplative',
              style: TextStyle(
                color: LoreTheme.warmBrown.withOpacity(0.6),
                fontSize: 10,
              ),
            ),
            Text(
              'Action-Packed',
              style: TextStyle(
                color: LoreTheme.warmBrown.withOpacity(0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String get _paceLabel {
    if (_paceValue < 0.25) return 'Slow & Deliberate';
    if (_paceValue < 0.5) return 'Measured';
    if (_paceValue < 0.75) return 'Brisk';
    return 'Rapid';
  }

  Widget _buildWorldNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('WORLD NOTES', style: LoreTheme.labelStyle()),
        const SizedBox(height: 8),
        Semantics(
          label: 'World notes text field',
          textField: true,
          child: TextField(
            controller: _notesController,
            onChanged: (_) => _markChanged(),
            style: const TextStyle(
              color: LoreTheme.parchment,
              fontFamily: LoreTheme.serifFont,
              fontSize: 14,
              height: 1.5,
            ),
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Describe the rules and lore of your world...',
              filled: true,
              fillColor: LoreTheme.deepBrown.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: LoreTheme.warmBrown.withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: LoreTheme.warmBrown.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: LoreTheme.goldAccent),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LoreTheme.narratorBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LoreTheme.warmBrown.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview,
                size: 14,
                color: LoreTheme.goldAccent.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Text('PREVIEW', style: LoreTheme.labelStyle(fontSize: 10)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _generatePreviewText(),
            style: LoreTheme.narratorText(fontSize: 14),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _generatePreviewText() {
    final style = _styleController.text;
    final pace = _paceLabel.toLowerCase();
    if (style.isEmpty) {
      return 'Set a narration style to see a preview...';
    }
    return 'With a $style voice and a $pace rhythm, the narrator '
        'weaves tales of ${widget.story.genre.isNotEmpty ? widget.story.genre : "adventure"}. '
        'The world breathes with the lore you have inscribed.';
  }

  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: 'Close panel',
              child: OutlinedButton(
                onPressed: widget.onClose,
                style: OutlinedButton.styleFrom(
                  foregroundColor: LoreTheme.lightBrown,
                  side: BorderSide(color: LoreTheme.warmBrown.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(0, 48),
                ),
                child: const Text('CLOSE'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Semantics(
              button: true,
              label: 'Apply changes',
              child: ElevatedButton(
                onPressed: _hasChanges ? _applyChanges : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LoreTheme.goldAccent,
                  foregroundColor: LoreTheme.inkBlack,
                  disabledBackgroundColor: LoreTheme.deepBrown.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(0, 48),
                ),
                child: const Text(
                  'APPLY',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
