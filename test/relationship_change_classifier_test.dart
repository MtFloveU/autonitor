import 'package:autonitor/core/relationship_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String? classify({
    required bool wasFollower,
    required bool wasFollowing,
    required bool isNowFollower,
    required bool isNowFollowing,
    String oldStatus = 'normal',
    String oldKeptStatus = 'normal',
    String currentStatus = 'normal',
  }) => classifyKeptRelationshipChange(
    wasFollower: wasFollower,
    wasFollowing: wasFollowing,
    isNowFollower: isNowFollower,
    isNowFollowing: isNowFollowing,
    oldStatus: oldStatus,
    oldKeptStatus: oldKeptStatus,
    currentStatus: currentStatus,
  );

  test('classifies a followed user following back as be_followed_back', () {
    expect(
      classify(
        wasFollower: false,
        wasFollowing: true,
        isNowFollower: true,
        isNowFollowing: true,
      ),
      'be_followed_back',
    );
  });

  test('classifies following a current follower as be_followed_back', () {
    expect(
      classify(
        wasFollower: true,
        wasFollowing: false,
        isNowFollower: true,
        isNowFollowing: true,
      ),
      'be_followed_back',
    );
  });

  test('classifies re-following a previously unfollowed user as recovered', () {
    expect(
      classify(
        wasFollower: false,
        wasFollowing: false,
        isNowFollower: false,
        isNowFollowing: true,
        oldStatus: 'normal_unfollowed',
      ),
      'recovered',
    );
  });

  test('does not classify a follower-only change as recovery', () {
    expect(
      classify(
        wasFollower: false,
        wasFollowing: false,
        isNowFollower: true,
        isNowFollowing: false,
        oldStatus: 'normal_unfollowed',
      ),
      isNull,
    );
  });
}
