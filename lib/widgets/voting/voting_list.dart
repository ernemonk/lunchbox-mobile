/// Voting List Widget
/// Shows all submissions with voting functionality

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'voting_state.dart';

class VotingList extends StatelessWidget {
  final VotingState state;
  final Function(int) onVote;
  final VoidCallback onEnterEditMode;

  const VotingList({
    super.key,
    required this.state,
    required this.onVote,
    required this.onEnterEditMode,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoBox(),
          const SizedBox(height: 16),
          _buildContent(),
          if (!state.loading && state.submissions.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSubmitNewButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Vote for the most accurate product information. The version with the most votes becomes the consensus.',
              style: TextStyle(fontSize: 12, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (state.loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state.submissions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              const Text(
                'No submissions yet.\nBe the first to contribute!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onEnterEditMode,
                icon: const Icon(Icons.add),
                label: const Text('Submit My Version'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Flexible(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: state.submissions.length,
        itemBuilder: (context, index) => _buildSubmissionCard(index),
      ),
    );
  }

  Widget _buildSubmissionCard(int index) {
    final submission = state.submissions[index];
    final isUserVote = state.userVote == index;
    final votes = submission['votes'] as int;
    final isTopVoted = index == 0;

    return Card(
      color: isUserVote 
          ? AppColors.primary.withValues(alpha: 0.1) 
          : AppColors.background,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => onVote(index),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildThumbnail(submission),
              const SizedBox(width: 12),
              _buildProductInfo(submission, isTopVoted),
              const SizedBox(width: 8),
              _buildVoteButton(votes, isUserVote),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(Map<String, dynamic> submission) {
    if (submission['image_url'] != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          submission['image_url'],
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 50,
            height: 50,
            color: Colors.grey[800],
            child: const Icon(Icons.image_not_supported, size: 20),
          ),
        ),
      );
    }
    
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.image, size: 20),
    );
  }

  Widget _buildProductInfo(Map<String, dynamic> submission, bool isTopVoted) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  submission['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isTopVoted) ...[
                const SizedBox(width: 4),
                const Icon(Icons.verified, size: 14, color: Colors.green),
              ],
            ],
          ),
          if (submission['brand'] != null) ...[
            const SizedBox(height: 2),
            Text(
              submission['brand'],
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            submission['category'] ?? 'Other',
            style: TextStyle(fontSize: 11, color: AppColors.accent),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteButton(int votes, bool isUserVote) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isUserVote ? AppColors.primary : Colors.grey[800],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUserVote ? Icons.check : Icons.thumb_up,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            '$votes',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitNewButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onEnterEditMode,
        icon: const Icon(Icons.add_circle_outline, size: 18),
        label: const Text(
          'Submit Different Version',
          style: TextStyle(fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
