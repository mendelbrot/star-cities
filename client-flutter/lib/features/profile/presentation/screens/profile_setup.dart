import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedIcon = 'default_icon';
  bool _isLoading = false;

  final List<String> _availableIcons = [
    'default_icon',
    'commander_alpha',
    'sector_beta',
    'orbit_gamma',
    'pulsar_delta',
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'username': _usernameController.text.trim(),
            'profile_icon': _selectedIcon,
          },
        ),
      );
      
      // The router will automatically refresh because AppStateManager 
      // is listening to onAuthStateChange.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  Text(
                    'INITIALIZE PROFILE',
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'USERNAME',
                      hintText: 'Enter your callsign',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Username is required';
                      }
                      if (value.trim().length < 3) {
                        return 'Minimum 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'SELECT ICON',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: _availableIcons.map((icon) {
                      final isSelected = _selectedIcon == icon;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIcon = icon),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.white24,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              icon.substring(0, 2).toUpperCase(),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 48),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : ElevatedButton(
                          onPressed: _saveProfile,
                          child: const Text('SAVE AND PROCEED'),
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
