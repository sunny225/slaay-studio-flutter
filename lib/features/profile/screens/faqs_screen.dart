import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/liquid_background.dart';
import '../../../services/api_client.dart';

class FaqsScreen extends StatefulWidget {
  const FaqsScreen({super.key});

  @override
  State<FaqsScreen> createState() => _FaqsScreenState();
}

class _FaqsScreenState extends State<FaqsScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _faqs = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _fetchFaqs();
  }

  Future<void> _fetchFaqs() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final res = await ApiClient.get('/public/faqs');
      if (res.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null && body['data']['faqs'] != null) {
          final List<dynamic> fetched = body['data']['faqs'];
          
          final cats = {'All'};
          for (final f in fetched) {
            if (f['category'] != null && f['category'].toString().isNotEmpty) {
              cats.add(f['category'].toString());
            }
          }

          setState(() {
            _faqs = fetched;
            _categories = cats.toList();
            _isLoading = false;
          });
          return;
        }
      }
      setState(() {
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final filteredFaqs = _selectedCategory == 'All'
        ? _faqs
        : _faqs.where((f) => f['category'] == _selectedCategory).toList();

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: isDarkMode ? Colors.white : AppColors.primary,
              size: 22,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'FAQs',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontSize: 16,
              color: isDarkMode ? Colors.white : AppColors.primary,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : Column(
                children: [
                  if (_categories.length > 1)
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _categories.length,
                        itemBuilder: (context, idx) {
                          final cat = _categories[idx];
                          final isSelected = _selectedCategory == cat;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(
                                cat,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDarkMode ? Colors.white70 : AppColors.primary),
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              backgroundColor: isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.03),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                              padding: EdgeInsets.zero,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedCategory = cat;
                                  });
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _fetchFaqs,
                      color: AppColors.primary,
                      child: filteredFaqs.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                                Center(
                                  child: Column(
                                    children: [
                                      HugeIcon(
                                        icon: HugeIcons.strokeRoundedHelpCircle,
                                        size: 48,
                                        color: AppColors.primary.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        "No FAQs Available",
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode ? Colors.white : AppColors.textPrimaryLight,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "No frequently asked questions found in this category.",
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: filteredFaqs.length,
                              itemBuilder: (context, index) {
                                final faq = filteredFaqs[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? AppColors.surfaceDark : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDarkMode ? Colors.white10 : AppColors.borderLight,
                                    ),
                                  ),
                                  child: ExpansionTile(
                                    title: Text(
                                      faq['question'] ?? '',
                                      style: GoogleFonts.outfit(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? Colors.white : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                    shape: const RoundedRectangleBorder(side: BorderSide.none),
                                    collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
                                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    expandedAlignment: Alignment.topLeft,
                                    iconColor: AppColors.primary,
                                    collapsedIconColor: isDarkMode ? Colors.white54 : Colors.black45,
                                    children: [
                                      Text(
                                        faq['answer'] ?? '',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12.5,
                                          height: 1.5,
                                          color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
