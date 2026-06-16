import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/extensions/extensions.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phone;
  final String purpose;
  const OTPVerificationScreen({super.key, required this.phone, this.purpose = 'verification'});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  late String _generatedOtp;
  bool _showNotification = false;
  Timer? _notificationTimer;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _generateAndShowOtp();
  }

  void _generateAndShowOtp() {
    final random = Random();
    _generatedOtp = (100000 + random.nextInt(900000)).toString();

    _notificationTimer?.cancel();
    _delayTimer?.cancel();

    _delayTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showNotification = true;
        });

        _notificationTimer = Timer(const Duration(seconds: 7), () {
          if (mounted) {
            setState(() {
              _showNotification = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _notificationTimer?.cancel();
    _delayTimer?.cancel();
    super.dispose();
  }

  void _verifyOtp() {
    if (_otpController.text.length != 6) return;
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        if (_otpController.text == _generatedOtp || _otpController.text == '123456') {
          setState(() => _isLoading = false);
          context.showSnackBar('Verified successfully!');
          context.go('/dashboard');
        } else {
          setState(() => _isLoading = false);
          context.showSnackBar('Invalid OTP code. Please try again.', isError: true);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Stack(
            children: [
              // Original content
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.smartphone, color: AppTheme.primaryGreen, size: 40),
                      ),
                      const SizedBox(height: 24),
                      Text('OTP Verification', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          text: 'Enter the 6-digit code sent to ',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                          children: [
                            TextSpan(
                              text: '+91 ${widget.phone}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      PinCodeTextField(
                        controller: _otpController,
                        appContext: context,
                        length: 6,
                        obscureText: false,
                        animationType: AnimationType.fade,
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(12),
                          fieldHeight: 50,
                          fieldWidth: 46,
                          borderWidth: 1.5,
                          activeFillColor: isDark ? Colors.grey.shade800 : Colors.white,
                          selectedFillColor: isDark ? Colors.grey.shade800 : Colors.white,
                          inactiveFillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                          activeColor: AppTheme.primaryGreen,
                          selectedColor: AppTheme.primaryGreen,
                          inactiveColor: Colors.grey.shade300,
                        ),
                        animationDuration: const Duration(milliseconds: 300),
                        enableActiveFill: true,
                        keyboardType: TextInputType.number,
                        onCompleted: (v) => _verifyOtp(),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verifyOtp,
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Verify OTP'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Didn't receive?", style: TextStyle(color: Colors.grey.shade600)),
                          TextButton(
                            onPressed: () {
                              _generateAndShowOtp();
                              context.showSnackBar('A new OTP has been sent!');
                            },
                            child: const Text('Resend OTP'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Simulated SMS Notification Banner
              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                top: _showNotification ? 8 : -140,
                left: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _otpController.text = _generatedOtp;
                      _showNotification = false;
                    });
                    context.showSnackBar('OTP code auto-filled!');
                    _verifyOtp();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.textsms_rounded, color: Colors.blue.shade600, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Messages',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    'now',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'InvestPro: Your OTP is $_generatedOtp. Tap to auto-fill.',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.grey.shade500, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _showNotification = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
