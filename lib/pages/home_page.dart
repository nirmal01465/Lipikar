import 'package:flutter/material.dart';
import 'package:lipikar/pages/profile_page.dart';
import 'package:lipikar/pages/statistics_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/finances_colors.dart';
import '../widgets/animated_banner.dart';
import '../widgets/total_balance_card_widget.dart';
import 'scan_document_screen.dart';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fabAnimationController;
  late AnimationController _floatingParticlesController;
  late Animation<double> _fabAnimation;
  late Animation<double> _particlesAnimation;

  final List<Widget> _screens = [
    const _HomeContent(),
    const ScanPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _floatingParticlesController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.elasticOut),
    );
    _particlesAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatingParticlesController, curve: Curves.linear),
    );

    _fabAnimationController.forward();
    _floatingParticlesController.repeat();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _floatingParticlesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Stack(
        children: [
          _buildFloatingParticles(),
          CustomScrollView(
            slivers: [
              _buildModernSliverAppBar(),
              SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return SlideTransition(
                      position: animation.drive(
                        Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                            .chain(CurveTween(curve: Curves.easeOutCubic)),
                      ),
                      child: child,
                    );
                  },
                  child: _screens[_selectedIndex],
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildGlassmorphicBottomNav(),
      floatingActionButton: _buildAdvancedFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildFloatingParticles() {
    return AnimatedBuilder(
      animation: _particlesAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlesPainter(_particlesAnimation.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildModernSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4FACFE), Color(0xFF00F2FE),
                const Color(0xFF4FACFE).withOpacity(0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              ..._buildBackgroundShapes(),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(-50 * (1 - value), 0),
                            child: Opacity(
                              opacity: value,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.auto_awesome,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Lipikar',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        Text(
                                          'AI-Powered Document Scanner',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 20, top: 8),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () {},
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF6B6B),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildBackgroundShapes() {
    return [
      Positioned(
        top: -100,
        right: -100,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1500),
          builder: (context, value, child) {
            return Transform.rotate(
              angle: value * 2 * math.pi,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 2,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      Positioned(
        top: 20,
        left: -50,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 2000),
          builder: (context, value, child) {
            return Transform.rotate(
              angle: -value * math.pi,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }

  Widget _buildGlassmorphicBottomNav() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.8),
                  ],
                ),
              ),
            ),
            BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              selectedItemColor: const Color(0xFF667EEA),
              unselectedItemColor: Colors.grey.shade500,
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              items: [
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.home_outlined, Icons.home, 0),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.document_scanner_outlined, Icons.document_scanner, 1),
                  label: 'Scan',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.person_outline, Icons.person, 2),
                  label: 'Profile',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData outlined, IconData filled, int index) {
    final isSelected = _selectedIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF667EEA).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isSelected ? filled : outlined,
        size: 24,
      ),
    );
  }

  Widget _buildAdvancedFAB() {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimation.value,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4FACFE), Color(0xFF00F2FE)
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  _fabAnimationController.reverse().then((_) {
                    _fabAnimationController.forward();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ScanPage()),
                    );
                  });
                },
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 33,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent({Key? key}) : super(key: key);

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> with TickerProviderStateMixin {
  late AnimationController _staggerController;
  late AnimationController _countAnimationController;
  late AnimationController _pulseController;
  late List<Animation<double>> _staggerAnimations;
  late Animation<double> _countAnimation;
  late Animation<double> _pulseAnimation;

  SharedPreferences? _prefs;
  int _totalScans = 0;
  int _totalWords = 0;
  String _lastScanDate = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadScanData();
  }

  void _initializeAnimations() {
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _countAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _staggerAnimations = List.generate(6, (index) {
      final start = index * 0.1;
      final end = math.min(start + 0.6, 1.0); // Cap end at 1.0 to fix assertion error
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _countAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _countAnimationController, curve: Curves.easeOutCubic),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _staggerController.forward();
    _countAnimationController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _loadScanData() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalScans = _prefs?.getInt('total_scans') ?? 0;
      _totalWords = _prefs?.getInt('total_words_extracted') ?? 0;
      _lastScanDate = _prefs?.getString('last_scan_datetime') ?? '';
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _countAnimationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildWelcomeSection(),
          const SizedBox(height: 24),
          _buildStatsCards(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildRecentScansSection(),
          const SizedBox(height: 24),
          _buildFeaturesShowcase(),
          const SizedBox(height: 24),
          _buildUpdatesSection(),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final hour = DateTime.now().hour;

    // Determine greeting text, icon, and colors
    String greeting;
    IconData iconData;
    List<Color> gradientColors;

    if (hour >= 5 && hour < 12) {
      greeting = 'Good Morning';
      iconData = Icons.wb_sunny;
      gradientColors = [
        const Color(0xFF4FACFE).withOpacity(0.8), // gentle dawn blue
        const Color(0xFF00F2FE).withOpacity(0.8),
      ];
    } else if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
      iconData = Icons.wb_sunny_outlined;
      gradientColors = [
        const Color(0xFFFFD194).withOpacity(0.8), // warm afternoon yellow
        const Color(0xFFFFE29F).withOpacity(0.8),
      ];
    } else if (hour >= 17 && hour < 20) {
      greeting = 'Good Evening';
      iconData = Icons.nights_stay;
      gradientColors = [
        const Color(0xFF667EEA).withOpacity(0.8), // twilight purple
        const Color(0xFF764BA2).withOpacity(0.8),
      ];
    } else {
      greeting = 'Good Night';
      iconData = Icons.nights_stay_outlined;
      gradientColors = [
        const Color(0xFF0F2027).withOpacity(0.8), // deep night blue
        const Color(0xFF203A43).withOpacity(0.8),
      ];
    }

    return AnimatedBuilder(
      animation: _staggerAnimations[0],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _staggerAnimations[0].value)),
          child: Opacity(
            opacity: _staggerAnimations[0].value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.first.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Icon(
                            iconData,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ready to scan and digitize your documents?',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildStatsCards() {
    return AnimatedBuilder(
      animation: _staggerAnimations[1],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _staggerAnimations[1].value)),
          child: Opacity(
            opacity: _staggerAnimations[1].value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildAdvancedStatCard(
                      title: 'Total Scans',
                      value: _totalScans,
                      icon: Icons.document_scanner,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                      ),
                      shadowColor: const Color(0xFF4FACFE),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildAdvancedStatCard(
                      title: 'Words Extracted',
                      value: _totalWords,
                      icon: Icons.text_fields,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                      ),
                      shadowColor: const Color(0xFF4FACFE),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdvancedStatCard({
    required String title,
    required int value,
    required IconData icon,
    required LinearGradient gradient,
    required Color shadowColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              Icon(
                Icons.trending_up,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _countAnimation,
            builder: (context, child) {
              final animatedValue = (value * _countAnimation.value).round();
              return Text(
                animatedValue.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return AnimatedBuilder(
      animation: _staggerAnimations[2],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _staggerAnimations[2].value)),
          child: Opacity(
            opacity: _staggerAnimations[2].value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildAdvancedQuickAction(
                        icon: Icons.camera_alt,
                        label: 'Scan Document',
                        colors: const [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                        onTap: () => _navigateToScan(context),
                      ),
                      SizedBox(width: 10,),
                      _buildAdvancedQuickAction(
                        icon: Icons.image,
                        label: 'From Gallery',
                        colors: const [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                        onTap: () => _navigateToScan(context),
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
  }

  Widget _buildAdvancedQuickAction({
    required IconData icon,
    required String label,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 160,
              height: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: colors[0].withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onTap,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentScansSection() {
    return AnimatedBuilder(
      animation: _staggerAnimations[3],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _staggerAnimations[3].value)),
          child: Opacity(
            opacity: _staggerAnimations[3].value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Scans',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      _buildGradientButton(
                        'View All',
                            () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const DocumentScanHistoryPage()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildRecentScansList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradientButton(String text, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          onHover: (hovering) {
            setState(() {}); // Trigger rebuild for hover effect if needed
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentScansList() {
    final List<Map<String, dynamic>> recentItems = [
      {
        'title': 'Bank Statement',
        'date': 'Today, 2:30 PM',
        'type': 'Document',
        'icon': Icons.description,
        'color': const Color(0xFF667EEA),
      },
      {
        'title': 'Receipt from Store',
        'date': 'Yesterday, 5:45 PM',
        'type': 'Receipt',
        'icon': Icons.receipt,
        'color': const Color(0xFF4FACFE),
      },
      {
        'title': 'Business Card',
        'date': 'Apr 15, 11:20 AM',
        'type': 'Image',
        'icon': Icons.image,
        'color': const Color(0xFF48BB78),
      },
    ];

    return Column(
      children: recentItems.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> item = entry.value;
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 100)),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(50 * (1 - value), 0),
              child: Opacity(
                opacity: value,
                child: _buildRecentScanItem(item),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildRecentScanItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['date'] as String,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item['type'] as String,
                    style: TextStyle(
                      color: item['color'] as Color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesShowcase() {
    return AnimatedBuilder(
      animation: _staggerAnimations[4],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _staggerAnimations[4].value)),
          child: Opacity(
            opacity: _staggerAnimations[4].value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Features',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFeatureCard(
                          title: 'AI-Powered OCR',
                          description: 'Extract text with high accuracy',
                          icon: Icons.auto_fix_high,
                          color: const Color(0xFF667EEA),
                        ),
                        _buildFeatureCard(
                          title: 'Cloud Sync',
                          description: 'Access your scans anywhere',
                          icon: Icons.cloud_upload,
                          color: const Color(0xFF4FACFE),
                        ),
                        _buildFeatureCard(
                          title: 'Secure Storage',
                          description: 'Bank-grade encryption',
                          icon: Icons.lock,
                          color: const Color(0xFF48BB78),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdatesSection() {
    return AnimatedBuilder(
      animation: _staggerAnimations[5],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _staggerAnimations[5].value)),
          child: Opacity(
            opacity: _staggerAnimations[5].value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Updates',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 160,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: const [
                        AnimatedBannerWidget(
                          title: 'Premium Access',
                          subtitle: 'Scan unlimited documents with AI!',
                          color: Color(0xFFED8936),
                          icon: Icons.star,
                        ),
                        AnimatedBannerWidget(
                          title: 'Enhanced OCR',
                          subtitle: 'Faster and more accurate text detection.',
                          color: Color(0xFF667EEA),
                          icon: Icons.auto_fix_high,
                        ),
                        AnimatedBannerWidget(
                          title: 'Cloud Storage',
                          subtitle: 'Access your scans from anywhere.',
                          color: Color(0xFF48BB78),
                          icon: Icons.cloud_upload,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToScan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScanPage()),
    );
  }
}

class ParticlesPainter extends CustomPainter {
  final double animationValue;

  ParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 20; i++) {
      final offset = Offset(
        (math.sin(animationValue * 2 * math.pi + i) * size.width / 2) + size.width / 2,
        (math.cos(animationValue * 2 * math.pi + i) * size.height / 2) + size.height / 2,
      );
      canvas.drawCircle(offset, 2 + (i % 5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
