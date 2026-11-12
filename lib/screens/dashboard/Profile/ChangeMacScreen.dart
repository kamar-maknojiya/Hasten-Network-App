import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vision_broadband/networking/BaseClient.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/CustomAppbar.dart';
import 'package:vision_broadband/widgets/PrimaryButton.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';

class ChangeMacScreen extends StatefulWidget {
  const ChangeMacScreen({super.key});

  @override
  State<ChangeMacScreen> createState() => _ChangeMacScreenState();
}

class _ChangeMacScreenState extends State<ChangeMacScreen> {
  final oldMacController = TextEditingController();
  final newMacController = TextEditingController();
  String? oldMacError;
  String? newMacError;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;
    final greyText = isDark ? Colors.white70 : Colors.black54;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                /// APPBAR
                CustomAppbar(title: 'Change MAC'),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          /// ICON
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? AppColors.darkCard2
                                  : Colors.grey.shade100,
                            ),
                            child: Icon(
                              Icons.router_outlined,
                              size: 45,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            "Update your device MAC address. Make sure to enter the correct format (XX:XX:XX:XX:XX:XX)",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: greyText,
                              fontSize: 12.sp,
                            ),
                          ),
                          const SizedBox(height: 35),

                          /// OLD MAC
                          _label("* Old MAC Address", text),
                          const SizedBox(height: 8),
                          _macField(
                            controller: oldMacController,
                            hint: "XX:XX:XX:XX:XX:XX",
                            textClr: text,
                            errorText: oldMacError,
                          ),

                          const SizedBox(height: 16),

                          /// NEW MAC
                          _label("* New MAC Address", text),

                          const SizedBox(height: 8),

                          _macField(
                            controller: newMacController,
                            hint: "XX:XX:XX:XX:XX:XX",
                            errorText: newMacError,
                            textClr: text,
                          ),

                          const SizedBox(height: 40),

                          /// BUTTON
                          PrimaryButton(
                            title: 'Update',
                            isLoading: isLoading,
                            icon: Icons.save_outlined,
                            onTap: changeMacAddress,
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
      ),
    );
  }

  Future<void> changeMacAddress() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      oldMacError = null;
      newMacError = null;
    });
    if (oldMacController.text.trim().isEmpty &&
        newMacController.text.trim().isEmpty) {
      setState(() {
        oldMacError = "MAC Address required";
        newMacError = "MAC Address required";
      });
      return;
    }
    if (oldMacController.text.trim().isEmpty) {
      setState(() {
        oldMacError = "MAC Address required";
      });
      return;
    }
    if (newMacController.text.trim().isEmpty) {
      setState(() {
        newMacError = "MAC Address required";
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      var reqArr = {
        'old_mac': oldMacController.text.trim(),
        'new_mac': newMacController.text.trim(),
      };
      print(reqArr);
      var response = await BaseClient().post(
        CHANGE_MAC_ADDRESS,
        reqArr,
        context,
      );
      print(response);
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      if (response == null) {
        errToast("Error! Something went wrong");
        return;
      }
      if (response['status'] == true) {
        successToast(response['message']);
        oldMacController.clear();
        newMacController.clear();
        Navigator.pop(context);
      } else {
        errToast(response['message'] ?? "Something went wrong");
      }
    } catch (e) {
      print(e);
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      errToast("Error! Something went wrong");
    }
  }

  Widget _label(String title, Color text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: text.withOpacity(.75),
          fontSize: 12.sp,
        ),
      ),
    );
  }

  Widget _macField({
    required TextEditingController controller,
    required String hint,
    String? errorText,
    required Color textClr,
  }) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.characters,
      style: GoogleFonts.poppins(color: textClr, fontSize: 13.sp),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        hintStyle: GoogleFonts.poppins(color: textClr, fontSize: 13.sp),
        contentPadding: EdgeInsets.all(10),
        fillColor: Colors.grey.withOpacity(.08),
        errorText: errorText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.withOpacity(.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.red),
        ),
      ),
      onChanged: (value) {
        if (value.isNotEmpty) {
          setState(() {
            if (controller == oldMacController) {
              oldMacError = null;
            } else if (controller == newMacController) {
              newMacError = null;
            }
          });
        }
      },
    );
  }

  @override
  void dispose() {
    oldMacController.dispose();
    newMacController.dispose();
    super.dispose();
  }
}
