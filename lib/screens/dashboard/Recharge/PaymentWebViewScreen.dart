import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/screens/dashboard/Recharge/PaymentSuccessScreen.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/CustomAppbar.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final paymentUrl;
  final orderId;

  const PaymentWebViewScreen({super.key, required this.paymentUrl, required this.orderId});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> with WidgetsBindingObserver {
  late final WebViewController controller;
  bool isLoading = true;
  bool _statusChecking = false;
  bool paymentAppOpened = false;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    print("====================================");
    print("APP LIFECYCLE => $state");
    print("paymentAppOpened => $paymentAppOpened");
    print("_statusChecking => $_statusChecking");
    print("====================================");

    // if (state == AppLifecycleState.resumed &&
    //     paymentAppOpened &&
    //     !_statusChecking) {
    //   print("APP RESUMED FROM PAYMENT APP");
    //
    //   paymentAppOpened = false;
    //   _statusChecking = true;
    //
    //   await checkPaymentStatus(widget.orderId);
    //
    //   _statusChecking = false;
    // }
    if (state == AppLifecycleState.resumed && !_statusChecking) {
      _statusChecking = true;

      await Future.delayed(const Duration(seconds: 1));

      await checkPaymentStatus(widget.orderId);

      _statusChecking = false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) async {
            print("========== NAVIGATION ==========");
            print("URL => ${request.url}");
            print("===============");
            print(request.url);
            print(Uri.parse(request.url).scheme);
            print(Uri.parse(request.url).host);
            print(Uri.parse(request.url).path);
            print(Uri.parse(request.url).query);
            print("===============");
            final uri = Uri.parse(request.url);
            print("SCHEME => ${uri.scheme}");
            print("HOST => ${uri.host}");
            print("PATH => ${uri.path}");
            print("QUERY => ${uri.queryParameters}");
            if (uri.scheme != "http" && uri.scheme != "https") {
              print("OPENING PAYMENT APP");
              paymentAppOpened = true;
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }
            final status = uri.queryParameters["status"]?.toLowerCase();
            print("STATUS PARAM => $status");
            if (status == "success" || status == "paid") {
              print("SUCCESS CALLBACK");
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PaymentSuccessScreen(orderId: widget.orderId)));
              return NavigationDecision.prevent;
            }
            if (status == "failed") {
              print("FAILED CALLBACK");
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PaymentFailedScreen(orderId: widget.orderId)));
              return NavigationDecision.prevent;
            }
            print("ALLOW WEBVIEW");
            return NavigationDecision.navigate;
          },
          onPageFinished: (url) async {
            print("=========== PAGE FINISHED ===========");
            print(url);
            if (url.contains("/pg-response/")) {
              print("PG RESPONSE PAGE DETECTED");
              if (!_statusChecking) {
                _statusChecking = true;
                setState(() {
                  isLoading = true;
                });
                await checkPaymentStatus(widget.orderId);
              }
              return;
            }
            if (mounted && !_statusChecking) {
              setState(() {
                isLoading = false;
              });
            }
          },
          onWebResourceError: (error) {
            print("WEBVIEW ERROR => ${error.description}");
            print("WEBVIEW ERROR");
            print("CODE => ${error.errorCode}");
            print("TYPE => ${error.errorType}");
            print("DESC => ${error.description}");
            if (mounted) {
              setState(() {
                isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> checkPaymentStatus(String orderId) async {
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      const int maxAttempts = 3;
      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        print("====================================");
        print("CHECK PAYMENT ATTEMPT => $attempt");
        print("ORDER ID => $orderId");
        final response = await http.get(
          Uri.parse("$GET_PAYMENT_STATUS/$orderId"),
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
        );
        print("STATUS CODE => ${response.statusCode}");
        print("BODY => ${response.body}");
        if (response.statusCode != 200) {
          print("API ERROR");
          break;
        }
        final body = jsonDecode(response.body);
        final status = body["status"] ?? false;
        final message = body["message"] ?? "";
        final paymentStatus = (body["data"] ?? "").toString();
        print("STATUS => $status");
        print("MESSAGE => $message");
        print("PAYMENT STATUS => $paymentStatus");
        switch (paymentStatus) {
          case "Paid":
            print("PAYMENT SUCCESS");
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => PaymentSuccessScreen(orderId: orderId)), (route) => false);
            return;
          case "Failed":
          case "Cancelled":
          case "Insufficient Site Balance":
          case "Failed to process IPTV recharge":
          case "Failed to process OTT recharge":
          case "Advance Recharge Exist":
          case "Unauthenticated":
            print("PAYMENT FAILED");
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => PaymentFailedScreen(orderId: orderId)), (route) => false);
            return;
          case "Processing":
            print("PAYMENT IS PROCESSING...");
            if (attempt < maxAttempts) {
              await Future.delayed(const Duration(seconds: 5));
              continue;
            }
            print("PAYMENT TIMEOUT");
            if (mounted) {
              errToast("Payment verification timed out");
              Navigator.pop(context);
              // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const PaymentFailedScreen(),), (route) => false);
            }
            return;
          default:
            print("UNKNOWN STATUS => $paymentStatus");
            if (mounted) {
              errToast(message.isNotEmpty ? message : "Unknown payment status");
            }
            return;
        }
      }
      if (mounted) {
        errToast("Unable to verify payment");
      }
    } catch (e, s) {
      print("====================================");
      print("PAYMENT STATUS ERROR");
      print(e);
      print(s);
      print("====================================");
      if (mounted) {
        errToast("Unable to verify payment");
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
  // Future<void> checkPaymentStatus2(String orderId) async {
  //   try {
  //     if (mounted) {
  //       setState(() {
  //         isLoading = true;
  //       });
  //     }
  //     final prefs = await SharedPreferences.getInstance();
  //     final token = prefs.getString('token');
  //     for (int i = 0; i < 10; i++) {
  //       print("CHECK PAYMENT ATTEMPT => ${i + 1}");
  //       final response = await http.get(
  //         Uri.parse("$GET_PAYMENT_STATUS/$orderId"),
  //         headers: {
  //           "Authorization": "Bearer $token",
  //           // "Accept": "text/event-stream",
  //         },
  //       );
  //       print("STATUS CODE => ${response.statusCode}");
  //       print("BODY => ${response.body}");
  //       if (response.statusCode != 200) {
  //         await Future.delayed(const Duration(seconds: 2));
  //         continue;
  //       }
  //       final dataLine = response.body.split('\n').firstWhere((line) => line.startsWith('data:'), orElse: () => '');
  //       if (dataLine.isEmpty) {
  //         print("NO DATA LINE FOUND");
  //         await Future.delayed(const Duration(seconds: 2));
  //         continue;
  //       }
  //       final jsonString = dataLine.replaceFirst('data:', '').trim();
  //       print("JSON STRING => $jsonString");
  //       final data = jsonDecode(jsonString);
  //       print("PARSED DATA => $data");
  //       final statusCode = data["status_code"]?.toString().toLowerCase() ?? "";
  //       print("PAYMENT STATUS => $statusCode");
  //       if (statusCode == "paid") {
  //         if (!mounted) return;
  //         Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()), (route) => false);
  //         return;
  //       }
  //       if (statusCode == "failed" || statusCode == "cancelled" || statusCode == "timeout") {
  //         if (!mounted) return;
  //         Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const PaymentFailedScreen()), (route) => false);
  //         return;
  //       }
  //       await Future.delayed(const Duration(seconds: 2));
  //     }
  //     errToast("Payment status timeout");
  //   } catch (e) {
  //     print("PAYMENT STATUS ERROR => $e");
  //     errToast("Unable to verify payment");
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         isLoading = false;
  //       });
  //     }
  //   }
  // }
  // Future<void> checkPaymentStatus1(String orderId) async {
  //   print("######################################");
  //   print("CHECK PAYMENT STATUS");
  //   print("ORDER ID => $orderId");
  //   print("######################################");
  //   try {
  //     setState(() {
  //       isLoading = true;
  //     });
  //     final prefs = await SharedPreferences.getInstance();
  //     final token = prefs.getString("token");
  //     for (int i = 1; i <= 10; i++) {
  //       print("------------ ATTEMPT $i ------------");
  //       final response = await http.get(
  //         Uri.parse("$GET_PAYMENT_STATUS/$orderId"),
  //         headers: {
  //           "Authorization": "Bearer $token",
  //           "Accept": "text/event-stream",
  //         },
  //       );
  //       print("STATUS CODE => ${response.statusCode}");
  //       print("RAW RESPONSE");
  //       print('RAW RESPONSE :: ${response.body}');
  //       if (response.statusCode != 200) {
  //         print("NOT 200");
  //         await Future.delayed(const Duration(seconds: 2));
  //         continue;
  //       }
  //       final dataLine = response.body.split("\n").firstWhere((e) => e.startsWith("data:"), orElse: () => "");
  //       print("DATA LINE");
  //       print(dataLine);
  //       if (dataLine.isEmpty) {
  //         print("NO DATA");
  //         await Future.delayed(const Duration(seconds: 2));
  //         continue;
  //       }
  //       final jsonString = dataLine.replaceFirst("data:", "").trim();
  //       print("JSON");
  //       print(jsonString);
  //       final data = jsonDecode(jsonString);
  //       print("PARSED");
  //       print(data);
  //       final statusCode = (data["status_code"] ?? "").toString().toLowerCase();
  //       final message = (data["message"] ?? "").toString();
  //       print("STATUS => $statusCode");
  //       print("MESSAGE => $message");
  //       if (statusCode == "paid") {
  //         print("GO SUCCESS");
  //         Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()), (_) => false);
  //         return;
  //       }
  //       if (statusCode == "failed" || statusCode == "cancelled" || statusCode == "timeout") {
  //         print("GO FAILED");
  //         Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const PaymentFailedScreen()), (_) => false);
  //         return;
  //       }
  //       print("STILL PROCESSING");
  //       await Future.delayed(const Duration(seconds: 2));
  //     }
  //     print("TIMEOUT");
  //     errToast("Payment timeout");
  //   } catch (e, s) {
  //     print("EXCEPTION");
  //     print(e);
  //     print(s);
  //     errToast("Unable to verify payment");
  //   } finally {
  //     _statusChecking = false;
  //     if (mounted) {
  //       setState(() {
  //         isLoading = false;
  //       });
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: CustomAppbar(title: "Payment Summary")),
            Expanded(
              child: Stack(
                children: [
                  if (!_statusChecking) WebViewWidget(controller: controller),
                  if (isLoading || _statusChecking)
                    Center(
                      child: Lottie.asset(
                        'assets/animation/loading.json',
                        height: 50,
                        repeat: true,
                        delegates: LottieDelegates(
                          values: [ValueDelegate.color(const ['**'], value: AppColors.primary)],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}