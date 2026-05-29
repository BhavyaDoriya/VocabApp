import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';
import 'study_screen.dart'; 
import 'settings_screen.dart';
import 'test_screen.dart';
import 'memory_bank_screen.dart'; // THE NEW ARCHIVE SCREEN
import 'audio_manager.dart'; // FOR THE THUMP SOUND
import 'dusty_atmosphere.dart'; // THE PHYSICS ENGINE
import 'tactical_button.dart'; // THE GAME BUTTON
import 'tactical_panel.dart'; // THE GAME HUD PANEL

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  
  String activeCategory = "Day-to-day Convo";
  int dailyGoal = 10;
  int wordsClearedToday = 0;
  int remainingWords = 10;
  bool isLoading = true;
  bool isFinishedToday = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final profile = await _supabase.from('profiles').select().eq('id', user.id).maybeSingle();
        if (profile != null) {
          
          String today = DateTime.now().toIso8601String().split('T')[0];
          
          setState(() {
            activeCategory = profile['active_category'] ?? "Day-to-day Convo";
            dailyGoal = profile['daily_goal'] ?? 10;
            
            if (profile['last_completed_date'] != today) {
              wordsClearedToday = 0;
              _supabase.from('profiles').update({
                'words_cleared_today': 0, 
                'last_completed_date': today
              }).eq('id', user.id);
            } else {
              wordsClearedToday = profile['words_cleared_today'] ?? 0;
            }

            remainingWords = dailyGoal - wordsClearedToday;
            if (remainingWords <= 0) {
              remainingWords = 0;
              isFinishedToday = true;
            } else {
              isFinishedToday = false;
            }
          });
        }
      }
    } catch (e) {
      print("Dashboard fetch error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthScreen()));
    }
  }

  // --- CUSTOM GAME NAVIGATION BAR ---
  Widget _buildGameNavBar(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF070709).withOpacity(0.9), // Deep void background
        border: Border(top: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // ACTIVE TAB (HUB)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("HUB", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 3.0, fontSize: 12)),
              const SizedBox(height: 4),
              Container(width: 20, height: 2, color: theme.colorScheme.primary), // Glowing underline
            ],
          ),
          // INACTIVE TAB (TEST ARENA)
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TestScreen())),
            child: Text("TEST ARENA", style: TextStyle(color: theme.colorScheme.primary.withOpacity(0.4), letterSpacing: 3.0, fontSize: 12)),
          ),
          // INACTIVE TAB (SETTINGS)
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())).then((_) {
                setState(() => isLoading = true);
                _loadDashboardData(); 
              });
            },
            child: Text("SETTINGS", style: TextStyle(color: theme.colorScheme.primary.withOpacity(0.4), letterSpacing: 3.0, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) return Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)));

    return Stack(
      children: [
        const DustyAtmosphere(), // Background physics

        Scaffold(
          backgroundColor: Colors.transparent, // Let atmosphere show
          appBar: AppBar(
            title: const Text('DASHBOARD', style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.bold, fontSize: 14)),
            actions: [
              IconButton(onPressed: _logout, icon: Icon(Icons.logout, color: theme.colorScheme.primary.withOpacity(0.5)))
            ],
          ),
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 600, // THE STRAITJACKET
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Replaced standard Card with TacticalPanel
                      TacticalPanel(
                        title: activeCategory,
                        subtitle: isFinishedToday 
                          ? "You have reached your daily parameters." 
                          : "Your daily batch is ready for extraction.",
                        trailingText: "GOAL: $dailyGoal",
                        bottomWidget: TacticalButton(
                          label: isFinishedToday ? "QUEUE COMPLETED" : "INITIALIZE ($remainingWords LEFT)",
                          isLoading: isLoading,
                          onTap: isFinishedToday ? null : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => StudyScreen(
                                batchSize: remainingWords, 
                                wordsAlreadyCleared: wordsClearedToday,
                                activeCategory: activeCategory
                              )),
                            ).then((_) {
                              setState(() => isLoading = true);
                              _loadDashboardData(); 
                            });
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // --- THE NEW MEMORY BANK BUTTON ---
                      // --- THE NEW MEMORY BANK PANEL ---
                      TacticalPanel(
                        title: "DATA ARCHIVE",
                        subtitle: "Access and decrypt previously acquired terminology.",
                        bottomWidget: TacticalButton(
                          label: "MEMORY BANK",
                          onTap: () {
                            AudioManager().playThump();
                            Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (context) => const MemoryBankScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: _buildGameNavBar(context, theme), // Custom HUD Nav
        ),
      ],
    );
  }
}