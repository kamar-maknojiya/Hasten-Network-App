import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void successToast(String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 1,
    backgroundColor: Colors.black,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}

void errToast(String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 10,
    backgroundColor: Colors.black,
    // backgroundColor: Color(0xffDF6283),
    textColor: Colors.white,
    fontSize: 16.0,
  );
}

// void successToast(BuildContext context, String message) {
//   final overlay = Overlay.of(context);
//   final opacity = ValueNotifier<double>(0.0);
//   late OverlayEntry entry;
//
//   entry = OverlayEntry(
//     builder: (context) {
//       return Positioned(
//         bottom: 40,
//         left: 0,
//         right: 0,
//         child: ValueListenableBuilder<double>(
//           valueListenable: opacity,
//           builder: (context, value, child) {
//             return Opacity(
//               opacity: value, // fade animation
//               child: Transform.translate(
//                 offset: Offset(0, (1 - value) * 20), // slide animation
//                 child: child,
//               ),
//             );
//           },
//           child: Center(
//             child: Material(
//               color: Colors.transparent,
//               child: Padding(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Container(
//                   // constraints: BoxConstraints(maxWidth: 260),
//                   padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//                   decoration: BoxDecoration(
//                     color: Colors.black87,
//                     borderRadius: BorderRadius.circular(8),
//                     // boxShadow: [
//                     //   BoxShadow(
//                     //     color: Colors.black26,
//                     //     blurRadius: 12,
//                     //     offset: Offset(0, 4),
//                     //   )
//                     // ],
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Image.asset(
//                         "assets/images/Group 1000003375.png",
//                         width: 30,
//                         height: 30,
//                       ),
//                       SizedBox(width: 10),
//                       Flexible(
//                         child: Text(
//                           message,
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 12,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       );
//     },
//   );
//
//   overlay.insert(entry);
//
//   // 👉 Fade In (0 → 1)
//   Future.microtask(() async {
//     for (double i = 0; i <= 1; i += 0.05) {
//       opacity.value = i;
//       await Future.delayed(Duration(milliseconds: 10));
//     }
//   });
//
//   // 👉 Wait then Fade Out (1 → 0)
//   Future.delayed(Duration(seconds: 2)).then((_) async {
//     for (double i = 1; i >= 0; i -= 0.05) {
//       opacity.value = i;
//       await Future.delayed(Duration(milliseconds: 10));
//     }
//     entry.remove();
//   });
// }
//
// void errToast(BuildContext context, String message) {
//   final overlay = Overlay.of(context);
//   final opacity = ValueNotifier<double>(0.0);
//   late OverlayEntry entry;
//
//   entry = OverlayEntry(
//     builder: (context) {
//       return Positioned(
//         bottom: 40,
//         left: 0,
//         right: 0,
//         child: ValueListenableBuilder<double>(
//           valueListenable: opacity,
//           builder: (context, value, child) {
//             return Opacity(
//                 opacity: value, // fade animation
//                 child: Transform.translate(
//                     offset: Offset(0, (1 - value) * 20), // slide animation
//                     child: child));
//           },
//           child: Center(
//             child: Material(
//               color: Colors.transparent,
//               child: Padding(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Container(
//                   // constraints: BoxConstraints(maxWidth: 260),
//                   padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
//                   decoration: BoxDecoration(
//                     color: MyTheme.mainOrangeColor,
//                     borderRadius: BorderRadius.circular(10),
//                     boxShadow: [
//                       BoxShadow(
//                           color: Colors.black26,
//                           blurRadius: 12,
//                           offset: Offset(0, 4))
//                     ],
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Image.asset("assets/images/Group 1000003375.png",
//                           width: 30, height: 30),
//                       SizedBox(width: 10),
//                       Flexible(
//                           child: Text(message,
//                               style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.w500))),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       );
//     },
//   );
//
//   overlay.insert(entry);
//
//   // 👉 Fade In (0 → 1)
//   Future.microtask(() async {
//     for (double i = 0; i <= 1; i += 0.05) {
//       opacity.value = i;
//       await Future.delayed(Duration(milliseconds: 10));
//     }
//   });
//
//   // 👉 Wait then Fade Out (1 → 0)
//   Future.delayed(Duration(seconds: 2)).then((_) async {
//     for (double i = 1; i >= 0; i -= 0.05) {
//       opacity.value = i;
//       await Future.delayed(Duration(milliseconds: 10));
//     }
//     entry.remove();
//   });
// }
