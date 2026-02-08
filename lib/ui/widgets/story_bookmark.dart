import 'package:flutter/material.dart';
import '../theme/lore_theme.dart';

/// A bookmark entry for saving story positions.
class StoryBookmark {
  final String id;
  final String title;
  final String preview;
  final DateTime timestamp;
  final int messageIndex;

  StoryBookmark({
    required this.id,
    required this.title,
    required this.preview,
    required this.timestamp,
    required this.messageIndex,
  });
}

/// Widget for displaying and managing story bookmarks.
class StoryBookmarkPanel extends StatelessWidget {
  final List<StoryBookmark> bookmarks;
  final void Function(StoryBookmark) onBookmarkTap;
  final void Function(StoryBookmark)? onBookmarkDelete;
  final VoidCallback? onAddBookmark;

  const StoryBookmarkPanel({
    super.key,
    required this.bookmarks,
    required this.onBookmarkTap,
    this.onBookmarkDelete,
    this.onAddBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Story bookmarks panel with ${bookmarks.length} saved positions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.bookmark, color: LoreTheme.goldAccent, size: 20),
              const SizedBox(width: 8),
              Text('BOOKMARKS', style: LoreTheme.sectionTitle(fontSize: 14)),
              const Spacer(),
              if (onAddBookmark != null)
                Semantics(
                  button: true,
                  label: 'Add bookmark at current position',
                  child: IconButton(
                    icon: Icon(
                      Icons.bookmark_add,
                      color: LoreTheme.goldAccent.withOpacity(0.7),
                      size: 20,
                    ),
                    onPressed: onAddBookmark,
                    tooltip: 'Bookmark this moment',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (bookmarks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No bookmarks saved yet. Mark important story moments to return to later.',
                style: TextStyle(
                  color: LoreTheme.warmBrown.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            )
          else
            ...bookmarks.map(
              (bookmark) => _BookmarkTile(
                bookmark: bookmark,
                onTap: () => onBookmarkTap(bookmark),
                onDelete: onBookmarkDelete != null
                    ? () => onBookmarkDelete!(bookmark)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  final StoryBookmark bookmark;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _BookmarkTile({
    required this.bookmark,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Bookmark: ${bookmark.title}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: LoreTheme.deepBrown.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: LoreTheme.goldAccent.withOpacity(0.15),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.bookmark,
                color: LoreTheme.goldAccent.withOpacity(0.6),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookmark.title,
                      style: const TextStyle(
                        color: LoreTheme.parchment,
                        fontFamily: LoreTheme.serifFont,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bookmark.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: LoreTheme.lightBrown.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTimestamp(bookmark.timestamp),
                      style: TextStyle(
                        color: LoreTheme.warmBrown.withOpacity(0.4),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                Semantics(
                  button: true,
                  label: 'Delete bookmark ${bookmark.title}',
                  child: IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 16,
                      color: LoreTheme.warmBrown.withOpacity(0.4),
                    ),
                    onPressed: onDelete,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

/// Chapter progress indicator showing story progression.
class ChapterProgressIndicator extends StatelessWidget {
  final int currentChapter;
  final int totalChapters;
  final String? chapterTitle;
  final double progress; // 0.0 to 1.0 within current chapter

  const ChapterProgressIndicator({
    super.key,
    required this.currentChapter,
    required this.totalChapters,
    this.chapterTitle,
    this.progress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Chapter $currentChapter of $totalChapters'
          '${chapterTitle != null ? ": $chapterTitle" : ""}'
          ', ${(progress * 100).round()}% complete',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: LoreTheme.inkBlack.withOpacity(0.8),
          border: Border(
            bottom: BorderSide(color: LoreTheme.warmBrown.withOpacity(0.2)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.menu_book,
                  size: 14,
                  color: LoreTheme.goldAccent.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  'CHAPTER $currentChapter',
                  style: TextStyle(
                    color: LoreTheme.goldAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontFamily: LoreTheme.serifFont,
                  ),
                ),
                if (chapterTitle != null) ...[
                  Text(
                    ' — ',
                    style: TextStyle(
                      color: LoreTheme.warmBrown.withOpacity(0.4),
                      fontSize: 11,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      chapterTitle!,
                      style: TextStyle(
                        color: LoreTheme.lightBrown.withOpacity(0.7),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        fontFamily: LoreTheme.serifFont,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  const Spacer(),
                Text(
                  '$currentChapter / $totalChapters',
                  style: TextStyle(
                    color: LoreTheme.warmBrown.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Chapter dots
            Row(
              children: List.generate(totalChapters, (i) {
                final isCompleted = i < currentChapter - 1;
                final isCurrent = i == currentChapter - 1;
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1.5),
                      color: isCompleted
                          ? LoreTheme.goldAccent.withOpacity(0.6)
                          : isCurrent
                          ? LoreTheme.goldAccent.withOpacity(0.3)
                          : LoreTheme.deepBrown.withOpacity(0.4),
                    ),
                    child: isCurrent
                        ? FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(1.5),
                                color: LoreTheme.goldAccent.withOpacity(0.8),
                              ),
                            ),
                          )
                        : null,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Branching narrative choice indicator.
class NarrativeChoiceCard extends StatelessWidget {
  final String choiceText;
  final String? consequence;
  final VoidCallback onTap;
  final bool isHighlighted;

  const NarrativeChoiceCard({
    super.key,
    required this.choiceText,
    this.consequence,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          'Story choice: $choiceText'
          '${consequence != null ? ". Consequence: $consequence" : ""}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isHighlighted
                ? LoreTheme.goldAccent.withOpacity(0.1)
                : LoreTheme.deepBrown.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighlighted
                  ? LoreTheme.goldAccent.withOpacity(0.5)
                  : LoreTheme.warmBrown.withOpacity(0.2),
              width: isHighlighted ? 1.5 : 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isHighlighted ? Icons.arrow_forward : Icons.chevron_right,
                color: isHighlighted
                    ? LoreTheme.goldAccent
                    : LoreTheme.warmBrown.withOpacity(0.5),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      choiceText,
                      style: TextStyle(
                        color: isHighlighted
                            ? LoreTheme.parchment
                            : LoreTheme.lightBrown,
                        fontFamily: LoreTheme.serifFont,
                        fontSize: 14,
                        fontWeight: isHighlighted
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (consequence != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        consequence!,
                        style: TextStyle(
                          color: LoreTheme.warmBrown.withOpacity(0.5),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
