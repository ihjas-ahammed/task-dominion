import 'package:flutter/material.dart';
import 'package:myapp_flutter/src/providers/game_provider.dart';
import 'package:myapp_flutter/src/widgets/header_widget.dart';
import 'package:myapp_flutter/src/widgets/middle_panel_widget.dart';
import 'package:myapp_flutter/src/widgets/player_stats_drawer.dart';
import 'package:myapp_flutter/src/widgets/task_navigation_drawer.dart'; // New Task Drawer
import 'package:myapp_flutter/src/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late GameProvider _gameProvider;
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _viewTabs = [
    {'label': 'Details', 'value': 'task-details', 'icon': MdiIcons.textBoxSearchOutline},
    {'label': 'Wares', 'value': 'artifact-shop', 'icon': MdiIcons.storefrontOutline},
    {'label': 'Forge', 'value': 'blacksmith', 'icon': MdiIcons.hammerWrench},
    {'label': 'Arena', 'value': 'game', 'icon': MdiIcons.swordCross},
    {'label': 'Logbook', 'value': 'daily-summary', 'icon': MdiIcons.bookOpenPageVariantOutline},
    {'label': 'Settings', 'value': 'settings', 'icon': MdiIcons.cogOutline},
  ];

  @override
  void initState() {
    super.initState();
    _gameProvider = Provider.of<GameProvider>(context, listen: false);
    int initialIndex = _viewTabs.indexWhere((tab) => tab['value'] == _gameProvider.currentView);
    if (initialIndex == -1) initialIndex = 0;

    _tabController = TabController(length: _viewTabs.length, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(_handleTabSelection);

    // Ensure a task is selected if none is, and tasks are available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_gameProvider.selectedTaskId == null && _gameProvider.mainTasks.isNotEmpty) {
        _gameProvider.setSelectedTaskId(_gameProvider.mainTasks.first.id);
      }
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _gameProvider.setCurrentView(_viewTabs[_tabController.index]['value'] as String);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update TabController if currentView changes from provider
    context.watch<GameProvider>(); // Rebuilds when GameProvider notifies
    int newIndex = _viewTabs.indexWhere((tab) => tab['value'] == _gameProvider.currentView);
    if (newIndex != -1 && newIndex != _tabController.index) {
      _tabController.index = newIndex;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 800; // Example breakpoint, adjust as needed.

    return Scaffold(
      backgroundColor: AppTheme.fhBgDark,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: HeaderWidget(),
      ),
      drawer: isLargeScreen ? null : const PlayerStatsDrawer(), // Left drawer for player stats
      endDrawer: isLargeScreen ? null : const TaskNavigationDrawer(), // Right drawer for task selection
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (isLargeScreen) {
            // Horizontal layout for larger screens
            return Row(
              children: [
                const PlayerStatsDrawer(), // Show drawer content as a panel
                Expanded(
                  child: Column(
                    children: [
                      _buildTopNavigationBar(), // Top navigation bar
                      Expanded(
                        child: MiddlePanelWidget(tabController: _tabController),
                      ),
                    ],
                  ),
                ),
                const TaskNavigationDrawer(), // Show task drawer content as panel
              ],
            );
          } else {
            // Vertical layout for smaller screens
            return MiddlePanelWidget(tabController: _tabController);
          }
        },
      ),
      bottomNavigationBar: isLargeScreen
          ? null
          : BottomNavigationBar(
              // only show on small screens
              currentIndex: _tabController.index,
              onTap: (index) {
                _tabController.animateTo(index);
              },
              items: _viewTabs.map((tab) {
                bool isSelected = _viewTabs[_tabController.index]['value'] == tab['value'];
                return BottomNavigationBarItem(
                  icon: Icon(tab['icon'] as IconData,
                      size: 20,
                      color: isSelected
                          ? AppTheme.fhAccentTeal
                          : AppTheme.fhTextSecondary.withOpacity(0.7)),
                  activeIcon: Icon(tab['icon'] as IconData,
                      size: 22, color: AppTheme.fhAccentTeal),
                  label: tab['label'] as String,
                );
              }).toList(),
            ),
    );
  }

  Widget _buildTopNavigationBar() {
    return Container(
      //  color: AppTheme.fhBgDark, // Background color for the nav bar
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      constraints: const BoxConstraints(maxWidth: 800),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppTheme.fhAccentTeal,
        indicatorWeight: 3,
        labelColor: AppTheme.fhAccentTeal,
        unselectedLabelColor: AppTheme.fhTextSecondary.withOpacity(0.7),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        tabs: _viewTabs.map((tab) {
          return Tab(
            text: tab['label'] as String,
            icon: Icon(tab['icon'] as IconData, size: 20),
          );
        }).toList(),
      ),
    );
  }
}
