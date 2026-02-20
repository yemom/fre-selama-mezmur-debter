import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../models/music.dart';
import '../../services/authenticate.dart';
import '../../services/music_service.dart';
import 'about_developer_screen.dart';
import 'category_screen.dart';
import 'music_player_screen.dart';

class MainScreen extends StatefulWidget {
  static const routeName = '/main';

  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MusicService _musicService = MusicService();
  List<CategoryModel> _allCategories = [];
  List<CategoryModel> _filteredCategories = [];
  List<String> _categoryFilters = ['All'];
  String _selectedFilter = 'All';
  Map<String, String> _categoryNameById = {};

  late double mediumIconSize;
  late double titleFontSize;
  late double subtitleFontSize;
  late double bodyFontSize;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _calculateSizes(BuildContext context) {
    final size = MediaQuery.of(context).size;
    mediumIconSize = size.width * 0.06;
    titleFontSize = size.width * 0.06;
    subtitleFontSize = size.width * 0.04;
    bodyFontSize = size.width * 0.035;
  }

  Future<void> _fetchCategories() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('categories')
        .orderBy('createdAt', descending: true)
        .get();

    if (!mounted) {
      return;
    }

    setState(() {
      _allCategories = snapshot.docs
          .map(CategoryModel.fromDoc)
          .toList(growable: false);
      _categoryNameById = {
        for (final category in _allCategories) category.id: category.name,
      };
      _categoryFilters =
          ['All'] +
          _allCategories.map((category) => category.name).toSet().toList();
      _filteredCategories = _allCategories;
    });
  }

  void _filterCategories(String query, {String? categoryFilter}) {
    if (!mounted) {
      return;
    }
    final normalizedQuery = query.toLowerCase().trim();
    setState(() {
      _filteredCategories = _allCategories.where((category) {
        final matchesQuery =
            normalizedQuery.isEmpty ||
            category.name.toLowerCase().contains(normalizedQuery) ||
            category.description.toLowerCase().contains(normalizedQuery) ||
            category.id.toLowerCase().contains(normalizedQuery);
        final matchesFilter =
            categoryFilter == null ||
            categoryFilter == 'All' ||
            category.name.toLowerCase() == categoryFilter.toLowerCase();
        return matchesQuery && matchesFilter;
      }).toList();
    });
  }

  bool _matchesMusicQuery(Music music, String query) {
    if (query.isEmpty) {
      return true;
    }
    final loweredQuery = query.toLowerCase();
    final categoryName = _categoryNameById[music.categoryId] ?? '';
    return music.title.toLowerCase().contains(loweredQuery) ||
        music.artist.toLowerCase().contains(loweredQuery) ||
        categoryName.toLowerCase().contains(loweredQuery) ||
        music.categoryId.toLowerCase().contains(loweredQuery);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final query = _searchController.text.trim();
    _calculateSizes(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            floating: true,
            centerTitle: true,
            backgroundColor: colorScheme.primary,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            title: Text(
              'መዝሙር ደብተር',
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimary,
              ),
            ),
            elevation: 0.0,
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                color: colorScheme.onPrimary,
                onPressed: () {
                  Navigator.pushNamed(context, AboutDeveloperScreen.routeName);
                },
              ),
              IconButton(
                icon: const Icon(Icons.exit_to_app),
                color: colorScheme.onPrimary,
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final route = MaterialPageRoute(
                    builder: (_) => const Authenticate(),
                  );
                  await FirebaseAuth.instance.signOut();
                  navigator.pushReplacement(route);
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: SafeArea(
                child: Column(
                  children: [
                    SizedBox(height: kToolbarHeight + 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'እንኳን ደህና መጡ!',
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Search categories & Music',
                            style: TextStyle(
                              fontSize: subtitleFontSize,
                              color: colorScheme.onPrimary.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) => _filterCategories(
                                value,
                                categoryFilter: _selectedFilter,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search categories & Music',
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        onPressed: () {
                                          _searchController.clear();
                                          _filterCategories(
                                            '',
                                            categoryFilter: _selectedFilter,
                                          );
                                        },
                                        icon: const Icon(Icons.clear),
                                        color: colorScheme.primary,
                                      )
                                    : null,
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (query.isEmpty) ...[
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categoryFilters.length,
                  itemBuilder: (context, index) {
                    final filter = _categoryFilters[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          filter,
                          style: TextStyle(
                            color: _selectedFilter == filter
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface,
                          ),
                        ),
                        selected: _selectedFilter == filter,
                        selectedColor: colorScheme.primary,
                        backgroundColor: colorScheme.surface,
                        onSelected: (_) {
                          setState(() {
                            _selectedFilter = filter;
                            _filterCategories(
                              _searchController.text,
                              categoryFilter: filter,
                            );
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: _filteredCategories.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Text(
                          'No categories found',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildCategoryCard(_filteredCategories[index]),
                        childCount: _filteredCategories.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200.0,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.8,
                          ),
                    ),
            ),
          ] else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Music',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<List<Music>>(
                      stream: _musicService.watchMusic(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final items = (snapshot.data ?? [])
                            .where((music) => _matchesMusicQuery(music, query))
                            .toList();
                        if (items.isEmpty) {
                          return Text(
                            'No music found',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final categoryName =
                                _categoryNameById[item.categoryId] ??
                                item.categoryId;
                            return ListTile(
                              leading: item.coverUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        item.coverUrl,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Icon(
                                      Icons.music_note,
                                      color: colorScheme.primary,
                                    ),
                              title: Text(
                                item.title.isEmpty ? 'Untitled' : item.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                item.artist.isEmpty
                                    ? categoryName
                                    : '${item.artist} • $categoryName',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: Icon(
                                Icons.play_arrow,
                                color: colorScheme.primary,
                              ),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  MusicPlayerScreen.routeName,
                                  arguments: item,
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Categories',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_filteredCategories.isEmpty)
                      Text(
                        'No categories found',
                        style: TextStyle(color: colorScheme.onSurface),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredCategories.length,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 200.0,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.8,
                            ),
                        itemBuilder: (context, index) =>
                            _buildCategoryCard(_filteredCategories[index]),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryScreen(category: category),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.quiz,
                  color: colorScheme.primary,
                  size: mediumIconSize,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                category.name,
                style: TextStyle(
                  fontSize: titleFontSize * 0.8,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Text(
                category.description,
                style: TextStyle(
                  fontSize: bodyFontSize,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
