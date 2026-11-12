import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vision_broadband/networking/BaseClient.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/CustomAppbar.dart';
import 'package:vision_broadband/widgets/Network/AppScaffold.dart';
import 'package:vision_broadband/widgets/Shimmer/TicketDetailsShimmer.dart';
import 'package:vision_broadband/widgets/TopAlertToast.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';

class TicketDetailsScreen extends StatefulWidget {
  final ticketId;
  const TicketDetailsScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailsScreen> createState() => _TicketDetailsScreenState();
}

class _TicketDetailsScreenState extends State<TicketDetailsScreen> {
  final TextEditingController messageController = TextEditingController();

  final List<Map<String, dynamic>> messages = [
    {
      "message": "Hello Sir",
      "time": "27 May 2026 11:57:35",
      "isMe": false,
      "file": null,
    },
    {
      "message": "Please check my issue",
      "time": "27 May 2026 12:01:27",
      "isMe": true,
      "file": null,
    },
    {
      "message": "",
      "time": "27 May 2026 12:03:10",
      "isMe": false,
      "file": "ticket_attachment.jpg",
    },
  ];

  bool isLoading = false;
  bool isResolve = false;
  bool isComment = false;

  @override
  void initState() {
    super.initState();
    getTicketDetails();
    loadPermissions();
  }

  bool canAddComment = false;

  Future<void> loadPermissions() async {
    final prefs = await SharedPreferences.getInstance();

    canAddComment = prefs.getString("add_ticket_comment") == "1";

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? ticketDetails;
  List<dynamic> comments = [];
  Future<void> getTicketDetails() async {
    setState(() {
      isLoading = true;
    });

    int ticketId = widget.ticketId;
    var response = await BaseClient()
        .get("$GET_TICKET_DETAILS/$ticketId", context)
        .catchError((err) {
          errToast("Error! Something went wrong");
          print(err);
        });

    print('response :: $response');

    if (response != null && response['status'] == true) {
      setState(() {
        ticketDetails = response['data'];
        comments = response['data']['comments'] ?? [];
        isLoading = false;
      });

      print("Subject => ${ticketDetails?['subject']}");
      print("Message => ${ticketDetails?['message']}");
      print("Comments => ${comments.length}");
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDate(String? date) {
    if (date == null ||
        date.trim().isEmpty ||
        date.trim() == "-" ||
        date.toLowerCase() == "null") {
      return "-";
    }

    try {
      DateTime dateTime = DateTime.parse(date);

      return DateFormat("dd MMM yyyy hh:mm a").format(dateTime);
    } catch (_) {
      try {
        final dateTime = DateFormat("yyyy-MM-dd HH:mm:ss").parse(date);

        return DateFormat("dd MMM yyyy hh:mm a").format(dateTime);
      } catch (_) {
        return "-";
      }
    }
  }

  String? selectedFileName;
  File? selectedFile;
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

  String getFileName(String filePath) {
    return filePath.split('/').last;
  }

  Future<void> ticketResolve() async {
    setState(() {
      isResolve = true;
    });

    try {
      int ticketId = widget.ticketId;
      var response = await BaseClient().post(
        "$TICKET_RESOLVE_URL/$ticketId",
        {},
        context,
      );

      print("TICKET_RESOLVE_URL ::$TICKET_RESOLVE_URL/$ticketId");
      print("response :: $response");

      setState(() {
        isResolve = false;
      });

      if (response != null && response['status'] == true) {
        // successToast(response['message']);
        TopAlert.show(
          context,
          // title: "Success",
          message: response['message'] ?? "Ticket resolved successfully",
          type: AlertType.success,
        );
        getTicketDetails();
      } else {
        TopAlert.show(
          context,
          // title: "Warning",
          message:
              response?['message'] ??
              "Ticket must be assigned before it can be resolved",
          type: AlertType.warning,
        );
      }
    } catch (e) {
      print("ERROR :: $e");

      setState(() {
        isResolve = false;
      });

      errToast("Error! Something went wrong");
    }
  }

  Future<void> ticketClose() async {
    setState(() {
      isResolve = true;
    });

    try {
      int ticketId = widget.ticketId;
      var response = await BaseClient().post(
        "$TICKET_CLOSE_URL/$ticketId",
        {},
        context,
      );

      print("TICKET_CLOSE_URL ::$TICKET_CLOSE_URL/$ticketId");
      print("response :: $response");

      setState(() {
        isResolve = false;
      });

      if (response != null && response['status'] == true) {
        // successToast(response['message']);
        TopAlert.show(
          context,
          // title: "Success",
          message: response['message'] ?? "Ticket Close successfully",
          type: AlertType.success,
        );
        getTicketDetails();
      } else {
        TopAlert.show(
          context,
          // title: "Warning",
          message:
              response?['message'] ??
              "Ticket must be assigned before it can be closed",
          type: AlertType.warning,
        );
      }
    } catch (e) {
      print("ERROR :: $e");

      setState(() {
        isResolve = false;
      });

      errToast("Error! Something went wrong");
    }
  }

  Future<void> ticketReOPen() async {
    setState(() {
      isResolve = true;
    });

    try {
      int ticketId = widget.ticketId;
      var response = await BaseClient().post(
        "$TICKET_REOPEN_URL/$ticketId",
        {},
        context,
      );

      print("TICKET_REOPEN_URL ::$TICKET_REOPEN_URL/$ticketId");
      print("response :: $response");

      setState(() {
        isResolve = false;
      });

      if (response != null && response['status'] == true) {
        // successToast(response['message']);
        TopAlert.show(
          context,
          // title: "Success",
          message: response['message'] ?? "Ticket Re-open successfully",
          type: AlertType.success,
        );
        getTicketDetails();
      } else {
        TopAlert.show(
          context,
          // title: "Warning",
          message:
              response?['message'] ??
              "Ticket must be assigned before it can be Re-open",
          type: AlertType.warning,
        );
      }
    } catch (e) {
      print("ERROR :: $e");

      setState(() {
        isResolve = false;
      });

      errToast("Error! Something went wrong");
    }
  }

  Future<void> showTicketConfirmationDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    required Future<void> Function() onConfirm,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;

    bool isProcessing = false;

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(.12),
                      ),
                      child: Icon(icon, color: color, size: 30),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: text,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: text.withOpacity(.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 45),
                              side: BorderSide(color: Colors.grey.shade500),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: isProcessing
                                ? null
                                : () => Navigator.pop(context),
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.poppins(
                                fontSize: 13.sp,
                                color: text,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              minimumSize: const Size(0, 45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: isProcessing
                                ? null
                                : () async {
                                    setDialogState(() {
                                      isProcessing = true;
                                    });

                                    await onConfirm();

                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  },
                            child: isProcessing
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    "Confirm",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String getTicketStatus(String? status) {
    switch (status) {
      case "0":
        return "Open";
      case "1":
        return "Reopen";
      case "2":
        return "Resolve";
      case "3":
        return "Close";
      default:
        return "Unknown";
    }
  }

  // Color statusColor(String status) {
  //   switch (status) {
  //     case "0": // Open
  //       return AppColors.secondary;
  //
  //     case "1": // Reopen
  //       return AppColors.secondary;
  //
  //     case "2": // Resolve
  //       return AppColors.orange;
  //
  //     case "3": // Close
  //       return AppColors.red;
  //
  //     default:
  //       return const Color(0xffDCEAFF);
  //   }
  // }

  Color statusColor(String status) {
    switch (status) {
      case "0":
        return AppColors.primary;

      case "1":
        return AppColors.primary;

      case "2":
        return AppColors.green;

      case "3":
        return AppColors.red;

      default:
        return Colors.black;
    }
  }

  Color statusBg(String status) {
    switch (status) {
      case "0": // Open
        return AppColors.primary.withOpacity(0.2);

      case "1": // Re-opened
        return AppColors.primary.withOpacity(0.2);

      case "2": // Resolved
        return AppColors.green.withOpacity(0.2);

      case "3": // Closed
        return AppColors.red.withOpacity(0.2);

      default:
        return AppColors.secondary.withOpacity(0.2);
    }
  }

  String getDisplayName(Map<String, dynamic> item, String ticketUsername) {
    // Engineer
    if (item["account"] != null) {
      final email = item["account"]["email"];
      if (email != null && email.toString().isNotEmpty) {
        return email;
      }
    }

    // Subscriber
    return ticketUsername;
  }

  String formatCommentTime(String dateTime) {
    final dt = DateTime.parse(dateTime);
    return DateFormat('hh:mm a').format(dt);
  }

  String formatWhatsAppDate(String dateTime) {
    final dt = DateTime.parse(dateTime);
    final now = DateTime.now();

    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today ${DateFormat('hh:mm a').format(dt)}';
    }

    final yesterday = now.subtract(const Duration(days: 1));

    if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day) {
      return 'Yesterday ${DateFormat('hh:mm a').format(dt)}';
    }

    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;
    final sub = isDark ? Colors.white60 : Colors.grey.shade600;

    return AppScaffold(
      child: WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, true);
          return false;
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: bg,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  /// HEADER
                  CustomAppbar(
                    title: 'Ticket Details',
                    onTap: () => Navigator.pop(context, true),
                  ),
                  const SizedBox(height: 10),

                  /// TOP CARD
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                      onRefresh:  getTicketDetails,
                      child: isLoading
                          ? const TicketDetailsShimmer()
                          : Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12)),
                                  child: Column(
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: statusBg(ticketDetails?['status'].toString() ?? ""),
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                          child: Text(
                                            ticketDetails!['status_label'].toString(),
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: statusColor(ticketDetails?['status'].toString() ?? ""),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          ticketDetails?['subject'] ?? '',
                                          style: GoogleFonts.poppins(
                                            color: text,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              "Created By",
                                              style: GoogleFonts.poppins(
                                                color: sub,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            ticketDetails?['username'] ?? '',
                                            style: GoogleFonts.poppins(
                                              color: text,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              "Created Date",
                                              style: GoogleFonts.poppins(
                                                color: sub,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            formatDate(ticketDetails?['created_at']?.toString()),
                                            style: GoogleFonts.poppins(
                                              color: text,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 15),
                                      if (ticketDetails?['status'] == "0" || ticketDetails?['status'] == "1")
                                        SizedBox(
                                          width: double.infinity,
                                          height: 42,
                                          child: OutlinedButton(
                                            onPressed: () {
                                              showTicketConfirmationDialog(
                                                title: "Resolve Ticket",
                                                message: "Are you sure you want to resolve this ticket?",
                                                icon: Icons.check_circle_outline,
                                                color: AppColors.green,
                                                onConfirm: ticketResolve,
                                              );
                                              // Navigator.pop(context, true);
                                            },
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(
                                                color: AppColors.green,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: Text(
                                              'Resolve',
                                              style: GoogleFonts.poppins(
                                                color: text,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),

                                      if (ticketDetails?['status'] == "2")
                                        Row(
                                          children: [
                                            Expanded(
                                              child: SizedBox(
                                                width: double.infinity,
                                                height: 42,
                                                child: OutlinedButton(
                                                  onPressed: () {
                                                    showTicketConfirmationDialog(
                                                      title: "Close Ticket",
                                                      message: "Are you sure you want to close this ticket?",
                                                      icon: Icons.cancel_outlined,
                                                      color: AppColors.red,
                                                      onConfirm: ticketClose,
                                                    );
                                                    // Navigator.pop(context, true);
                                                  },
                                                  style: OutlinedButton.styleFrom(
                                                    side: const BorderSide(color: AppColors.red),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  ),
                                                  child: Text(
                                                    'Close',
                                                    style: GoogleFonts.poppins(
                                                      color: text,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 15),
                                            Expanded(
                                              child: SizedBox(
                                                width: double.infinity,
                                                height: 42,
                                                child: OutlinedButton(
                                                  onPressed: () {
                                                    showTicketConfirmationDialog(
                                                      title: "Re-open Ticket",
                                                      message: "Are you sure you want to re-open this ticket?",
                                                      icon: Icons.refresh,
                                                      color: AppColors.secondary,
                                                      onConfirm: ticketReOPen,
                                                    );
                                                    // Navigator.pop(context, true);
                                                  },
                                                  style: OutlinedButton.styleFrom(
                                                    side: const BorderSide(color: AppColors.green),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  ),
                                                  child: Text(
                                                    'Re-open',
                                                    style: GoogleFonts.poppins(
                                                      color: text,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    margin: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: card,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: isDark
                                          ? []
                                          : [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(.06),
                                                blurRadius: 15,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Comments",
                                          style: GoogleFonts.poppins(
                                            color: text,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Expanded(
                                          child: ListView.builder(
                                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                                            itemCount: comments.length,
                                            reverse: true,
                                            itemBuilder: (context, index) {
                                              final item = comments[comments.length - 1 - index];
                                              final bool isSender = item['subscriber_id'] != null;
                                              final displayName = getDisplayName(item, ticketDetails?["username"]);
                                              return Column(
                                                crossAxisAlignment: isSender
                                                    ? CrossAxisAlignment.end
                                                    : CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                                    child: Text(
                                                      displayName,
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w600,
                                                            color: text.withOpacity(0.7)),
                                                    ),
                                                  ),

                                                  const SizedBox(height: 4),
                                                  Container(
                                                    margin: const EdgeInsets.only(bottom: 12),
                                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .65),
                                                    decoration: BoxDecoration(
                                                      color: isDark
                                                          ? Color(0xff0D4B48)
                                                          : Color(0xffB2ECDD),
                                                      borderRadius: BorderRadius.only(
                                                        topLeft: const Radius.circular(12),
                                                        topRight: const Radius.circular(12),
                                                        bottomLeft: isSender
                                                            ? const Radius.circular(12)
                                                            : Radius.zero,
                                                        bottomRight: isSender
                                                            ? Radius.zero
                                                            : const Radius.circular(12),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: isSender
                                                          ? CrossAxisAlignment.end
                                                          : CrossAxisAlignment.start,
                                                      children: [
                                                        if (item["comment"].toString().isNotEmpty)
                                                          Text(
                                                            item["comment"],
                                                            style: GoogleFonts.poppins(
                                                              color: text,
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),

                                                        if (item["comment"].toString().isNotEmpty)
                                                          const SizedBox(height: 4),
                                                        if (item["attachment"] != null && item["attachment"].isNotEmpty)
                                                          Align(
                                                            alignment: Alignment.centerLeft,
                                                            child: GestureDetector(
                                                              onTap: () {
                                                                showAttachmentImage(context, item["attachment"].toString());
                                                              },
                                                              child: Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                                decoration: BoxDecoration(
                                                                  color: isDark
                                                                      ? Color(0xff57817F)
                                                                      : Color(0xffC8F2E6),
                                                                  borderRadius: BorderRadius.circular(8),
                                                                ),
                                                                child: Row(
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    Icon(
                                                                      Icons.attach_file,
                                                                      color: text,
                                                                      size: 16,
                                                                    ),
                                                                    const SizedBox(width: 4),
                                                                    Flexible(
                                                                      child: Text(
                                                                        getFileName(item["attachment"]),
                                                                        overflow: TextOverflow.ellipsis,
                                                                        style: GoogleFonts.poppins(
                                                                          color: text,
                                                                          fontSize: 12,
                                                                          fontWeight: FontWeight.w500,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),

                                                        if (item["attachment"] != null)
                                                          const SizedBox(height: 4),

                                                        Align(
                                                          alignment: Alignment.centerRight,
                                                          child: Text(
                                                            formatWhatsAppDate(item["created_date"]),
                                                            style: GoogleFonts.poppins(
                                                              color: text.withOpacity(0.4),
                                                              fontSize: 10,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (selectedFile != null)
                                          Container(
                                            margin: const EdgeInsets.only(bottom: 10),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: card,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: AppColors.primary.withOpacity(.3)),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.attach_file,
                                                  color: AppColors.primary,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    selectedFileName ?? "",
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.poppins(
                                                      color: text,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),

                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      selectedFile = null;
                                                      selectedFileName = null;
                                                    });
                                                  },
                                                  child: const Icon(
                                                    Icons.close,
                                                    size: 20,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (ticketDetails?['status'] != "3" && canAddComment)
                                          SafeArea(
                                            top: false,
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      color: isDark
                                                          ? const Color(0xff1F2535)
                                                          : Colors.grey.shade100,
                                                      borderRadius: BorderRadius.circular(50),
                                                      border: Border.all(color: Colors.grey.withOpacity(.2),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        IconButton(
                                                          onPressed: () {
                                                            // setState(() {
                                                            //   messages.add({
                                                            //     "isMe": true,
                                                            //     "message": "",
                                                            //     "file":
                                                            //         "ticket_attachment.pdf",
                                                            //     "time": "Now",
                                                            //   });
                                                            // });
                                                          },
                                                          icon: GestureDetector(
                                                            onTap: pickFile,
                                                            child: Icon(Icons.attach_file_rounded, color: sub),
                                                          ),
                                                        ),

                                                        Expanded(
                                                          child: TextField(
                                                            controller: messageController,
                                                            style: GoogleFonts.poppins(color: text, fontSize: 15),
                                                            decoration: InputDecoration(
                                                              hintText: "Type a comment...",
                                                              hintStyle: GoogleFonts.poppins(color: sub, fontSize: 12),
                                                              border: InputBorder.none,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                GestureDetector(
                                                  // onTap: () {
                                                  //   if (messageController.text.trim().isEmpty) {
                                                  //     return;
                                                  //   }
                                                  //   setState(() {
                                                  //     messages.add({
                                                  //       "isMe": true,
                                                  //       "message": messageController.text,
                                                  //       "file": null,
                                                  //       "time": "Now",
                                                  //     });
                                                  //   });
                                                  //   messageController.clear();
                                                  //   Future.delayed(const Duration(seconds: 1), () {
                                                  //     if (!mounted) return;
                                                  //     setState(() {
                                                  //       messages.add({
                                                  //         "isMe": false,
                                                  //         "message":
                                                  //             "Thank you. Our support team will review your ticket.",
                                                  //         "file": null,
                                                  //         "time": "Now",
                                                  //       });
                                                  //     });
                                                  //   });
                                                  // },
                                                  child: GestureDetector(
                                                    onTap: isComment
                                                        ? null
                                                        : () {
                                                            addComment();
                                                          },
                                                    child: Container(
                                                      width: 45,
                                                      height: 45,
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primary,
                                                        borderRadius: BorderRadius.circular(30),
                                                      ),
                                                      child: Center(
                                                        child: isComment
                                                            ? const SizedBox(
                                                                width: 20,
                                                                height: 20,
                                                                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                                                              )
                                                            : const Icon(
                                                                Icons.send_rounded,
                                                                color: Colors.white,
                                                                size: 22,
                                                              ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Future<void> addComment() async {
  //   if (messageController.text.trim().isEmpty && selectedFile == null) {
  //     // errToast("Please enter a comment or select a file");
  //     return;
  //   }
  //   setState(() {
  //     isComment = true;
  //   });
  //
  //   var payload = {
  //     "ticket_id": ticketDetails?['ticket_id']?.toString() ?? '',
  //     "comment": messageController.text.trim(),
  //   };
  //
  //   Map<String, File?> files = {};
  //
  //   if (selectedFile != null) {
  //     files["attachment"] = selectedFile;
  //   }
  //
  //   print("PAYLOAD => $payload");
  //   print("FILE => ${selectedFile?.path}");
  //
  //   var response = await BaseClient()
  //       .multipartRequest(ADD_COMMENT_URL, payload, files, context)
  //       .catchError((err) {
  //         errToast("Error! Something went wrong");
  //         print(err);
  //       });
  //
  //   setState(() {
  //     isComment = false;
  //   });
  //
  //   print("ADD_COMMENT_URL :: $ADD_COMMENT_URL");
  //   print("payload :: $payload");
  //   print("RESPONSE :: $response");
  //
  //   if (response != null && response['status'] == true) {
  //     messageController.clear();
  //
  //     setState(() {
  //       selectedFile = null;
  //       selectedFileName = null;
  //     });
  //     await getTicketDetailsMsg();
  //   } else {
  //     errToast(response?['message'] ?? "Failed to send Message");
  //   }
  // }
  Future<void> addComment() async {
    // if (messageController.text.trim().isEmpty) {
    //   errToast("The comment field is required.");
    //   return;
    // }

    if (messageController.text.trim().isEmpty && selectedFile == null) {
      errToast("The comment field is required.");
      return;
    }

    setState(() {
      isComment = true;
    });

    try {
      Map<String, dynamic> payload = {
        "ticket_id": ticketDetails?['ticket_id']?.toString() ?? '',
        "comment": messageController.text.trim(),
      };

      Map<String, File?> files = {};

      if (selectedFile != null) {
        files["attachment"] = selectedFile;
      }

      print("ADD COMMENT");
      print("URL => $ADD_COMMENT_URL");
      print("PAYLOAD => $payload");
      print("FILE => ${selectedFile?.path}");

      final response = await BaseClient().multipartRequest(
        ADD_COMMENT_URL,
        payload,
        files,
        context,
      );

      print("ADD COMMENT RESPONSE => $response");

      if (response != null && response['status'] == true) {
        messageController.clear();

        setState(() {
          selectedFile = null;
          selectedFileName = null;
        });

        // successToast(response['message'] ?? "Comment added successfully");

        await getTicketDetailsMsg();
      } else {
        errToast(response?['message'] ?? "Failed to send comment");
      }
    } catch (e) {
      print("ADD COMMENT ERROR => $e");
      errToast("Something went wrong");
    } finally {
      if (mounted) {
        setState(() {
          isComment = false;
        });
      }
    }
  }

  Future<void> getTicketDetailsMsg() async {
    setState(() {
      isComment = true;
    });

    int ticketId = widget.ticketId;
    var response = await BaseClient()
        .get("$GET_TICKET_DETAILS/$ticketId", context)
        .catchError((err) {
          errToast("Error! Something went wrong");
          print(err);
        });

    print('response :: $response');

    if (response != null && response['status'] == true) {
      setState(() {
        ticketDetails = response['data'];
        comments = response['data']['comments'] ?? [];
        isComment = false;
      });

      print("Subject => ${ticketDetails?['subject']}");
      print("Message => ${ticketDetails?['message']}");
      print("Comments => ${comments.length}");
    } else {
      setState(() {
        isComment = false;
      });
    }
  }

  void showAttachmentImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    "$mainUrl/$imagePath",
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;

                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text(
                          "Unable to load image",
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    },
                  ),
                ),
              ),

              Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.black,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
