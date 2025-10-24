    class Account {
      /// The unique Twitter User ID (Rest ID / twid).
      final String id;
      /// The full cookie string required for authentication.
      final String cookie;
      /// The user's display name (e.g., "Elon Musk"). Fetched from API.
      final String? name;
      /// The user's screen name / handle (e.g., "elonmusk"). Fetched from API.
      final String? screenName;
      /// The URL for the user's profile image. Fetched from API.
      final String? avatarUrl;
    
      Account({
        required this.id,
        required this.cookie,
        this.name,
        this.screenName,
        this.avatarUrl,
      });
    
      /// Creates an Account instance from a JSON map.
      factory Account.fromJson(Map<String, dynamic> json) {
        return Account(
          id: json['id'] as String? ?? '', // Provide default empty string
          cookie: json['cookie'] as String? ?? '', // Provide default empty string
          name: json['name'] as String?,
          screenName: json['screenName'] as String?,
          avatarUrl: json['avatarUrl'] as String?,
        );
      }
    
      /// Converts the Account instance to a JSON map.
      Map<String, dynamic> toJson() {
        return {
          'id': id,
          'cookie': cookie,
          'name': name,
          'screenName': screenName,
          'avatarUrl': avatarUrl,
        };
      }
    
      // Optional: Add copyWith for easier updates
      Account copyWith({
        String? id,
        String? cookie,
        String? name,
        String? screenName,
        String? avatarUrl,
      }) {
        return Account(
          id: id ?? this.id,
          cookie: cookie ?? this.cookie,
          name: name ?? this.name,
          screenName: screenName ?? this.screenName,
          avatarUrl: avatarUrl ?? this.avatarUrl,
        );
      }
    
      // Optional: Override toString for better debugging
      @override
      String toString() {
        return 'Account(id: $id, name: $name, screenName: $screenName, avatarUrl: $avatarUrl, cookie: ${cookie.length > 10 ? cookie.substring(0, 10) + '...' : cookie})';
      }
    }