import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../main/main_navigation.dart';

class VerifySignupScreen extends StatefulWidget {
  final String email;
  final String? fullName;
  final String? phoneNumber;

  const VerifySignupScreen({
    super.key,
    required this.email,
    this.fullName,
    this.phoneNumber,
  });

  @override
  State<VerifySignupScreen> createState() => _VerifySignupScreenState();
}

class _VerifySignupScreenState extends State<VerifySignupScreen> {
  final _otpController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan kode OTP')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Verify OTP for Signup
      final AuthResponse res = await _supabase.auth.verifyOTP(
        token: otp,
        type: OtpType.signup,
        email: widget.email,
      );

      if (res.session != null) {
        // 2. Update Profile with Name and Phone (now that needed permissions are likely granted via RLS or authenticated)
        // Note: 'profiles' row is usually created via Trigger. We just update it.
        final userId = res.user!.id;

        await _supabase.from('profiles').update({
          if (widget.fullName != null) 'full_name': widget.fullName,
          if (widget.phoneNumber != null) 'phone_number': widget.phoneNumber,
          'email': widget.email,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);

        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
             content: Text('Verifikasi Berhasil! Selamat Datang.'),
             backgroundColor: Colors.green,
           ));
           
           // Navigate to Main App
           Navigator.of(context).pushAndRemoveUntil(
             MaterialPageRoute(builder: (_) => const MainNavigation()),
             (route) => false,
           );
        }
      } else {
        throw 'Verifikasi gagal. Sesi tidak ditemukan.';
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Masukkan kode verifikasi (OTP) yang telah dikirim ke email Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              widget.email,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
             const SizedBox(height: 32),
             
             TextField(
               controller: _otpController,
               keyboardType: TextInputType.number,
               maxLength: 8, // Allow up to 8 as per user request (though standard is 6)
               textAlign: TextAlign.center,
               style: const TextStyle(fontSize: 24, letterSpacing: 4),
               decoration: const InputDecoration(
                 hintText: 'Masukkan Token',
                 counterText: '',
                 border: OutlineInputBorder(),
               ),
             ),
             
             const SizedBox(height: 24),
             
             SizedBox(
               width: double.infinity,
               child: ElevatedButton(
                 onPressed: _isLoading ? null : _verifyOtp,
                 style: ElevatedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   backgroundColor: AppTheme.primaryOrange,
                   foregroundColor: Colors.white,
                 ),
                 child: _isLoading 
                   ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                   : const Text('Verifikasi'),
               ),
             ),
          ],
        ),
      ),
    );
  }
}
