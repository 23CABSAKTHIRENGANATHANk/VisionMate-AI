// ---------------------------------------------------------------------------
// help_card.dart
// An expandable information card used in the Help screen for FAQs and
// Getting Started steps. Smooth expand/collapse animation via AnimatedSize.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// An expandable card displaying a [title] and collapsible [body] text.
///
/// Tapping the card header toggles the body content visibility with a
/// smooth height animation. Useful for FAQ sections and getting-started
/// guides where users need progressive disclosure.
///
/// Example:
/// ```dart
/// HelpCard(
///   title: AppStrings.faqQ1,
///   body: AppStrings.faqA1,
///   icon: Icons.help_outline_rounded,
/// )
/// ```
class HelpCard extends StatefulWidget {
  const HelpCard({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.help_outline_rounded,
    this.initiallyExpanded = false,
  });

  /// The question or step label shown in the card header.
  final String title;

  /// The detailed answer or description shown when the card is expanded.
  final String body;

  /// Icon displayed on the leading side of the header.
  final IconData icon;

  /// Whether the card body is visible on first render.
  final bool initiallyExpanded;

  @override
  State<HelpCard> createState() => _HelpCardState();
}

class _HelpCardState extends State<HelpCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      // Provides a clear description for screen readers including current state.
      label: '${widget.title}. ${_isExpanded ? "Expanded" : "Collapsed"}',
      button: true,
      child: AnimatedContainer(
        duration: 250.ms,
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isExpanded
                ? colorScheme.primary.withAlpha(77)
                : colorScheme.outline.withAlpha(51),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _isExpanded
                  ? colorScheme.primary.withAlpha(20)
                  : Colors.black.withAlpha(10),
              blurRadius: _isExpanded ? 12 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Header row ────────────────────────────────────────────────
            InkWell(
              onTap: _toggleExpanded,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Leading icon.
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.icon,
                        color: colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Title — expands to fill remaining space.
                    Expanded(
                      child: Text(
                        widget.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Animated chevron rotates when expanded.
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: 250.ms,
                      curve: Curves.easeInOut,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Expandable body ────────────────────────────────────────────
            AnimatedSize(
              duration: 300.ms,
              curve: Curves.easeInOut,
              child: _isExpanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(
                            color: colorScheme.outline.withAlpha(51),
                            height: 16,
                          ),
                          Text(
                            widget.body,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withAlpha(204),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    )
                  // AnimatedSize requires a sized child even when collapsed.
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
