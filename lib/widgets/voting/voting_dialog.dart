/// Voting Dialog Widget - Main Entry Point
/// Simplified dialog that delegates to focused sub-components

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'voting_state.dart';
import 'voting_edit_form.dart';
import 'voting_list.dart';

class VotingDialog extends StatefulWidget {
  final String barcode;
  final Map<String, dynamic> currentData;

  const VotingDialog({
    super.key,
    required this.barcode,
    required this.currentData,
  });

  @override
  State<VotingDialog> createState() => _VotingDialogState();
}

class _VotingDialogState extends State<VotingDialog> {
  late final VotingState _state;

  @override
  void initState() {
    super.initState();
    _state = VotingState(
      barcode: widget.barcode,
      currentData: widget.currentData,
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );
    _state.loadSubmissions();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            if (_state.isEditMode)
              VotingEditForm(
                state: _state,
                onSubmit: () => _handleSubmit(context),
              )
            else
              VotingList(
                state: _state,
                onVote: (index) => _handleVote(context, index),
                onEnterEditMode: _state.enterEditMode,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        if (_state.isEditMode)
          IconButton(
            onPressed: () => _handleExitEditMode(context),
            icon: const Icon(Icons.arrow_back),
            color: AppColors.primary,
            tooltip: 'Back to voting',
          ),
        Icon(
          _state.isEditMode ? Icons.edit : Icons.how_to_vote,
          color: AppColors.primary,
          size: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _state.isEditMode ? 'Edit Product Info' : 'Vote for Correct Info',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _state.isEditMode ? 'Submit your version' : 'Help improve product data',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  void _handleExitEditMode(BuildContext context) {
    // CRITICAL: Unfocus before removing form to prevent mouse tracker freeze
    FocusScope.of(context).unfocus();
    _state.exitEditMode();
  }

  Future<void> _handleVote(BuildContext context, int index) async {
    try {
      await _state.vote(index);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Vote recorded!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSubmit(BuildContext context) async {
    // Validate
    final name = _state.nameController.text.trim();
    if (name.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a product name'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // CRITICAL: Unfocus BEFORE any async/state work
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 50));
    
    if (!mounted) return;

    try {
      await _state.submitEdit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Your version has been submitted!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
