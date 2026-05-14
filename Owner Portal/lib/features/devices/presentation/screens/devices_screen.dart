import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  // Simulated Dataset of active terminal node registrations
  final List<Map<String, dynamic>> _devices = [
    {
      'id': 'TERM-AX901',
      'tenant': 'Sri Kumaran Groceries',
      'os': 'Windows 11',
      'ip': '192.168.1.45',
      'version': 'v1.4.2',
      'status': 'Online',
      'lastSeen': 'Active Now',
    },
    {
      'id': 'TERM-BR402',
      'tenant': 'Sri Kumaran Groceries',
      'os': 'Android 13 (Sunmi POS)',
      'ip': '192.168.1.48',
      'version': 'v1.4.2',
      'status': 'Offline',
      'lastSeen': '2 hours ago',
    },
    {
      'id': 'TERM-CL112',
      'tenant': 'Sangeetha Sweets',
      'os': 'Windows 10',
      'ip': '112.85.4.22',
      'version': 'v1.4.0',
      'status': 'Online',
      'lastSeen': 'Active Now',
    },
    {
      'id': 'TERM-DN774',
      'tenant': 'Rathna Stores Mega',
      'os': 'iPadOS 17',
      'ip': '192.168.0.101',
      'version': 'v1.4.2',
      'status': 'Online',
      'lastSeen': 'Active Now',
    },
    {
      'id': 'TERM-EP009',
      'tenant': 'Modern Bakers Co.',
      'os': 'Android 12',
      'ip': '10.0.2.15',
      'version': 'v1.3.9',
      'status': 'Offline',
      'lastSeen': '5 days ago',
    },
  ];

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
              setState(() {
                _devices.removeWhere((d) => d['id'] == terminalId);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('🛑 Device $terminalId revoked and de-registered successfully.'), backgroundColor: AppColors.error),
              );
            },
            child: const Text('Revoke Forever'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.devices_other_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${_devices.length} Activated Units',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // 2. Device Limit Monitoring Visual Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withOpacity(0.9), const Color(0xFF4F46E5)],
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

            // 3. Main Auditing Table
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
                          Expanded(flex: 2, child: Text('LAST ACTIVITY', style: _headerStyle())),
                          SizedBox(width: 120, child: Text('ACTIONS', style: _headerStyle())),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Data Rows
                    if (_devices.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: Text('No active devices registered.')),
                      ),

                    ..._devices.map((device) {
                      final bool isOnline = device['status'] == 'Online';
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
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
                                    device['id'],
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        device['os'].toString().contains('Windows') ? Icons.desktop_windows_rounded : Icons.phone_android_rounded,
                                        size: 12,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        device['os'],
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
                                device['tenant'],
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
                                    device['ip'],
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  Text(
                                    device['version'],
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),

                            // Activity Sync Badge
                            Expanded(
                              flex: 2,
                              child: Row(
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
                                    device['lastSeen'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isOnline ? const Color(0xFF10B981) : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Revoke Access
                            SizedBox(
                              width: 120,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  icon: const Icon(Icons.no_accounts_rounded, color: AppColors.error),
                                  onPressed: () => _revokeAccess(device['id']),
                                  tooltip: 'Revoke Terminal Access',
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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
