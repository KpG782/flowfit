import 'package:flutter/material.dart';

/// Widget for displaying friendly error messages in Buddy onboarding
///
/// Shows errors in a kid-friendly way with optional retry action.
class BuddyErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool showRetry;

  const BuddyErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.showRetry = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (showRetry && onRetry != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget for displaying loading state in Buddy onboarding
class BuddyLoadingWidget extends StatelessWidget {
  final String? message;

  const BuddyLoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
