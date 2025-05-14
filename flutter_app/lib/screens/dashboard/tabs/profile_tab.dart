import 'package:flutter/material.dart';
import 'package:payviya_app/core/theme/app_theme.dart';
import 'package:payviya_app/services/api_service.dart';
import 'package:payviya_app/widgets/user_avatar.dart';
import 'package:payviya_app/widgets/notification_icon.dart';
import 'package:payviya_app/screens/profile/edit_profile_screen.dart';
import 'package:payviya_app/services/auth_service.dart';
import 'package:payviya_app/screens/auth/login_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isLoading = true;
  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final response = await ApiService.get('/users/me');
      if (mounted) {
        setState(() {
          _userData = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı bilgileri yüklenirken bir hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: false,
            snap: false,
            backgroundColor: Colors.white,
            elevation: 0,
            title: Row(
              children: [
                UserAvatar(
                  name: _userData['name'] ?? '',
                  surname: _userData['surname'] ?? '',
                  radius: 18,
                  backgroundColor: AppTheme.primaryColor,
                  textColor: Colors.white,
                  fontSize: 16,
                ),
                const Expanded(
                  child: Text(
                    'Profilim',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),  
                const NotificationIcon(),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Profile Info Section
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      UserAvatar(
                        name: _userData['name'] ?? '',
                        surname: _userData['surname'] ?? '',
                        radius: 40,
                        backgroundColor: AppTheme.primaryColor,
                        textColor: Colors.white,
                        fontSize: 24,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${_userData['name'] ?? ''} ${_userData['surname'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userData['email'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_userData['country_code'] != null && _userData['phone_number'] != null)
                        Text(
                          '0${_userData['phone_number']}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                    ],
                  ),
                ),

                // Settings Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSettingsItem(
                        icon: Icons.person_outline,
                        title: 'Profil Bilgileri',
                        onTap: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(
                                userData: _userData,
                              ),
                            ),
                          );
                          
                          if (result != null && mounted) {
                            setState(() {
                              _userData = result;
                            });
                          }
                        },
                      ),
                      _buildSettingsItem(
                        icon: Icons.notifications_outlined,
                        title: 'Bildirim Ayarları',
                        onTap: () {
                          // Navigate to notification settings
                        },
                      ),
                      _buildSettingsItem(
                        icon: Icons.security,
                        title: 'Güvenlik',
                        onTap: () {
                          // Navigate to security settings
                        },
                      ),
                      _buildSettingsItem(
                        icon: Icons.help_outline,
                        title: 'Yardım',
                        onTap: () {
                          // Navigate to help
                        },
                      ),
                      _buildSettingsItem(
                        icon: Icons.info_outline,
                        title: 'Hakkında',
                        onTap: () {
                          // Navigate to about
                        },
                        showDivider: false,
                      ),
                    ],
                  ),
                ),

                // Logout Button
                Container(
                  margin: const EdgeInsets.all(16),
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Show confirmation dialog
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Çıkış Yap'),
                          content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('İptal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Çıkış Yap'),
                            ),
                          ],
                        ),
                      );

                      if (shouldLogout != true) return;

                      try {
                        // Clear local auth data and storage
                        await AuthService.logout();
                        
                        if (mounted) {
                          // Navigate to login and clear all routes
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Çıkış yapılırken bir hata oluştu'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Çıkış Yap'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
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
} 