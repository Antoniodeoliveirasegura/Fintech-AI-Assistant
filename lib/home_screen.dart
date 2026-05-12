import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'note.dart';
import 'weather_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _weatherService = WeatherService();
  WeatherData? _weather;
  bool _weatherLoading = true;
  String? _weatherError;
  List<Note> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    try {
      final weather = await _weatherService.getWeather();
      setState(() {
        _weather = weather;
        _weatherLoading = false;
      });
    } catch (_) {
      setState(() {
        _weatherError = 'Could not load weather';
        _weatherLoading = false;
      });
    }
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('notes');
    if (stored != null) {
      setState(() => _notes = Note.listFromJson(stored));
    }
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notes', Note.listToJson(_notes));
  }

  Future<void> _addNote() async {
    final controller = TextEditingController();
    final content = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Write something...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (content == null || content.isEmpty) return;

    final note = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      createdAt: DateTime.now(),
      weatherDescription: _weather?.description ?? 'unknown',
      weatherEmoji: _weather?.emoji ?? '🌡️',
      temperature: _weather?.temperature ?? 0,
    );

    setState(() => _notes.insert(0, note));
    await _saveNotes();
  }

  Future<void> _deleteNote(String id) async {
    setState(() => _notes.removeWhere((n) => n.id == id));
    await _saveNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildWeatherCard()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: _notes.isEmpty
                ? SliverToBoxAdapter(child: _buildEmptyState())
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _buildNoteCard(_notes[i]),
                      childCount: _notes.length,
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNote,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('New Note'),
      ),
    );
  }

  Widget _buildWeatherCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradientColors(),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: _weatherLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              : _weatherError != null
                  ? _buildWeatherError()
                  : _buildWeatherContent(),
        ),
      ),
    );
  }

  Widget _buildWeatherContent() {
    final w = _weather!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Miami, FL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'United States',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
            Text(w.emoji, style: const TextStyle(fontSize: 52)),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${w.temperature.round()}°F',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 64,
            fontWeight: FontWeight.w200,
            letterSpacing: -3,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _capitalize(w.description),
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _stat(Icons.water_drop_outlined, '${w.humidity}%', 'Humidity'),
            const SizedBox(width: 28),
            _stat(Icons.air, '${w.windSpeed.round()} mph', 'Wind'),
          ],
        ),
      ],
    );
  }

  Widget _stat(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeatherError() {
    return Row(
      children: [
        const Icon(Icons.cloud_off_outlined, color: Colors.white60),
        const SizedBox(width: 8),
        Text(_weatherError!, style: const TextStyle(color: Colors.white70)),
        const Spacer(),
        TextButton(
          onPressed: () {
            setState(() {
              _weatherLoading = true;
              _weatherError = null;
            });
            _fetchWeather();
          },
          child: const Text('Retry', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildNoteCard(Note note) {
    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteNote(note.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.content,
                style: const TextStyle(fontSize: 15, height: 1.5),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${note.weatherEmoji} ${note.temperature.round()}°F · ${_capitalize(note.weatherDescription)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(note.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.only(top: 72),
      child: Column(
        children: [
          Text('📝', style: TextStyle(fontSize: 52)),
          SizedBox(height: 12),
          Text(
            'No notes yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tap New Note to get started',
            style: TextStyle(color: Colors.black38),
          ),
        ],
      ),
    );
  }

  List<Color> _gradientColors() {
    if (_weather == null) {
      return [const Color(0xFF4A90D9), const Color(0xFF2C5F8A)];
    }
    switch (_weather!.main.toLowerCase()) {
      case 'clear':
        return [const Color(0xFFFF8C42), const Color(0xFFFFBF00)];
      case 'clouds':
        return [const Color(0xFF7F8FA6), const Color(0xFF596275)];
      case 'rain':
      case 'drizzle':
        return [const Color(0xFF4A90D9), const Color(0xFF1B4F72)];
      case 'thunderstorm':
        return [const Color(0xFF2C3E50), const Color(0xFF4A235A)];
      case 'snow':
        return [const Color(0xFFAED6F1), const Color(0xFF5DADE2)];
      default:
        return [const Color(0xFF4A90D9), const Color(0xFF2C5F8A)];
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return isToday ? 'Today $time' : '${dt.month}/${dt.day} $time';
  }
}
