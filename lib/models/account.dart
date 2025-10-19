// [已更新]
// 核心改动：
// 1. 移除了不再需要的 `dart:convert` 导入。
class Account {
  final String id;
  final String cookie;

  Account({required this.id, required this.cookie});

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      cookie: json['cookie'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cookie': cookie,
    };
  }
}

