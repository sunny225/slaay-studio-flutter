import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../home/screens/main_navigation_wrapper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../providers/product_provider.dart';
import 'product_detail_screen.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/press_scale_effect.dart';
import '../../../core/widgets/smooth_page_route.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchScreen extends StatefulWidget {
  final bool triggerVoiceSearch;
  const SearchScreen({super.key, this.triggerVoiceSearch = false});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _searchQuery = '';

  // Speech-to-Text instances
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isSpeechInitialized = false;

  final List<String> _popularSuggestions = [
    'SHIRTS',
    'JEANS',
    'TROUSERS',
    'POLOS',
    'CARGOS',
    'SHORTS',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.triggerVoiceSearch) {
        _startVoiceSearchFlow();
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Timer? _debounce;

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  Future<void> _startVoiceSearchFlow() async {
    // 1. Request microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required for voice search.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
      return;
    }

    // 2. Initialize Speech engine
    if (!_isSpeechInitialized) {
      try {
        _isSpeechInitialized = await _speech.initialize(
          onStatus: (val) => debugPrint('STT status: $val'),
          onError: (val) => debugPrint('STT error: $val'),
        );
      } catch (e) {
        debugPrint('Error initializing Speech-to-Text: $e');
      }
    }

    if (!_isSpeechInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voice search is not available on this device.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
      return;
    }

    // 3. Show pulsating sound overlay sheet and start listening
    if (mounted) {
      _showSpeechListeningSheet();
    }
  }

  void _showSpeechListeningSheet() {
    bool sheetListening = true;

    // Trigger Speech recognition
    _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _searchController.text = result.recognizedWords;
            _searchController.selection = TextSelection.fromPosition(
              TextPosition(offset: result.recognizedWords.length),
            );
          });
        }

        if (result.finalResult) {
          // Final transcription received, close the wave panel automatically
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted && Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          });
        }
      },
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            // Keep track of active recognition status updates
            _speech.statusListener = (status) {
              if (status == 'notListening' || status == 'done') {
                if (context.mounted) {
                  setSheetState(() {
                    sheetListening = false;
                  });
                }
              }
            };

            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            return Container(
              height: 300,
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 20),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    sheetListening ? 'LISTENING...' : 'TAP MICROPHONE TO RESUME',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: sheetListening ? Colors.red : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // Microphone pulsating button
                  GestureDetector(
                    onTap: () {
                      if (sheetListening) {
                        _speech.stop();
                        setSheetState(() => sheetListening = false);
                      } else {
                        setSheetState(() => sheetListening = true);
                        _speech.listen(
                          onResult: (result) {
                            if (mounted) {
                              setState(() {
                                _searchController.text = result.recognizedWords;
                              });
                            }
                            if (result.finalResult) {
                              Future.delayed(const Duration(milliseconds: 1000), () {
                                if (mounted && Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }
                              });
                            }
                          },
                        );
                      }
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (sheetListening)
                          const ListeningPulseRings(),
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: sheetListening ? Colors.red : Colors.black,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (sheetListening ? Colors.red : Colors.black).withValues(alpha: 0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedMic01,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'Say what you are looking for...'
                          : _searchController.text,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      // Safe guard: stop speech listener when sheet pops
      _speech.stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Filter products dynamically based on search query matching name, description, or category
    final query = _searchQuery.trim().toLowerCase();
    final results = productProvider.products.where((product) {
      return product.name.toLowerCase().contains(query) ||
          product.fabric.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
    }).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBgColor(context),
        body: SafeArea(
          child: Column(
            children: [
              // Search Input Header Row matching immersive aesthetics
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    // Back button circle matching standard style
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowLeft01,
                          color: const Color(0xFF121111),
                          size: Theme.of(context).platform == TargetPlatform.iOS ? 18 : 22,
                        ),
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            final hasWrapper = context.findAncestorWidgetOfExactType<MainNavigationWrapper>() != null;
                            if (hasWrapper) {
                              MainNavigationWrapper.activeTabNotifier.value = 0;
                            } else {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const MainNavigationWrapper()),
                                (route) => false,
                              );
                            }
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF6F6F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDarkMode ? Colors.white12 : Colors.black.withValues(alpha: 0.04),
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 14),
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedSearch01,
                              color: isDarkMode ? Colors.white70 : AppColors.secondary,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _focusNode,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.white : AppColors.primary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search shirts, jeans, kurtas...',
                                  hintStyle: GoogleFonts.outfit(
                                    color: isDarkMode ? Colors.white30 : AppColors.textSecondaryLight.withValues(alpha: 0.5),
                                    fontWeight: FontWeight.normal,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            else
                              IconButton(
                                icon: const HugeIcon(
                                  icon: HugeIcons.strokeRoundedMic01,
                                  color: AppColors.secondary,
                                  size: 20,
                                ),
                                onPressed: _startVoiceSearchFlow,
                              ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _searchQuery.isEmpty
                    ? _buildSuggestionsStage(isDarkMode)
                    : _buildResultsStage(results, isDarkMode),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsStage(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'POPULAR SEARCHES',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: isDarkMode ? Colors.white70 : AppColors.secondary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _popularSuggestions.map((suggestion) {
              return ActionChip(
                label: Text(
                  suggestion,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                backgroundColor: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF6F6F6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isDarkMode ? Colors.white12 : Colors.black.withValues(alpha: 0.04),
                  ),
                ),
                onPressed: () {
                  _searchController.text = suggestion;
                  _searchController.selection = TextSelection.fromPosition(
                    TextPosition(offset: suggestion.length),
                  );
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsStage(List<dynamic> results, bool isDarkMode) {
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedSearch01,
                size: 64,
                color: AppColors.borderLight,
              ),
              const SizedBox(height: 16),
              Text(
                'No match found',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try searching for general keywords like shirts, denims, or loose fit.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.52,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final product = results[index];
        return PressScaleEffect(
          onTap: () {
            Navigator.push(
              context,
              SmoothPageRoute(
                child: ProductDetailScreen(productId: product.slug),
                direction: AxisDirection.right,
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image container
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDarkMode ? Colors.white12 : const Color(0xFFF2F2F2),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CachedNetworkImage(
                            imageUrl: product.images[0],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, url) => Container(color: const Color(0xFFF6F6F6)),
                            memCacheWidth: 360,
                          ),
                        ),
                        if (product.isOos)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.4),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'SOLD OUT',
                                    style: GoogleFonts.outfit(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (!product.isOos && product.totalStockLeft < 6)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE65100),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                'ONLY ${product.totalStockLeft} LEFT!',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Title and Price
              Text(
                product.fabric,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                product.name,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppColors.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    '₹${product.price.toInt()}',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDarkMode ? Colors.white : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (product.originalPrice > product.price)
                    Text(
                      '₹${product.originalPrice.toInt()}',
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        color: isDarkMode ? Colors.white30 : AppColors.textSecondaryLight,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// Reusable continuous scale pulse rings for voice listening visual feedback
class ListeningPulseRings extends StatefulWidget {
  const ListeningPulseRings({super.key});

  @override
  State<ListeningPulseRings> createState() => _ListeningPulseRingsState();
}

class _ListeningPulseRingsState extends State<ListeningPulseRings> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 72 + (_controller.value * 50),
              height: 72 + (_controller.value * 50),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withValues(alpha: 0.3 * (1.0 - _controller.value)),
              ),
            ),
            Container(
              width: 72 + (_controller.value * 100),
              height: 72 + (_controller.value * 100),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withValues(alpha: 0.15 * (1.0 - _controller.value)),
              ),
            ),
          ],
        );
      },
    );
  }
}
