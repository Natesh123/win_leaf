import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/rewards_provider.dart';
import '../core/app_colors.dart';
import 'widgets/gradient_background.dart';
import 'auth_screen.dart';
import '../models/point_history.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RewardsProvider>(
      builder: (context, provider, child) {
          if (provider.userId == null && !provider.isLoading) {
            return _buildLoginPrompt(context);
          }

          return GradientBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: const Text('My Points', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),

              ),
              body: RefreshIndicator(
                onRefresh: provider.fetchData,
                child: provider.isLoading 
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Points History',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'You have ${provider.customer?.points ?? 0} Points',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textGrey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildPointsHistoryTable(provider.pointsHistory),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
              ),
            ),
          );
        },
      );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('My Points', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stars_outlined, size: 80, color: AppColors.primaryOrange),
                const SizedBox(height: 24),
                const Text(
                  'Rewards Await!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,color: AppColors.textDark),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sign in to your account to view your reward points and exclusive benefits.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black)
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {
                    // Navigate to AuthScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    );
                  },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Login Now'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildPointsHistoryTable(List<PointHistory> history) {
    if (history.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardGrey),
        ),
        child: const Center(
          child: Text('No points history found', style: TextStyle(color: AppColors.textGrey)),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryOrange,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white24)),
            ),
            child: Row(
              children: const [
                Expanded(flex: 3, child: Text('Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Date', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 1, child: Text('Points', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          // Rows
          ...history.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isLast = idx == history.length - 1;
            
            // Zebra striping effect like website
            final bgColor = idx % 2 == 0 ? Colors.white.withOpacity(0.05) : Colors.transparent;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: bgColor,
                border: isLast ? null : const Border(bottom: BorderSide(color: Colors.white12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3, 
                    child: Text(
                      item.event, 
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontStyle: FontStyle.italic),
                    )
                  ),
                  Expanded(
                    flex: 2, 
                    child: Text(
                      _formatDate(item.date), 
                      style: const TextStyle(color: Colors.white, fontSize: 11, decoration: TextDecoration.underline),
                    )
                  ),
                  Expanded(
                    flex: 1, 
                    child: Text(
                      item.points, 
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    )
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      if (dateStr.isEmpty) return 'Unknown';
      if (dateStr.contains('ago')) return dateStr;
      
      final date = DateTime.tryParse(dateStr);
      if (date == null) return dateStr;
      
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inMinutes < 60) {
        return '${diff.inMinutes} minutes ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} hours ago';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} days ago';
      } else {
        return DateFormat('MMM dd, yyyy').format(date);
      }
    } catch (e) {
      return dateStr;
    }
  }

}
