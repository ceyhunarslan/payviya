import 'package:flutter/material.dart';
import 'package:payviya_app/core/theme/app_theme.dart';
import 'package:payviya_app/services/auth_service.dart';
import 'package:payviya_app/screens/auth/login_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // Mock user data
  final Map<String, dynamic> _userData = {
    'name': 'Ahmet Yılmaz',
    'email': 'ahmet.yilmaz@example.com',
    'phoneNumber': '+90 555 123 4567',
    'profileImage': 'assets/images/avatar.png',
    'memberSince': 'Ocak 2023',
    'totalSavings': 876.50,
    'activeCampaigns': 5,
    'savedCards': 3,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile header with user info
              _buildProfileHeader(),
              
              // Stats section
              _buildStatsSection(),
              
              // Settings section
              _buildSettingsSection(),
              
              // About section
              _buildAboutSection(),
              
              // Log out button
              _buildLogoutButton(),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        children: [
          // Profile picture and edit button
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    width: 4,
                  ),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/avatar.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () {
                    // Change profile picture
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // User name
          Text(
            _userData['name'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          
          // Contact info
          Text(
            _userData['email'],
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _userData['phoneNumber'],
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          // Edit profile button
          OutlinedButton(
            onPressed: () {
              // Navigate to edit profile
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: AppTheme.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Profili Düzenle'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hesap Özeti',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.savings_outlined,
                  title: 'Toplam Tasarruf',
                  value: '₺${_userData['totalSavings']}',
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.local_offer_outlined,
                  title: 'Aktif Kampanyalar',
                  value: '${_userData['activeCampaigns']}',
                  color: AppTheme.primaryColor,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.credit_card_outlined,
                  title: 'Kayıtlı Kartlar',
                  value: '${_userData['savedCards']}',
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, right: 16),
            child: Text(
              'Hesap Ayarları',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingItem(
            icon: Icons.account_circle_outlined,
            title: 'Kişisel Bilgiler',
            onTap: () {
              // Navigate to personal info settings
            },
          ),
          _buildSettingItem(
            icon: Icons.lock_outline,
            title: 'Güvenlik',
            onTap: () {
              // Navigate to security settings
            },
          ),
          _buildSettingItem(
            icon: Icons.notifications_outlined,
            title: 'Bildirimler',
            onTap: () {
              // Navigate to notification settings
            },
          ),
          _buildSettingItem(
            icon: Icons.language_outlined,
            title: 'Dil ve Bölge',
            onTap: () {
              // Navigate to language settings
            },
          ),
          _buildSettingItem(
            icon: Icons.payment_outlined,
            title: 'Ödeme Tercihleri',
            onTap: () {
              // Navigate to payment preferences
            },
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, right: 16),
            child: Text(
              'Uygulama Hakkında',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingItem(
            icon: Icons.info_outline,
            title: 'Hakkımızda',
            onTap: () {
              // Show about page
            },
          ),
          _buildSettingItem(
            icon: Icons.contact_support_outlined,
            title: 'Yardım ve Destek',
            onTap: () {
              // Navigate to help and support
            },
          ),
          _buildSettingItem(
            icon: Icons.policy_outlined,
            title: 'Gizlilik Politikası',
            onTap: () {
              // Show privacy policy
            },
          ),
          _buildSettingItem(
            icon: Icons.description_outlined,
            title: 'Kullanım Koşulları',
            onTap: () {
              // Show terms of service
            },
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.textSecondaryColor,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 56,
            endIndent: 16,
          ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.only(top: 24, left: 16, right: 16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Logout logic
          _showLogoutConfirmationDialog();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Çıkış Yap',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              // Close the dialog
              Navigator.of(context).pop();
              
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              );
              
              try {
                // Perform logout
                await AuthService.logout();
                
                // Close loading indicator
                Navigator.of(context).pop();
                
                // Navigate to login screen and remove all previous routes
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              } catch (e) {
                // Close loading indicator
                Navigator.of(context).pop();
                
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Çıkış yapılırken bir hata oluştu: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Çıkış Yap',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
} 