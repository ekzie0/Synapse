import 'package:flutter/material.dart';

class LinkTextEditingController extends TextEditingController {
  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final List<InlineSpan> children = [];
    
    // Это выражение ищет [[любой текст]]
    final RegExp regExp = RegExp(r'(\[\[.*?\]\])');

    text.splitMapJoin(
      regExp,
      onMatch: (Match match) {
        final fullMatch = match[0]!;
        final content = fullMatch.substring(2, fullMatch.length - 2); // Текст без [[]]
        
        children.add(TextSpan(
          children: [
            TextSpan(text: '[[', style: style?.copyWith(color: Colors.blueAccent.withOpacity(0.3))),
            TextSpan(text: content, style: style?.copyWith(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            TextSpan(text: ']]', style: style?.copyWith(color: Colors.blueAccent.withOpacity(0.3))),
          ],
        ));
        return '';
      },
      onNonMatch: (String text) {
        children.add(TextSpan(text: text, style: style));
        return '';
      },
    );

    return TextSpan(style: style, children: children);
  }
}