import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/colors.dart';
import '../models/app_state.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  bool _isLoadingPlans = true;
  bool _isCreatingLink = false;
  List<dynamic> _plans = [];
  String? _errorMessage;
  Timer? _paymentPollTimer;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      final plansData = await appState.fetchSubscriptionPlans();
      setState(() {
        _plans = plansData.where((plan) {
          final name = (plan['planName'] ?? '').toString().toLowerCase();
          return name == 'free' || name == 'plus';
        }).toList();
        _isLoadingPlans = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load pricing plans. Please try again.";
        _isLoadingPlans = false;
      });
    }
  }

  Future<void> _handleUpgrade(String planId) async {
    setState(() {
      _isCreatingLink = true;
      _errorMessage = null;
    });

    final appState = Provider.of<AppState>(context, listen: false);
    try {
      final result = await appState.createPaymentLink(planId);
      final String? checkoutUrl = result['checkoutUrl']?.toString();
      final String? qrCode = result['qrCode']?.toString();

      if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
        if (qrCode != null && qrCode.isNotEmpty) {
          if (mounted) {
            _showQrPaymentDialog(qrCode, checkoutUrl);
          }
        } else {
          final Uri url = Uri.parse(checkoutUrl);
          try {
            await launchUrl(url, mode: LaunchMode.externalApplication);
            if (mounted) {
              _showPostPaymentDialog();
            }
          } catch (e) {
            throw Exception("Could not open checkout page: $e");
          }
        }
      } else {
        throw Exception("Failed to generate payment checkout link.");
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception:", "").trim();
      });
    } finally {
      setState(() {
        _isCreatingLink = false;
      });
    }
  }

  void _showQrPaymentDialog(String qrCode, String checkoutUrl) {
    final appState = Provider.of<AppState>(context, listen: false);
    final userId = appState.loggedInUserId ?? '';

    _paymentPollTimer?.cancel();
    _paymentPollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final result = await appState.checkPaymentStatus(userId);
        final String status = result['status']?.toString() ?? 'pending';

        if (status == 'success') {
          timer.cancel();
          _paymentPollTimer = null;
          
          if (mounted) {
            Navigator.pop(context); // Close QR modal
            await appState.loadAllData(); // Refresh profile
            _showSuccessUpgradeDialog(); // Show success pop-up
          }
        } else if (status == 'failed') {
          timer.cancel();
          _paymentPollTimer = null;
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Transaction cancelled or failed.")),
            );
          }
        }
      } catch (e) {
        debugPrint("Error polling payment status: $e");
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "QR Payment",
                  style: TextStyle(color: AppColors.textLight, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => _confirmCancelPayment(ctx, appState, userId),
                ),
              ],
            ),
            const Divider(color: Color(0xFF1E293B)),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.network(
                  "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${Uri.encodeComponent(qrCode)}",
                  height: 200,
                  width: 200,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      height: 200,
                      width: 200,
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primaryBlue),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(
                      height: 200,
                      width: 200,
                      child: Center(
                        child: Text("Cannot load QR code", style: TextStyle(color: Colors.redAccent)),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Scan the QR code with your banking app to pay 50,000₫.",
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final Uri url = Uri.parse(checkoutUrl);
                try {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } catch (e) {
                  debugPrint("Could not open checkout page: $e");
                }
              },
              icon: const Icon(Icons.open_in_browser, color: Colors.white, size: 18),
              label: const Text(
                "Open Payment Website",
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isCreatingLink ? null : () => _confirmCancelPayment(ctx, appState, userId),
              icon: const Icon(Icons.cancel, color: Colors.white, size: 18),
              label: const Text(
                "Cancel Payment",
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.overlapRed,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      _paymentPollTimer?.cancel();
      _paymentPollTimer = null;
    });
  }

  void _confirmCancelPayment(BuildContext dialogContext, AppState appState, String userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Confirm Cancellation", style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text("Are you sure you want to cancel this payment?", style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Go back", style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.overlapRed),
            onPressed: () async {
              Navigator.pop(ctx); // Close confirmation dialog
              Navigator.pop(dialogContext); // Close QR modal dialog
              
              setState(() {
                _isCreatingLink = true;
              });
              
              try {
                await appState.cancelPayment(userId);
                await appState.loadAllData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Payment cancelled successfully.")),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Cannot cancel order: $e")),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isCreatingLink = false;
                  });
                }
              }
            },
            child: const Text("Confirm cancel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSuccessUpgradeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              "Upgrade Successful!",
              style: TextStyle(color: AppColors.textLight, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Your account has been successfully upgraded to Plus plan. Enjoy unlimited features!",
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Return to Profile Screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Explore Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPostPaymentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.payment, color: AppColors.primaryBlue, size: 24),
            const SizedBox(width: 8),
            Text("Payment Started", style: TextStyle(color: AppColors.textLight, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "Once you have completed the payment in the browser, return here and refresh your Profile page to activate your Plus status.",
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Return to profile
              Provider.of<AppState>(context, listen: false).loadAllData();
            },
            child: Text("Done", style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.userProfile;
    final currentSub = user?['subscriptionType']?.toString().toUpperCase() ?? "FREE";

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Upgrade Membership",
          style: TextStyle(color: AppColors.textLight, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoadingPlans 
          ? Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title / Intro
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.flash_on, color: AppColors.primaryBlue, size: 36),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Unlock Premium Features",
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Choose a plan that fits your lifestyle",
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.redAccent, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Plans cards list
                  ..._plans.map((plan) {
                    final String planName = plan['planName'] ?? 'Plan';
                    final bool isPaid = planName.toLowerCase() == 'plus';
                    final planId = plan['planId']?.toString() ?? '';
                    final price = (plan['price'] ?? 0).toDouble();
                    final duration = plan['durationDays'] ?? 30;

                    // Parse features
                    List<String> featuresList = [];
                    final rawFeatures = plan['features'];
                    if (rawFeatures is String) {
                      featuresList = rawFeatures.split(',').map((e) => e.trim()).toList();
                    }

                    // Format price
                    final priceLabel = price == 0 
                        ? "Free" 
                        : "${_formatPrice(price)} / $duration Days";

                    final bool isCurrentPlan = currentSub == planName.toUpperCase();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        gradient: isPaid
                            ? LinearGradient(
                                colors: [
                                  AppColors.primaryBlue.withOpacity(0.2),
                                  Colors.purple.withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isPaid ? null : AppColors.cardDark,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isPaid 
                              ? AppColors.primaryBlue.withOpacity(0.4) 
                              : const Color(0xFF1E293B),
                          width: isPaid ? 2 : 1,
                        ),
                        boxShadow: isPaid 
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryBlue.withOpacity(0.15),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                )
                              ]
                            : null,
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                planName.toUpperCase(),
                                style: TextStyle(
                                  color: isPaid ? AppColors.primaryBlue : AppColors.textLight,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              if (isCurrentPlan)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.greenAccent, width: 0.5),
                                  ),
                                  child: const Text(
                                    "Active",
                                    style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            plan['description'] ?? '',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            priceLabel,
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Color(0xFF1E293B)),
                          const SizedBox(height: 12),

                          // Features list
                          ...featuresList.map((feat) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      color: isPaid ? AppColors.primaryBlue : Colors.greenAccent,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        feat,
                                        style: TextStyle(
                                          color: AppColors.textLight,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),

                          const SizedBox(height: 24),
                          // Upgrade Button
                          if (isPaid && !isCurrentPlan)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isCreatingLink ? null : () => _handleUpgrade(planId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: AppColors.primaryBlue.withOpacity(0.5),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: _isCreatingLink
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Text(
                                        "Upgrade Now",
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      int p = price.toInt();
      String s = p.toString();
      // add comma formatting
      if (s.length > 3) {
        return "${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}₫";
      }
      return "$s₫";
    }
    return "${price.toStringAsFixed(0)}₫";
  }
}
