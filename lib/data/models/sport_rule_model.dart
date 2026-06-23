import 'package:flutter/material.dart';

class SportRuleItem {
  final String title;
  final String cardSubtitle;
  final String subtitle;
  final String emoji;
  final Color color;
  final List<SportRule> rules;

  const SportRuleItem({
    required this.title,
    required this.cardSubtitle,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.rules,
  });
}

class SportRule {
  final String title;
  final String description;

  const SportRule({
    required this.title,
    required this.description,
  });
}
