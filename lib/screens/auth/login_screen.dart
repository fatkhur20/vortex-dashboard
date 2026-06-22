import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vortex_dashboard/core/constants/theme_constants.dart';

class LoginScreen extends StatefulWidget {
  final void Function(String name, String? photoPath) onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _picker = ImagePicker();
  String? _photoPath;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF0D0D0D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                )),
              const SizedBox(height: 20),
              const Text('Add Photo', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: ThemeConstants.primaryColor),
                title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: ThemeConstants.primaryColor),
                title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;
    final file = await _picker.pickImage(source: source, maxWidth: 512, maxHeight: 512);
    if (file != null) {
      setState(() => _photoPath = file.path);
    }
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    widget.onLogin(name, _photoPath);
  }

  @override
  Widget build(BuildContext context) {
    final initial = _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: ThemeConstants.amoledBackground,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 48),
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ThemeConstants.primaryColor.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ThemeConstants.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 30, spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.speed, color: ThemeConstants.primaryColor, size: 50),
                  ),
                  const SizedBox(height: 24),
                  const Text('VORTEX', style: TextStyle(
                    color: ThemeConstants.primaryColor, fontSize: 40,
                    fontWeight: FontWeight.bold, letterSpacing: 10,
                  )),
                  const SizedBox(height: 4),
                  Text('DASHBOARD', style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 16, letterSpacing: 6, fontWeight: FontWeight.w300,
                  )),
                  const SizedBox(height: 48),
                  const Text('Welcome', style: TextStyle(
                    color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700,
                  )),
                  const SizedBox(height: 8),
                  Text('Enter your name to get started',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
                  const SizedBox(height: 32),

                  // Avatar picker
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Stack(
                      children: [
                        Container(
                          width: 88, height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ThemeConstants.primaryColor.withValues(alpha: 0.15),
                            border: Border.all(
                              color: ThemeConstants.primaryColor.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: _photoPath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(44),
                                  child: Image.file(File(_photoPath!), fit: BoxFit.cover),
                                )
                              : Center(
                                  child: Text(initial, style: const TextStyle(
                                    fontSize: 36, fontWeight: FontWeight.w700,
                                    color: ThemeConstants.primaryColor,
                                  )),
                                ),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ThemeConstants.primaryColor,
                              border: Border.all(color: ThemeConstants.amoledBackground, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Name input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: TextField(
                      controller: _nameCtrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      decoration: InputDecoration(
                        hintText: 'Your name',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
                        prefixIcon: Icon(Icons.person, color: Colors.white.withValues(alpha: 0.3)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _nameCtrl.text.trim().isEmpty ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeConstants.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
