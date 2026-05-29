import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dusty_atmosphere.dart';
import 'audio_manager.dart';

// --- DATA STRUCTURE ---
class ArchivedWord {
  final String word;
  final DateTime date;
  ArchivedWord(this.word, this.date);
}

class MemoryBankScreen extends StatefulWidget {
  const MemoryBankScreen({super.key});

  @override
  State<MemoryBankScreen> createState() => _MemoryBankScreenState();
}

class _MemoryBankScreenState extends State<MemoryBankScreen> {
  final _supabase = Supabase.instance.client;
  List<ArchivedWord> _allWords = [];
  bool _isLoading = true;

  // Time Selection State
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  int? _selectedDay = DateTime.now().day; // <-- 1. Made nullable to allow "deselection"

  final List<String> _monthNames = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];

  @override
  void initState() {
    super.initState();
    _fetchMemoryBank();
  }

  Future<void> _fetchMemoryBank() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final data = await _supabase.from('known_words').select('word, created_at').eq('user_id', user.id);
      
      if (mounted) {
        setState(() {
          _allWords = data.map((row) {
            DateTime parsedDate = row['created_at'] != null ? DateTime.parse(row['created_at']).toLocal() : DateTime.now();
            return ArchivedWord(row['word'].toString(), parsedDate);
          }).toList();
          
          _allWords.sort((a, b) => a.word.compareTo(b.word)); 
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Archive Error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Database Error: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  int get _daysInSelectedMonth {
    return DateTime(_selectedYear, _selectedMonth + 1, 0).day;
  }

  // 2. Updated filtering engine to handle the "deselected" state
  List<ArchivedWord> get _filteredWords {
    return _allWords.where((w) {
      bool yearMonthMatch = w.date.year == _selectedYear && w.date.month == _selectedMonth;
      if (_selectedDay == null) return yearMonthMatch; // Return whole month if no day selected
      return yearMonthMatch && w.date.day == _selectedDay;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        const DustyAtmosphere(), 

        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('DATA ARCHIVES', style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.bold, fontSize: 14)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                AudioManager().playClick();
                Navigator.pop(context);
              },
            ),
          ),
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 600, 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    
                    // --- 1. THE MONTH WRAP GRID & YEAR TOGGLE ---
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                      color: const Color(0xFF070709).withOpacity(0.5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("GLOBAL CYCLE: $_selectedYear", style: TextStyle(color: theme.colorScheme.primary.withOpacity(0.5), letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold)),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.arrow_back_ios, size: 14, color: theme.colorScheme.primary),
                                    onPressed: () {
                                      AudioManager().playClick();
                                      setState(() {
                                        _selectedYear--;
                                        if (_selectedDay != null && _selectedDay! > _daysInSelectedMonth) {
                                          _selectedDay = _daysInSelectedMonth;
                                        }
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.arrow_forward_ios, size: 14, color: theme.colorScheme.primary),
                                    onPressed: () {
                                      AudioManager().playClick();
                                      setState(() {
                                        _selectedYear++;
                                        if (_selectedDay != null && _selectedDay! > _daysInSelectedMonth) {
                                          _selectedDay = _daysInSelectedMonth;
                                        }
                                      });
                                    },
                                  ),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8, 
                            runSpacing: 12, 
                            children: List.generate(12, (index) {
                              final isSelected = _selectedMonth == (index + 1);
                              return GestureDetector(
                                onTap: () {
                                  AudioManager().playClick();
                                  setState(() {
                                    _selectedMonth = index + 1;
                                    if (_selectedDay != null && _selectedDay! > _daysInSelectedMonth) {
                                      _selectedDay = _daysInSelectedMonth;
                                    }
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent,
                                    border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.primary.withOpacity(0.2)),
                                  ),
                                  child: Text(
                                    _monthNames[index],
                                    style: TextStyle(
                                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.5),
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      letterSpacing: 2.0,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    // --- 2. THE DAY WRAP GRID ---
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                      color: const Color(0xFF070709).withOpacity(0.5),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 16,
                        children: List.generate(_daysInSelectedMonth, (index) {
                          final day = index + 1;
                          final isSelected = _selectedDay == day;
                          final hasData = _allWords.any((w) => w.date.year == _selectedYear && w.date.month == _selectedMonth && w.date.day == day);

                          return GestureDetector(
                            // 3. The Toggle Logic: Deselect if already selected
                            onTap: () {
                              AudioManager().playClick();
                              setState(() {
                                if (_selectedDay == day) {
                                  _selectedDay = null; // Turn off the filter
                                } else {
                                  _selectedDay = day; // Turn on the filter
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 40,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected ? theme.colorScheme.primary.withOpacity(0.2) : Colors.transparent,
                                border: Border(bottom: BorderSide(color: isSelected ? theme.colorScheme.primary : Colors.transparent, width: 2)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    day.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.5),
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (hasData)
                                    Container(margin: const EdgeInsets.only(top: 4), width: 4, height: 4, decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle))
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    // --- 3. THE DATA LIST ---
                    Expanded(
                      child: _isLoading
                          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
                          : _filteredWords.isEmpty
                              ? Center(
                                  child: Text(
                                    "NO INTEL EXTRACTED.",
                                    style: TextStyle(color: theme.colorScheme.primary.withOpacity(0.4), letterSpacing: 2.0),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(24),
                                  itemCount: _filteredWords.length,
                                  itemBuilder: (context, index) {
                                    return MemoryCard(word: _filteredWords[index].word);
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- THE TACTICAL EXPANDABLE CARD ---
class MemoryCard extends StatefulWidget {
  final String word;
  const MemoryCard({super.key, required this.word});

  @override
  State<MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<MemoryCard> {
  bool _isExpanded = false;
  bool _isDecrypting = false;
  
  String? _definition;
  List<String>? _examples;

  Future<void> _decryptData() async {
    AudioManager().playClick();
    
    if (_definition != null) {
      setState(() => _isExpanded = !_isExpanded);
      return;
    }

    setState(() {
      _isExpanded = true;
      _isDecrypting = true;
    });

    try {
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;

      final response = await http.post(
        Uri.parse('https://vocab-proxy-three.vercel.app/api/generate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "response_format": {"type": "json_object"},
          "messages": [
            {
              "role": "system",
              "content": "You are a secure dictionary API. Return a JSON object with keys 'definition' (string, simple meaning) and 'examples' (array of 2 strings showing usage). No extra text."
            },
            {
              "role": "user",
              "content": "Word: ${widget.word}"
            }
          ]
        }),
      );

      if (response.statusCode == 200 && mounted) {
        String rawContent = jsonDecode(response.body)['choices'][0]['message']['content'];
        final aiData = jsonDecode(rawContent);
        
        setState(() {
          _definition = aiData['definition'];
          _examples = List<String>.from(aiData['examples'] ?? []);
          _isDecrypting = false;
        });
      } else {
        throw Exception("Decryption failed");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _definition = "DATA CORRUPTED. UNABLE TO DECRYPT.";
          _examples = [];
          _isDecrypting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: _isExpanded ? theme.colorScheme.primary : theme.colorScheme.primary.withOpacity(0.2),
          width: _isExpanded ? 1.5 : 1.0,
        ),
        color: _isExpanded ? theme.colorScheme.primary.withOpacity(0.05) : Colors.transparent,
      ),
      child: InkWell(
        onTap: _decryptData,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.word.toUpperCase(),
                    style: TextStyle(
                      color: _isExpanded ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3.0,
                      fontSize: 16,
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  )
                ],
              ),
              
              if (_isExpanded) ...[
                const SizedBox(height: 16),
                Divider(color: theme.colorScheme.primary.withOpacity(0.2)),
                const SizedBox(height: 16),

                if (_isDecrypting)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Column(
                        children: [
                          SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary)),
                          const SizedBox(height: 16),
                          Text("DECRYPTING DATA...", style: TextStyle(color: theme.colorScheme.primary.withOpacity(0.6), letterSpacing: 2.0, fontSize: 10)),
                        ],
                      ),
                    ),
                  )
                else ...[
                  Text(
                    _definition ?? "",
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.9), fontSize: 15, height: 1.5),
                  ),
                  if (_examples != null && _examples!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text("FIELD EXAMPLES", style: TextStyle(color: theme.colorScheme.primary.withOpacity(0.5), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 2.0)),
                    const SizedBox(height: 12),
                    ..._examples!.map((ex) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text("\"$ex\"", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontStyle: FontStyle.italic, fontSize: 14)),
                        )),
                  ]
                ]
              ]
            ],
          ),
        ),
      ),
    );
  }
}