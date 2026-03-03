import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:star_cities/shared/widgets/grid_loading_indicator.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _supabase = Supabase.instance.client;
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isCheckingUsername = false;
  String? _usernameError;
  Timer? _debounce;

  bool get _isInitialSetup {
    final metadata = _supabase.auth.currentUser?.userMetadata;
    return metadata == null || metadata['username'] == null;
  }

  @override
  void initState() {
    super.initState();
    final currentUsername = _supabase.auth.currentUser?.userMetadata?['username'] as String?;
    if (currentUsername != null) {
      _usernameController.text = currentUsername;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    setState(() {
      _usernameError = null;
    });

    if (value.length < 3) return;

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _checkUsernameAvailability(value);
    });
  }

  Future<void> _checkUsernameAvailability(String username) async {
    setState(() => _isCheckingUsername = true);
    try {
      final res = await _supabase
          .from('user_profiles')
          .select('id')
          .eq('username', username)
          .maybeSingle();
      
      if (res != null && res['id'] != _supabase.auth.currentUser?.id) {
        setState(() => _usernameError = 'Username is already taken');
      }
    } catch (e) {
      // Ignore errors for availability check
    } finally {
      if (mounted) setState(() => _isCheckingUsername = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _usernameError != null) return;

    setState(() => _isLoading = true);

    try {
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'username': _usernameController.text.trim(),
          },
        ),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isInitialSetup ? 'INITIALIZE PROFILE' : 'EDIT PROFILE'),
        actions: [
          IconButton(
            onPressed: () => _supabase.auth.signOut(),
            icon: Icon(LucideIcons.logOut, color: theme.colorScheme.error),
            tooltip: 'SIGN OUT',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isInitialSetup) ...[
                    const Text(
                      'WELCOME COMMANDER.\nPLEASE INITIALIZE YOUR CALLSIGN.',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                  ],
                  TextFormField(
                    controller: _usernameController,
                    onChanged: _onUsernameChanged,
                    decoration: InputDecoration(
                      labelText: 'USERNAME',
                      suffixIcon: _isCheckingUsername 
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: GridLoadingIndicator(size: 20),
                          )
                        : null,
                      errorText: _usernameError,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Username is required';
                      if (value.trim().length < 3) return 'Minimum 3 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 48),
                  _isLoading
                      ? const Center(child: GridLoadingIndicator(size: 40))
                      : ElevatedButton(
                          onPressed: _saveProfile,
                          child: Text(_isInitialSetup ? 'START CAREER' : 'UPDATE PROFILE'),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
