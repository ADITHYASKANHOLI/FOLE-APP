import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/youtube_utils.dart';
import '../data/admin_repository.dart';
import 'admin_auth_notifier.dart';
import 'admin_dashboard_screen.dart';

class AdminCreateLectureScreen extends ConsumerStatefulWidget {
  const AdminCreateLectureScreen({super.key});

  @override
  ConsumerState<AdminCreateLectureScreen> createState() =>
      _AdminCreateLectureScreenState();
}

class _AdminCreateLectureScreenState
    extends ConsumerState<AdminCreateLectureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _moduleIdController = TextEditingController();
  final _youtubeUrlController = TextEditingController();
  final _instructorController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _detectedVideoId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _youtubeUrlController.addListener(_onUrlChanged);
  }

  @override
  void dispose() {
    _youtubeUrlController.removeListener(_onUrlChanged);
    _titleController.dispose();
    _moduleIdController.dispose();
    _youtubeUrlController.dispose();
    _instructorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onUrlChanged() {
    final videoId = YouTubeUtils.extractVideoId(_youtubeUrlController.text);
    if (videoId != _detectedVideoId) {
      setState(() => _detectedVideoId = videoId);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_detectedVideoId == null) {
      setState(() => _errorMessage =
          'Please provide a valid YouTube link or 11-character video ID.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = ref.read(adminAuthNotifierProvider).valueOrNull ?? '';
      final repo = ref.read(adminRepositoryProvider);

      final success = await repo.createLesson(
        adminToken: token,
        title: _titleController.text,
        moduleId: _moduleIdController.text.trim(),
        youtubeUrl: _youtubeUrlController.text.trim(),
        instructor: _instructorController.text,
        description: _descriptionController.text,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lecture published successfully!'),
              backgroundColor: AppColors.successGreen,
            ),
          );
          ref.invalidate(adminDashboardProvider);
          context.pop();
        } else {
          setState(() {
            _errorMessage = 'Server rejected lecture creation.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        title: const Text(
          'Add New Lecture',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.errorRed.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Lecture Title
                _buildField(
                  controller: _titleController,
                  label: 'Lecture Title',
                  hint: 'e.g. Eigenvalues & Diagonalization',
                  validator: (v) => v == null || v.trim().length < 2
                      ? 'Title is required (min 2 characters)'
                      : null,
                ),
                const SizedBox(height: 16),

                // Module ID
                _buildField(
                  controller: _moduleIdController,
                  label: 'Module / Unit Identifier',
                  hint: 'e.g. mod-01 or Module UUID',
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Module ID is required'
                      : null,
                ),
                const SizedBox(height: 16),

                // YouTube URL / Video ID
                _buildField(
                  controller: _youtubeUrlController,
                  label: 'YouTube Link or Video ID',
                  hint: 'https://www.youtube.com/watch?v=... or 11-char ID',
                  helper: 'Supports watch URLs, youtu.be, shorts, and embeds',
                  validator: (v) => YouTubeUtils.extractVideoId(v) == null
                      ? 'Valid YouTube link required'
                      : null,
                ),
                const SizedBox(height: 12),

                // Live YouTube Thumbnail Preview Box
                if (_detectedVideoId != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xFFF59E0B), size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Verified Video ID: $_detectedVideoId',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              YouTubeUtils.getThumbnailUrl(_detectedVideoId)!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.black26,
                                child: const Center(
                                  child: Icon(Icons.broken_image_rounded,
                                      color: Colors.white30),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Instructor Name (optional)
                _buildField(
                  controller: _instructorController,
                  label: 'Instructor Name (Optional)',
                  hint: 'e.g. Dr. Sarah Ahmed',
                ),
                const SizedBox(height: 16),

                // Description (optional)
                _buildField(
                  controller: _descriptionController,
                  label: 'Lecture Description / Syllabus Coverage (Optional)',
                  hint: 'Brief summary of concepts derived in this lesson',
                  maxLines: 3,
                ),
                const SizedBox(height: 28),

                // Submit Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: AppColors.navy950,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.navy950),
                            ),
                          )
                        : const Text(
                            'Publish Lecture',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? helper,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            helperStyle: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: const Color(0xFF0F172A),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFF59E0B)),
            ),
          ),
        ),
      ],
    );
  }
}
