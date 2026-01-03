import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../main.dart';

/// Edit Profile Screen
///
/// Allows users to update their profile information including name, bio, and location.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  User? _currentUser;
  String? _profilePhotoUrl;
  DateTime? _birthday;
  bool _isFirstTimeSetup = false;

  @override
  void initState() {
    super.initState();
    _currentUser = supabase.auth.currentUser;
    _loadUserProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh current user in case it wasn't available in initState
    if (_currentUser == null) {
      final user = supabase.auth.currentUser;
      if (user != null) {
        setState(() {
          _currentUser = user;
        });
        // Reload profile with the newly available user
        _loadUserProfile();
      }
    }
    // Check if this is first-time setup from registration
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is bool && args == true) {
      _isFirstTimeSetup = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    
    try {
      // Refresh session to ensure user is loaded (especially after signup)
      print('Refreshing session...');
      await supabase.auth.refreshSession();
      _currentUser = supabase.auth.currentUser;
      print('Current user after refresh: ${_currentUser?.id}');
      
      if (_currentUser == null) {
        print('No user found after session refresh - session might be missing');
        // Try to get session one more time with a delay
        await Future.delayed(const Duration(milliseconds: 500));
        await supabase.auth.refreshSession();
        _currentUser = supabase.auth.currentUser;
        
        if (_currentUser == null) {
          print('Still no user - redirecting to login');
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Session expired. Please login again.'),
                backgroundColor: Colors.red,
              ),
            );
            Navigator.pushReplacementNamed(context, '/welcome');
          }
          return;
        }
      }

      // Load user profile from database
      print('Loading user profile for: ${_currentUser!.id}');
      final profile = await _authService.getUserProfile(_currentUser!.id);
      
      if (profile != null && mounted) {
        setState(() {
          _nameController.text = profile['display_name'] ?? _currentUser?.userMetadata?['name'] ?? '';
          _bioController.text = profile['bio'] ?? '';
          _locationController.text = profile['location'] ?? 'PANABO';
          _profilePhotoUrl = profile['avatar_url'];
          if (profile['birthday'] != null) {
            _birthday = DateTime.parse(profile['birthday']);
          }
          _isLoading = false;
        });
      } else if (mounted) {
        // Use metadata if no profile exists yet
        setState(() {
          _nameController.text = _currentUser?.userMetadata?['name'] ?? '';
          _locationController.text = 'PANABO';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error loading profile: ${e.toString()}');
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentUser == null) return;

    setState(() => _isSaving = true);

    try {
      final updates = {
        'display_name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'location': _locationController.text.trim(),
        'avatar_url': _profilePhotoUrl,
        'birthday': _birthday?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _authService.updateUserProfile(_currentUser!.id, updates);

      if (mounted) {
        _showSnackBar('Profile updated successfully!');
        
        if (_isFirstTimeSetup) {
          // First-time setup, navigate to home
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // Regular edit, go back
          Navigator.pop(context, true); // Return true to indicate profile was updated
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error updating profile: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _uploadProfilePhoto() async {
    try {
      // Check if user is logged in, try to refresh if not
      if (_currentUser == null) {
        _currentUser = supabase.auth.currentUser;
        if (_currentUser != null) {
          setState(() {}); // Update UI with new user
        }
      }
      
      if (_currentUser == null) {
        if (mounted) {
          _showSnackBar('Please wait, loading user data...');
        }
        return;
      }

      // Pick image file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        // Show loading
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uploading photo...')),
          );
        }

        // Upload to storage
        final storageService = StorageService();
        final photoUrl = await storageService.uploadProfilePicture(result.files.first);

        // Update state
        setState(() {
          _profilePhotoUrl = photoUrl;
        });

        if (mounted) {
          _showSnackBar('Photo uploaded successfully!');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error uploading photo: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _isFirstTimeSetup 
            ? null  // No back button for first-time setup
            : IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          _isFirstTimeSetup ? 'Complete Your Profile' : 'Edit Profile',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          if (_isFirstTimeSetup)
            TextButton(
              onPressed: () {
                // Skip profile setup and go to home
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: Text(
                'Skip',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _isFirstTimeSetup ? 'Done' : 'Save',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Picture Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: theme.primaryColor.withOpacity(0.2),
                          backgroundImage: _profilePhotoUrl != null 
                              ? NetworkImage(_profilePhotoUrl!)
                              : null,
                          child: _profilePhotoUrl == null
                              ? Text(
                                  _nameController.text.isNotEmpty
                                      ? _nameController.text[0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, size: 20),
                              color: Colors.white,
                              onPressed: _uploadProfilePhoto,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentUser?.email ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Form Fields
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Name',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    _buildDivider(),
                    _buildTextField(
                      controller: _locationController,
                      label: 'Location',
                      icon: Icons.location_on_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your location';
                        }
                        return null;
                      },
                    ),
                    _buildDivider(),
                    _buildBirthdayField(),
                    _buildDivider(),
                    _buildTextField(
                      controller: _bioController,
                      label: 'Bio',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                      hint: 'Tell us a bit about yourself',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Additional Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Your profile information helps other users know more about you and builds trust in the community.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Colors.grey[200]),
    );
  }

  Widget _buildBirthdayField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: _birthday ?? DateTime(now.year - 25),
            firstDate: DateTime(1900),
            lastDate: now,
            helpText: 'Select your birthday',
          );
          if (picked != null) {
            setState(() {
              _birthday = picked;
            });
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Birthday',
            prefixIcon: const Icon(Icons.cake_outlined),
            suffixIcon: _birthday != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        _birthday = null;
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _birthday != null
                    ? _formatDate(_birthday!)
                    : 'Select your birthday',
                style: TextStyle(
                  fontSize: 16,
                  color: _birthday != null ? Colors.black : Colors.grey[600],
                ),
              ),
              if (_birthday != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_calculateAge(_birthday!)} years old',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  int _calculateAge(DateTime birthday) {
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month || (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age;
  }
}
