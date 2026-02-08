import 'package:flutter/material.dart';
import '../theme/lore_theme.dart';

/// Search result from story history.
class StorySearchResult {
  final int messageIndex;
  final String role; // 'user' or 'ai'
  final String text;
  final String matchSnippet;

  StorySearchResult({
    required this.messageIndex,
    required this.role,
    required this.text,
    required this.matchSnippet,
  });
}

/// Search overlay for finding content in story history.
class StorySearchOverlay extends StatefulWidget {
  final List<Map<String, String>> messages;
  final void Function(int messageIndex) onResultTap;
  final VoidCallback onClose;

  const StorySearchOverlay({
    super.key,
    required this.messages,
    required this.onResultTap,
    required this.onClose,
  });

  @override
  State<StorySearchOverlay> createState() => _StorySearchOverlayState();
}

class _StorySearchOverlayState extends State<StorySearchOverlay> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  List<StorySearchResult> _results = [];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    final lowerQuery = query.toLowerCase();
    final results = <StorySearchResult>[];

    for (int i = 0; i < widget.messages.length; i++) {
      final msg = widget.messages[i];
      final text = msg['content'] ?? msg['text'] ?? '';
      final role = msg['role'] ?? 'unknown';

      if (text.toLowerCase().contains(lowerQuery)) {
        // Extract snippet around match
        final matchIndex = text.toLowerCase().indexOf(lowerQuery);
        final start = (matchIndex - 30).clamp(0, text.length);
        final end = (matchIndex + query.length + 30).clamp(0, text.length);
        final snippet =
            '${start > 0 ? "..." : ""}'
            '${text.substring(start, end)}'
            '${end < text.length ? "..." : ""}';

        results.add(
          StorySearchResult(
            messageIndex: i,
            role: role,
            text: text,
            matchSnippet: snippet,
          ),
        );
      }
    }

    setState(() => _results = results);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Story search. ${_results.length} results found.',
      child: Container(
        color: LoreTheme.inkBlack.withOpacity(0.95),
        child: SafeArea(
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        textField: true,
                        label: 'Search story history',
                        child: TextField(
                          controller: _searchController,
                          focusNode: _focusNode,
                          onChanged: _performSearch,
                          style: const TextStyle(
                            color: LoreTheme.parchment,
                            fontFamily: LoreTheme.serifFont,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search the chronicles...',
                            hintStyle: TextStyle(
                              color: LoreTheme.warmBrown.withOpacity(0.4),
                              fontStyle: FontStyle.italic,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: LoreTheme.goldAccent.withOpacity(0.6),
                            ),
                            filled: true,
                            fillColor: LoreTheme.deepBrown.withOpacity(0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      button: true,
                      label: 'Close search',
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: LoreTheme.lightBrown,
                        ),
                        onPressed: widget.onClose,
                      ),
                    ),
                  ],
                ),
              ),
              // Results count
              if (_searchController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_results.length} result${_results.length == 1 ? "" : "s"} found',
                      style: TextStyle(
                        color: LoreTheme.warmBrown.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              // Results list
              Expanded(
                child: _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: LoreTheme.warmBrown.withOpacity(0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Enter a search term to find story moments'
                                  : 'No matches found in the chronicles',
                              style: TextStyle(
                                color: LoreTheme.warmBrown.withOpacity(0.5),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final result = _results[index];
                          final isUser = result.role == 'user';
                          return Semantics(
                            button: true,
                            label:
                                '${isUser ? "Your message" : "Narrator"}: ${result.matchSnippet}',
                            child: GestureDetector(
                              onTap: () =>
                                  widget.onResultTap(result.messageIndex),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: LoreTheme.deepBrown.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: LoreTheme.warmBrown.withOpacity(
                                      0.15,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          isUser
                                              ? Icons.person
                                              : Icons.auto_stories,
                                          size: 14,
                                          color: isUser
                                              ? LoreTheme.lightBrown
                                              : LoreTheme.goldAccent,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isUser ? 'YOU' : 'NARRATOR',
                                          style: TextStyle(
                                            color: isUser
                                                ? LoreTheme.lightBrown
                                                : LoreTheme.goldAccent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    _buildHighlightedText(
                                      result.matchSnippet,
                                      _searchController.text,
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
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          color: LoreTheme.lightBrown.withOpacity(0.7),
          fontSize: 13,
          height: 1.4,
        ),
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(
          TextSpan(
            text: text.substring(start),
            style: TextStyle(color: LoreTheme.lightBrown.withOpacity(0.7)),
          ),
        );
        break;
      }

      if (index > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, index),
            style: TextStyle(color: LoreTheme.lightBrown.withOpacity(0.7)),
          ),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: TextStyle(
            color: LoreTheme.goldAccent,
            fontWeight: FontWeight.bold,
            backgroundColor: LoreTheme.goldAccent.withOpacity(0.15),
          ),
        ),
      );

      start = index + query.length;
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, height: 1.4),
        children: spans,
      ),
    );
  }
}
