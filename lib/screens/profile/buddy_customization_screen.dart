import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../widgets/buddy_character_widget.dart';
import '../../widgets/buddy_idle_animation.dart';
import '../../utils/buddy_colors.dart';
import '../../utils/buddy_leveling.dart';

/// Buddy Customization Screen
///
/// Allows users to customize their whale Buddy's appearance:
/// - Change color (unlocked colors only)
/// - Select accessories (unlocked items only)
/// - Change background
///
/// Shows locked items with level requirements
class BuddyCustomizationScreen extends ConsumerStatefulWidget {
  const BuddyCustomizationScreen({super.key});

  @override
  ConsumerState<BuddyCustomizationScreen> createState() =>
      _BuddyCustomizationScreenState();
}

class _BuddyCustomizationScreenState
    extends ConsumerState<BuddyCustomizationScreen> {
  String _selectedColor = 'blue';
  final int _currentLevel = 5; // TODO: Get from actual Buddy profile

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FD),
      appBar: AppBar(
        title: const Text('Customize Your Whale'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(onPressed: _handleSave, child: const Text('Save')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Buddy preview
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: BuddyIdleAnimation(
                  child: BuddyCharacterWidget(
                    color: BuddyColors.getColor(_selectedColor),
                    size: 150,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Color selection
            Text(
              'Colors',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF314158),
              ),
            ),

            const SizedBox(height: 16),

            _buildColorGrid(),

            const SizedBox(height: 32),

            // Coming soon sections
            _buildComingSoonSection('Accessories', SolarIconsOutline.crown),
            const SizedBox(height: 24),
            _buildComingSoonSection('Backgrounds', SolarIconsOutline.gallery),
          ],
        ),
      ),
    );
  }

  Widget _buildColorGrid() {
    final colors = BuddyColors.getAllColorsInOrder();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((colorName) {
        final isUnlocked = BuddyColors.isUnlocked(colorName, _currentLevel);
        final isSelected = _selectedColor == colorName;
        final color = BuddyColors.getColor(colorName);
        final levelRequired = BuddyColors.getLevelRequirement(colorName);

        return GestureDetector(
          onTap: isUnlocked
              ? () {
                  setState(() {
                    _selectedColor = colorName;
                  });
                }
              : null,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isUnlocked ? color : Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                if (isSelected)
                  const Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                if (!isUnlocked)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock, color: Colors.grey, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          'Lvl $levelRequired',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildComingSoonSection(String title, IconData icon) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF314158),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Coming soon!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleSave() {
    // TODO: Save to Supabase
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Buddy color changed to ${BuddyColors.getDisplayName(_selectedColor)}!',
        ),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
    Navigator.pop(context);
  }
}
