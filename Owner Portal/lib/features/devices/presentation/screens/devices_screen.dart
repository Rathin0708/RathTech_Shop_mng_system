import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/device_model.dart';
import '../providers/device_providers.dart';

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All'; // 'All', 'Online', 'Offline'

  void _revokeAccess(String terminalId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Terminal Authorization?'),
        content: Text('Terminating session for $terminalId will instantly force-logout the active cashier and disable offline caching permissions on that device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(devicesListProvider.notifier).revokeDevice(terminalId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🛑 Device $terminalId revoked and de-registered successfully.'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: const Text('Revoke Forever'),
          ),
        ],
      ),
    );
  }

  void _showAddSimulatedDeviceDialog() {
    final formKey = GlobalKey<FormState>();
    String id = 'TERM-${100 + DateTime.now().second * 3}';
    String tenant = '';
    String os = 'Android 14 (Sunmi)';
    String ip = '192.168.1.120';
    String version = 'v1.4.2';

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          title: Text('Register New Hardware Terminal', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: id,
                      decoration: const InputDecoration(labelText: 'Terminal ID / Serial'),
                      onChanged: (v) => id = v,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Tenant Shop Name', hintText: 'e.g. Apollo Pharmacy'),
                      onChanged: (v) => tenant = v,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: os,
                      decoration: const InputDecoration(labelText: 'Operating System'),
                      items: ['Android 14 (Sunmi)', 'Windows 11 POS', 'Windows 10 Pro', 'iPadOS 17', 'macOS Sonoma']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) os = v;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: ip,
                            decoration: const InputDecoration(labelText: 'Local IP Assignment'),
                            onChanged: (v) => ip = v,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            initialValue: version,
                            decoration: const InputDecoration(labelText: 'App Version'),
                            onChanged: (v) => version = v,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final dev = DeviceModel(
                    id: id.trim().toUpperCase(),
                    tenant: tenant.trim(),
                    os: os,
                    ip: ip.trim(),
                    version: version.trim(),
                    status: 'Online',
                    lastSeen: 'Active Now',
                  );
                  ref.read(devicesListProvider.notifier).addDevice(dev);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Simulated device registered to tenant account!'), backgroundColor: AppColors.success),
                  );
                }
              },
              child: const Text('Register Lease'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(devicesListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter and Search logic
    final filteredDevices = devices.where((d) {
      final query = _searchQuery.toLowerCase();
      final matchesQuery = d.id.toLowerCase().contains(query) || d.tenant.toLowerCase().contains(query);
      
      if (_statusFilter == 'All') return matchesQuery;
      return matchesQuery && d.status.toLowerCase() == _statusFilter.toLowerCase();
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header with stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terminal Registration Hub',
                      style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monitor physical hardware allocations and enforce SaaS device limits across tenants.',
                      style: GoogleFonts.inter(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _showAddSimulatedDeviceDialog,
                      icon: const Icon(Icons.add_to_queue_rounded, size: 18),
                      label: const Text('Register Terminal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.devices_other_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            '${devices.length} Active Leases',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 2. Device Limit Monitoring Visual Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withValues(alpha: 0.9), const Color(0xFF4F46E5)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security_rounded, color: Colors.white, size: 48),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HARDWARE LICENSING ENFORCEMENT ACTIVE',
                          style: GoogleFonts.inter(letterSpacing: 1.5, fontWeight: FontWeight.w800, fontSize: 11, color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Device concurrency is constrained by tenant plans (Starter: 1 | Pro: 3 | Enterprise: ∞). Over-allocation is blocked automatically by API validators.',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 3. Search and filter panel
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF374151) : Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search by Terminal ID or Tenant...',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    height: 24,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: _statusFilter,
                    underline: const SizedBox(),
                    items: ['All', 'Online', 'Offline']
                        .map((s) => DropdownMenuItem(value: s, child: Text('$s Status', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _statusFilter = v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Main Auditing Table
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF374151)
                        : Colors.grey.shade200,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListView(
                  children: [
                    // Table Header
                    Container(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1F2937)
                          : Colors.grey.shade50,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text('TERMINAL ID / OS', style: _headerStyle())),
                          Expanded(flex: 3, child: Text('TENANT / CLIENT', style: _headerStyle())),
                          Expanded(flex: 2, child: Text('IP & VERSION', style: _headerStyle())),
                          Expanded(flex: 2, child: Text('STATUS / PINGS', style: _headerStyle())),
                          SizedBox(width: 120, child: Text('ACTIONS', style: _headerStyle())),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Data Rows
                    if (filteredDevices.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: Text('No active devices match selected criteria.')),
                      ),

                    ...filteredDevices.map((device) {
                      final bool isOnline = device.status == 'Online';
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF374151) : Colors.grey.shade100)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Row(
                          children: [
                            // OS & Type
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device.id,
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        device.os.toLowerCase().contains('windows') ? Icons.desktop_windows_rounded : Icons.phone_android_rounded,
                                        size: 12,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        device.os,
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Tenant
                            Expanded(
                              flex: 3,
                              child: Text(
                                device.tenant,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),

                            // Network
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device.ip,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  Text(
                                    device.version,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),

                            // Activity Sync Badge
                            Expanded(
                              flex: 2,
                              child: InkWell(
                                onTap: () {
                                  ref.read(devicesListProvider.notifier).toggleStatus(device.id);
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isOnline ? const Color(0xFF10B981) : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      device.lastSeen,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: isOnline ? const Color(0xFF10B981) : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Revoke Access
                            SizedBox(
                              width: 120,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  icon: const Icon(Icons.no_accounts_rounded, color: AppColors.error),
                                  onPressed: () => _revokeAccess(device.id),
                                  tooltip: 'Revoke Terminal Access',
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _headerStyle() {
    return GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1,
      color: Colors.grey.shade500,
    );
  }
}
