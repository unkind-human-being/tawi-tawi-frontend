import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../auth/screen/role_selection_screen.dart';
import 'commuter_edit_profile_screen.dart';

// NEW IMPORTS for the Report Feature
import '../../../core/database/local_db.dart';
import '../../sync_engine/services/sync_service.dart';
import '../../../core/theme/app_theme.dart';

class CommuterSettingsScreen extends StatefulWidget {
  final String fullName;
  final String initials;
  final String discountStatus;

  const CommuterSettingsScreen({
    super.key,
    required this.fullName,
    required this.initials,
    required this.discountStatus,
  });

  @override
  State<CommuterSettingsScreen> createState() => _CommuterSettingsScreenState();
}

class _CommuterSettingsScreenState extends State<CommuterSettingsScreen> {
  late String _currentName;
  late String _currentInitials;

  final Color _deepOcean = const Color(0xFF0B192C);
  final Color _neonTeal = const Color(0xFF00FFCA);
  final Color _softBg = const Color(0xFFF4F7F9);

  @override
  void initState() {
    super.initState();
    _currentName = widget.fullName;
    _currentInitials = widget.initials;
  }

  void _handleLogout(BuildContext context) {
    ApiClient.instance.options.headers.remove('Authorization');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (route) => false, 
    );
  }

  // --- REPORT INCIDENT BOTTOM SHEET ---
  void _showIncidentReportSheet(BuildContext context) {
    String selectedType = 'Safety Concern';
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, top: 24, left: 24, right: 24),
            decoration: BoxDecoration(color: context.dynamicCard, borderRadius:
            const BorderRadius.only(topLeft: Radius.circular(24), 
            topRight: Radius.circular(24))),
            child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: context.dynamicBorder,
                 borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text('Report an Issue', style: TextStyle(color: context.dynamicText, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('This report will be sent directly to the local government authorities.', style: TextStyle(color: context.dynamicMuted, fontSize: 12)),
                const SizedBox(height: 24),
                Text('Incident Type', style: TextStyle(color: context.dynamicMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: context.isDarkMode ? AppColors.darkBg : AppColors.softBg, borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true, value: selectedType, 
                      dropdownColor: context.dynamicCard,
                      items: ['Safety Concern', 'Overpricing', 'Vehicle Breakdown', 'Weather Delay', 'Other'].map((type) => DropdownMenuItem(value: type, child: Text(type, style: TextStyle(color: context.dynamicText, fontWeight: FontWeight.w600)))).toList(),
                      onChanged: (val) { if (val != null) setSheetState(() => selectedType = val); },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Description', style: TextStyle(color: context.dynamicMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: descController, maxLines: 3, 
                  style: TextStyle(color: context.dynamicText),
                  decoration: InputDecoration(hintText: 'Provide details about the incident...', hintStyle: TextStyle(color: context.dynamicMuted, fontSize: 13), filled: true, fillColor: context.isDarkMode ? AppColors.darkBg : AppColors.softBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (descController.text.trim().isEmpty) return;
                    final payload = { "commuter_name": _currentName, "incident_type": selectedType, "description": descController.text.trim(), "status": "Pending Review" };
                    
                    // Offline First: Queue the action locally
                    await LocalDatabase.instance.queueOfflineAction('/incidents/report', payload);
                    
                    // Attempt to sync immediately
                    SyncService.syncOfflineData();
                    
                    if (!context.mounted) return;
                    Navigator.pop(context); // Close the sheet
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Incident logged. It will sync automatically.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), 
                      backgroundColor: AppColors.neonTeal, 
                      behavior: SnackBarBehavior.floating
                    ));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('SUBMIT REPORT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final bool isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.softBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        foregroundColor: context.dynamicText,
        elevation: 0,
        centerTitle: true,
        title: const Text('Account Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          // Important: Pass the updated name back to the Dashboard when leaving!
          onPressed: () => Navigator.pop(context, _currentName), 
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48, 
                  backgroundColor: _deepOcean.withOpacity(0.1), 
                  child: Text(_currentInitials, style: TextStyle(color: _deepOcean, fontSize: 36, fontWeight: FontWeight.bold))
                ),
                const SizedBox(height: 16),
                Text(_currentName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _deepOcean)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _neonTeal.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    widget.discountStatus.toUpperCase(), 
                    style: TextStyle(color: Colors.teal[800], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          const Text('PREFERENCES', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          
          _buildSettingsTile(context, Icons.person_outline, 'Edit Profile', onTap: () async {
            final updatedName = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CommuterEditProfileScreen(currentName: _currentName),
              ),
            );
            
            if (updatedName != null && updatedName is String) {
              setState(() {
                _currentName = updatedName;
                _currentInitials = updatedName.isNotEmpty ? updatedName[0].toUpperCase() : 'C';
              });
            }
          }),

          _buildSettingsTile(context, Icons.payment, 'Payment Methods'),
          _buildSettingsTile(context, Icons.history, 'Trip History'),
          
          const SizedBox(height: 24),
          const Text('SYSTEM', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),

          _buildSettingsTile(context, Icons.info_outline, 'About Pemeyaan'),
          _buildSettingsTile(context, Icons.help_outline, 'Help & Support'),

          const SizedBox(height: 40),

          // NEW: Report Incident Button
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            tileColor: Colors.white,
            leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent)),
            title: const Text('Report an Incident', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
            onTap: () => _showIncidentReportSheet(context),
          ),
          const SizedBox(height: 12),

          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            tileColor: Colors.white,
            leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.logout, color: Colors.redAccent)),
            title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
            onTap: () => _handleLogout(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, IconData icon, String title, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: Colors.white,
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _softBg, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: _deepOcean, size: 20)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: _deepOcean, fontSize: 15)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: onTap ?? () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title coming soon.'), backgroundColor: _neonTeal, behavior: SnackBarBehavior.floating));
        },
      ),
    );
  }
}