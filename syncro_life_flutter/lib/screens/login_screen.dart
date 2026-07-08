import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/google_sign_in_web_button.dart';
import '../theme/colors.dart';
import '../theme/custom_icons.dart';
import '../models/app_state.dart';
import 'main_navigation.dart';
import 'admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showAdminLogin = false;
  String? _errorMessage;
  bool _rememberAdmin = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '112861230992-bp8aq8dqrd6s3nvt6enmv0hc9g9rsmcp.apps.googleusercontent.com' : null,
    serverClientId: kIsWeb ? null : '112861230992-bp8aq8dqrd6s3nvt6enmv0hc9g9rsmcp.apps.googleusercontent.com',
    scopes: <String>[
      'email',
      'https://www.googleapis.com/auth/calendar.events.readonly',
    ],
  );
  StreamSubscription<GoogleSignInAccount?>? _googleSignInSubscription;
  GoogleSignInAccount? _pendingWebAccount;

  Future<void> _loadAdminCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool('remember_admin') ?? false;
      if (remember) {
        final savedUser = prefs.getString('admin_username') ?? '';
        final savedPass = prefs.getString('admin_password') ?? '';
        setState(() {
          _rememberAdmin = true;
          _usernameController.text = savedUser;
          _passwordController.text = savedPass;
        });
      }
    } catch (e) {
      debugPrint("LoginScreen: Error loading admin credentials: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAdminCredentials();

    _googleSignInSubscription = _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) async {
      if (account == null) return;
      if (!mounted) return;
      
      final appState = Provider.of<AppState>(context, listen: false);
      _clearError();
      
      try {
        final String? serverAuthCode = account.serverAuthCode;
        if (serverAuthCode == null) {
          setState(() {
            _errorMessage = "Google auth failed: Server Auth Code is null.";
          });
          return;
        }

        final success = await appState.loginWithGoogle(
          serverAuthCode,
          clientId: '112861230992-bp8aq8dqrd6s3nvt6enmv0hc9g9rsmcp.apps.googleusercontent.com',
          redirectUri: kIsWeb ? 'postmessage' : '',
        );
        if (success && mounted) {
          appState.googlePhotoUrl = account.photoUrl;
          _navigateToNextScreen(appState);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            if (kIsWeb) {
              _pendingWebAccount = account;
              _errorMessage = "Cửa sổ cấp quyền truy cập Lịch bị chặn bởi trình duyệt hoặc gặp lỗi. Vui lòng click nút dưới đây để tiếp tục đăng nhập.";
            } else {
              _errorMessage = _formatGoogleSignInError(e);
            }
          });
        }
      }
    });
  }

  Future<void> _handleGoogleSignIn(AppState appState) async {
    _clearError();
    try {
      final GoogleSignInAccount? user = await _googleSignIn.signIn();
      if (user == null) {
        setState(() {
          _errorMessage = "Google Sign-In was cancelled or failed.";
        });
        return;
      }

      final String? serverAuthCode = user.serverAuthCode;
      if (serverAuthCode == null) {
        setState(() {
          _errorMessage = "Google auth failed: Server Auth Code is null.";
        });
        return;
      }

      final success = await appState.loginWithGoogle(
        serverAuthCode,
        clientId: '112861230992-bp8aq8dqrd6s3nvt6enmv0hc9g9rsmcp.apps.googleusercontent.com',
        redirectUri: '',
      );
      if (success && mounted) {
        appState.googlePhotoUrl = user.photoUrl;
        _navigateToNextScreen(appState);
      }
    } catch (e) {
      setState(() {
        _errorMessage = _formatGoogleSignInError(e);
      });
    }
  }

  Future<void> _handlePendingWebAuth(AppState appState) async {
    if (_pendingWebAccount == null) return;
    _clearError();
    
    try {
      final String? serverAuthCode = _pendingWebAccount!.serverAuthCode;
      if (serverAuthCode == null) {
        setState(() {
          _errorMessage = "Google auth failed: Server Auth Code is null.";
        });
        return;
      }

      final success = await appState.loginWithGoogle(
        serverAuthCode,
        clientId: '112861230992-bp8aq8dqrd6s3nvt6enmv0hc9g9rsmcp.apps.googleusercontent.com',
        redirectUri: 'postmessage',
      );
      if (success && mounted) {
        appState.googlePhotoUrl = _pendingWebAccount!.photoUrl;
        _navigateToNextScreen(appState);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _formatGoogleSignInError(e);
        });
      }
    }
  }

  Widget _buildGoogleSignInButton(AppState appState) {
    if (kIsWeb) {
      if (_pendingWebAccount != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: appState.isLoading ? null : () => _handlePendingWebAuth(appState),
              icon: Icon(Icons.lock_open, color: Colors.white, size: 18),
              label: Text(
                "Cho phép cấp quyền & Đăng nhập",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentTeal,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () {
                setState(() {
                  _pendingWebAccount = null;
                  _errorMessage = null;
                });
              },
              child: Text(
                "Cancel and retry",
                style: TextStyle(color: AppColors.textMuted, fontSize: 12, decoration: TextDecoration.underline),
              ),
            ),
          ],
        );
      }

      return Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: buildWebSignInButton(
          initializationFuture: Future.value(true),
          isInitialized: true,
        ),
      );
    } else {
      return OutlinedButton(
        onPressed: appState.isLoading ? null : () => _handleGoogleSignIn(appState),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textLight,
          side: BorderSide(color: AppColors.googleBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.symmetric(vertical: 14),
          backgroundColor: AppColors.googleBg,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://www.google.com/images/branding/googleg/1x/googleg_standard_color_128dp.png',
              width: 18,
              height: 18,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.login, color: AppColors.accentTeal, size: 18);
              },
            ),
            SizedBox(width: 12),
            Text(
              "Continue with Google",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _googleSignInSubscription?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToNextScreen(AppState appState) {
    if (appState.isAdmin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainNavigation()),
      );
    }
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  String _formatGoogleSignInError(Object e) {
    final errStr = e.toString();
    final errLower = errStr.toLowerCase();
    if (errLower.contains("popup") || errLower.contains("unavailable") || errLower.contains("blocked")) {
      return "Cửa sổ đăng nhập Google bị chặn bởi trình duyệt. Vui lòng cho phép cửa sổ bật lên và thử lại.";
    }
    if (errLower.contains("android_backup") || errLower.contains("tron") || errLower.contains("battery_stats") || errLower.contains("-1") || errLower.contains("idpiframe_initialization_failed")) {
      return "Đăng nhập Google thất bại do cổng localhost (port) hoặc nguồn gốc (origin) này chưa được đăng ký trong Google Cloud Console. Để chạy thử nghiệm, bạn hãy bấm vào nút 'Login as admin' bên dưới và nhập username/password (nhập customer/customer hoặc admin/admin để tự động đăng nhập ngoại tuyến).";
    }
    return errStr.replaceAll("Exception:", "").trim();
  }

  Future<void> _handleSubmit(AppState appState) async {
    _clearError();
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberAdmin) {
        await prefs.setBool('remember_admin', true);
        await prefs.setString('admin_username', username);
        await prefs.setString('admin_password', password);
      } else {
        await prefs.setBool('remember_admin', false);
        await prefs.remove('admin_username');
        await prefs.remove('admin_password');
      }

      // Call Login API
      final success = await appState.loginUser(username, password);
      if (success && mounted) {
        _navigateToNextScreen(appState);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception:", "").trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: IconButton(
              icon: Icon(
                appState.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: appState.isDarkMode ? Colors.yellow : AppColors.primaryBlue,
              ),
              tooltip: appState.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              onPressed: () => appState.toggleTheme(),
            ),
          ),
          Center(
            child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hand-drawn lightning bolt logo with premium typography
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LightningBoltIcon(size: 40, tint: AppColors.accentTeal),
                  SizedBox(width: 12),
                  Text(
                    "Syncro Life",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Center(
                child: Text(
                  "AI-powered lifestyle synchronizer",
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 36),

              // Card panel for the Auth Form
              AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: !_showAdminLogin
                    ? Container(
                        key: ValueKey('google_login'),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              "Welcome",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textLight),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Please sign in with Google to access your synced schedule.",
                              style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
                            ),
                            SizedBox(height: 24),
                            _buildGoogleSignInButton(appState),
                            if (_errorMessage != null) ...[
                              SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: AppColors.overlapRed,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      )
                    : Container(
                        key: ValueKey('admin_login'),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.arrow_back, color: AppColors.textLight, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _showAdminLogin = false;
                                        _clearError();
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    "Admin Login",
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textLight),
                                  ),
                                ],
                              ),
                              SizedBox(height: 24),

                              // Username Input Field
                              TextFormField(
                                controller: _usernameController,
                                style: TextStyle(color: AppColors.textLight, fontSize: 14),
                                onChanged: (_) => _clearError(),
                                decoration: InputDecoration(
                                  hintText: "Username",
                                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                                  fillColor: AppColors.inputFill,
                                  filled: true,
                                  prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted, size: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppColors.inputBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppColors.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppColors.primaryBlue),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return "Username is required";
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),

                              // Password Input Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                style: TextStyle(color: AppColors.textLight, fontSize: 14),
                                onChanged: (_) => _clearError(),
                                decoration: InputDecoration(
                                  hintText: "Password",
                                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                                  fillColor: AppColors.inputFill,
                                  filled: true,
                                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.textMuted, size: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppColors.inputBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppColors.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppColors.primaryBlue),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return "Password is required";
                                  return null;
                                },
                              ),
                              Row(
                                children: [
                                  Theme(
                                    data: Theme.of(context).copyWith(
                                      unselectedWidgetColor: AppColors.textMuted,
                                    ),
                                    child: Checkbox(
                                      value: _rememberAdmin,
                                      activeColor: AppColors.primaryBlue,
                                      checkColor: Colors.white,
                                      side: BorderSide(color: AppColors.textMuted, width: 1.5),
                                      onChanged: (val) {
                                        setState(() {
                                          _rememberAdmin = val ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  Text(
                                    "Remember admin credentials",
                                    style: TextStyle(color: AppColors.textLight, fontSize: 13),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),

                              // Error message panel
                              if (_errorMessage != null)
                                Padding(
                                  padding: EdgeInsets.only(bottom: 12.0),
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: AppColors.overlapRed, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),

                              SizedBox(height: 8),

                              // Submit Button
                              ElevatedButton(
                                onPressed: appState.isLoading ? null : () => _handleSubmit(appState),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  disabledBackgroundColor: Color(0xFF1E293B),
                                ),
                                child: appState.isLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Text(
                                        "Sign In",
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              SizedBox(height: 20),

              // Admin panel entry trigger / toggle back
              Center(
                child: TextButton.icon(
                  onPressed: appState.isLoading
                      ? null
                      : () {
                          setState(() {
                            _showAdminLogin = !_showAdminLogin;
                            _clearError();
                          });
                        },
                  icon: Icon(
                    _showAdminLogin ? Icons.login : Icons.admin_panel_settings,
                    color: AppColors.textMuted,
                    size: 16,
                  ),
                  label: Text(
                    _showAdminLogin ? "Back to Google Sign-In" : "Login as admin",
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
        ],
      ),
    );
  }
}
