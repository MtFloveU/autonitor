part of 'user_detail_page.dart';

String formatJoinedTime(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  try {
    final cleaned = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    final parts = cleaned.split(' ');
    if (parts.length < 6) return raw;

    final monthMap = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    final month = monthMap[parts[1]];
    if (month == null) return raw;

    final day = int.parse(parts[2]);
    final timeParts = parts[3].split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final second = int.parse(timeParts[2]);
    final year = int.parse(parts[5]);

    final utc = DateTime.utc(year, month, day, hour, minute, second);
    final local = utc.toLocal();

    final formatter = DateFormat.yMd().add_Hms();
    return formatter.format(local);
  } catch (e) {
    debugPrint('formatJoinTime error: $e');
    return raw;
  }
}

class _StatItemData {
  final IconData icon;
  final String label;
  final String value;
  final String jsonKey;

  _StatItemData(this.icon, this.label, this.value, this.jsonKey);
}

class _TextEntity {
  final int start;
  final int end;
  final String text;
  final String type; // 'link' or 'mention'
  final String? data; // expandedUrl for link, username for mention

  _TextEntity(this.start, this.end, this.text, this.type, this.data);
}
