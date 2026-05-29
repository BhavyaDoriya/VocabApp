import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // <-- 1. IMPORT FOUNDATION
import 'onboarding_screen.dart';
import "home_screen.dart";
import 'dusty_atmosphere.dart'; 
import 'tactical_button.dart'; 
import 'audio_manager.dart'; 

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController(); // For password reset
  final _supabase = Supabase.instance.client;
  
  bool _isLoading = false;
  bool _isSignUp = false;

  @override
  void initState() {
    super.initState();
    
    _supabase.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      // 1. INTERCEPT PASSWORD RECOVERY CLICKS
      if (event == AuthChangeEvent.passwordRecovery) {
        _showNewPasswordDialog();
      } 
      // 2. STANDARD LOGIN ROUTING
      else if ((event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession) && session != null) {
        try {
          final profile = await _supabase.from('profiles').select('active_category').eq('id', session.user.id).maybeSingle();
          
          if (mounted) {
            if (profile != null && profile['active_category'] != null) {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomeScreen()));
            } else {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const OnboardingScreen()));
            }
          }
        } catch (e) {
          if (mounted) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const OnboardingScreen()));
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  // --- PASSWORD RECOVERY LOGIC ---
  Future<void> _sendResetEmail() async {
    AudioManager().playThump();
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your email address first.'), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _supabase.auth.resetPasswordForEmail(
        _emailController.text.trim(),
        // 2. CONDITIONAL REDIRECT
        redirectTo: kIsWeb ? null : 'vocabapp://callback', 
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recovery directive sent. Check your inbox.'), backgroundColor: Color(0xFF2E7D32)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNewPasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111114), 
        shape: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), width: 1), 
        title: Text('RECALIBRATE PASSWORD', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your new security clearance code below.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 20),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, letterSpacing: 2.0),
              decoration: InputDecoration(
                labelText: 'NEW PASSWORD',
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
              ),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (_newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters.'), backgroundColor: Colors.redAccent));
                return;
              }
              AudioManager().playThump();
              try {
                await _supabase.auth.updateUser(UserAttributes(password: _newPasswordController.text));
                if (mounted) {
                  Navigator.pop(context);
                  _passwordController.clear();
                  _newPasswordController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PASSWORD RECALIBRATED'), backgroundColor: Color(0xFF2E7D32)));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
              }
            },
            child: Text('UPDATE', style: TextStyle(color: Theme.of(context).colorScheme.primary, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _emailAuth() async {
    AudioManager().startBgm(); 
    setState(() => _isLoading = true);
    
    try {
      if (_isSignUp) {
        await _supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          // 3. CONDITIONAL REDIRECT
          emailRedirectTo: kIsWeb ? null : 'vocabapp://callback', 
        );
        
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false, 
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF111114), 
              shape: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), width: 1), 
              title: Text('VERIFY YOUR IDENTITY', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
              content: Text('We just sent a secure link to ${_emailController.text.trim()}.\n\nPlease click the link in that email to initialize your instance.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              actions: [
                TextButton(
                  onPressed: () {
                    AudioManager().playClick();
                    Navigator.of(context).pop(); 
                    setState(() {
                      _isSignUp = false;
                      _passwordController.clear();
                    });
                  },
                  child: Text('UNDERSTOOD', style: TextStyle(color: Theme.of(context).colorScheme.primary, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      } else {
        await _supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          
        );
      }
    } on AuthException catch (e) {
      String errorMessage = e.message;
      if (e.message.contains('Invalid login credentials')) {
        errorMessage = 'Invalid credentials, or email not verified yet. Please check your inbox!';
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent));
    } catch (e) {
      if (e.toString().contains('Failed to fetch')) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Connecting to memory bank...'), backgroundColor: Theme.of(context).colorScheme.primary, duration: const Duration(seconds: 2)));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('An unexpected network error occurred.'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignIn() async {
    AudioManager().startBgm(); 
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        // 4. CONDITIONAL REDIRECT
        redirectTo: kIsWeb ? null : 'vocabapp://callback', 
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to launch Google Sign-In'), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        const DustyAtmosphere(), 
        
        Scaffold(
          backgroundColor: Colors.transparent, 
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 600, 
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('DAILY VOCAB', textAlign: TextAlign.center, style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 6)),
                        const SizedBox(height: 10),
                        Text(_isSignUp ? 'Initialize your database' : 'Access your memory bank', textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), letterSpacing: 2.0)),
                        const SizedBox(height: 60),

                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: theme.colorScheme.onSurface, letterSpacing: 1.5),
                          decoration: const InputDecoration(labelText: 'EMAIL'),
                        ),
                        const SizedBox(height: 24),

                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          style: TextStyle(color: theme.colorScheme.onSurface, letterSpacing: 2.0),
                          decoration: const InputDecoration(labelText: 'PASSWORD'),
                        ),
                        
                        // --- FORGOT PASSWORD INJECTION ---
                        if (!_isSignUp) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              onTap: () {
                                AudioManager().playClick();
                                _sendResetEmail();
                              },
                              child: Text('FORGOT PASSWORD?', style: TextStyle(color: theme.colorScheme.primary.withOpacity(0.6), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 32),

                        TacticalButton(label: _isSignUp ? 'REGISTER ENGINE' : 'ENGAGE', onTap: _emailAuth, isLoading: _isLoading),
                        const SizedBox(height: 16),
                        
                        TextButton(
                          onPressed: () {
                            AudioManager().playClick();
                            setState(() => _isSignUp = !_isSignUp);
                          },
                          child: Text(_isSignUp ? 'Already have an instance? Log in' : 'Need an instance? Register', style: TextStyle(color: theme.colorScheme.primary.withOpacity(0.7), letterSpacing: 1.0)),
                        ),

                        const SizedBox(height: 30),
                        
                        Row(
                          children: [
                            Expanded(child: Divider(color: theme.colorScheme.primary.withOpacity(0.2))),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text("OR", style: TextStyle(color: theme.colorScheme.primary.withOpacity(0.4), fontWeight: FontWeight.bold, letterSpacing: 2.0))),
                            Expanded(child: Divider(color: theme.colorScheme.primary.withOpacity(0.2))),
                          ],
                        ),
                        const SizedBox(height: 30),

                        InkWell(
                          onTap: _googleSignIn,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [theme.colorScheme.primary.withOpacity(0.08), Colors.transparent], begin: Alignment.centerLeft, end: Alignment.centerRight),
                              border: Border(
                                left: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5), width: 3), 
                                top: BorderSide(color: theme.colorScheme.primary.withOpacity(0.1), width: 1),
                                bottom: BorderSide(color: theme.colorScheme.primary.withOpacity(0.1), width: 1),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.account_circle, color: theme.colorScheme.primary, size: 20),
                                const SizedBox(width: 12),
                                Text("CONTINUE WITH GOOGLE", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 2.0, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}