import 'dart:async';
import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/product.dart';
import '../services/woocommerce_service.dart';
import '../models/testimonial.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'product_details_screen.dart';
import 'rewards_screen.dart';
import 'profile_screen.dart';
import 'shop_screen.dart';
import 'about_us_screen.dart';
import 'auth_screen.dart';
import 'subscriptions_screen.dart';
import 'referral_coupons_screen.dart';
import '../services/url_launcher_service.dart';
import '../services/auth_service.dart';
import '../models/customer.dart';
import '../models/cart_provider.dart';
import '../providers/home_provider.dart';
import '../providers/profile_provider.dart';

import 'widgets/floating_chat_bot.dart';
import 'widgets/gradient_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ValueNotifier<int> _currentIndex = ValueNotifier(0);
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    CartProvider().loadCartFromServer();
    _pages = [
      HomeContent(onViewAll: () {
        _currentIndex.value = 1;
      }),
      const ShopScreen(),
      const RewardsScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  void dispose() {
    _currentIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _currentIndex,
      builder: (context, index, child) {
        return Scaffold(
          body: GradientBackground(child: _pages[index]),
          floatingActionButton: const FloatingChatBot(),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: index,
            onTap: (newIndex) => _currentIndex.value = newIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.backgroundLight,
            selectedItemColor: AppColors.primaryOrange,
            unselectedItemColor: AppColors.textGrey,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            showUnselectedLabels: true,
            elevation: 8,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Shop'),
              BottomNavigationBarItem(icon: Icon(Icons.military_tech), label: 'Rewards'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        );
      },
    );
  }
}


class HomeContent extends StatelessWidget {
  final VoidCallback? onViewAll;
  const HomeContent({super.key, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeProvider(),
      child: _HomeContentBody(onViewAll: onViewAll),
    );
  }
}

class _HomeContentBody extends StatefulWidget {
  final VoidCallback? onViewAll;
  const _HomeContentBody({this.onViewAll});

  @override
  State<_HomeContentBody> createState() => _HomeContentBodyState();
}

class _HomeContentBodyState extends State<_HomeContentBody> with WidgetsBindingObserver {
  final PageController _bannerController = PageController();
  final PageController _testimonialController = PageController();
  final ScrollController _scrollController = ScrollController();
  Timer? _bannerTimer;
  Timer? _testimonialTimer;
  bool _showAllVideos = false;

  // Video banner
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;
  bool _isMuted = false;

  // Image banners (slides 2, 3)
  final List<String> _bannerImages = [
    'assets/images/home_banner.png',
    'assets/images/banner_image_2.png',
    'assets/images/banner_masala_chai.png',
  ];

  // Total banner count = 1 video + images
  int get _totalBannerCount => 1 + _bannerImages.length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    _initVideo();
    _startBannerAutoRotate();
    _startTestimonialAutoRotate();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      // Pause video when user scrolls down past the video banner
      if (_scrollController.offset > 150) {
        if (_videoController != null && _videoController!.value.isPlaying) {
          _videoController?.pause();
          if (mounted) setState(() {});
        }
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _videoController?.pause();
    }
  }

  @override
  void deactivate() {
    // Pause video when navigating to next screen or switching tabs
    _videoController?.pause();
    super.deactivate();
  }

  Future<void> _initVideo() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse('https://winleafteas.com/wp-content/uploads/2026/07/winleaf-tea-intro-video.mp4'),
      );
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.setVolume(1.0); // unmuted by default
      _videoController!.play();
      if (mounted) {
        setState(() => _videoInitialized = true);
      }
    } catch (e) {
      // Video failed to load - thumbnail image will stay visible instead
      debugPrint('Video init failed: $e');
      _videoController?.dispose();
      _videoController = null;
    }
  }

  void _startBannerAutoRotate() {
    _bannerTimer?.cancel();
    // Do not start auto-rotate if currently on the video slide (page 0)
    if (_bannerController.hasClients && (_bannerController.page?.round() ?? 0) == 0) {
      return;
    }
    if (!_bannerController.hasClients) {
      // Initially, it starts at 0 (video), so do not auto-rotate.
      return;
    }
    _bannerTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (_bannerController.hasClients) {
        int nextItem = (_bannerController.page?.round() ?? 0) + 1;
        if (nextItem >= _totalBannerCount) {
          nextItem = 0;
          _bannerController.animateToPage(
            nextItem,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        } else {
          _bannerController.nextPage(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  void _startTestimonialAutoRotate() {
    _testimonialTimer?.cancel();
    _testimonialTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_testimonialController.hasClients) {
        final testimonials = context.read<HomeProvider>().testimonials;
        if (testimonials != null && testimonials.isNotEmpty) {
          int nextItem = (_testimonialController.page?.toInt() ?? 0) + 1;
          if (nextItem >= testimonials.length) {
            nextItem = 0;
            _testimonialController.animateToPage(
              nextItem,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeIn,
            );
          } else {
            _testimonialController.nextPage(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _bannerTimer?.cancel();
    _testimonialTimer?.cancel();
    _bannerController.dispose();
    _testimonialController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning \u2615';
    } else if (hour < 17) {
      return 'Good Afternoon \u2600';
    } else if (hour < 21) {
      return 'Good Evening \ud83c\udf04';
    } else {
      return 'Good Evening \ud83c\udf19';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        return SafeArea(
          child: RefreshIndicator(
            onRefresh: provider.fetchAll,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(provider),
                    const SizedBox(height: 24),
                    _buildBanner(),
                    const SizedBox(height: 32),
                    _buildVideoTestimonialsSection(),
                    const SizedBox(height: 32),
                    _buildFeaturedSection(context, provider),
                    const SizedBox(height: 32),
                    _buildFounderStory(context),
                    const SizedBox(height: 32),
                    _buildTestimonialsSection(provider),
                    const SizedBox(height: 32),
                    _buildServicesSection(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(HomeProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('assets/images/winleaf logo.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Winleaf Tea Lover',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: AppColors.textGrey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryGold.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryGold.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.stars, color: AppColors.secondaryGold, size: 20),
              const SizedBox(width: 4),
              provider.isLoadingPoints 
                ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textDark))
                : Text(
                    '${provider.points ?? 0} Points',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBanner() {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: _totalBannerCount,
            onPageChanged: (index) {
              // Pause video when not on first slide, play when on first
              if (index == 0) {
                _videoController?.play();
              } else {
                _videoController?.pause();
              }
              _startBannerAutoRotate();
            },
            itemBuilder: (context, index) {
              if (index == 0) {
                // --- Video Banner ---
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.black,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: GestureDetector(
                      onTap: () {
                        if (_videoController != null && _videoController!.value.isInitialized) {
                          setState(() {
                            if (_videoController!.value.isPlaying) {
                              _videoController!.pause();
                            } else {
                              _videoController!.play();
                            }
                          });
                        }
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                        // Thumbnail shown instantly while video loads
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/home_banner.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Video fades in once initialized
                        if (_videoController != null)
                          AnimatedOpacity(
                            opacity: _videoInitialized ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 600),
                            child: _videoInitialized
                                ? FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width: _videoController!.value.size.width,
                                      height: _videoController!.value.size.height,
                                      child: VideoPlayer(_videoController!),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        // Dark overlay for readability
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                              colors: [
                                Colors.black.withOpacity(0.5),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        // Label
                        const Positioned(
                          bottom: 12,
                          left: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pure Assam Tea',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                                ),
                              ),
                              Text(
                                'Crafted through centuries-old traditions',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Center Play Button Overlay when Video is Paused
                        if (_videoController != null && _videoInitialized && !_videoController!.value.isPlaying)
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _videoController?.play();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            ),
                          ),
                        // Video Controls: Play/Pause and Mute/Unmute buttons
                        Positioned(
                          bottom: 10,
                          right: 12,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Play / Pause button
                              GestureDetector(
                                onTap: () {
                                  if (_videoController != null && _videoController!.value.isInitialized) {
                                    setState(() {
                                      if (_videoController!.value.isPlaying) {
                                        _videoController!.pause();
                                      } else {
                                        _videoController!.play();
                                      }
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    (_videoController?.value.isPlaying ?? false)
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Mute / Unmute button
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isMuted = !_isMuted;
                                    _videoController?.setVolume(_isMuted ? 0 : 1);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isMuted ? Icons.volume_off : Icons.volume_up,
                                    color: Colors.white,
                                    size: 18,
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
              );
              } else {
                // --- Image Banners ---
                final imageIndex = index - 1;
                return InkWell(
                  onTap: () => widget.onViewAll?.call(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: AssetImage(_bannerImages[imageIndex]),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_totalBannerCount, (index) {
            return AnimatedBuilder(
              animation: _bannerController,
              builder: (context, child) {
                double selected = 0;
                if (_bannerController.hasClients) {
                  selected = (_bannerController.page ?? 0);
                }
                bool isActive = index == selected.round();
                return Container(
                  width: isActive ? 20 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primaryOrange : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildVideoTestimonialsSection() {
    final List<String> videoUrls = [
      'https://winleafteas.com/wp-content/uploads/2026/08/Video-64422.mp4', // Was 3rd, now 1st
      'https://winleafteas.com/wp-content/uploads/2026/08/Video-17451.mp4', // Was 4th, now 2nd
      'https://winleafteas.com/wp-content/uploads/2026/08/Video-55719.mp4', // Was 1st, now 3rd
      'https://winleafteas.com/wp-content/uploads/2026/08/Video-13805.mp4', // Was 2nd, now 4th
      'https://winleafteas.com/wp-content/uploads/2026/08/Video-1776.mp4',
      'https://winleafteas.com/wp-content/uploads/2026/08/Video-84302.mp4',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Video Testimonials',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            if (videoUrls.length > 2)
              TextButton(
                onPressed: () {
                  setState(() {
                    _showAllVideos = !_showAllVideos;
                  });
                },
                child: Text(
                  _showAllVideos ? 'Less' : 'More',
                  style: GoogleFonts.montserrat(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: VideoTestimonialItem(videoUrl: videoUrls[0]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: VideoTestimonialItem(videoUrl: videoUrls[1]),
              ),
            ),
          ],
        ),
        if (_showAllVideos) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: VideoTestimonialItem(videoUrl: videoUrls[2]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: VideoTestimonialItem(videoUrl: videoUrls[3]),
                ),
              ),
            ],
          ),
          if (videoUrls.length > 4) ...[
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, 
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 9 / 16,
              ),
              itemCount: videoUrls.length - 4,
              itemBuilder: (context, index) {
                return VideoTestimonialItem(videoUrl: videoUrls[index + 4]);
              },
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildFeaturedSection(BuildContext context, HomeProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Featured Product',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            TextButton(
              onPressed: () {
                widget.onViewAll?.call();
              },
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: GoogleFonts.montserrat(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textDark, size: 20),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (provider.isLoadingProducts)
          const Center(child: CircularProgressIndicator())
        else if (provider.featuredProducts == null || provider.featuredProducts!.isEmpty)
          const Center(child: Text('No products found', style: TextStyle(color: AppColors.textDark)))
        else
          Column(
            children: provider.featuredProducts!
                .map((product) => _buildProductItem(context, product))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildProductItem(BuildContext context, Product product) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 140,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: CachedNetworkImage(
                      imageUrl: product.images.isNotEmpty ? product.images[0] : '',
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Container(
                        color: AppColors.cardGrey,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.cardGrey,
                        child: const Center(child: Icon(Icons.image_not_supported)),
                      ),
                    ),
                  ),
                  if (product.onSale)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SALE',
                          style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailsScreen(product: product),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryOrange,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_bag, size: 14),
                                SizedBox(width: 4),
                                Text('Buy Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₹${product.price.toInt()}',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryOrange,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFounderStory(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  image: const DecorationImage(
                    image: AssetImage('assets/images/winleaf logo.png'),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'The Win Leaf Story',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Founded by Mr. Syed Mohammed',
                      style: GoogleFonts.montserrat(
                        color: AppColors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Our Founder Mr. Syed Mohammed, a former Cricketer for Assam & RCB, discovered the true essence of Assam tea during his playing days. He is now on a mission to bring the best Assam tea to the world.',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              height: 1.5,
              color: AppColors.black,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutUsScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryOrange),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Read Full Story', style: TextStyle(color: AppColors.primaryOrange)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialsSection(HomeProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            'Our Valued Customers',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (provider.isLoadingTestimonials)
          const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (provider.testimonials == null || provider.testimonials!.isEmpty)
          const Center(child: Text('No testimonials found', style: TextStyle(color: AppColors.textDark)))
        else
          SizedBox(
            height: 250,
            child: PageView.builder(
              controller: _testimonialController,
              itemCount: provider.testimonials!.length,
              onPageChanged: (index) {
                _startTestimonialAutoRotate();
              },
              itemBuilder: (context, index) {
                final t = provider.testimonials![index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: AppColors.cardGrey, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                image: t.image.startsWith('assets/') 
                                      ? AssetImage(t.image) as ImageProvider
                                      : CachedNetworkImageProvider(t.image),
                                  fit: BoxFit.cover,
                                ),
                                border: Border.all(
                                    color: AppColors.primaryGold.withOpacity(0.3),
                                    width: 1.5),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.name,
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      color: AppColors.textDark,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    t.role,
                                    style: GoogleFonts.montserrat(
                                      color: AppColors.textGrey,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.format_quote_rounded,
                              color: AppColors.primaryGold.withOpacity(0.2),
                              size: 44,
                            ),
                          ],
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Text(
                              t.comment,
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: AppColors.textDark,
                                height: 1.5,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
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
    );
  }

  Widget _buildServicesSection() {
    final services = [
      {'icon': Icons.subscriptions_outlined, 'title': 'Subscription', 'subtitle': 'Tea at your doorstep', 'action': 'subscriptions'},
      {'icon': Icons.card_giftcard_outlined, 'title': 'Rewards', 'subtitle': 'Redeem points', 'action': 'rewards'},
      {'icon': Icons.share_outlined, 'title': 'Refer & Earn', 'subtitle': 'Earn \u20B9100 credit', 'action': 'refer'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            'Our Features',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final s = services[index];
            final colors = [
              AppColors.primaryOrange,
              AppColors.primaryGold,
              AppColors.primaryGreen,
            ];
            final themeColor = colors[index % colors.length];
            return _buildSquareServiceItem(
              context,
              s['icon'] as IconData,
              s['title'] as String,
              s['subtitle'] as String,
              themeColor,
              s['action'] as String,
            );
          },
        ),
      ],
    );
  }

  void _handleFeatureTap(BuildContext context, String action) {
    final profileProvider = context.read<ProfileProvider>();
    
    if (action == 'rewards') {
      // RewardsScreen handles login internally
      Navigator.push(context, MaterialPageRoute(builder: (_) => const RewardsScreen()));
      return;
    }
    
    if (!profileProvider.isLoggedIn) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen())).then((_) {
        profileProvider.checkStatus();
      });
      return;
    }

    if (action == 'subscriptions') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionsScreen()));
    } else if (action == 'refer') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralCouponsScreen()));
    }
  }

  Widget _buildSquareServiceItem(BuildContext context, IconData icon, String title, String subtitle, Color themeColor, String action) {
    return GestureDetector(
      onTap: () => _handleFeatureTap(context, action),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: themeColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: themeColor.withOpacity(0.1), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: themeColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: themeColor, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.montserrat(
                color: AppColors.textGrey,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class VideoTestimonialItem extends StatefulWidget {
  final String videoUrl;
  const VideoTestimonialItem({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoTestimonialItemState createState() => _VideoTestimonialItemState();
}

class _VideoTestimonialItemState extends State<VideoTestimonialItem> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Delay initialization to prevent blocking the UI thread during page load
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
        _controller!.initialize().then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isInitialized && _controller != null)
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              )
            else
              Container(
                color: Colors.black12,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.grey, strokeWidth: 2),
                ),
              ),
            
            if (_isInitialized && _controller != null)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
                  });
                },
                child: Container(
                  color: Colors.transparent, // to catch taps
                  alignment: Alignment.center,
                  child: Icon(
                    _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white.withOpacity(_controller!.value.isPlaying ? 0.0 : 0.8),
                    size: 48,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
