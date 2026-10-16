import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/models/owner_profile.dart';
import '../../data/repositories/owner_repository.dart';
import 'login_screen.dart';
import 'owner_profile_screen.dart';
import '../../../employee/presentation/screens/employee_list_screen.dart';
import '../../../attendance/presentation/screens/attendance_list_screen.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  final _repository = OwnerRepository(ApiClient());

  late Future<OwnerProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _repository.getProfile();
  }

  Future<void> _logout() async {
    await TokenStorage.clearSession();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _openProfile(OwnerProfile profile) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => OwnerProfileScreen(profile: profile),
      ),
    );

    if (!mounted) return;

    setState(() {
      _profileFuture = _repository.getProfile();
    });
  }

  void _retryProfile() {
    setState(() {
      _profileFuture = _repository.getProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text(
          'SEMA Dashboard',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: _logout,
            icon: Icon(Icons.logout_rounded, color: colors.error),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<OwnerProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            final message = error is ApiException
                ? error.message
                : 'Unable to load your organization profile.';

            final unauthorized =
                error is ApiException && error.statusCode == 401;

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withValues(
                          alpha: 0.5,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        unauthorized
                            ? Icons.lock_outline_rounded
                            : Icons.cloud_off_outlined,
                        size: 40,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      unauthorized ? 'Session expired' : 'Unable to load data',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: unauthorized ? _logout : _retryProfile,
                      icon: Icon(
                        unauthorized
                            ? Icons.login_rounded
                            : Icons.refresh_rounded,
                      ),
                      label: Text(unauthorized ? 'Sign in again' : 'Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final profile = snapshot.data;

          if (profile == null) {
            return Center(
              child: FilledButton.icon(
                onPressed: _retryProfile,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              final future = _repository.getProfile();

              setState(() {
                _profileFuture = future;
              });

              try {
                await future;
              } catch (_) {
                // FutureBuilder handles errors automatically
              }
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                // Welcome Greeting Section
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WELCOME BACK',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile.ownerName.isEmpty
                                ? 'Organization Owner'
                                : profile.ownerName,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Professional Organization Profile Card
                Material(
                  color: colors.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () => _openProfile(profile),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Organization Logo or Custom Avatar Badge
                          FutureBuilder<Uint8List>(
                            future: profile.logoExists
                                ? _repository.getLogoBytes(profile.id)
                                : null,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return CircleAvatar(
                                  radius: 28,
                                  backgroundColor: colors.surface,
                                  backgroundImage: MemoryImage(snapshot.data!),
                                );
                              }
                              return Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    profile.organizationName.isEmpty
                                        ? 'O'
                                        : profile.organizationName[0]
                                              .toUpperCase(),
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          color: colors.onPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 14),
                          // Organization Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        profile.organizationName,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color: colors.onPrimaryContainer,
                                              fontWeight: FontWeight.w700,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: colors.surface.withValues(
                                          alpha: 0.7,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.edit_outlined,
                                        size: 14,
                                        color: colors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Email Row
                                Row(
                                  children: [
                                    Icon(
                                      Icons.email_outlined,
                                      size: 13,
                                      color: colors.onPrimaryContainer
                                          .withValues(alpha: 0.7),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        profile.email,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: colors.onPrimaryContainer
                                                  .withValues(alpha: 0.85),
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                // Website Row (Displayed if available)
                                if (profile.website != null &&
                                    profile.website!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.language_outlined,
                                        size: 13,
                                        color: colors.onPrimaryContainer
                                            .withValues(alpha: 0.7),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          profile.website!,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colors.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Section Label
                Text(
                  'MANAGEMENT MODULES',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 12),

                // Modern 2-Column Dashboard Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  children: [
                    _DashboardCard(
                      icon: Icons.people_outline_rounded,
                      title: 'Employees',
                      subtitle: 'Records & directory',
                      color: colors.surfaceContainerLow,
                      accentColor: colors.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const EmployeeListScreen(),
                          ),
                        );
                      },
                    ),
                    _DashboardCard(
                      icon: Icons.event_available_outlined,
                      title: 'Attendance',
                      subtitle: 'Daily log tracker',
                      color: colors.surfaceContainerLow,
                      accentColor: colors.tertiary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const AttendanceListScreen(),
                          ),
                        );
                      },
                    ),
                    _DashboardCard(
                      icon: Icons.payments_outlined,
                      title: 'Advances',
                      subtitle: 'Loans & requests',
                      color: colors.surfaceContainerLow,
                      accentColor: colors.secondary,
                      isComingSoon: true,
                    ),
                    _DashboardCard(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Hisab',
                      subtitle: 'Ledger & settlements',
                      color: colors.surfaceContainerLow,
                      accentColor: colors.primary,
                      isComingSoon: true,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.accentColor,
    this.onTap,
    this.isComingSoon = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color accentColor;
  final VoidCallback? onTap;
  final bool isComingSoon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accentColor, size: 22),
                  ),
                  if (isComingSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Soon',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
