import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../firebase_options.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

// ─── Riverpod Provider: Real-time staff list from Firestore ─────────────────
final staffListProvider = StreamProvider<List<UserEntity>>((ref) {
  final authState = ref.watch(authControllerProvider);
  final ownerTenantId = authState.user?.tenantId;

  Query query = FirebaseFirestore.instance.collection('users');

  if (ownerTenantId != null) {
    query = query.where('tenantId', isEqualTo: ownerTenantId);
  } else {
    // Fallback: show all users if tenantId is not yet set (initial owner)
    query = query.orderBy('createdAt', descending: false);
  }

  return query.snapshots().map((snap) =>
    snap.docs.map((doc) => UserModel.fromSnapshot(doc)).toList(),
  );
});

// ─── Staff Management Screen ──────────────────────────────────────────────────
class StaffManagementScreen extends ConsumerWidget {
  const StaffManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final staffAsync = ref.watch(staffListProvider);
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border(
                bottom: BorderSide(
                    color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => context.go(RouteNames.settings),
                      tooltip: 'Back to Settings',
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Staff & Roles Management',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddStaffDialog(context, ref, authState.user),
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text('Add New Staff'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active Team Members',
                      style: GoogleFonts.inter(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your employees, assign specific roles, and control their POS access.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  Expanded(
                    child: staffAsync.when(
                      loading: () => const Center(
                          child: CircularProgressIndicator()),
                      error: (e, _) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cloud_off_rounded,
                                size: 48, color: AppColors.error),
                            const SizedBox(height: 12),
                            Text('Could not load staff data.',
                                style: TextStyle(color: Colors.grey.shade600)),
                            Text('$e',
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.error)),
                          ],
                        ),
                      ),
                      data: (staffList) {
                        if (staffList.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.people_outline_rounded,
                                    size: 60, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text('No staff members yet.',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 16)),
                                const SizedBox(height: 8),
                                const Text(
                                    'Tap "Add New Staff" to create your first team member.',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 13)),
                              ],
                            ),
                          );
                        }
                        return _StaffListView(
                          staffList: staffList,
                          isDark: isDark,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddStaffDialog(
      BuildContext context, WidgetRef ref, UserEntity? owner) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddStaffDialog(ownerTenantId: owner?.tenantId ?? owner?.uid ?? ''),
    ).then((success) {
      if (success == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Staff account created and saved to Firebase!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }
}

// ─── Staff ListView ───────────────────────────────────────────────────────────
class _StaffListView extends StatelessWidget {
  final List<UserEntity> staffList;
  final bool isDark;

  const _StaffListView({required this.staffList, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: ListView.separated(
        itemCount: staffList.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        itemBuilder: (context, index) {
          final staff = staffList[index];
          final isOwner =
              staff.role == UserRole.admin || staff.role == UserRole.superAdmin;

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            leading: CircleAvatar(
              backgroundColor: isOwner
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : Colors.grey.shade200,
              child: Icon(
                isOwner
                    ? Icons.workspace_premium_rounded
                    : Icons.person_rounded,
                color:
                    isOwner ? AppColors.primary : Colors.grey.shade600,
              ),
            ),
            title: Text(staff.name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(staff.email,
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 12)),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRoleBadge(staff.role),
                const SizedBox(width: 16),
                if (!isOwner)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    color: isDark ? AppColors.cardDark : Colors.white,
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'disable',
                          child: Row(children: [
                            Icon(Icons.block_rounded,
                                size: 16, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Disable Account',
                                style: TextStyle(color: AppColors.error)),
                          ])),
                    ],
                    onSelected: (val) async {
                      if (val == 'disable') {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(staff.uid)
                            .update({'isActive': false});
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('${staff.name} has been disabled.'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    Color bgColor;
    Color textColor;
    String label;

    switch (role) {
      case UserRole.admin:
      case UserRole.superAdmin:
        bgColor = AppColors.primary.withValues(alpha: 0.15);
        textColor = AppColors.primary;
        label = 'OWNER';
        break;
      case UserRole.manager:
        bgColor = Colors.indigo.withValues(alpha: 0.15);
        textColor = Colors.indigo;
        label = 'MANAGER';
        break;
      case UserRole.accountant:
        bgColor = Colors.teal.withValues(alpha: 0.15);
        textColor = Colors.teal;
        label = 'ACCOUNTANT';
        break;
      case UserRole.cashier:
        bgColor = Colors.orange.withValues(alpha: 0.15);
        textColor = Colors.orange.shade800;
        label = 'CASHIER';
        break;
      default:
        bgColor = Colors.grey.withValues(alpha: 0.15);
        textColor = Colors.grey.shade700;
        label = 'STAFF';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.5)),
    );
  }
}

// ─── Add Staff Dialog ─────────────────────────────────────────────────────────
class _AddStaffDialog extends StatefulWidget {
  final String ownerTenantId;
  const _AddStaffDialog({required this.ownerTenantId});

  @override
  State<_AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends State<_AddStaffDialog> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  UserRole _selectedRole = UserRole.cashier;
  bool _isLoading = false;
  bool _obscurePass = true;
  String? _errorMsg;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      setState(() => _errorMsg = 'All fields are required.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _errorMsg = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      // ── Use Secondary Firebase App so Owner stays logged in ──────────────
      FirebaseApp secondaryApp;
      try {
        secondaryApp = Firebase.app('staff_creator');
      } catch (_) {
        secondaryApp = await Firebase.initializeApp(
          name: 'staff_creator',
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // Create Firebase Auth account for the new staff
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      final staffUid = credential.user!.uid;

      // Sign out the secondary app session immediately (Owner unaffected)
      await secondaryAuth.signOut();

      // ── Save staff profile to Firestore ──────────────────────────────────
      final userModel = UserModel(
        uid: staffUid,
        email: email,
        name: name,
        role: _selectedRole,
        tenantId: widget.ownerTenantId,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(staffUid)
          .set(userModel.toMap());

      if (!mounted) return;
      Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMsg = _parseError(e.code);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMsg = 'Unexpected error: $e';
      });
    }
  }

  String _parseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Use a different one.';
      case 'invalid-email':
        return 'The email address format is invalid.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      default:
        return 'Failed to create staff account. Code: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_add_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Add New Staff Member',
                    style: GoogleFonts.outfit(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            Text('Creates a Firebase Auth account + saves to Firestore.',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 24),

            // Error Banner
            if (_errorMsg != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_errorMsg!,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 12))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Full Name
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.badge_outlined),
                filled: true,
                fillColor: isDark ? AppColors.cardDark : Colors.grey.shade50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 14),

            // Email
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: const Icon(Icons.email_outlined),
                filled: true,
                fillColor: isDark ? AppColors.cardDark : Colors.grey.shade50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 14),

            // Role Dropdown
            DropdownButtonFormField<UserRole>(
              initialValue: _selectedRole,
              dropdownColor: isDark ? AppColors.cardDark : Colors.white,
              decoration: InputDecoration(
                labelText: 'Assign Role',
                prefixIcon: const Icon(Icons.admin_panel_settings_outlined),
                filled: true,
                fillColor: isDark ? AppColors.cardDark : Colors.grey.shade50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              items: const [
                DropdownMenuItem(
                  value: UserRole.manager,
                  child: Row(children: [
                    Icon(Icons.manage_accounts_rounded,
                        size: 18, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text('Manager – Full access except Settings'),
                  ]),
                ),
                DropdownMenuItem(
                  value: UserRole.accountant,
                  child: Row(children: [
                    Icon(Icons.calculate_rounded,
                        size: 18, color: Colors.teal),
                    SizedBox(width: 8),
                    Text('Accountant – Reports & Cash Ledger'),
                  ]),
                ),
                DropdownMenuItem(
                  value: UserRole.cashier,
                  child: Row(children: [
                    Icon(Icons.point_of_sale_rounded,
                        size: 18, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Cashier – Billing & Cash Drawer only'),
                  ]),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedRole = val);
              },
            ),
            const SizedBox(height: 14),

            // Password
            TextField(
              controller: _passCtrl,
              obscureText: _obscurePass,
              decoration: InputDecoration(
                labelText: 'Temporary Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePass
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscurePass = !_obscurePass),
                ),
                filled: true,
                fillColor: isDark ? AppColors.cardDark : Colors.grey.shade50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                helperText: 'Staff will use this to log in. Min 6 characters.',
              ),
            ),
            const SizedBox(height: 28),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _save,
                  icon: _isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.cloud_upload_rounded, size: 18),
                  label: Text(_isLoading ? 'Creating...' : 'Create & Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
