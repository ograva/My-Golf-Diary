import 'package:flutter/material.dart';

/// Course or range name field. Recent names come first, then catalog matches.
/// Typed text that is not in the list stays a custom venue.
class VenueNameField extends StatefulWidget {
  const VenueNameField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.catalogNames,
    this.focusNode,
    this.recentNames = const [],
    this.hintText,
    this.captionFor,
    this.onSelected,
    this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String labelText;
  final String? hintText;
  final List<String> recentNames;
  final List<String> catalogNames;
  final String? Function(String text)? captionFor;
  final ValueChanged<String>? onSelected;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  State<VenueNameField> createState() => _VenueNameFieldState();
}

class _VenueNameFieldState extends State<VenueNameField> {
  FocusNode? _ownedFocus;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocus!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) _ownedFocus = FocusNode();
    widget.controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(VenueNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
    }
    if (widget.focusNode == null && _ownedFocus == null) {
      _ownedFocus = FocusNode();
    } else if (widget.focusNode != null && _ownedFocus != null) {
      _ownedFocus!.dispose();
      _ownedFocus = null;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _ownedFocus?.dispose();
    super.dispose();
  }

  void _onText() {
    if (mounted) setState(() {});
  }

  Iterable<String> _options(TextEditingValue value) {
    final query = value.text.trim().toLowerCase();
    bool matches(String name) =>
        query.isEmpty || name.toLowerCase().contains(query);
    final seen = <String>{};
    final matchesOut = <String>[];
    for (final name in [...widget.recentNames, ...widget.catalogNames]) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) continue;
      if (!seen.add(trimmed.toLowerCase())) continue;
      if (matches(trimmed)) matchesOut.add(trimmed);
      if (matchesOut.length >= 12) break;
    }
    return matchesOut;
  }

  @override
  Widget build(BuildContext context) {
    final caption = widget.captionFor?.call(widget.controller.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Autocomplete<String>(
          textEditingController: widget.controller,
          focusNode: _focusNode,
          displayStringForOption: (option) => option,
          optionsBuilder: _options,
          onSelected: (option) {
            widget.controller.text = option;
            widget.controller.selection =
                TextSelection.collapsed(offset: option.length);
            widget.onSelected?.call(option);
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: widget.labelText,
                hintText: widget.hintText,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: widget.autofocus,
              onSubmitted: (text) {
                onFieldSubmitted();
                widget.onSubmitted?.call(text);
              },
            );
          },
        ),
        if (caption != null) ...[
          const SizedBox(height: 6),
          Text(caption, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}
