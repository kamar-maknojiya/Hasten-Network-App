import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vision_broadband/networking/BaseClient.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/screens/dashboard/Ticket/SupportTicketScreen.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/CustomAppbar.dart';
import 'package:vision_broadband/widgets/Network/AppScaffold.dart';
import 'package:vision_broadband/widgets/TopAlertToast.dart';
import 'package:vision_broadband/widgets/PrimaryButton.dart';
import 'package:file_picker/file_picker.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';

class AddTicketScreen extends StatefulWidget {
  const AddTicketScreen({super.key});

  @override
  State<AddTicketScreen> createState() => _AddTicketScreenState();
}

class _AddTicketScreenState extends State<AddTicketScreen> {
  final subjectController = TextEditingController();
  final messageController = TextEditingController();
  final tagController = TextEditingController();
  String? selectedPriority;
  String? selectedGroup;
  final priorities = ["Low", "Medium", "High", "Urgent"];
  final groups = ["Technical", "Sales"];
  bool isLoading = false;
  String? selectedFileName;
  File? selectedFile;
  String? subjectError;
  String? messageError;
  String? priorityError;
  String? groupError;

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        selectedFileName = result.files.single.name;
        selectedFile = File(result.files.single.path!);
      });

      print("Selected File: ${selectedFile?.path}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;
    final greyText = isDark ? Colors.grey : Colors.black;
    final subText = isDark ? Colors.white70 : Colors.black54;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: AppScaffold(
        child: Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0.w),
              child: Column(
                children: [
                  CustomAppbar(title: 'Add Ticket'),
                  SizedBox(height: 10.h),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16.r),
                            decoration: BoxDecoration(
                              color: card,
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: isDark
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                customTextField(
                                  titleText: '* Subject',
                                  controller: subjectController,
                                  hint: "Enter subject",
                                  errorText: subjectError,
                                  text: text,
                                ),
                                SizedBox(height: 12.h),
                                customTextField(
                                  titleText: "* Message",
                                  controller: messageController,
                                  hint: "Describe your issue in detail...",
                                  errorText: messageError,
                                  text: text,
                                ),
                                SizedBox(height: 12.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          customDropdown(
                                            value: selectedPriority,
                                            titleText: "* Priority",
                                            hint: "Select Priority",
                                            items: priorities,
                                            fieldColor: bg,
                                            text: text,
                                            errorText: priorityError,
                                            onChanged: (v) {
                                              setState(() {
                                                selectedPriority = v;
                                                priorityError = null;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          customDropdown(
                                            value: selectedGroup,
                                            titleText: "* Group",
                                            hint: "Select Group",
                                            items: groups,
                                            fieldColor: bg,
                                            text: text,
                                            errorText: groupError,
                                            onChanged: (v) {
                                              setState(() {
                                                selectedGroup = v;
                                                groupError = null;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                // SizedBox(height: 12.h),
                                // customTextField(
                                //   titleText: "Tag",
                                //   controller: tagController,
                                //   hint: "Optional tag",
                                //   text: text,
                                // ),
                                SizedBox(height: 12.h),
                                Text(
                                  'Attachment',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                    color: text.withOpacity(.60),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: pickFile,
                                  child: Container(
                                    height: 120.h,
                                    width: double.infinity,
                                    padding: EdgeInsets.all(16.r),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(.08),
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(.3),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.upload_file_rounded,
                                          size: 35,
                                          color: subText,
                                        ),
                                        SizedBox(height: 10.h),
                                        Text(
                                          selectedFileName ??
                                              "Tap to upload file",
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w600,
                                            color: text.withOpacity(.9),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 25),
                                PrimaryButton(
                                  title: 'Submit Ticket',
                                  isLoading: isLoading,
                                  onTap: () {
                                    createTicket();
                                  },
                                ),
                                // PrimaryButton(
                                //   title: 'Submit Ticket',
                                //   onTap: () {
                                //     TopAlert.show(
                                //       context,
                                //       title: "Success",
                                //       message: "Ticket resolved successfully",
                                //       type: AlertType.success,
                                //     );
                                //   },
                                // ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool validator() {
    bool isValid = true;
    setState(() {
      subjectError = null;
      messageError = null;
      priorityError = null;
      groupError = null;

      if (subjectController.text.trim().isEmpty) {
        subjectError = "Subject field is required";
        isValid = false;
      }
      if (messageController.text.trim().isEmpty) {
        messageError = "Message field is required";
        isValid = false;
      }
      if (selectedPriority == null) {
        priorityError = "Please select priority";
        isValid = false;
      }

      if (selectedGroup == null) {
        groupError = "Please select group";
        isValid = false;
      }
    });

    return isValid;
  }

  Future<void> createTicket() async {
    FocusScope.of(context).unfocus();
    if (!validator()) return;
    setState(() {
      isLoading = true;
    });
    var payload = {
      "subject": subjectController.text.trim(),
      "message": messageController.text.trim(),
      "priority": getPriorityValue(),
      "group": getGroupValue(),
      "tag": tagController.text.trim(),
      "close_otp_ver": "0",
    };
    Map<String, File?> files = {};
    if (selectedFile != null) {
      files["attachment"] = selectedFile;
    }
    print("PAYLOAD => $payload");
    print("FILE => ${selectedFile?.path}");
    var response = await BaseClient()
        .multipartRequest(CREATE_TICKET_URL, payload, files, context)
        .catchError((err) {
          errToast("Error! Something went wrong");
          print(err);
        });
    setState(() {
      isLoading = false;
    });
    print("CREATE_TICKET_URL :: $CREATE_TICKET_URL");
    print("payload :: $payload");
    print("RESPONSE :: $response");
    if (response != null && response['status'] == true) {
      successToast(response['message']);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SupportTicketScreen()),
        (route) => false,
      );
    } else {
      errToast(response?['message'] ?? "Failed to create ticket");
    }
  }

  String getPriorityValue() {
    switch (selectedPriority) {
      case "Low":
        return "0";
      case "Medium":
        return "1";
      case "High":
        return "2";
      case "Urgent":
        return "3";
      default:
        return "0";
    }
  }

  String getGroupValue() {
    switch (selectedGroup) {
      case "Sales":
        return "0";
      case "Technical":
        return "1";
      default:
        return "1";
    }
  }

  Widget customDropdown({
    required String? value,
    required String hint,
    required String titleText,
    required List<String> items,
    required String? errorText,
    required Function(String?) onChanged,
    required Color fieldColor,
    required Color text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titleText,
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: text.withOpacity(.60),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 68,
          child: DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            hint: Text(
              hint,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: text.withOpacity(.60),
              ),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.withOpacity(.08),
              errorText: errorText,
              errorStyle: GoogleFonts.poppins(color: Colors.red, fontSize: 11.sp),
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
            dropdownColor: fieldColor,
            icon: Icon(Icons.keyboard_arrow_down, color: text),
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: text,
            ),
            onChanged: onChanged,
            items: items.map((e) {
              return DropdownMenuItem(value: e, child: Text(e));
            }).toList(),
          ),
        ),

      ],
    );
  }

  Widget customTextField({
    required TextEditingController controller,
    required String hint,
    required String titleText,
    required String? errorText,
    required Color text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titleText,
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: text.withOpacity(.60),
          ),
        ),

        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: text,
          ),

          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: text.withOpacity(.60),
            ),
            filled: true,
            fillColor: Colors.grey.withOpacity(.08),
            contentPadding: const EdgeInsets.all(10),
            errorText: errorText,
            errorStyle: GoogleFonts.poppins(color: Colors.red, fontSize: 11.sp),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
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
        ),
      ],
    );
  }
}
