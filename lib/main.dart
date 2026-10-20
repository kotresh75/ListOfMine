import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/list_item.dart';
import 'services/storage_service.dart';
import 'widgets/add_item_sheet.dart';
import 'widgets/item_card.dart';
import 'widgets/stats_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F0E17),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ListofMineApp());
}

class ListofMineApp extends StatelessWidget {
  const ListofMineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ListofMine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0E17),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B5CF6),
          secondary: Color(0xFF06B6D4),
          surface: Color(0xFF161424),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0E17),
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CategoryDef> _categories = [];
  List<ListItem> _items = [];
  String _selectedCategoryFilter = 'all'; // 'all' or categoryId
  String _completionFilter = 'all'; // 'all', 'completed', 'uncompleted'
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final cats = await StorageService.loadCategories();
    final items = await StorageService.loadItems();
    setState(() {
      _categories = cats;
      _items = items;
      _isLoading = false;
    });
  }

  Future<void> _addItem(ListItem newItem) async {
    final updated = [newItem, ..._items];
    setState(() => _items = updated);
    await StorageService.saveItems(updated);
  }

  Future<void> _toggleItemStatus(ListItem item) async {
    final updated = _items.map((i) {
      if (i.id == item.id) {
        final newStatus = !i.isCompleted;
        return i.copyWith(
          isCompleted: newStatus,
          completedAt: newStatus ? DateTime.now() : null,
        );
      }
      return i;
    }).toList();

    setState(() => _items = updated);
    await StorageService.saveItems(updated);
  }

  Future<void> _deleteItem(String id) async {
    final updated = _items.where((i) => i.id != id).toList();
    setState(() => _items = updated);
    await StorageService.saveItems(updated);
  }

  CategoryDef _getCategory(String catId) {
    return _categories.firstWhere(
      (c) => c.id == catId,
      orElse: () => const CategoryDef(
        id: 'unknown',
        name: 'General',
        iconEmoji: '📝',
        completedVerb: 'Done',
        uncompletedVerb: 'To Do',
        colorValue: 0xFF8B5CF6,
      ),
    );
  }

  void _showAddDialog() {
    final defaultCat = _selectedCategoryFilter == 'all'
        ? _categories.first.id
        : _selectedCategoryFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddItemSheet(
        categories: _categories,
        initialCategoryId: defaultCat,
        onAdd: _addItem,
      ),
    );
  }

  void _showAddCustomCategoryDialog() {
    final nameController = TextEditingController();
    final emojiController = TextEditingController(text: '✨');
    final completedController = TextEditingController(text: 'Finished');
    final uncompletedController = TextEditingController(text: 'To Finish');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B1828),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'New Custom Category',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Category Name (e.g. Games, Concerts)',
                  labelStyle: TextStyle(color: Colors.white60),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emojiController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Icon Emoji',
                  labelStyle: TextStyle(color: Colors.white60),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: completedController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Verb for Done (e.g. Played, Attended)',
                  labelStyle: TextStyle(color: Colors.white60),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: uncompletedController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Verb for Pending (e.g. Backlog, Wishlist)',
                  labelStyle: TextStyle(color: Colors.white60),
                ),
              ),
            ],
          ),
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
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final cat = CategoryDef(
                id: name.toLowerCase().replaceAll(RegExp(r'\s+'), '_'),
                name: name,
                iconEmoji: emojiController.text.trim().isEmpty
                    ? '✨'
                    : emojiController.text.trim(),
                completedVerb: completedController.text.trim().isEmpty
                    ? 'Done'
                    : completedController.text.trim(),
                uncompletedVerb: uncompletedController.text.trim().isEmpty
                    ? 'To Do'
                    : uncompletedController.text.trim(),
                colorValue: 0xFFEC4899, // Pink
              );
              await StorageService.saveCustomCategory(cat);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              _loadData();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  List<ListItem> get _filteredItems {
    return _items.where((item) {
      if (_selectedCategoryFilter != 'all' &&
          item.categoryId != _selectedCategoryFilter) {
        return false;
      }
      if (_completionFilter == 'completed' && !item.isCompleted) return false;
      if (_completionFilter == 'uncompleted' && item.isCompleted) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = item.title.toLowerCase().contains(q);
        final matchesSubtitle = item.subtitle.toLowerCase().contains(q);
        final matchesNotes = item.notes.toLowerCase().contains(q);
        if (!matchesTitle && !matchesSubtitle && !matchesNotes) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
        ),
      );
    }

    final filtered = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.checklist_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ListofMine',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Watched • Visited • Read',
                  style: TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Add Custom Category',
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFFC084FC)),
            onPressed: _showAddCustomCategoryDialog,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Banner with stats
          SliverToBoxAdapter(
            child: StatsBanner(items: _items, categories: _categories),
          ),

          // Search Bar & Completion Filter
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  // Search Input
                  TextField(
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search movies, places, notes...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white54,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1A1826),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All Lists'),
                          selected: _selectedCategoryFilter == 'all',
                          selectedColor:
                              const Color(0xFF8B5CF6).withOpacity(0.35),
                          backgroundColor: const Color(0xFF191724),
                          labelStyle: TextStyle(
                            color: _selectedCategoryFilter == 'all'
                                ? Colors.white
                                : Colors.white60,
                            fontWeight: _selectedCategoryFilter == 'all'
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (sel) {
                            if (sel) {
                              setState(() => _selectedCategoryFilter = 'all');
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ..._categories.map((c) {
                          final isSel = _selectedCategoryFilter == c.id;
                          final color = Color(c.colorValue);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              avatar: Text(c.iconEmoji),
                              label: Text(c.name),
                              selected: isSel,
                              selectedColor: color.withOpacity(0.35),
                              backgroundColor: const Color(0xFF191724),
                              side: BorderSide(
                                color: isSel ? color : Colors.transparent,
                              ),
                              labelStyle: TextStyle(
                                color: isSel ? Colors.white : Colors.white60,
                                fontWeight: isSel
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              onSelected: (sel) {
                                if (sel) {
                                  setState(() => _selectedCategoryFilter = c.id);
                                }
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Segmented Tabs: All / Done / To Do
                  Row(
                    children: [
                      _buildFilterTab('all', 'All (${_items.length})'),
                      const SizedBox(width: 8),
                      _buildFilterTab(
                        'completed',
                        'Done (${_items.where((i) => i.isCompleted).length})',
                      ),
                      const SizedBox(width: 8),
                      _buildFilterTab(
                        'uncompleted',
                        'Pending (${_items.where((i) => !i.isCompleted).length})',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Items List
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.inbox_outlined,
                      size: 54,
                      color: Colors.white24,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'No matches found'
                          : 'No items in this list yet',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap + below to add your first movie, place, or book!',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = filtered[index];
                  final cat = _getCategory(item.categoryId);
                  return ItemCard(
                    item: item,
                    category: cat,
                    onToggleStatus: () => _toggleItemStatus(item),
                    onDelete: () => _deleteItem(item.id),
                    onRatingChanged: (newRating) async {
                      final updated = _items.map((i) {
                        if (i.id == item.id) {
                          return i.copyWith(rating: newRating);
                        }
                        return i;
                      }).toList();
                      setState(() => _items = updated);
                      await StorageService.saveItems(updated);
                    },
                  );
                },
                childCount: filtered.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Item',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: _showAddDialog,
      ),
    );
  }

  Widget _buildFilterTab(String filterKey, String label) {
    final isSel = _completionFilter == filterKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _completionFilter = filterKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSel
                ? const Color(0xFF8B5CF6).withOpacity(0.25)
                : const Color(0xFF161422),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSel ? const Color(0xFF8B5CF6) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              color: isSel ? Colors.white : Colors.white54,
            ),
          ),
        ),
      ),
    );
  }
}
