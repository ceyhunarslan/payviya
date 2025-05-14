import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:payviya_app/models/user.dart';
import 'package:payviya_app/services/api_service.dart';
import 'package:payviya_app/services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class UserService {
  static User? _currentUser;
  static const storage = FlutterSecureStorage();
  
  // Get the current user from memory or fetch if not loaded
  static Future<User?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }
    
    // Try to get from local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_data');
      
      if (userJson != null) {
        _currentUser = User.fromJson(jsonDecode(userJson));
        return _currentUser;
      }
    } catch (e) {
      print('Error loading user from storage: $e');
    }
    
    // If not in storage, try to fetch from API
    return await fetchUserProfile();
  }
  
  // Fetch current user profile from the API
  static Future<User?> fetchUserProfile() async {
    try {
      // Try to fetch from API first
      try {
        print('Attempting to fetch user profile from API');
        final userData = await ApiService.get('/users/me');
        print('User data fetched successfully: $userData');
        
        final user = User.fromJson(userData);
        
        // Cache the user data
        _currentUser = user;
        _saveUserToStorage(user);
        
        return user;
      } catch (e) {
        print('Error fetching user profile: $e');
        
        // If API request failed, try to get from storage first
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString('user_data');
        
        if (userJson != null) {
          try {
            _currentUser = User.fromJson(jsonDecode(userJson));
            return _currentUser;
          } catch (storageError) {
            print('Error loading user from storage: $storageError');
          }
        }
        
        // If storage failed, try to create from token
        final token = await AuthService.getToken();
        if (token != null) {
          try {
            // Use the JWT token to extract user ID and create a temporary user
            final decodedToken = JwtDecoder.decode(token);
            print('Decoded token: $decodedToken');
            
            final userId = decodedToken['sub'];
            final userName = decodedToken['name'] ?? 'User';
            final userEmail = decodedToken['email'] ?? userId.toString();
            
            // Create a placeholder user with minimal information
            final user = User(
              id: int.tryParse(userId.toString()) ?? 1,
              email: userEmail,
              name: userName,
              surname: '',
              isActive: true,
              isAdmin: false,
              createdAt: DateTime.now(),
            );
            
            // Cache the user data
            _currentUser = user;
            _saveUserToStorage(user);
            
            return user;
          } catch (tokenError) {
            print('Error decoding token: $tokenError');
            
            // If we're in web environment and having token issues, let's try to login again
            if (kIsWeb) {
              print('Web environment detected with token issues. Redirecting to login');
              await AuthService.logout();
              return null;
            }
          }
        }
        
        // If all attempts fail, clear user data and return null
        await clearUserData();
        return null;
      }
    } catch (e) {
      print('Error in user profile recovery: $e');
      await clearUserData();
      return null;
    }
  }
  
  // Update user profile
  static Future<User?> updateProfile({
    String? name,
    String? surname,
    String? email,
    String? phone,
    String? countryCode,
  }) async {
    try {
      final userData = await ApiService.post('/users/update', {
        if (name != null) 'name': name,
        if (surname != null) 'surname': surname,
        if (email != null) 'email': email,
        if (phone != null) 'phone_number': phone,
        if (countryCode != null) 'country_code': countryCode,
      });
      
      final updatedUser = User.fromJson(userData);
      
      // Update cached user
      _currentUser = updatedUser;
      _saveUserToStorage(updatedUser);
      
      return updatedUser;
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }
  
  // Clear user data on logout
  static Future<void> clearUserData() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
  }
  
  // Save user to local storage
  static Future<void> _saveUserToStorage(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toJson()));
  }
} 