import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:vision_broadband/networking/BaseClient.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/CustomAppbar.dart';
import 'package:vision_broadband/widgets/PrimaryButton.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final companyController = TextEditingController();
  final addressController = TextEditingController();
  final countryController = TextEditingController();
  final stateController = TextEditingController();
  final cityController = TextEditingController();
  final zipController = TextEditingController();
  final phoneController = TextEditingController();
  final mobileController = TextEditingController();
  final taxController = TextEditingController();

  Map<String, dynamic> userData = {};
  bool isLoading = false;
  bool hasLoading = false;
  String isUpdate = '0';

  @override
  void initState() {
    super.initState();
    getProfile();
  }

  Future<void> getPermission() async {

    var response = await BaseClient().get(GET_PERMISSIONS, context).catchError((
        err,
        ) {
      return null;
    });
    if (!mounted) return;
    if (response != null && response['status'] == true) {
      final permission = response['data'];
      isUpdate = permission['update_profile'] ?? "0";
      print('isUpdate :: $isUpdate');
    }
  }

  void getProfile() async {
    setState(() {
      isLoading = true;
    });
    var response = await BaseClient()
        .get(GET_PROFILE_DETAILS, context)
        .catchError((err) {
          errToast("Error! Something went wrong");
          print(err);
        });
    if (response == null) {
      errToast("Error! Something went wrong");
    } else {
      if (response['status'] == true) {
        setState(() {
          userData = response['data'];
          fullNameController.text = userData['fullname'] ?? "";
          emailController.text = userData['email'] ?? "";
          companyController.text = userData['company_name'] ?? "";
          addressController.text = userData['address'] ?? "";
          countryController.text = userData['country'] ?? "";
          stateController.text = userData['state'] ?? "";
          cityController.text = userData['city'] ?? "";
          zipController.text = userData['zip'] ?? "";
          phoneController.text = userData['phone_no'] ?? '';
          mobileController.text = userData['mobile_no'] ?? '';
          taxController.text = userData['tax_no'] ?? '';
        });
        setState(() {
          isLoading = false;
        });
      } else {
        errToast(response['message']);
        setState(() {
          isLoading = false;
        });
      }
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
        body: isLoading
            ? Center(
                child: Lottie.asset(
                  'assets/animation/loading.json',
                  height: 60,
                  repeat: true,
                  delegates: LottieDelegates(
                    values: [
                      ValueDelegate.color(const [
                        '**',
                      ], value: AppColors.primary),
                    ],
                  ),
                ),
              )
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      /// APPBAR
                      CustomAppbar(title: 'Edit Profile'),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: card,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label("* Full Name", text),
                                    const SizedBox(height: 2),
                                    _buildField(
                                      fullNameController,
                                      "Full Name",
                                      text,
                                      errorText: fullNameError,
                                    ),
                                    const SizedBox(height: 12),

                                    _label("* Email", text),

                                    const SizedBox(height: 2),

                                    _buildField(
                                      emailController,
                                      "Email",
                                      text,
                                      errorText: emailError,
                                      keyboardType: TextInputType.emailAddress,
                                    ),

                                    const SizedBox(height: 12),

                                    _label("* Company Name", text),

                                    const SizedBox(height: 2),

                                    _buildField(
                                      companyController,
                                      "Company Name",
                                      text,
                                      errorText: companyError,
                                    ),

                                    const SizedBox(height: 12),
                                    _label("* Address", text),

                                    const SizedBox(height: 2),

                                    TextField(
                                      controller: addressController,
                                      maxLines: 4,
                                      style: GoogleFonts.poppins(
                                        color: text,
                                        fontSize: 13.sp,
                                        // fontWeight: FontWeight.w600,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: "Address",
                                        filled: true,
                                        fillColor: Colors.grey.withOpacity(.08),
                                        hintStyle: GoogleFonts.poppins(
                                          color: text,
                                          fontSize: 13.sp,
                                          // fontWeight: FontWeight.w600,
                                        ),
                                        errorText: addressError,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: AppColors.red),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.withOpacity(.3),
                                          ),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        if (value.isNotEmpty) {
                                          setState(() {
                                            addressError = null;
                                          });
                                        }
                                      },
                                    ),

                                    const SizedBox(height: 12),

                                    /// COUNTRY + STATE
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,

                                            children: [
                                              _label("* Country", text),

                                              const SizedBox(height: 2),

                                              _buildField(
                                                countryController,
                                                "Country",
                                                text,
                                                errorText: countryError,
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(width: 14),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,

                                            children: [
                                              _label("* State", text),

                                              const SizedBox(height: 2),

                                              _buildField(
                                                stateController,
                                                "State",
                                                text,
                                                errorText: stateError,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    /// CITY + ZIP
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,

                                            children: [
                                              _label("* City", text),

                                              const SizedBox(height: 2),

                                              _buildField(
                                                cityController,
                                                "City",
                                                text,
                                                errorText: cityError,
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(width: 14),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,

                                            children: [
                                              _label("* Zip", text),

                                              const SizedBox(height: 2),

                                              _buildField(
                                                zipController,
                                                "Zip",
                                                text,
                                                errorText: zipError,
                                                keyboardType:
                                                    TextInputType.number,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    /// PHONE NUMBER
                                    _label("* Phone Number", text),

                                    const SizedBox(height: 2),

                                    _buildField(
                                      phoneController,
                                      "Phone Number",
                                      errorText: phoneError,
                                      keyboardType: TextInputType.phone,
                                      text,
                                    ),

                                    const SizedBox(height: 12),

                                    /// MOBILE NUMBER
                                    _label("* Mobile Number", text),

                                    const SizedBox(height: 2),

                                    _buildField(
                                      mobileController,
                                      "Mobile Number",
                                      text,
                                      errorText: mobileError,
                                      keyboardType: TextInputType.phone,
                                    ),

                                    const SizedBox(height: 12),

                                    /// TAX NUMBER
                                    _label("* Tax Number", text),

                                    const SizedBox(height: 2),

                                    _buildField(
                                      taxController,
                                      "Tax Number",
                                      text,
                                      errorText: taxError,
                                    ),

                                    const SizedBox(height: 20),

                                    PrimaryButton(
                                      title: 'Update',
                                      isLoading: hasLoading,
                                      icon: Icons.save_outlined,
                                      onTap: updateProfile,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
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

  String? fullNameError;
  String? emailError;
  String? companyError;
  String? addressError;
  String? countryError;
  String? stateError;
  String? cityError;
  String? zipError;
  String? phoneError;
  String? mobileError;
  String? taxError;
  bool validator() {
    bool isValid = true;
    setState(() {
      fullNameError = null;
      emailError = null;
      companyError = null;
      addressError = null;
      countryError = null;
      stateError = null;
      cityError = null;
      zipError = null;
      phoneError = null;
      mobileError = null;
      taxError = null;
      if (fullNameController.text.trim().isEmpty) {
        fullNameError = "Full Name is required";
        isValid = false;
      }
      if (emailController.text.trim().isEmpty) {
        emailError = "Email is required";
        isValid = false;
      }
      if (companyController.text.trim().isEmpty) {
        companyError = "Company Name is required";
        isValid = false;
      }
      if (addressController.text.trim().isEmpty) {
        addressError = "Address is required";
        isValid = false;
      }
      if (countryController.text.trim().isEmpty) {
        countryError = "Country is required";
        isValid = false;
      }
      if (stateController.text.trim().isEmpty) {
        stateError = "State is required";
        isValid = false;
      }
      if (cityController.text.trim().isEmpty) {
        cityError = "City is required";
        isValid = false;
      }
      if (zipController.text.trim().isEmpty) {
        zipError = "Zip is required";
        isValid = false;
      }
      if (phoneController.text.trim().isEmpty) {
        phoneError = "Phone Number is required";
        isValid = false;
      }
      if (mobileController.text.trim().isEmpty) {
        mobileError = "Mobile Number is required";
        isValid = false;
      }
      if (taxController.text.trim().isEmpty) {
        taxError = "Tax Number is required";
        isValid = false;
      }
    });

    return isValid;
  }

  Future<void> updateProfile() async {
    FocusScope.of(context).unfocus();
    if (!validator()) return;
    setState(() {
      hasLoading = true;
    });
    try {
      var payload = {
        "fullname": fullNameController.text.trim(),
        "company_name": companyController.text.trim(),
        "email": emailController.text.trim(),
        "address": addressController.text.trim(),
        "country": countryController.text.trim(),
        "state": stateController.text.trim(),
        "city": cityController.text.trim(),
        "zip": zipController.text.trim(),
        "phone_no": phoneController.text.trim(),
        "mobile_no": mobileController.text.trim(),
        "tax_no": taxController.text.trim(),
      };
      var response = await BaseClient().post(UPDATE_PROFILE_DETAILS, payload, context);
      if (!mounted) return;
      setState(() {
        hasLoading = false;
      });
      if (response == null) {
        errToast("Error! Something went wrong");
        return;
      }
      if (response['status'] == true) {
        successToast(response['message']);
        Navigator.pop(context);
      } else {
        errToast(response['message'] ?? "Something went wrong");
      }
    } catch (e) {
      print(e);
      if (!mounted) return;
      setState(() {
        hasLoading = false;
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

  Widget _buildField(
    TextEditingController controller,
    String hint,
    Color textClr, {
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(
        color: textClr,
        fontSize: 13.sp,
        // fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        hintStyle: GoogleFonts.poppins(
          color: textClr,
          fontSize: 13.sp,
          // fontWeight: FontWeight.w600,
        ),
        fillColor: Colors.grey.withOpacity(.08),
        contentPadding: EdgeInsets.all(10),
        errorText: errorText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(.3)),
        ),
      ),

      onChanged: (value) {
        setState(() {
          if (controller == fullNameController) {
            fullNameError = null;
          } else if (controller == emailController) {
            emailError = null;
          } else if (controller == companyController) {
            companyError = null;
          } else if (controller == addressController) {
            addressError = null;
          } else if (controller == countryController) {
            countryError = null;
          } else if (controller == stateController) {
            stateError = null;
          } else if (controller == cityController) {
            cityError = null;
          } else if (controller == zipController) {
            zipError = null;
          } else if (controller == phoneController) {
            phoneError = null;
          } else if (controller == mobileController) {
            mobileError = null;
          } else if (controller == taxController) {
            taxError = null;
          }
        });
      },
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    companyController.dispose();
    addressController.dispose();
    countryController.dispose();
    stateController.dispose();
    cityController.dispose();
    zipController.dispose();
    phoneController.dispose();
    mobileController.dispose();
    taxController.dispose();
    super.dispose();
  }
}
