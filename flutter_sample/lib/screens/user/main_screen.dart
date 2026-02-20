import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../services/authenticate.dart';
import '../../theme/theme.dart';
import 'about_developer_screen.dart';
import 'category_screen.dart';

class MainScreen extends StatefulWidget {
  static const routeName = '/main';

  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<CategoryModel> _allCategories = [];
  List<CategoryModel> _filteredCategories = [];
  List<String> _categoryFilters = ['All'];
  String _selectedFilter = 'All';

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

    setState(() {
      _allCategories = snapshot.docs
          .map(CategoryModel.fromDoc)
          .toList(growable: false);
      _categoryFilters =
          ['All'] +
          _allCategories.map((category) => category.name).toSet().toList();
      _filteredCategories = _allCategories;
    });
  }

  void _filterCategories(String query, {String? categoryFilter}) {
    setState(() {
      _filteredCategories = _allCategories.where((category) {
        final matchesQuery =
            category.name.toLowerCase().contains(query.toLowerCase()) ||
            category.description.toLowerCase().contains(query.toLowerCase());
        final matchesFilter =
            categoryFilter == null ||
            categoryFilter == 'All' ||
            category.name.toLowerCase() == categoryFilter.toLowerCase();
        return matchesQuery && matchesFilter;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    _calculateSizes(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            floating: true,
            centerTitle: true,
            backgroundColor: AppTheme.primaryColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            title: Text(
              'Music & Lyrics',
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            elevation: 0.0,
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                color: AppTheme.backgroundColor,
                onPressed: () {
                  Navigator.pushNamed(context, AboutDeveloperScreen.routeName);
                },
              ),
              IconButton(
                icon: const Icon(Icons.exit_to_app),
                color: AppTheme.backgroundColor,
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
                            'Welcome!',
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Search categories',
                            style: TextStyle(
                              fontSize: subtitleFontSize,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
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
                              onChanged: (value) => _filterCategories(value),
                              decoration: InputDecoration(
                                hintText: 'Search categories...',
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        onPressed: () {
                                          _searchController.clear();
                                          _filterCategories('');
                                        },
                                        icon: const Icon(Icons.clear),
                                        color: AppTheme.primaryColor,
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
                              ? Colors.white
                              : AppTheme.textPrimaryColor,
                        ),
                      ),
                      selected: _selectedFilter == filter,
                      selectedColor: AppTheme.primaryColor,
                      backgroundColor: Colors.white,
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
                        style: TextStyle(color: AppTheme.textScondaryColor),
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
        ],
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
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
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.quiz,
                  color: AppTheme.primaryColor,
                  size: mediumIconSize,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                category.name,
                style: TextStyle(
                  fontSize: titleFontSize * 0.8,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
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
                  color: AppTheme.textScondaryColor,
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
