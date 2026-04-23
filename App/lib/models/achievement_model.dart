class Achievement {
  final String id;
  final String name;
  final String description;
  final String iconPath;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
  });
}

final List<Achievement> allAchievements = [
  Achievement(
    id: 'str_5',
    name: 'Apprentice Warrior',
    description: 'Reach Strength Level 5',
    iconPath: 'assets/icons/medal.png',
  ),
  Achievement(
    id: 'str_10',
    name: 'Master Warrior',
    description: 'Reach Strength Level 10',
    iconPath: 'assets/icons/medal.png',
  ),
  Achievement(
    id: 'int_5',
    name: 'Apprentice Scholar',
    description: 'Reach Intelligence Level 5',
    iconPath: 'assets/icons/medal.png',
  ),
  Achievement(
    id: 'int_10',
    name: 'Master Scholar',
    description: 'Reach Intelligence Level 10',
    iconPath: 'assets/icons/medal.png',
  ),
  Achievement(
    id: 'mind_5',
    name: 'Apprentice Meditator',
    description: 'Reach Mind Level 5',
    iconPath: 'assets/icons/medal.png',
  ),
  Achievement(
    id: 'mind_10',
    name: 'Master Meditator',
    description: 'Reach Mind Level 10',
    iconPath: 'assets/icons/medal.png',
  ),
];
