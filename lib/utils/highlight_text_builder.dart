import 'package:flutter/material.dart';

class HighlightTextBuilder {
  /// 构建带有高亮的富文本
  /// [onlyFirst] 如果为 true，则只高亮第一个匹配的关键词，后续重复的关键词不高亮。
  static TextSpan build(
    BuildContext context,
    String text,
    String query, {
    bool onlyFirst = false,
  }) {
    if (query.isEmpty) {
      return TextSpan(
        text: text,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      );
    }

    final List<TextSpan> spans = [];
    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();

    int start = 0;
    int indexOfHighlight = lowerText.indexOf(lowerQuery);

    // 如果未找到任何匹配
    if (indexOfHighlight == -1) {
      return TextSpan(
        text: text,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      );
    }

    while (indexOfHighlight != -1) {
      // 1. 添加高亮前的普通文本
      if (indexOfHighlight > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, indexOfHighlight),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        );
      }

      // 2. 添加高亮文本
      spans.add(
        TextSpan(
          text: text.substring(
            indexOfHighlight,
            indexOfHighlight + query.length,
          ),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = indexOfHighlight + query.length;

      // [核心修改] 如果只需要高亮第一个，直接退出循环，将剩余部分作为普通文本处理
      if (onlyFirst) {
        break;
      }

      indexOfHighlight = lowerText.indexOf(lowerQuery, start);
    }

    // 3. 添加剩余的文本 (普通样式)
    if (start < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(start),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      );
    }

    return TextSpan(children: spans);
  }
}
