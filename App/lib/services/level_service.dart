import 'dart:math';

class LevelService {
  // --- EXP Calculation Logic ---

  /// Focus (Intelligence) EXP
  /// - < 30 mins: 1 exp/min
  /// - 30-60 mins: 2 exp/min (marginal)
  /// - > 60 mins: 3 exp/min (marginal)
  static int calculateFocusExp(int minutes) {
    if (minutes <= 30) {
      return minutes * 1;
    } else if (minutes <= 60) {
      return (30 * 1) + ((minutes - 30) * 2);
    } else {
      return (30 * 1) + (30 * 2) + ((minutes - 60) * 3);
    }
  }

  /// Sleep (Mind) EXP
  /// - 1 exp/min
  static int calculateSleepExp(int minutes) {
    return minutes * 1;
  }

  /// Cardio (Strength) EXP
  /// - 2 exp/min
  static int calculateCardioExp(int minutes) {
    return minutes * 2;
  }

  /// Weight Training (Strength) EXP
  /// - 1 exp/rep
  static int calculateWeightExp(int reps) {
    return reps * 1;
  }

  // --- Coin Calculation Logic ---

  static int calculateFocusCoins(int minutes) {
    return minutes; // 1 coin per minute
  }

  static int calculateSleepCoins(int minutes) {
    return (minutes / 2).floor(); // 0.5 coin per minute
  }

  static int calculateCardioCoins(int minutes) {
    return minutes; // 1 coin per minute
  }

  static int calculateWeightCoins(int reps) {
    return (reps / 5).floor(); // 1 coin per 5 reps
  }

  // --- Leveling Logic ---

  /// Required EXP to reach next level from current level
  /// Formula: 10 * (level ^ 1.5)
  static int getExpToNextLevel(int currentLevel) {
    return (10 * pow(currentLevel, 1.5)).round();
  }

  /// Checks if the pet levels up.
  /// Returns a map with 'newLevel', 'rolloverExp', 'levelsGained'
  static Map<String, int> checkLevelUp(int currentExp, int currentLevel) {
    int exp = currentExp;
    int level = currentLevel;
    int levelsGained = 0;

    while (true) {
      int requiredExp = getExpToNextLevel(level);
      if (exp >= requiredExp) {
        exp -= requiredExp;
        level++;
        levelsGained++;
      } else {
        break;
      }
    }

    return {
      'newLevel': level,
      'rolloverExp': exp,
      'levelsGained': levelsGained,
    };
  }

  /// Calculate Coin Reward
  /// Base reward for activity + Bonus for leveling up
  static int calculateCoinReward({
    required int baseReward,
    required int levelsGained,
  }) {
    // 50 coins bonus per level up
    return baseReward + (levelsGained * 50);
  }
}
