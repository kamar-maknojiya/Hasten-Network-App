import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vision_broadband/networking/api_url.dart';
import 'package:vision_broadband/screens/auth/LoginScreen.dart';
import 'package:vision_broadband/widgets/AppConfig.dart';
import 'package:vision_broadband/widgets/toast_massage.dart';

class BaseClient {
  var client = http.Client();

  // BaseClient() {
  //
  //   check().then((intenet) async {
  //     if (!intenet) {
  //       errToast(context,'Please check your internet connectivity!');
  //     }
  //   });
  // }

  // Future<dynamic> get(String api, context) async {
  //   var prefs = await SharedPreferences.getInstance();
  //   var url = Uri.parse(api);
  //   var token = prefs.getString('token');
  //   var _headers = {
  //     "Accept": "application/json",
  //     'Authorization': 'Bearer ${token!}',
  //   };
  //   print('token : $token');
  //   var response = await client.get(url, headers: _headers);
  //   // return jsonDecode(response.body);
  //   print("URL==$url");
  //   if (response.statusCode == 200 || response.statusCode == 201) {
  //     print("Response==${response.body}");
  //     return jsonDecode(response.body);
  //   } else if (response.statusCode == 401) {
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (context) => LoginScreen()),
  //     );
  //     errToast("Error! Please login again.");
  //   }
  // }

  Future<dynamic> get(String api, context) async {
    if (api != GET_SITE_SETTINGS) {
      refreshCurrency(context);
    }
    var prefs = await SharedPreferences.getInstance();
    var url = Uri.parse(api);
    var token = prefs.getString('token');
    var headers = {
      "Accept": "application/json",
      "Authorization": "Bearer ${token!}",
      'Content-Type': 'application/json',
    };
    print("token : $token");
    var response = await client.get(url, headers: headers);
    print("URL :: $url");
    print("STATUS CODE :: ${response.statusCode}");
    print("RESPONSE :: ${response.body}");
    if (response.statusCode == 401) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      errToast("Error! Please login again.");
      return null;
    }
    // if (api != GET_SITE_SETTINGS) {
    //   refreshCurrency(context);
    // }
    return jsonDecode(response.body);
  }

  Future<dynamic> authGet(String api, context) async {
    var url = Uri.parse(api);
    var _headers = {"Accept": "application/json"};
    var response = await client.get(url, headers: _headers);
    print("URL :: $url");
    print("STATUS CODE :: ${response.statusCode}");
    print("RESPONSE :: ${response.body}");
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      errToast("Error! Please login again.");
    }
  }

  Future<dynamic> authPost(String api, dynamic payload, context) async {
    var url = Uri.parse(api);
    var _headers = {"Accept": "application/json"};
    try {
      var response = await client.post(url, body: payload, headers: _headers);
      print("URL :: $url");
      print("PAYLOAD :: $payload");
      print("STATUS CODE :: ${response.statusCode}");
      print("RESPONSE :: ${response.body}");
      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 400) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
        errToast("Error! Please login again.");
        // final bodyStr = await response.stream.bytesToString();
        // print(bodyStr);
        // return jsonDecode(bodyStr);
      }
    } on Exception catch (e) {
      print(e);
    }
  }

  Future<dynamic> post(String api, dynamic payload, context) async {
    var url = Uri.parse(api);
    var prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');
    var _headers = {
      "Accept": "application/json",
      'Authorization': 'Bearer ' + token!,
    };
    var response = await client.post(url, body: payload, headers: _headers); //
    print("URL :: $url");
    print("PAYLOAD :: $payload");
    print("STATUS CODE :: ${response.statusCode}");
    print("RESPONSE :: ${response.body}");

    if (response.statusCode == 401) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      errToast("Error! Please login again.");
    } else {
      return jsonDecode(response.body);
    }
    // if (response.statusCode == 200 ||
    //     response.statusCode == 201 ||
    //     response.statusCode == 400 ||
    //     response.statusCode == 500) {
    //   // print("Response==${response.body}");
    //   return jsonDecode(response.body);
    // } else if (response.statusCode == 401) {
    //   Navigator.pushReplacement(
    //     context,
    //     MaterialPageRoute(builder: (context) => LoginScreen()),
    //   );
    //   errToast("Error! Please login again.");
    //   // final bodyStr = await response.stream.bytesToString();
    //   // print(bodyStr);
    //   // return jsonDecode(bodyStr);
    // }
  }

  Future<dynamic> postB(
    String api,
    dynamic payload,
    BuildContext context,
  ) async {
    try {
      var url = Uri.parse(api);

      var prefs = await SharedPreferences.getInstance();
      var token = prefs.getString('token');

      var headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };

      print("URL :: $url");
      print("PAYLOAD :: ${jsonEncode(payload)}");

      final response = await client.post(
        url,
        headers: headers,
        body: jsonEncode(payload),
      );

      print("STATUS CODE :: ${response.statusCode}");
      print("RESPONSE :: ${response.body}");

      if (response.statusCode == 401) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
        );

        errToast("Please login again");
        return null;
      }

      return jsonDecode(response.body);
    } catch (e) {
      print("POST ERROR :: $e");
      rethrow;
    }
  }

  // Future<dynamic> postJsonArray(
  //     String api, Map<String, dynamic> payload, BuildContext context) async {
  //   var url = Uri.parse(api);
  //   var prefs = await SharedPreferences.getInstance();
  //   var token = prefs.getString('token');
  //
  //   var headers = {
  //     "Accept": "application/json",
  //     "Content-Type": "application/json", // ⭐ IMPORTANT
  //     "Authorization": "Bearer $token",
  //   };
  //
  //   print("URL :: $url");
  //   print("PAYLOAD :: ${jsonEncode(payload)}");
  //   print("TOKEN :: $token");
  //
  //   var response = await client.post(
  //     url,
  //     headers: headers,
  //     body: jsonEncode(payload), // ⭐ JSON ENCODE
  //   );
  //
  //   print("STATUS CODE :: ${response.statusCode}");
  //   print("RAW BODY :: ${response.body}");
  //
  //   // HTML protection
  //   if (response.body.trim().startsWith('<')) {
  //     return {
  //       "status": false,
  //       "message": "Server returned HTML instead of JSON",
  //     };
  //   }
  //
  //   return jsonDecode(response.body);
  // }

  Future<dynamic> multipost(String api, dynamic payload, context) async {
    var url = Uri.parse(api);
    var prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');

    var _headers = {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
    print('token : $token');
    try {
      var response = await client.post(
        url,
        headers: _headers,
        body: jsonEncode(payload),
      );
      print("URL==$url");
      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 400) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
        errToast("Error! Please login again.");
      } else {
        errToast("Unexpected error! ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Exception: $e");
      errToast("Something went wrong!");
      return null;
    }
  }

  Future<dynamic> postJson(String api, dynamic payload, context) async {
    var url = Uri.parse(api);
    var prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');
    var _headers = {
      "Accept": "application/json",
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token!}',
    };
    print('token : $token');
    var response = await client.post(
      url,
      body: jsonEncode(payload),
      headers: _headers,
    );
    print("URL :: $url");
    print("STATUS CODE :: ${response.statusCode}");
    print("RESPONSE :: ${response.body}");
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 400 ||
        response.statusCode == 404 ||
        response.statusCode == 302) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      errToast("Error! Please login again.");
      // final bodyStr = await response.stream.bytesToString();
      // print(bodyStr);
      // return jsonDecode(bodyStr);
    }
  }

  Future<dynamic> patch(String api, dynamic payload, context) async {
    var url = Uri.parse(api);
    var prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');
    var _headers = {
      "Accept": "application/json",
      'Authorization': 'Bearer ${token!}',
    };
    var response = await client.patch(url, body: payload, headers: _headers); //
    print("URL==$url");
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 400) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      errToast("Error! Please login again.");
      // final bodyStr = await response.stream.bytesToString();
      // print(bodyStr);
      // return jsonDecode(bodyStr);
    }
  }

  Future<dynamic> delete(String api, context) async {
    var url = Uri.parse(api);
    var prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');
    var _headers = {
      "Accept": "application/json",
      'Authorization': 'Bearer ${token!}',
    };
    var response = await client.delete(url, headers: _headers);
    print("URL==$url");
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      errToast("Error! Please login again.");
      // final bodyStr = await response.stream.bytesToString();
      // print(bodyStr);
      // return jsonDecode(bodyStr);
    }
  }

  // Future<dynamic> multipartRequest(String api, dynamic body, Map<String, File?> files, context) async {
  //   var uri = Uri.parse(api);
  //   final request = await http.MultipartRequest('POST', uri);
  //   Map<String, dynamic> params = body as Map<String, dynamic>;
  //   var prefs = await SharedPreferences.getInstance();
  //   var token = prefs.getString('token');
  //   request.headers['Accept'] = "application/json";
  //   request.headers['Authorization'] = 'Bearer ${token!}';
  //   params.forEach((key, value) {
  //     request.fields[key] = value;
  //   });
  //   files.forEach((key, file) {
  //     request.files.add(
  //       http.MultipartFile.fromBytes(
  //         key,
  //         File(file!.path).readAsBytesSync(),
  //         filename: file.path.split("/").last),
  //     );
  //   });
  //   var response = await request.send();
  //   print("URL==$uri");
  //   if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 400) {
  //     final bodyStr = await response.stream.bytesToString();
  //     return jsonDecode(bodyStr);
  //   } else if (response.statusCode == 401) {
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (context) => LoginScreen()),
  //     );
  //     errToast("Error! Please login again.");
  //   }
  // }

  Future<dynamic> multipartRequest(
    String api,
    dynamic body,
    Map<String, File?> files,
    BuildContext context,
  ) async {
    try {
      var uri = Uri.parse(api);

      var prefs = await SharedPreferences.getInstance();
      var token = prefs.getString('token');

      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      });

      /// Add Fields
      Map<String, dynamic> params = body as Map<String, dynamic>;

      params.forEach((key, value) {
        request.fields[key] = value?.toString() ?? "";
      });

      /// Add Files
      for (var entry in files.entries) {
        final file = entry.value;

        if (file != null && await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath(entry.key, file.path),
          );
        }
      }

      print("========================================");
      print("MULTIPART REQUEST");
      print("URL => $uri");
      print("FIELDS => ${request.fields}");
      print("FILES => ${request.files.length}");

      for (var file in request.files) {
        print("FILE => ${file.field} : ${file.filename}");
      }

      print("========================================");

      final streamedResponse = await request.send();

      final responseBody = await streamedResponse.stream.bytesToString();

      print("========================================");
      print("STATUS CODE => ${streamedResponse.statusCode}");
      print("RESPONSE => $responseBody");
      print("========================================");

      if (responseBody.isNotEmpty) {
        final jsonResponse = jsonDecode(responseBody);

        if (streamedResponse.statusCode == 401) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );

          errToast("Session expired. Please login again.");
        }

        return jsonResponse;
      }

      return {"status": false, "message": "Empty response from server"};
    } catch (e, s) {
      print("========================================");
      print("MULTIPART ERROR => $e");
      print("STACKTRACE => $s");
      print("========================================");

      return {"status": false, "message": e.toString()};
    }
  }

  Future<void> refreshCurrency(BuildContext context) async {
    try {
      var prefs = await SharedPreferences.getInstance();
      var token = prefs.getString('token');

      var response = await client.get(
        Uri.parse(GET_SITE_SETTINGS),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        await prefs.setString('site_mobile_no', data["data"]['site_mobile_no']);
        String currency = data["data"]["site_currency"] ?? "\$";

        // Update only if changed
        if (AppConfig.siteCurrency != currency) {
          AppConfig.siteCurrency = currency;
          await prefs.setString("site_currency", currency);

          print("Currency Updated => $currency");
        }
      }
    } catch (e) {
      print("Currency API Error => $e");
    }
  }

  Future<Uint8List?> downloadInvoicePdf(
    String api,
    BuildContext context,
  ) async {
    try {
      var url = Uri.parse(api);
      var prefs = await SharedPreferences.getInstance();
      var token = prefs.getString('token');
      var headers = {"Authorization": "Bearer $token"};
      final request = http.Request("GET", url);
      request.headers.addAll(headers);
      final streamedResponse = await client.send(request);
      if (streamedResponse.statusCode == 200) {
        return await streamedResponse.stream.toBytes();
      } else if (streamedResponse.statusCode == 401) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
        errToast("Error! Please login again.");
      }
    } catch (e) {
      print("PDF Download Error :: $e");
    }
    return null;
  }

  Future<dynamic> downloadFile(String api, dynamic payload, context) async {
    var url = Uri.parse(api);
    var prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');
    var _headers = {'Authorization': 'Bearer ${token!}'};
    var response = await client.post(url, body: payload, headers: _headers);
    print("URL==$url");
    if (response.statusCode == 200 || response.statusCode == 400) {
      return response.body;
    } else if (response.statusCode == 401) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      errToast("Error! Please login again.");
    }
  }

  Future<dynamic> downloadFileForinvoice(String api, context) async {
    var url = Uri.parse(api);
    var prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('token');
    var _headers = {'Authorization': 'Bearer ${token!}'};
    print('_headers :: $_headers');
    var response = await client.get(url, headers: _headers);
    print("URL==$url");
    if (response.statusCode == 200 || response.statusCode == 400) {
      return response.body;
    } else if (response.statusCode == 401) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      errToast("Error! Please login again.");
    }
  }
}
