import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/liquid_background.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../services/api_client.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket(AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final name = _nameController.text.trim().isNotEmpty 
        ? _nameController.text.trim()
        : (auth.userName ?? 'User');
    final email = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : (auth.email ?? 'support@slaay.com');
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    try {
      final res = await ApiClient.post('/public/support/ticket', {
        'name': name,
        'email': email,
        'subject': subject,
        'message': message,
      });

      setState(() {
        _isSubmitting = false;
      });

      if (res.statusCode == 200 || res.statusCode == 201) {
        final Map<String, dynamic> body = jsonDecode(res.body);
        if (body['success'] == true) {
          _subjectController.clear();
          _messageController.clear();
          
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(
                  'Query Submitted',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
                content: Text(
                  'We have received your support request. Our customer care team will get back to you at $email shortly.',
                  style: GoogleFonts.outfit(fontSize: 13),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                ],
              ),
            );
          }
          return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit support request. Please try again.'), backgroundColor: AppColors.error),
        );
      }
    } catch (_) {
      setState(() {
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error. Please check your connection.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (_nameController.text.isEmpty && authProvider.userName != null && !authProvider.userName!.startsWith('User_')) {
      _nameController.text = authProvider.userName!;
    }
    if (_emailController.text.isEmpty && authProvider.email != null) {
      _emailController.text = authProvider.email!;
    }

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
            'HELP & SUPPORT',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontSize: 16,
              color: isDarkMode ? Colors.white : AppColors.primary,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact details card
              Card(
                elevation: 0,
                color: isDarkMode ? AppColors.surfaceDark : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: isDarkMode ? Colors.white10 : AppColors.borderLight),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: const HugeIcon(icon: HugeIcons.strokeRoundedMailAtSign01, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Email Support', style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : AppColors.textPrimaryLight)),
                                const SizedBox(height: 2),
                                Text('support@slaay.com', style: GoogleFonts.outfit(fontSize: 12, color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: const HugeIcon(icon: HugeIcons.strokeRoundedCustomerService, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Customer Care Hotline', style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : AppColors.textPrimaryLight)),
                                const SizedBox(height: 2),
                                Text('+91 1800 123 4567', style: GoogleFonts.outfit(fontSize: 12, color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                                const SizedBox(height: 2),
                                Text('Mon - Sat: 9:00 AM - 6:00 PM', style: GoogleFonts.outfit(fontSize: 10, color: isDarkMode ? Colors.white30 : Colors.black38)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Submit a Query',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 12),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.outfit(fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.outfit(fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Email Address'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter email';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                          return 'Enter valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _subjectController,
                      style: GoogleFonts.outfit(fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Subject / Concern'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter subject' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _messageController,
                      style: GoogleFonts.outfit(fontSize: 13),
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Message / Inquiry Details',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter your message details' : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : () => _submitTicket(authProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text('SUBMIT INQUIRY', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
