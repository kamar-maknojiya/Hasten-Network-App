import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vision_broadband/networking/BaseClient.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/CustomAppbar.dart';
import 'package:vision_broadband/widgets/PrimaryButton.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  String? oldPasswordError;
  String? newPasswordError;
  String? confirmPasswordError;

  bool isLoading = false;
  bool oldObscure = true;
  bool newObscure = true;
  bool confirmObscure = true;
  bool oldError = false;
  bool newError = false;
  bool confirmError = false;

  void validateAndSave() {
    setState(() {
      oldError = oldPasswordController.text.trim().isEmpty;
      newError = newPasswordController.text.trim().isEmpty;
      confirmError = confirmPasswordController.text.trim().isEmpty;
    });

    if (!oldError && !newError && !confirmError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password Changed Successfully")),
      );
    }
  }

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
                CustomAppbar(title: 'Change Password'),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          /// LOCK ICON
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(color: isDark ? AppColors.darkCard2 : Colors.grey.shade100, shape: BoxShape.circle),
                            child: Icon(Icons.lock_outline, size: 45, color: AppColors.primary),
                          ),

                          const SizedBox(height: 30),

                          /// OLD PASSWORD
                          _label("Old Password", greyText),

                          const SizedBox(height: 2),

                          _passwordField(
                            controller: oldPasswordController,
                            hint: "Old Password",
                            obscure: oldObscure,
                            textClr: text,
                            errorText: oldPasswordError,
                            onToggle: () {
                              setState(() {
                                oldObscure = !oldObscure;
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          /// NEW PASSWORD
                          _label("New Password", greyText),

                          const SizedBox(height: 2),

                          _passwordField(
                            controller: newPasswordController,
                            hint: "New Password",
                            obscure: newObscure,
                            textClr: text,
                            errorText: newPasswordError,
                            onToggle: () {
                              setState(() {
                                newObscure = !newObscure;
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          /// CONFIRM PASSWORD
                          _label("Confirm Password", greyText),

                          const SizedBox(height: 2),

                          _passwordField(
                            controller: confirmPasswordController,
                            hint: "Confirm Password",
                            obscure: confirmObscure,
                            textClr: text,
                            errorText: confirmPasswordError,
                            onToggle: () {
                              setState(() {
                                confirmObscure = !confirmObscure;
                              });
                            },
                          ),

                          // _passwordField(
                          //   controller: confirmPasswordController,
                          //   hint: "Confirm Password",
                          //   obscure: confirmObscure,
                          //   error: confirmError,
                          //   textClr: text,
                          //   onToggle: () {
                          //     setState(() {
                          //       confirmObscure = !confirmObscure;
                          //     });
                          //   },
                          // ),
                          const SizedBox(height: 40),
                          PrimaryButton(
                            title: 'Update',
                            isLoading: isLoading,
                            icon: Icons.save_outlined,
                            onTap: changePassword,
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

  Future<void> changePassword() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      oldPasswordError = null;
      newPasswordError = null;
      confirmPasswordError = null;
    });
    if (oldPasswordController.text.trim().isEmpty &&
        newPasswordController.text.trim().isEmpty &&
        confirmPasswordController.text.trim().isEmpty) {
      setState(() {
        oldPasswordError = "Old Password required";
        newPasswordError = "New Password required";
        confirmPasswordError = "Confirm Password required";
      });
      return;
    }
    if (oldPasswordController.text.trim().isEmpty) {
      setState(() {
        oldPasswordError = "Old Password required";
      });
      return;
    }
    if (newPasswordController.text.trim().isEmpty) {
      setState(() {
        newPasswordError = "New Password required";
      });
      return;
    }
    if (confirmPasswordController.text.trim().isEmpty) {
      setState(() {
        confirmPasswordError = "Confirm Password required";
      });
      return;
    }
    if (newPasswordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      setState(() {
        confirmPasswordError = "Password does not match";
      });
      return;
    }
    setState(() {
      isLoading = true;
    });

    try {
      var reqArr = {
        'old_password': oldPasswordController.text.trim(),
        'new_password': newPasswordController.text.trim(),
        'confirm_password': confirmPasswordController.text.trim(),
      };
      print(reqArr);
      var response = await BaseClient().post(CHANGE_PASSWORD, reqArr, context);
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
        oldPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();
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
  // Future<void> changePassword() async {
  //   setState(() {
  //     isLoading = true;
  //   });
  //
  //   setState(() {
  //     oldPasswordError = null;
  //     newPasswordError = null;
  //     confirmPasswordError = null;
  //   });
  //
  //   if (oldPasswordController.text.trim().isEmpty &&
  //       newPasswordController.text.trim().isEmpty &&
  //       confirmPasswordController.text.trim().isEmpty) {
  //     setState(() {
  //       oldPasswordError = "Old Password required";
  //       newPasswordError = "New Password required";
  //       confirmPasswordError = "Confirm Password required";
  //     });
  //     isLoading = false;
  //     return;
  //   }
  //   if (oldPasswordController.text.trim().isEmpty) {
  //     setState(() {
  //       oldPasswordError = "Old Password required";
  //     });
  //     isLoading = false;
  //     return;
  //   }
  //
  //   if (newPasswordController.text.trim().isEmpty) {
  //     setState(() {
  //       newPasswordError = "New Password required";
  //     });
  //     isLoading = false;
  //     return;
  //   }
  //
  //   if (confirmPasswordController.text.trim().isEmpty) {
  //     setState(() {
  //       confirmPasswordError = "Confirm Password required";
  //     });
  //     isLoading = false;
  //     return;
  //   }
  //
  //   if (newPasswordController.text.trim() !=
  //       confirmPasswordController.text.trim()) {
  //     setState(() {
  //       confirmPasswordError = "Password does not match";
  //     });
  //     isLoading = false;
  //     return;
  //   }
  //
  //   var reqArr = {
  //     'old_password': oldPasswordController.text,
  //     'new_password': newPasswordController.text,
  //     'confirm_password': confirmPasswordController.text,
  //   };
  //   print(reqArr);
  //   var response = await BaseClient()
  //       .post(CHANGE_PASSWORD, reqArr, context)
  //       .catchError((err) {
  //         errToast("Error! Something went wrong");
  //         print(err);
  //       });
  //   print(response);
  //   if (response == null) {
  //     errToast("Error! Something went wrong");
  //     setState(() {
  //       isLoading = false;
  //     });
  //   } else {
  //     setState(() {
  //       isLoading = false;
  //     });
  //     if (response['status'] == true) {
  //       successToast(response['message']);
  //     } else {
  //       errToast(response['message']);
  //     }
  //   }
  // }

  Widget _label(String title, Color text) {
    return Align(
      alignment: Alignment.centerLeft,

      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: text.withOpacity(.6),
          fontSize: 12.sp,
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required Color textClr,
    required VoidCallback onToggle,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.poppins(
        color: textClr,
        fontSize: 12.sp,
        // fontWeight: FontWeight.w600,
      ),

      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
          color: textClr,
          fontSize: 12.sp,
          // fontWeight: FontWeight.w600,
        ),
        errorText: errorText,
        contentPadding: EdgeInsets.all(10),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(.30)),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      onChanged: (value) {
        if (value.isNotEmpty) {
          setState(() {
            if (controller == oldPasswordController) {
              oldPasswordError = null;
            } else if (controller == newPasswordController) {
              newPasswordError = null;
            } else if (controller == confirmPasswordController) {
              confirmPasswordError = null;
            }
          });
        }
      },
    );
  }
  // Widget _passwordField({
  //   required TextEditingController controller,
  //   required String hint,
  //   required bool obscure,
  //   required bool error,
  //   required Color textClr,
  //   required VoidCallback onToggle,
  // }) {
  //   return TextField(
  //     controller: controller,
  //     obscureText: obscure,
  //     style: GoogleFonts.poppins(
  //       color: textClr,
  //       fontSize: 12.sp,
  //       // fontWeight: FontWeight.w600,
  //     ),
  //     decoration: InputDecoration(
  //       hintText: hint,
  //       hintStyle: GoogleFonts.poppins(
  //         color: textClr.withOpacity(0.6),
  //         fontSize: 12.sp,
  //         // fontWeight: FontWeight.w600,
  //       ),
  //       suffixIcon: IconButton(
  //         onPressed: onToggle,
  //         icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
  //       ),
  //       filled: true,
  //       fillColor: Colors.grey.withOpacity(.08),
  //       contentPadding: EdgeInsets.all(10),
  //       border: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(12),
  //         borderSide: BorderSide.none,
  //       ),
  //       enabledBorder: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(12),
  //         borderSide: BorderSide(
  //           color: error ? Colors.red : Colors.grey.withOpacity(.30),
  //         ),
  //       ),
  //       focusedBorder: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(12),
  //         borderSide: BorderSide(color: error ? Colors.red : AppColors.primary),
  //       ),
  //     ),
  //   );
  // }

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
