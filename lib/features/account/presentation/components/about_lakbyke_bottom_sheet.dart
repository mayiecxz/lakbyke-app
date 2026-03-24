import 'package:flutter/material.dart';
import 'package:lakbyke_mobile/core/constants/colors.dart';
import 'package:lakbyke_mobile/features/account/domain/about_constants.dart';

/// Bottom sheet that displays the official LakByke information in a modern card layout.
class AboutLakBykeBottomSheet extends StatelessWidget {
  const AboutLakBykeBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AboutLakBykeBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Limits height to 90% of screen so it's scrollable without covering the top
    final maxHeight = MediaQuery.of(context).size.height * 0.9;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'About LakByke',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.homePrimary,
                      ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                color: AppColors.textSecondary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            ],
          ),
          const SizedBox(height: 20),

          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Description
                  Text(
                    lakbykeAboutDescription.trim(),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 24),

                  // Official Channels Card
                  _buildSectionCard(
                    title: 'Official Channels',
                    icon: Icons.public_rounded,
                    children: [
                      _buildInfoRow(Icons.facebook_rounded, 'Facebook', lakbykeOfficialFacebook),
                      const Divider(height: 16, thickness: 1),
                      _buildInfoRow(Icons.email_rounded, 'Email', lakbykeOfficialEmail),
                      const Divider(height: 16, thickness: 1),
                      _buildInfoRow(Icons.language_rounded, 'Website', lakbykeOfficialWebsite),
                      const Divider(height: 16, thickness: 1),
                      _buildInfoRow(Icons.play_circle_fill_rounded, 'YouTube Teaser', lakbykeOfficialYoutubeTeaser),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Academic Affiliation Card
                  _buildSectionCard(
                    title: 'Academic Affiliation',
                    icon: Icons.school_rounded,
                    children: [
                      _buildInfoRow(Icons.account_balance_rounded, 'Institution', lakbykeInstitution),
                      const Divider(height: 16, thickness: 1),
                      _buildInfoRow(Icons.menu_book_rounded, 'Program', lakbykeProgram),
                      const Divider(height: 16, thickness: 1),
                      _buildInfoRow(Icons.person_outline_rounded, 'Adviser', lakbykeAdviser),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // The Team Card
                  _buildSectionCard(
                    title: 'Development Team',
                    icon: Icons.groups_rounded,
                    children: [
                      _buildTeamMember(lakbykeTeamLeader, 'Team Leader / PM', isLeader: true),
                      const Divider(height: 16, thickness: 1),
                      _buildTeamMember(lakbykeTeamFrontend1, 'Frontend Developer'),
                      _buildTeamMember(lakbykeTeamDba, 'Database Administrator'),
                      _buildTeamMember(lakbykeTeamAppDev, 'App Developer'),
                      _buildTeamMember(lakbykeTeamHardware, 'Hardware Specialist'),
                      _buildTeamMember(lakbykeTeamFrontend2, 'Frontend Developer'),
                      _buildTeamMember(lakbykeTeamBackend, 'Backend Developer'),
                      _buildTeamMember(lakbykeTeamDoc, 'Documentation Officer'),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a clean white card with a subtle shadow and header for grouping
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.homePrimary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  /// Helper for Channels and Academic Affiliation rows
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textTertiary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Helper specifically for team members
  Widget _buildTeamMember(String name, String role, {bool isLeader = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isLeader ? Icons.star_rounded : Icons.person_rounded,
            size: 18,
            color: isLeader ? Colors.orangeAccent : AppColors.textTertiary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    color: isLeader ? AppColors.homePrimary : AppColors.textPrimary,
                    fontWeight: isLeader ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}