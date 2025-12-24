import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme/app_colors.dart';
import '../models/subscription.dart';
import '../services/subscription_service.dart';

/// Subscription status and trial activation page
class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  UserSubscription? _subscription;
  bool _isLoading = true;
  bool _hasUsedTrial = false;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    setState(() => _isLoading = true);
    
    // Check for expired subscriptions first
    await SubscriptionService.checkAndUpdateExpiredSubscriptions();
    
    final subscription = await SubscriptionService.getSubscription();
    final hasUsedTrial = await SubscriptionService.hasUsedFreeTrial();
    
    setState(() {
      _subscription = subscription;
      _hasUsedTrial = hasUsedTrial;
      _isLoading = false;
    });
  }

  Future<void> _activateFreeTrial() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check if already used trial
    if (_hasUsedTrial) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already used your free trial.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Check if already has trial or premium
    if (_subscription?.tier != SubscriptionTier.free) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You already have an active subscription!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Free Trial'),
        content: const Text(
          '🎉 Get 1 month of Premium FREE!\n\n'
          'Includes:\n'
          '• Unlimited recipe generations\n'
          '• Unlimited saved favorites\n'
          '• Export & print recipes\n'
          '• Full history access\n\n'
          'Start your free trial now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Start Free Trial'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      // Activate 30-day trial
      await SubscriptionService.activateFreeTrial();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Free trial activated! Enjoy Premium for 30 days!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Reload subscription
        await _loadSubscription();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Current Status Card
                  _buildStatusCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Features comparison
                  if (_subscription?.tier == SubscriptionTier.free && !_hasUsedTrial)
                    _buildFreeTrialOffer(),
                  
                  if (_subscription?.tier == SubscriptionTier.free && _hasUsedTrial)
                    _buildTrialAlreadyUsed(),
                  
                  if (_subscription?.isPremium == true ||
                      _subscription?.isTrial == true)
                    _buildPremiumFeatures(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final isPremium = _subscription?.isPremium ?? false;
    final isTrial = _subscription?.isTrial ?? false;
    final daysRemaining = _subscription?.daysRemaining;

    IconData icon;
    Color color;
    String title;
    String subtitle;

    if (isPremium || isTrial) {
      icon = Icons.star;
      color = AppColors.success;
      title = isTrial ? '✨ Free Trial Active' : '💎 Premium Active';
      subtitle = daysRemaining != null
          ? '$daysRemaining days remaining'
          : 'Active subscription';
    } else {
      icon = Icons.star_border;
      color = AppColors.textSecondary;
      title = 'Free Plan';
      subtitle = '5 recipes per day • 10 saved favorites';
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isPremium || isTrial
              ? LinearGradient(
                  colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeTrialOffer() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.secondary.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎁 Limited Time Offer',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Get Premium FREE for 30 days!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem('♾️ Unlimited recipe generations'),
            _buildFeatureItem('♾️ Unlimited saved favorites'),
            _buildFeatureItem('♾️ Unlimited fridge items'),
            _buildFeatureItem('📄 Export & print recipes'),
            _buildFeatureItem('📜 Full recipe history'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _activateFreeTrial,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start Free Trial',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'No payment required • Cancel anytime',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrialAlreadyUsed() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Trial Already Used',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'You\'ve already enjoyed your 30-day free trial of Premium.\n\n'
              'Paid subscription plans coming soon!',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Current Free Plan includes:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _buildFeatureItem('5 recipe generations per day'),
            _buildFeatureItem('10 saved favorites'),
            _buildFeatureItem('50 fridge items'),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFeatures() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Premium Features',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem('♾️ Unlimited recipe generations'),
            _buildFeatureItem('♾️ Unlimited saved favorites'),
            _buildFeatureItem('♾️ Unlimited fridge items'),
            _buildFeatureItem('📄 Export & print recipes'),
            _buildFeatureItem('📜 Full recipe history'),
            _buildFeatureItem('⚡ Priority support'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
