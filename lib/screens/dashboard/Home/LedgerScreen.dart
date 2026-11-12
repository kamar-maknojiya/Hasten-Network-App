import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:vision_broadband/networking/BaseClient.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/theme/app_colors.dart';
import 'package:vision_broadband/widgets/AppConfig.dart';
import 'package:vision_broadband/widgets/CustomAppbar.dart';
import 'package:vision_broadband/widgets/Network/AppScaffold.dart';
import 'package:vision_broadband/widgets/Shimmer/LedgerShimmer.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  int selectedTab = 0;
  final searchController = TextEditingController();
  List<dynamic> filteredLedgerList = [];
  List<dynamic> filteredTransactionList = [];
  bool isLoading = false;
  List<String> tabs = [];
  List<dynamic> ledgerList = [];
  List<dynamic> transactionList = [];
  int page = 1;
  int perPage = 15;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  int transactionPage = 1;
  bool transactionLoadingMore = false;
  bool transactionHasMoreData = true;
  String isLedger = '0';
  String isTransaction = '0';

  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // getLedgerData();
    getPermission();
    // getOnlineTransactions();
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        if (tabs[selectedTab] == "Ledger") {
          if (!isLoadingMore && hasMoreData) {
            page++;
            getLedgerData(isPagination: true);
          }
        } else if (tabs[selectedTab] == "Online Transactions") {
          if (!transactionLoadingMore && transactionHasMoreData) {
            transactionPage++;
            getOnlineTransactions(isPagination: true);
          }
        }
      }
    });
  }

  Future<void> getPermission() async {
    setState(() {
      isLoading = true;
    });
    var response = await BaseClient()
        .get(GET_PERMISSIONS, context)
        .catchError((err) => null);

    if (!mounted) return;

    if (response != null && response['status'] == true) {
      final permission = response['data'];

      setState(() {
        isLedger = permission['ledger_list'] ?? "0";
        isTransaction = permission['online_transaction'] ?? "0";
      });

      if (isLedger == "1") {
        await getLedgerData();
      }

      if (isTransaction == "1") {
        await getOnlineTransactions();
      }

      // Select first available tab
      // if (isLedger == "1") {
      //   selectedTab = 0;
      // } else if (isTransaction == "1") {
      //   selectedTab = 1;
      // }
      tabs.clear();
      if (isLedger == "1") {
        tabs.add("Ledger");
      }
      if (isTransaction == "1") {
        tabs.add("Online Transactions");
      }
      selectedTab = 0;
      setState(() {
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> getLedgerData({bool isPagination = false}) async {
    if (isPagination) {
      isLoadingMore = true;
    } else {
      isLoading = true;
    }
    setState(() {});
    try {
      var response = await BaseClient().get(
        "$GET_LEDGERS_DATA?page=$page&per_page=$perPage",
        context,
      );
      print(
        "GET_LEDGERS_DATA :: $GET_LEDGERS_DATA?page=$page&per_page=$perPage",
      );
      print("response :: $response");
      if (response != null && response['status'] == true) {
        List<dynamic> newData = response['data']['data'] ?? [];
        if (!mounted) return;
        setState(() {
          if (isPagination) {
            ledgerList.addAll(newData);
          } else {
            ledgerList = newData;
          }
          filteredLedgerList = List.from(ledgerList);
          hasMoreData = newData.length == perPage;
          isLoading = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      isLoading = false;
      isLoadingMore = false;
      setState(() {});
    }
  }

  Future<void> getOnlineTransactions({bool isPagination = false}) async {
    if (isPagination) {
      transactionLoadingMore = true;
    } else {
      isLoading = true;
    }
    setState(() {});
    try {
      var response = await BaseClient().get(
        "$GET_ONLINE_TRANSACTION?page=$transactionPage&per_page=$perPage",
        context,
      );
      print(
        "TRANSACTION URL => "
        "$GET_ONLINE_TRANSACTION?page=$transactionPage&per_page=$perPage",
      );
      if (response != null && response['status'] == true) {
        List<dynamic> newData = response['data']['data'] ?? [];
        if (!mounted) return;
        setState(() {
          if (isPagination) {
            transactionList.addAll(newData);
          } else {
            transactionList = newData;
          }
          filteredTransactionList = List.from(transactionList);
          transactionHasMoreData = newData.length == perPage;
          isLoading = false;
          transactionLoadingMore = false;
        });
      }
    } catch (e) {
      transactionLoadingMore = false;
      isLoading = false;
      setState(() {});
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

  void filterData(String value) {
    if (tabs[selectedTab] == "Ledger") {
      setState(() {
        filteredLedgerList = ledgerList.where((item) {
          return (item['order_id'] ?? '').toString().toLowerCase().contains(
                value.toLowerCase(),
              ) ||
              (item['txn_id'] ?? '').toString().toLowerCase().contains(
                value.toLowerCase(),
              );
        }).toList();
      });
    } else {
      setState(() {
        filteredTransactionList = transactionList.where((item) {
          return (item['order_id'] ?? '').toString().toLowerCase().contains(
                value.toLowerCase(),
              ) ||
              (item['txn_id'] ?? '').toString().toLowerCase().contains(
                value.toLowerCase(),
              );
        }).toList();
      });
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
      child: AppScaffold(
        child: Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  /// APPBAR
                  CustomAppbar(title: 'Ledger'),
                  const SizedBox(height: 8),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        page = 1;
                        transactionPage = 1;
                        hasMoreData = true;
                        transactionHasMoreData = true;
                        if (isLedger == "1") {
                          await getLedgerData();
                        }
                        if (isTransaction == "1") {
                          await getOnlineTransactions();
                        }
                      },
                      child: isLoading
                          ? const LedgerShimmer()
                          : Column(
                              children: [
                                Row(
                                  children: [
                                    ...List.generate(tabs.length, (index) {
                                      return Padding(
                                        padding: EdgeInsets.only(right: 12.w),
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedTab = index;
                                              searchController.clear();
                                              if (tabs[index] == "Ledger") {
                                                filteredLedgerList = List.from(ledgerList);
                                              } else {
                                                filteredTransactionList = List.from(transactionList);
                                              }
                                            });
                                          },
                                          child: Container(
                                            height: 32.h,
                                            padding: EdgeInsets.symmetric(horizontal: 16 ),
                                            decoration: BoxDecoration(
                                              color: selectedTab == index ? AppColors.primary : card,
                                              borderRadius: BorderRadius.circular(100),
                                            ),
                                            child: Center(
                                              child: Text(
                                                tabs[index],
                                                style: GoogleFonts.poppins(
                                                  color: selectedTab == index ? Colors.white : Colors.grey.shade600,
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                TextField(
                                  controller: searchController,
                                  onChanged: filterData,
                                  style: GoogleFonts.poppins(color: text, fontSize: 13.sp),
                                  decoration: InputDecoration(
                                    hintText: tabs.isNotEmpty && tabs[selectedTab] == "Ledger"
                                        ? "Search Ledger"
                                        : "Search Transactions",
                                    prefixIcon: const Icon(Icons.search),
                                    filled: true,
                                    fillColor: card,
                                    hintStyle: GoogleFonts.poppins(color: text, fontSize: 13.sp),
                                    contentPadding: EdgeInsets.all(10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.withOpacity(.30)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: AppColors.primary),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child:
                                      tabs.isNotEmpty && tabs[selectedTab] == "Ledger"
                                      ? filteredLedgerList.isEmpty
                                            ? emptyState(
                                                card,
                                                text,
                                                "You don't have any Ledger",
                                                "No Ledger Found.")
                                            : _ledgerList(isDark)
                                      : filteredTransactionList.isEmpty
                                      ? emptyState(
                                          card,
                                          text,
                                          "You don't have any Online Transaction",
                                          "No Online Transaction Found.",
                                        )
                                      : _transactionList(isDark),
                                ),
                                // Expanded(
                                //   child: selectedTab == 0
                                //       ? filteredLedgerList.isEmpty
                                //             ? emptyState(
                                //                 card,
                                //                 text,
                                //                 "You don't have any Ledger",
                                //                 "No ledger Found.",
                                //               )
                                //             : _ledgerList(isDark)
                                //       : filteredTransactionList.isEmpty
                                //       ? emptyState(
                                //           card,
                                //           text,
                                //           "You don't have any Online Transaction",
                                //           "No Online Transaction Found.",
                                //         )
                                //       : _transactionList(isDark),
                                // ),
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

  Widget _ledgerList(bool isDark) {
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;
    return ListView.builder(
      padding: EdgeInsets.zero,
      controller: scrollController,
      itemCount: filteredLedgerList.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredLedgerList.length) {
          return Padding(
            padding: EdgeInsets.all(0),
            child: Center(
              child: Lottie.asset(
                'assets/animation/loading.json',
                height: 50,
                repeat: true,
                delegates: LottieDelegates(
                  values: [
                    ValueDelegate.color(const ['**'], value: AppColors.primary),
                  ],
                ),
              ),
            ),
          );
        }
        final item = filteredLedgerList[index];

        final bool isCredit = item['credit'] != null && item['credit'].toString().isNotEmpty;

        final String amount = isCredit
            ? item['credit'].toString()
            : item['debit'].toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 8.0),
          padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 10),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // if (item['order_id'] != null &&
                      //     item['order_id'].toString().isNotEmpty)
                      //   Text(
                      //     item['order_id'],
                      //     style: GoogleFonts.poppins(
                      //       color: text,
                      //       fontSize: 12.sp,
                      //       fontWeight: FontWeight.w600,
                      //     ),
                      //   ),
                      if (item['txn_id'] != null &&
                          item['txn_id'].toString().isNotEmpty &&
                          item['txn_id'].toString() != "null")
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['txn_id'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: text,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 4),

                      Text(
                        item['created_at']?.toString().split("T").first ?? "",
                        style: GoogleFonts.poppins(color: text.withOpacity(.6), fontSize: 12.sp),
                      ),
                    ],
                  ),

                  Text(
                    "${isCredit ? '+' : '-'} $amount",
                    style: GoogleFonts.poppins(
                      color: isCredit ? AppColors.green : AppColors.red,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              if (item['receipt_no'] != null &&
                  item['receipt_no'].toString().isNotEmpty &&
                  item['receipt_no'].toString() != "null") ...[
                const SizedBox(height: 6),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['receipt_no'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: text,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(.20),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        item['pg_name'] ?? "Payment Gateway",
                        style: GoogleFonts.poppins(
                          color: AppColors.secondary,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String getStatusText(String? status) {
    switch (status) {
      case "0":
        return "Process";
      case "1":
        return "Success";
      case "2":
        return "Failed";
      case "3":
        return "Cancel";
      case "-1":
        return "Data Not Found";
      case "-2":
        return "Timeout";
      case "4":
        return "Insufficient Balance";
      default:
        return "Unknown";
    }
  }

  Color getStatusColor(String? status) {
    switch (status) {
      case "0": // Process
        return AppColors.orange;

      case "1": // Success
        return AppColors.green;

      case "3": // Cancel
        return Colors.grey.shade600;

      case "2": // Failed
      case "-1": // Data Not Found
      case "-2": // Timeout
      case "4": // Insufficient Balance
        return AppColors.red;

      default:
        return Colors.grey;
    }
  }

  Color getStatusBgColor(String? status) {
    return getStatusColor(status).withOpacity(0.12);
  }

  Widget _transactionList(bool isDark) {
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final text = isDark ? Colors.white : Colors.black;

    return ListView.builder(
      padding: EdgeInsets.zero,
      controller: scrollController,
      // itemCount: filteredTransactionList.length,
      itemCount:
          filteredTransactionList.length + (transactionLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredTransactionList.length) {
          return Padding(
            padding: EdgeInsets.all(0),
            child: Center(
              child: Lottie.asset(
                'assets/animation/loading.json',
                height: 50,
                repeat: true,
                delegates: LottieDelegates(
                  values: [
                    ValueDelegate.color(const ['**'], value: AppColors.primary),
                  ],
                ),
              ),
            ),
          );
        }
        final item = filteredTransactionList[index];

        final bool isSuccess = item['status'].toString() == "1";

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 10),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['order_id'] ?? '',
                      style: GoogleFonts.poppins(
                        color: text,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    if (item['txn_id'] != null &&
                        item['txn_id'].toString().isNotEmpty &&
                        item['txn_id'].toString() != "null")
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          item['txn_id'],
                          style: GoogleFonts.poppins(color: text, fontSize: 11.sp, fontWeight: FontWeight.w500),
                        ),
                      ),
                    const SizedBox(height: 5),
                    Text(
                      formatDate(item['created_at']?.toString()),
                      style: GoogleFonts.poppins(color: text.withOpacity(.6), fontSize: 12.sp),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Container(
                  //   padding: const EdgeInsets.symmetric(
                  //     horizontal: 16,
                  //     vertical: 3,
                  //   ),
                  //   decoration: BoxDecoration(
                  //     color: isSuccess
                  //         ? Colors.green.withOpacity(.15)
                  //         : Colors.orange.withOpacity(.15),
                  //     borderRadius: BorderRadius.circular(30),
                  //   ),
                  //   child: Text(
                  //     isSuccess ? "Success" : "Failed",
                  //     style: GoogleFonts.poppins(
                  //       color: isSuccess ? Colors.green : Colors.orange,
                  //       fontSize: 12.sp,
                  //       fontWeight: FontWeight.w500,
                  //     ),
                  //   ),
                  // ),
                  SizedBox(
                    // width: 110,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      decoration: BoxDecoration(
                        color: getStatusBgColor(item['status']?.toString()),
                        borderRadius: BorderRadius.circular(4)),
                      child: Center(
                        child: Text(
                          getStatusText(item['status']?.toString()),
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: getStatusColor(item['status']?.toString()),
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${AppConfig.siteCurrency} ${item['credit'] ?? '0'}",
                    style: GoogleFonts.poppins(
                      color: AppColors.green,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget emptyState(Color card, Color textClr, String text, String subText) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_sharp, size: 40, color: AppColors.primary),
            const SizedBox(height: 20),
            Text(
              text,
              style: GoogleFonts.poppins(
                color: textClr,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subText,
              style: GoogleFonts.poppins(
                color: textClr.withOpacity(0.5),
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
