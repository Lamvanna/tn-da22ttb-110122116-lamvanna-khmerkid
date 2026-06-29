/// Model dữ liệu cho thử thách hàng ngày
class DailyChallenge {
  final String title;
  final int rewardStars;
  final bool isCompleted;

  const DailyChallenge({
    required this.title,
    required this.rewardStars,
    this.isCompleted = false,
  });
}

/// Dữ liệu mẫu thử thách
class DailyChallengeData {
  DailyChallengeData._();

  static const List<DailyChallenge> challenges = [
    DailyChallenge(
      title: 'Làm 3 bài kiểm tra',
      rewardStars: 10,
      isCompleted: true,
    ),
    DailyChallenge(
      title: 'Đạt 80% điểm',
      rewardStars: 15,
      isCompleted: true,
    ),
    DailyChallenge(
      title: 'Hoàn thành không sai lần nào',
      rewardStars: 25,
      isCompleted: false,
    ),
  ];
}
