import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/list_item.dart';
import '../models/movie_search_result.dart';
import '../services/movie_service.dart';

class AddItemSheet extends StatefulWidget {
  final List<CategoryDef> categories;
  final String initialCategoryId;
  final Function(ListItem) onAdd;

  const AddItemSheet({
    super.key,
    required this.categories,
    required this.initialCategoryId,
    required this.onAdd,
  });

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  late String _selectedCatId;
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _notesController = TextEditingController();
  final _movieSearchController = TextEditingController();

  bool _isCompleted = false;
  double _rating = 4.0;
  String? _selectedPosterUrl;

  // Movie search state
  Timer? _debounceTimer;
  List<MovieSearchResult> _movieSearchResults = [];
  bool _isSearchingMovies = false;
  MovieSearchResult? _selectedMovie;

  @override
  void initState() {
    super.initState();
    _selectedCatId = widget.initialCategoryId;
    if (_isMovieCategory) {
      _loadInitialMovieSuggestions();
    }
  }

  bool get _isMovieCategory =>
      _selectedCatId == 'movies' || _selectedCatId.contains('movie');

  void _loadInitialMovieSuggestions() {
    setState(() {
      _movieSearchResults = MovieService.curatedPopularSuggestions;
    });
  }

  void _onMovieSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      _loadInitialMovieSuggestions();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _isSearchingMovies = true);
      try {
        final results = await MovieService.searchMovies(query);
        if (mounted) {
          setState(() {
            _movieSearchResults = results;
            _isSearchingMovies = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSearchingMovies = false);
        }
      }
    });
  }

  void _selectMovie(MovieSearchResult movie) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedMovie = movie;
      _titleController.text = movie.title;
      final subtitleParts = [
        if (movie.year.isNotEmpty) movie.year,
        if (movie.directorOrArtist.isNotEmpty) movie.directorOrArtist,
        if (movie.genre.isNotEmpty) movie.genre,
      ];
      _subtitleController.text = subtitleParts.join(' • ');
      if (movie.overview.isNotEmpty) {
        _notesController.text = movie.overview;
      }
      if (movie.rating > 0) {
        _rating = movie.rating;
      }
      _selectedPosterUrl = movie.posterUrl.isNotEmpty ? movie.posterUrl : null;
    });
  }

  void _clearSelectedMovie() {
    setState(() {
      _selectedMovie = null;
      _selectedPosterUrl = null;
    });
  }

  void _showTmdbKeyDialog() async {
    final currentKey = await MovieService.getTmdbApiKey() ?? '';
    final keyController = TextEditingController(text: currentKey);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B1828),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.vpn_key_rounded, color: Color(0xFF8B5CF6), size: 22),
            SizedBox(width: 8),
            Text(
              'TMDB API Key',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Optional: Enter your free API key from themoviedb.org for full access to 900,000+ movies, HD posters, and ratings.\n\nWithout a key, the app seamlessly uses the open movie catalog.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: keyController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Paste TMDB API Key...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF262335),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await MovieService.saveTmdbApiKey(keyController.text);
              if (ctx.mounted) Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('TMDB key updated!'),
                  backgroundColor: Color(0xFF8B5CF6),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleController.dispose();
    _subtitleController.dispose();
    _notesController.dispose();
    _movieSearchController.dispose();
    super.dispose();
  }

  CategoryDef get _currentCat => widget.categories.firstWhere(
        (c) => c.id == _selectedCatId,
        orElse: () => widget.categories.first,
      );

  @override
  Widget build(BuildContext context) {
    final cat = _currentCat;
    final theme = Theme.of(context);
    final catColor = Color(cat.colorValue);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF16141E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white12),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Text(
                  'Add New Item',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Category Selector Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.categories.map((c) {
                  final isSel = c.id == _selectedCatId;
                  final chipColor = Color(c.colorValue);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSel,
                      showCheckmark: false,
                      avatar: Text(c.iconEmoji),
                      label: Text(c.name),
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : Colors.white70,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: const Color(0xFF221F2C),
                      selectedColor: chipColor.withOpacity(0.35),
                      side: BorderSide(
                        color: isSel ? chipColor : Colors.transparent,
                        width: 1.5,
                      ),
                      onSelected: (val) {
                        if (val) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedCatId = c.id;
                            if (_isMovieCategory && _movieSearchResults.isEmpty) {
                              _loadInitialMovieSuggestions();
                            }
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // MOVIE SEARCH SECTION (Approach A - Remote Catalog)
            if (_isMovieCategory) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF251E3E), Color(0xFF1B192A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: catColor.withOpacity(0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.movie_filter_rounded, color: catColor, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Movie Database Search',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: _showTmdbKeyDialog,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.key_rounded,
                                  size: 14,
                                  color: catColor.withOpacity(0.8),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'API Key',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: catColor.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Search input
                    TextField(
                      controller: _movieSearchController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      onChanged: _onMovieSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search 900k+ movies (e.g. Inception, Dune)...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white54,
                          size: 18,
                        ),
                        suffixIcon: _isSearchingMovies
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                ),
                              )
                            : (_movieSearchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      size: 18,
                                      color: Colors.white54,
                                    ),
                                    onPressed: () {
                                      _movieSearchController.clear();
                                      _loadInitialMovieSuggestions();
                                    },
                                  )
                                : null),
                        filled: true,
                        fillColor: const Color(0xFF151322),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Selected Movie Chip banner if picked
                    if (_selectedMovie != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: catColor.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            if (_selectedPosterUrl != null &&
                                _selectedPosterUrl!.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  _selectedPosterUrl!,
                                  width: 28,
                                  height: 38,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.movie,
                                    size: 24,
                                    color: Colors.white70,
                                  ),
                                ),
                              )
                            else
                              const Icon(Icons.movie, color: Colors.white70, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedMovie!.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${_selectedMovie!.year} • Auto-filled details',
                                    style: TextStyle(
                                      color: catColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18, color: Colors.white70),
                              tooltip: 'Clear selection',
                              onPressed: _clearSelectedMovie,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Suggestions Horizontal List
                    if (_movieSearchResults.isNotEmpty) ...[
                      const Text(
                        'Suggestions (Tap to auto-fill):',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 96,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _movieSearchResults.length,
                          itemBuilder: (context, index) {
                            final m = _movieSearchResults[index];
                            return GestureDetector(
                              onTap: () => _selectMovie(m),
                              child: Container(
                                width: 180,
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF141220),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _selectedMovie?.title == m.title
                                        ? catColor
                                        : Colors.white10,
                                    width: _selectedMovie?.title == m.title ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    if (m.posterUrl.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          m.posterUrl,
                                          width: 44,
                                          height: 72,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 44,
                                            height: 72,
                                            color: Colors.white12,
                                            child: const Icon(
                                              Icons.movie,
                                              color: Colors.white38,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 44,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          color: Colors.white10,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(
                                          Icons.movie,
                                          color: Colors.white38,
                                          size: 20,
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            m.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (m.year.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              m.year,
                                              style: TextStyle(
                                                color: catColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                          if (m.directorOrArtist.isNotEmpty) ...[
                                            const SizedBox(height: 1),
                                            Text(
                                              m.directorOrArtist,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white38,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Title Field
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Title / Name (e.g. Inception, Tokyo)',
                labelStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: const Color(0xFF221F2D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: catColor),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle Field
            TextField(
              controller: _subtitleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Subtitle / Details (e.g. Director, Country, Author)',
                labelStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: const Color(0xFF221F2D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: catColor),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status Switch (Watched vs Want to watch, etc.)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF221F2D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isCompleted ? catColor.withOpacity(0.5) : Colors.white10,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: _isCompleted ? catColor : Colors.white54,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isCompleted
                              ? 'Status: ${cat.completedVerb}'
                              : 'Status: ${cat.uncompletedVerb}',
                          style: TextStyle(
                            color: _isCompleted ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _isCompleted ? 'Marked as completed' : 'Keep in bucket list',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isCompleted,
                    activeColor: catColor,
                    onChanged: (v) {
                      HapticFeedback.lightImpact();
                      setState(() => _isCompleted = v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Rating if completed
            if (_isCompleted) ...[
              Row(
                children: [
                  const Text('Rating: ', style: TextStyle(color: Colors.white70)),
                  for (int i = 1; i <= 5; i++)
                    IconButton(
                      icon: Icon(
                        i <= _rating ? Icons.star : Icons.star_border,
                        color: Colors.amberAccent,
                        size: 24,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() => _rating = i.toDouble());
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Notes Field
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Notes or thoughts (optional)',
                labelStyle: const TextStyle(color: Colors.white60),
                filled: true,
                fillColor: const Color(0xFF221F2D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: catColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                onPressed: () {
                  final title = _titleController.text.trim();
                  if (title.isEmpty) return;

                  HapticFeedback.mediumImpact();
                  final item = ListItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title,
                    subtitle: _subtitleController.text.trim(),
                    categoryId: _selectedCatId,
                    isCompleted: _isCompleted,
                    rating: _isCompleted ? _rating : 0.0,
                    notes: _notesController.text.trim(),
                    imageUrl: _selectedPosterUrl,
                    createdAt: DateTime.now(),
                    completedAt: _isCompleted ? DateTime.now() : null,
                  );
                  widget.onAdd(item);
                  Navigator.pop(context);
                },
                child: Text(
                  'Add to ${cat.name}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
