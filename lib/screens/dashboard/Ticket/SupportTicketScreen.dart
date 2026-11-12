import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vision_broadband/networking/BaseClient.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/screens/dashboard/BottomNavScreen.dart';
import 'package:vision_broadband/screens/dashboard/Ticket/AddTicketScreen.dart';
import 'package:vision_broadband/screens/dashboard/Ticket/TicketDetailsScreen.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/CustomAppbar.dart';
import 'package:vision_broadband/widgets/Network/AppScaffold.dart';
import 'package:vision_broadband/widgets/Shimmer/SupportTicketShimmer.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';

class SupportTicketScreen extends StatefulWidget {
  const SupportTicketScreen({super.key});

  @override
  State<SupportTicketScreen> createState() => _SupportTicketScreenState();
}

class _SupportTicketScreenState extends State<SupportTicketScreen> {
  int selectedTab = 0;
  bool isLoading = false;
  // final List<String> tabs = ["All", "Open", "Reopen", "Resolve", "Close"];
  final List<String> tabs = ["All", "Open", "Re-opened", "Resolved", "Closed"];

  List<dynamic> supportTickets = [];

  List<dynamic> get filteredTickets {
    switch (selectedTab) {
      case 0: // All
        return supportTickets;

      case 1: // Open
        return supportTickets
            .where((e) => e['status_label'].toString() == "Open")
            .toList();

      case 2: // Reopen
        return supportTickets
            .where((e) => e['status_label'].toString() == "Re-opened")
            .toList();

      case 3: // Resolve
        return supportTickets
            .where((e) => e['status_label'].toString() == "Resolved")
            .toList();

      case 4: // Close
        return supportTickets
            .where((e) => e['status_label'].toString() == "Closed")
            .toList();

      default:
        return supportTickets;
    }
  }

  bool canViewTickets = false;
  bool canAddTicket = false;
  bool canUpdateTicket = false;

  Future<void> loadPermissions() async {
    final prefs = await SharedPreferences.getInstance();

    canViewTickets = prefs.getString("ticket_list") == "1";
    canAddTicket = prefs.getString("add_ticket") == "1";
    canUpdateTicket = prefs.getString("update_ticket") == "1";

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    loadPermissions();

    // if (canViewTickets) {
    getSupportTicket();
    // }
  }

  Future<void> getSupportTicket() async {
    setState(() {
      isLoading = true;
    });

    var response = await BaseClient()
        .get(GET_SUPPORT_TICKET, context)
        .catchError((err) {
          errToast("Error! Something went wrong");
          print(err);
        });

    print('response :: $response');

    if (response != null && canViewTickets && response['status'] == true) {
      setState(() {
        supportTickets = response['data']['data'] ?? [];
        isLoading = false;
      });

      print("Total Tickets : ${supportTickets.length}");
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;

    return AppScaffold(
      child: Scaffold(
        backgroundColor: bg,
        floatingActionButton: !isLoading && canAddTicket
            ? Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTicketScreen()));
                  },
                  child: const Icon(Icons.add, color: Colors.white, size: 35),
                ),
              )
            : SizedBox(),

        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                CustomAppbar(
                  title: 'Support Ticket',
                  onTap: () {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNavScreen()));
                  },
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                    onRefresh: () async {
                      getSupportTicket();
                    },
                    child: isLoading
                        ? const SupportTicketShimmer()
                        : !canViewTickets
                        ? buildEmpty()
                        : Column(
                            children: [
                              SizedBox(
                                height: 30,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: EdgeInsets.zero,
                                  itemCount: tabs.length,
                                  itemBuilder: (context, index) {
                                    bool selected = selectedTab == index;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedTab = index;
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 14),
                                        decoration: BoxDecoration(
                                          color: selected ? AppColors.primary : card,
                                          borderRadius: BorderRadius.circular(30),
                                        ),

                                        child: Center(
                                          child: Text(
                                            tabs[index],
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: selected ? Colors.white : isDark ? Colors.white70 : Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: filteredTickets.isEmpty
                                    ? _buildNoTicket(card, text)
                                    : ListView.builder(
                                        padding: EdgeInsets.zero,
                                        itemCount: filteredTickets.length,
                                        itemBuilder: (context, index) {
                                          final ticket = filteredTickets[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 16),
                                            child: _ticketCard(ticket, card, text, isDark),
                                          );
                                        },
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
    );
  }

  Widget buildEmpty() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;
    final subText = isDark ? Colors.white70 : Colors.black54;
    return Center(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 2)),]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 50, color: AppColors.red),
            const SizedBox(height: 6),
            Text(
              "Access Denied",
              style: GoogleFonts.poppins(color: text, fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              "You don't have permission to\nview support tickets.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: subText, fontSize: 12.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ticketCard(
    Map<String, dynamic> ticket,
    Color card,
    Color text,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () async {
        if (canUpdateTicket) {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetailsScreen(ticketId: ticket["ticket_id"])));
          if (result == true) {
            getSupportTicket();
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${ticket["ticket_id"]}  ${ticket["subject"]}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _labelColumn(
                            "Status",
                            _chip(
                              getStatusText(ticket["status"].toString()),
                              statusBg(ticket["status"].toString()),
                              statusText(ticket["status"].toString()),
                            ),
                            isDark,
                          ),
                        ),
                        Expanded(
                          child: _labelColumn(
                            "Group",
                            Text(
                              ticket["group_label"],
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                // color: ticket["group"] == '0'
                                //     ? const Color(0xffA63DD1)
                                //     : AppColors.secondary,
                              ),
                            ),
                            // _chip(
                            //   ticket["group"] == '0' ? 'Technical' : 'Sales',
                            //   // ticket["group"] == "0"
                            //   //     ? const Color(0xffA63DD1).withOpacity(0.2)
                            //   //     : AppColors.secondary.withOpacity(0.2),
                            //   ticket["group"] == "0"
                            //       ? const Color(0xffA63DD1)
                            //       : AppColors.secondary,
                            // ),
                            isDark,
                          ),
                        ),
                        Expanded(
                          child: _labelColumn(
                            "Priority",
                            Text(
                              ticket["priority_label"],
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _priorityText(ticket["priority"]),
                              ),
                            ),
                            isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Divider(color: isDark ? Colors.white24 : Colors.grey.shade300),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Created: ${formatDate(ticket['created_at'])}",
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: text.withOpacity(0.6),
                                ),
                              ),

                              if (ticket["resolve_date"] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  "Resolved: ${formatDate(ticket['resolve_date'])}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: text.withOpacity(0.6),
                                  ),
                                ),
                              ],
                              if (ticket["close_date"] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  "Closed: ${formatDate(ticket['close_date'])}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: text.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                    if(canUpdateTicket)    GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetailsScreen(ticketId: ticket["ticket_id"])));
                            if (result == true) {
                              getSupportTicket();
                            }
                          },
                          child: Icon(Icons.edit, color: text, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String getStatusText(String status) {
    switch (status) {
      case "0":
        return "Open";
      case "1":
        return "Re-opened";
      case "2":
        return "Resolved";
      case "3":
        return "Closed";
      default:
        return "Unknown";
    }
  }

  Widget _labelColumn(String title, Widget child, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: isDark ? Colors.white60 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _chip(String text, Color bg, Color textClr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(50)),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textClr,
        ),
      ),
    );
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

  // Color statusBg(String priority) {
  //   switch (priority) {
  //     case "0":
  //       return AppColors.secondary.withOpacity(0.2);
  //     case "1":
  //       return AppColors.secondary.withOpacity(0.2);
  //     case "2":
  //       return AppColors.green.withOpacity(0.2);
  //     case "3":
  //       return Color(0xff3357ff).withOpacity(0.2);
  //     default:
  //       return const Color(0xffDCEAFF).withOpacity(0.2);
  //   }
  // }

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

  // Color statusText(String priority) {
  //   switch (priority) {
  //     case "0":
  //       return AppColors.secondary;
  //     case "1":
  //       return AppColors.secondary;
  //     case "2":
  //       return AppColors.green;
  //     case "3":
  //       return Color(0xff4d6bff);
  //     default:
  //       return Colors.black;
  //   }
  // }

  Color statusText(String status) {
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

  Color _priorityBg(String priority) {
    switch (priority) {
      case "0":
        return AppColors.teal.withOpacity(0.2);
      case "1":
        return AppColors.secondary.withOpacity(0.2);

      case "2":
        return AppColors.orange.withOpacity(0.2);

      case "3":
        return AppColors.red.withOpacity(0.2);

      default:
        return AppColors.secondary.withOpacity(0.2);
    }
  }

  Color _priorityText(String priority) {
    switch (priority) {
      case "0":
        return AppColors.teal;

      case "1":
        return AppColors.primary;

      case "2":
        return AppColors.orange;

      case "3":
        return AppColors.red;

      default:
        return Colors.black;
    }
  }

  String getPriority(String? priority) {
    switch (priority) {
      case "0":
        return "Low";
      case "1":
        return "Medium";
      case "2":
        return "High";
      case "3":
        return "Urgent";
      default:
        return "Unknown";
    }
  }

  Widget _buildNoTicket(Color card, Color text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.support_agent, size: 50, color: AppColors.primary),
          const SizedBox(height: 20),
          Text(
            "No Tickets",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "No support tickets found.",
            style: GoogleFonts.poppins(fontSize: 12, color: text.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}
