import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const NotesApp());
}

/// Model representing a single note.
class Note {
  final String id;
  String title;
  String content;
  DateTime dateTime;
  Color color;
  String category;
  bool isFavorite;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.dateTime,
    required this.color,
    required this.category,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'dateTime': dateTime.toIso8601String(),
      'color': color.toARGB32(),
      'category': category,
      'isFavorite': isFavorite,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      color: Color(json['color'] as int),
      category: json['category'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}

/// Dynamic modern gradient note card colors (matching Light and Dark backgrounds).
const List<Color> noteColors = [
  Color(0xFFE0F2FE), // Sky Blue
  Color(0xFFDCFCE7), // Mint Green
  Color(0xFFFEF9C3), // Soft Yellow
  Color(0xFFFCE7F3), // Cherry Blossom Pink
  Color(0xFFF3E8FF), // Lavender Purple
  Color(0xFFFFEDD5), // Soft Peach
  Color(0xFFE2E8F0), // Cool Slate
  Color(0xFFF5F5F4), // Warm Stone
];

/// List of standard categories.
const List<String> categories = ['All', 'Personal', 'Work', 'Study', 'Ideas', 'Others'];

class NotesApp extends StatefulWidget {
  const NotesApp({super.key});

  @override
  State<NotesApp> createState() => _NotesAppState();
}

class _NotesAppState extends State<NotesApp> {
  // Theme mode state
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Notes Dashboard',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      // Light Neomorphic-Glass Theme
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5), // Indigo 600
          brightness: Brightness.light,
          surface: const Color(0xFFF8FAFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9), // Light Slate Background
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Color(0xFF0F172A)),
          titleTextStyle: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ),
      // Dark Neomorphic-Glass Theme
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF818CF8), // Indigo 400
          brightness: Brightness.dark,
          surface: const Color(0xFF0F172A),
        ),
        scaffoldBackgroundColor: const Color(0xFF020617), // Deep Dark Navy/Black
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ),
      home: NotesHomeScreen(
        isDarkMode: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class NotesHomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const NotesHomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<NotesHomeScreen> createState() => _NotesHomeScreenState();
}

class _NotesHomeScreenState extends State<NotesHomeScreen> {
  // Pre-populated Notes
  final List<Note> _notes = [];

  // Active States
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _showFavoritesOnly = false;

  // Search input controller
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? notesJson = prefs.getString('saved_notes');
      if (notesJson != null) {
        final List<dynamic> decoded = jsonDecode(notesJson);
        setState(() {
          _notes.clear();
          _notes.addAll(decoded.map((item) => Note.fromJson(item as Map<String, dynamic>)));
        });
      }
    } catch (e) {
      debugPrint('Error loading notes: $e');
    }
  }

  Future<void> _saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(_notes.map((note) => note.toJson()).toList());
      await prefs.setString('saved_notes', encoded);
    } catch (e) {
      debugPrint('Error saving notes: $e');
    }
  }

  // Greeting based on system time
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // Header date display
  String get _formattedHeaderDate {
    final now = DateTime.now();
    final weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[now.weekday % 7]}, ${months[now.month - 1]} ${now.day}';
  }

  // Date/Time Formatter inside Card
  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return '${months[dt.month - 1]} ${dt.day}, $hour:$minute $ampm';
    }
  }

  // Filtered Notes List
  List<Note> get _filteredNotes {
    return _notes.where((note) {
      final matchesCategory = _selectedCategory == 'All' || note.category == _selectedCategory;
      final matchesSearch = note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.content.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFavorite = !_showFavoritesOnly || note.isFavorite;
      return matchesCategory && matchesSearch && matchesFavorite;
    }).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime)); // Newest first
  }

  // Stats Counters
  int get _totalCount => _notes.length;
  int get _favoriteCount => _notes.where((n) => n.isFavorite).length;
  int get _ideasCount => _notes.where((n) => n.category == 'Ideas').length;

  // CRUD Operations
  void _addNote(String title, String content, String category, Color color) {
    setState(() {
      _notes.add(Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.trim().isEmpty ? 'Untitled' : title.trim(),
        content: content.trim(),
        dateTime: DateTime.now(),
        category: category,
        color: color,
      ));
    });
    _saveNotes();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved to Dashboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _editNote(String id, String title, String content, String category, Color color) {
    final index = _notes.indexWhere((note) => note.id == id);
    if (index != -1) {
      setState(() {
        _notes[index].title = title.trim().isEmpty ? 'Untitled' : title.trim();
        _notes[index].content = content.trim();
        _notes[index].category = category;
        _notes[index].color = color;
        _notes[index].dateTime = DateTime.now(); // Update edited timestamp
      });
      _saveNotes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note updated!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _deleteNote(Note note) {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      setState(() {
        _notes.removeAt(index);
      });
      _saveNotes();

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${note.title}" removed'),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: Theme.of(context).colorScheme.inversePrimary,
            onPressed: () {
              setState(() {
                _notes.insert(index, note);
              });
              _saveNotes();
            },
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _toggleFavorite(Note note) {
    setState(() {
      note.isFavorite = !note.isFavorite;
    });
    _saveNotes();
  }

  // Slide-Up Bottom Sheet Editor
  void _showBottomEditor({Note? note}) {
    final isEditing = note != null;
    final titleController = TextEditingController(text: isEditing ? note.title : '');
    final contentController = TextEditingController(text: isEditing ? note.content : '');
    String selectedCat = isEditing ? note.category : 'Personal';
    Color selectedColor = isEditing ? note.color : noteColors[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final wordCount = contentController.text.trim().isEmpty
                ? 0
                : contentController.text.trim().split(RegExp(r'\s+')).length;
            final charCount = contentController.text.length;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    )
                  ],
                ),
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 14,
                  bottom: 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    // Handle indicator
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header of sheet
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Modify Note' : 'New Thought',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: widget.isDarkMode ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 20, thickness: 0.8),

                    // Title Entry
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'Enter title (optional)',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        labelText: 'Title',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        fillColor: Colors.transparent,
                        filled: false,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 50,
                    ),
                    const SizedBox(height: 12),

                    // Content Body Entry
                    TextField(
                      controller: contentController,
                      onChanged: (val) {
                        setSheetState(() {}); // update word/character count
                      },
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        labelText: 'Content',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        alignLabelWithHint: true,
                        fillColor: Colors.transparent,
                        filled: false,
                      ),
                      maxLines: 8,
                      minLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 8),

                    // Word & Character Counter row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$wordCount words  |  $charCount characters',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Category Selector Chips
                    const Text(
                      'Category',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: categories.where((c) => c != 'All').map((cat) {
                          final isSelected = selectedCat == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : (widget.isDarkMode ? Colors.white70 : Colors.black87),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setSheetState(() {
                                    selectedCat = cat;
                                  });
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Note Colors picker
                    const Text(
                      'Select Note Color Accent',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 42,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: noteColors.length,
                        itemBuilder: (context, index) {
                          final color = noteColors[index];
                          final isSelected = selectedColor == color;
                          return GestureDetector(
                            onTap: () {
                              setSheetState(() {
                                selectedColor = color;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey.withValues(alpha: 0.3),
                                  width: isSelected ? 3 : 1.5,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.black87,
                                      size: 18,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bottom sheet Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                            ),
                            onPressed: () {
                              if (contentController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Note content cannot be empty!'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }
                              if (isEditing) {
                                _editNote(
                                  note.id,
                                  titleController.text,
                                  contentController.text,
                                  selectedCat,
                                  selectedColor,
                                );
                              } else {
                                _addNote(
                                  titleController.text,
                                  contentController.text,
                                  selectedCat,
                                  selectedColor,
                                );
                              }
                              Navigator.pop(context);
                            },
                            child: Text(isEditing ? 'Save Changes' : 'Add Note'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        );
      },
    );
  }

  // Emulated Pinterest Grid Builder (splits items into N vertical columns dynamically)
  Widget _buildStaggeredGrid(List<Note> notes, bool isDesktop) {
    final columnsCount = isDesktop ? 3 : 2;
    final List<List<Note>> columns = List.generate(columnsCount, (_) => []);

    for (int i = 0; i < notes.length; i++) {
      columns[i % columnsCount].add(notes[i]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(columnsCount, (colIndex) {
        return Expanded(
          child: Column(
            children: columns[colIndex].map((note) {
              return Padding(
                padding: const EdgeInsets.all(6.0),
                child: _buildNoteCard(note),
              );
            }).toList(),
          ),
        );
      }),
    );
  }

  // Dashboard Note Card Widget
  Widget _buildNoteCard(Note note) {

    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        decoration: BoxDecoration(
          color: Colors.redAccent.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_sweep_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
      confirmDismiss: (direction) async {
        _deleteNote(note);
        return true;
      },
      child: Card(
        color: note.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () => _showBottomEditor(note: note),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card Header: Category & Favorites Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        note.category,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        // Favorite Heart Action
                        GestureDetector(
                          onTap: () => _toggleFavorite(note),
                          child: Icon(
                            note.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 18,
                            color: note.isFavorite ? Colors.redAccent : Colors.black54,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Quick Edit Icon
                        GestureDetector(
                          onTap: () => _showBottomEditor(note: note),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Note Title
                Text(
                  note.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),

                // Note Body
                Text(
                  note.content,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 14),

                // Note Footer: Access Time & Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_filled_rounded,
                          size: 12,
                          color: Colors.black45,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateTime(note.dateTime),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                    // Quick Delete
                    GestureDetector(
                      onTap: () => _deleteNote(note),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredNotes;
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: Stack(
        children: [
          // Glassmorphic Backdrop Rings decoration
          Positioned(
            top: -60,
            left: -40,
            width: 250,
            height: 250,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: widget.isDarkMode ? 0.15 : 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 150,
            right: -60,
            width: 300,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.pinkAccent.withValues(alpha: widget.isDarkMode ? 0.08 : 0.05),
              ),
            ),
          ),

          // Scrollable Area
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Top Custom Header / Stats Dashboard bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Greeting and theme switch
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formattedHeaderDate.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.grey.shade500,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _greeting,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: widget.isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            // Spinning style Theme Button
                            Container(
                              decoration: BoxDecoration(
                                color: widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: widget.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                                ),
                              ),
                              child: IconButton(
                                icon: AnimatedRotation(
                                  turns: widget.isDarkMode ? 0.5 : 0.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Icon(
                                    widget.isDarkMode ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                                    color: widget.isDarkMode ? Colors.amber : Colors.indigo.shade600,
                                    size: 20,
                                  ),
                                ),
                                onPressed: widget.onToggleTheme,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Search and Filter Pill Input
                        TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search title or keyword details...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 20),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            fillColor: widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Dashboard Statistics Row
                        Row(
                          children: [
                            // Total count
                            Expanded(
                              child: _buildStatCard(
                                title: 'Total Notes',
                                value: '$_totalCount',
                                icon: Icons.folder_open_rounded,
                                activeColor: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Favorites Count toggle
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _showFavoritesOnly = !_showFavoritesOnly;
                                  });
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: _buildStatCard(
                                  title: 'Favorites',
                                  value: '$_favoriteCount',
                                  icon: _showFavoritesOnly ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  activeColor: Colors.redAccent,
                                  isSelected: _showFavoritesOnly,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Ideas count
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    if (_selectedCategory == 'Ideas') {
                                      _selectedCategory = 'All';
                                    } else {
                                      _selectedCategory = 'Ideas';
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: _buildStatCard(
                                  title: 'Ideas Tag',
                                  value: '$_ideasCount',
                                  icon: Icons.lightbulb_outline_rounded,
                                  activeColor: Colors.amber,
                                  isSelected: _selectedCategory == 'Ideas',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Horizontal Tag Chips Bar
                        SizedBox(
                          height: 38,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final cat = categories[index];
                              final isSelected = _selectedCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: FilterChip(
                                  label: Text(cat),
                                  selected: isSelected,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                  checkmarkColor: Theme.of(context).colorScheme.primary,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : (widget.isDarkMode ? Colors.white70 : Colors.black87),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = cat;
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Main Notes Content
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: widget.isDarkMode
                                    ? const Color(0xFF1E293B)
                                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _searchQuery.isNotEmpty || _showFavoritesOnly
                                    ? Icons.search_off_rounded
                                    : Icons.library_books_outlined,
                                size: 60,
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty || _showFavoritesOnly
                                  ? 'No matching results'
                                  : 'Workspace is empty',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _searchQuery.isNotEmpty || _showFavoritesOnly
                                  ? 'Try resetting the favorite toggle, categories, or query search.'
                                  : 'Tap the button below to write down your first custom thought!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  // Custom Pinterest Masonry Grid listing
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverToBoxAdapter(
                      child: _buildStaggeredGrid(filtered, isDesktop),
                    ),
                  ),

                // Bottom offset spacer sliver so FAB does not cover card items
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
          ),
        ],
      ),

      // Extended Dynamic Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBottomEditor(),
        label: const Text('Add Note'),
        icon: const Icon(Icons.edit_note_rounded),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
    );
  }

  // Helper builder for neomorphic stats cards
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color activeColor,
    bool isSelected = false,
  }) {
    final themeBg = widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? activeColor.withValues(alpha: 0.1) : themeBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? activeColor
              : (widget.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: isSelected ? activeColor : activeColor.withValues(alpha: 0.8)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isSelected
                  ? activeColor
                  : (widget.isDarkMode ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
