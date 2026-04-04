import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const StudyPlannerApp());
}

// ── REPLACE THIS WITH YOUR GEMINI API KEY ──
const String geminiApiKey = 'AIzaSyAUTzAogmlqkj-4xy0WNuqmu6zOoHQUSLM';
const String geminiUrl =
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$geminiApiKey';

// ── THEME COLORS ──
const bgColor = Color(0xFF0F1117);
const surfaceColor = Color(0xFF181C27);
const surface2Color = Color(0xFF1F2535);
const borderColor = Color(0xFF2A3048);
const accentColor = Color(0xFFE8C96D);
const accent2Color = Color(0xFF6DBFE8);
const textColor = Color(0xFFDCE3F0);
const mutedColor = Color(0xFF7A859E);
const dangerColor = Color(0xFFE87070);
const successColor = Color(0xFF6DE8A8);

class StudyPlannerApp extends StatelessWidget {
  const StudyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyPlanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: bgColor,
        colorScheme: const ColorScheme.dark(
          primary: accentColor,
          surface: surfaceColor,
        ),
        fontFamily: 'serif',
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// ══════════════════════════════════════════
//  HOME PAGE
// ══════════════════════════════════════════
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _syllabusController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  bool _loading = false;
  String _error = '';
  Map<String, dynamic>? _result;

  String _buildPrompt(String syllabus, String course) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return '''
SYLLABUS CONTENT:
$syllabus

You are an expert academic planner. Analyze this syllabus and return ONLY valid JSON — no markdown, no explanation, no backticks.

Today's date: $today
Course name hint: ${course.isEmpty ? 'infer from syllabus' : course}

Return this exact JSON structure:
{
  "courseName": "string",
  "courseCode": "string or empty",
  "instructor": "string or empty",
  "semester": "string or empty",
  "totalWeeks": number,
  "assignments": [
    {
      "name": "string",
      "dueDate": "YYYY-MM-DD or descriptive string",
      "type": "exam|assignment|project|quiz|other",
      "weight": "string e.g. 20% or empty",
      "description": "brief description"
    }
  ],
  "topics": ["array of main topics/units covered"],
  "weeklySchedule": [
    {
      "week": number,
      "startDate": "YYYY-MM-DD or empty",
      "theme": "week theme/focus",
      "tasks": [
        {
          "day": "Mon|Tue|Wed|Thu|Fri|Sat|Sun",
          "title": "specific study task",
          "detail": "brief detail",
          "durationMins": number,
          "type": "review|read|practice|prepare|work|study"
        }
      ]
    }
  ],
  "studyTips": ["2-3 personalized tips based on this syllabus"]
}

Rules:
- Generate a realistic day-by-day study schedule covering the course duration (up to 8 weeks)
- Space tasks evenly, front-load harder topics, taper before exams
- Include rest days on weekends
- Be specific in task titles
- durationMins should be realistic (30-120 mins per task)
- Return ONLY the JSON object, nothing else
''';
  }

  Future<void> _analyze() async {
    if (_syllabusController.text.trim().length < 50) {
      setState(() => _error = 'Please paste more syllabus content (at least 50 characters).');
      return;
    }

    setState(() { _loading = true; _error = ''; _result = null; });

    try {
      final prompt = _buildPrompt(_syllabusController.text, _courseController.text);
      final response = await http.post(
        Uri.parse(geminiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{ 'parts': [{ 'text': prompt }] }]
        }),
      );

      final data = jsonDecode(response.body);
      if (data['error'] != null) throw Exception(data['error']['message']);

      String raw = '';
      for (final part in data['candidates'][0]['content']['parts']) {
        raw += part['text'] ?? '';
      }

      raw = raw.replaceAll('```json', '').replaceAll('```', '').trim();
      final start = raw.indexOf('{');
      final parsed = jsonDecode(raw.substring(start));
      setState(() { _result = parsed; });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ResultsPage(result: parsed)),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  const Text(
                    'StudyPlanner',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: accentColor),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'AI-POWERED',
                      style: TextStyle(color: accentColor, fontSize: 10, letterSpacing: 1.5),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Upload box
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, style: BorderStyle.solid),
                      ),
                      child: const Column(
                        children: [
                          Text('📄', style: TextStyle(fontSize: 40)),
                          SizedBox(height: 12),
                          Text(
                            'Paste your syllabus below',
                            style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Copy and paste your course syllabus text',
                            style: TextStyle(color: mutedColor, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Syllabus text input
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _syllabusController,
                            maxLines: 8,
                            style: const TextStyle(color: textColor, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Paste your course syllabus here — assignments, topics, schedule...',
                              hintStyle: TextStyle(color: mutedColor),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: const BoxDecoration(
                              border: Border(top: BorderSide(color: borderColor)),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: ValueListenableBuilder(
                                valueListenable: _syllabusController,
                                builder: (_, val, __) => Text(
                                  '${val.text.length} chars',
                                  style: const TextStyle(color: mutedColor, fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Course name input
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: TextField(
                        controller: _courseController,
                        style: const TextStyle(color: textColor, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Course name (optional, e.g. CS101 Data Structures)',
                          hintStyle: TextStyle(color: mutedColor),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Generate button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _analyze,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: bgColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          disabledBackgroundColor: accentColor.withOpacity(0.4),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: bgColor),
                              )
                            : const Text(
                                'GENERATE STUDY PLAN',
                                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                              ),
                      ),
                    ),

                    // Error
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: dangerColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: dangerColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          'Error: $_error',
                          style: const TextStyle(color: dangerColor, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════
//  RESULTS PAGE
// ══════════════════════════════════════════
class ResultsPage extends StatefulWidget {
  final Map<String, dynamic> result;
  const ResultsPage({super.key, required this.result});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'exam': return dangerColor;
      case 'assignment': return accent2Color;
      case 'project': return accentColor;
      case 'quiz': return successColor;
      default: return mutedColor;
    }
  }

  String _taskIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('review')) return '📖';
    if (t.contains('read')) return '📚';
    if (t.contains('practice')) return '✏️';
    if (t.contains('prepare')) return '🗂️';
    if (t.contains('work')) return '💻';
    if (t.contains('study')) return '🧠';
    return '📌';
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final assignments = List<Map<String, dynamic>>.from(r['assignments'] ?? []);
    final topics = List<String>.from(r['topics'] ?? []);
    final schedule = List<Map<String, dynamic>>.from(r['weeklySchedule'] ?? []);
    final tips = List<String>.from(r['studyTips'] ?? []);
    final totalSessions = schedule.fold<int>(0, (s, w) => s + (w['tasks'] as List? ?? []).length);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: mutedColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r['courseName'] ?? 'Your Course',
                          style: const TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (r['instructor'] != null && r['instructor'].toString().isNotEmpty)
                          Text(
                            '${r['instructor']} · ${r['semester'] ?? ''}',
                            style: const TextStyle(color: mutedColor, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Stats row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _statCard('${assignments.length}', 'Deadlines'),
                  const SizedBox(width: 8),
                  _statCard('${topics.length}', 'Topics'),
                  const SizedBox(width: 8),
                  _statCard('${r['totalWeeks'] ?? '?'}', 'Weeks'),
                  const SizedBox(width: 8),
                  _statCard('$totalSessions', 'Sessions'),
                ],
              ),
            ),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.transparent,
                dividerColor: Colors.transparent,
                labelColor: textColor,
                unselectedLabelColor: mutedColor,
                indicator: BoxDecoration(
                  color: surface2Color,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderColor),
                ),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Schedule'),
                  Tab(text: 'Tips'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── OVERVIEW TAB ──
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionLabel('Assignments & Deadlines'),
                        const SizedBox(height: 8),
                        ...assignments.map((a) => _assignmentCard(a)),
                        const SizedBox(height: 20),
                        _sectionLabel('Topics Covered'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: topics.map((t) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: surface2Color,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: borderColor),
                            ),
                            child: Text(t, style: const TextStyle(color: textColor, fontSize: 12)),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),

                  // ── SCHEDULE TAB ──
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: schedule.map((week) {
                        final tasks = List<Map<String, dynamic>>.from(week['tasks'] ?? []);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: borderColor)),
                              ),
                              child: Text(
                                'WEEK ${week['week']}${week['theme'] != null ? ' · ${week['theme']}' : ''}',
                                style: const TextStyle(color: accentColor, fontSize: 11, letterSpacing: 1.5),
                              ),
                            ),
                            ...['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
                              final dayTasks = tasks.where((t) => t['day'] == day).toList();
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      child: Text(day, style: const TextStyle(color: mutedColor, fontSize: 12)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: dayTasks.isEmpty
                                          ? const Text('Rest day', style: TextStyle(color: mutedColor, fontSize: 12, fontStyle: FontStyle.italic))
                                          : Column(
                                              children: dayTasks.map((task) => Container(
                                                margin: const EdgeInsets.only(bottom: 4),
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: surfaceColor,
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: borderColor),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Text(_taskIcon(task['title'] ?? ''), style: const TextStyle(fontSize: 14)),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(task['title'] ?? '', style: const TextStyle(color: textColor, fontSize: 13)),
                                                          if (task['detail'] != null && task['detail'].toString().isNotEmpty)
                                                            Text(task['detail'], style: const TextStyle(color: mutedColor, fontSize: 11)),
                                                        ],
                                                      ),
                                                    ),
                                                    if (task['durationMins'] != null)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: accent2Color.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(3),
                                                        ),
                                                        child: Text(
                                                          '${task['durationMins']}m',
                                                          style: const TextStyle(color: accent2Color, fontSize: 11),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              )).toList(),
                                            ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 12),
                          ],
                        );
                      }).toList(),
                    ),
                  ),

                  // ── TIPS TAB ──
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: tips.asMap().entries.map((e) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TIP ${e.key + 1}', style: const TextStyle(color: accentColor, fontSize: 11, letterSpacing: 1.5)),
                            const SizedBox(height: 8),
                            Text(e.value, style: const TextStyle(color: textColor, fontSize: 14, height: 1.6)),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String num, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            Text(num, style: const TextStyle(color: accentColor, fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: mutedColor, fontSize: 10, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: const TextStyle(color: accentColor, fontSize: 11, letterSpacing: 1.5));
  }

  Widget _assignmentCard(Map<String, dynamic> a) {
    final type = a['type'] ?? 'other';
    final color = _typeColor(type);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface2Color,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(a['name'] ?? '', style: const TextStyle(color: textColor, fontSize: 14))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(type, style: TextStyle(color: color, fontSize: 10, letterSpacing: 0.8)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Due: ${a['dueDate'] ?? 'TBD'}  ${a['weight'] != null && a['weight'].toString().isNotEmpty ? '· ${a['weight']}' : ''}',
                  style: const TextStyle(color: mutedColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
