import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isOtpSent = false;
  
  final _supabase = Supabase.instance.client;

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan email')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Use resetPasswordForEmail for proper recovery flow
      await _supabase.auth.resetPasswordForEmail(email);
      setState(() => _isOtpSent = true);
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kode reset dikirim ke email')));
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengirim kode: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyAndReset() async {
    final otp = _otpController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan kode OTP')));
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan password baru')));
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password tidak cocok')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      
      // Verify OTP (Type recovery for resetPassword flow)
      final res = await _supabase.auth.verifyOTP(
        token: otp,
        type: OtpType.recovery, 
        email: email,
      );
      
      if (res.session != null) {
        // User logged in, now update password
        await _supabase.auth.updateUser(UserAttributes(password: password));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
             content: Text('Password berhasil diubah. Silakan login dengan password baru.'),
             backgroundColor: Colors.green,
          ));
          // Sign out to force re-login with new password, or keep logged in?
          // Usually better to let them try login. 
          await _supabase.auth.signOut();
          Navigator.pop(context); // Go back to login
        }
      }
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal verifikasi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lupa Password')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               if (!_isOtpSent) ...[
                 const Text('Masukkan email untuk menerima kode reset password.'),
                 const SizedBox(height: 20),
                 TextField(
                   controller: _emailController,
                   decoration: const InputDecoration(
                     labelText: 'Email', 
                     border: OutlineInputBorder(),
                     prefixIcon: Icon(Icons.email),
                   ),
                   keyboardType: TextInputType.emailAddress,
                 ),
                 const SizedBox(height: 24),
                 ElevatedButton(
                   onPressed: _isLoading ? null : _sendOtp,
                   style: ElevatedButton.styleFrom(
                     padding: const EdgeInsets.symmetric(vertical: 16),
                   ),
                   child: _isLoading 
                     ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                     : const Text('Kirim Kode'),
                 )
               ] else ...[
                 const Text('Masukkan kode 6-digit yang dikirim ke email Anda.'),
                 const SizedBox(height: 20),
                 TextField(
                   controller: _otpController,
                   decoration: const InputDecoration(
                     labelText: 'Kode OTP', 
                     border: OutlineInputBorder(),
                     prefixIcon: Icon(Icons.lock_clock),
                   ),
                   keyboardType: TextInputType.number,
                 ),
                 const SizedBox(height: 16),
                 TextField(
                   controller: _passwordController,
                   obscureText: true,
                   decoration: const InputDecoration(
                     labelText: 'Password Baru', 
                     border: OutlineInputBorder(),
                     prefixIcon: Icon(Icons.lock),
                   ),
                 ),
                 const SizedBox(height: 16),
                 TextField(
                   controller: _confirmPasswordController,
                   obscureText: true,
                   decoration: const InputDecoration(
                     labelText: 'Konfirmasi Password', 
                     border: OutlineInputBorder(),
                     prefixIcon: Icon(Icons.lock_outline),
                   ),
                 ),
                 const SizedBox(height: 24),
                 ElevatedButton(
                   onPressed: _isLoading ? null : _verifyAndReset,
                   style: ElevatedButton.styleFrom(
                     padding: const EdgeInsets.symmetric(vertical: 16),
                   ),
                   child: _isLoading 
                     ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                     : const Text('Simpan Password Baru'),
                 ),
                 TextButton(
                   onPressed: () => setState(() => _isOtpSent = false),
                   child: const Text('Ubah Email'),
                 )
               ]
            ],
          ),
        ),
      ),
    );
  }
}
