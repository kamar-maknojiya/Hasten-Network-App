import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vision_broadband/networking/api_url.dart';

/// ---------------------------------------------------------------------------
///  KYC SERVICE  (Subscriber API: "13 KYC")
///
///   GET  /kyc-config                   -> show_ekyc, show_manual_kyc, ekyc_enabled,
///                                         vendor_type, max_file_size_kb,
///                                         allowed_file_types, documents[] (+ types)
///   GET  /kyc-details                  -> ekyc {kyc_status, is_verified, mismatch_message}
///                                         documents[] {document, selected_type, remaining, files[]}
///   POST /kyc/upload-document          -> document, document_type, files[]
///   POST /ekyc/verify                  -> type 1: ekyc_id + request_id (OTP sent)
///                                         type 2: link (DigiLocker)
///   POST /ekyc/submit-aadhaar-otp      -> ekyc_id, request_id, aadhaar_otp
///
///  Documents, document types, file limits and e-KYC availability all come
///  from /kyc-config, so nothing is hard-coded in the app.
///
///  e-KYC kyc_status : 0 Pending, 1 Verified, 2 Mobile not matched,
///                     3 Email not matched, 4 Mobile & Email not matched
///                     (server treats any status != 0 as done / is_verified)
///  e-KYC vendor_type: 1 OTP based, 2 DigiLocker (open link)
/// ---------------------------------------------------------------------------
class KycService {
  static const String configUrl = baseUrl + "/kyc-config";
  static const String detailsUrl = baseUrl + "/kyc-details";
  static const String uploadUrl = baseUrl + "/kyc/upload-document";
  static const String verifyUrl = baseUrl + "/ekyc/verify";
  static const String submitOtpUrl = baseUrl + "/ekyc/submit-aadhaar-otp";

  /// Last loaded config (used by the upload sheet for size / type limits).
  static KycConfig? lastConfig;

  /// Quick check from the permissions saved by the Home screen (no API call).
  static Future<KycPermissions> permissions() async {
    final prefs = await SharedPreferences.getInstance();
    bool on(String k) => prefs.get(k)?.toString() == "1";
    return KycPermissions(ekyc: on('ekyc'), manual: on('manual_kyc'));
  }

  static Future<Map<String, String>> _headers({bool json = false}) async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      'Authorization': 'Bearer ${prefs.getString('token') ?? ''}',
    };
  }

  static dynamic _decode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  static bool _ok(dynamic json) => json is Map && (json['status'] == true || json['status']?.toString() == '1');

  static String _msg(dynamic json) {
    if (json is! Map) return '';
    final m = json['message'];
    if (m != null && m.toString().isNotEmpty) return m.toString();
    final e = json['errors'];
    if (e is Map && e.isNotEmpty) {
      final v = e.values.first;
      return v is List && v.isNotEmpty ? v.first.toString() : v.toString();
    }
    return '';
  }

  static Map<String, dynamic> _data(dynamic json) =>
      json is Map && json['data'] is Map ? Map<String, dynamic>.from(json['data']) : <String, dynamic>{};

  // ---- GET /kyc-config ------------------------------------------------------
  static Future<KycConfig> fetchConfig() async {
    final res = await http.get(Uri.parse(configUrl), headers: await _headers()).timeout(const Duration(seconds: 30));
    print("KYC CONFIG :: ${res.statusCode} ${res.body}");
    final json = _decode(res.body);
    if (res.statusCode == 403) return lastConfig = KycConfig.none; // KYC not allowed for this site
    if (_ok(json)) return lastConfig = KycConfig.fromJson(_data(json));
    throw KycException(_msg(json));
  }

  // ---- GET /kyc-config + /kyc-details ---------------------------------------
  static Future<KycStatus> fetchStatus() async {
    final config = await fetchConfig();
    if (!config.perms.any) return KycStatus.empty(config);

    final res = await http.get(Uri.parse(detailsUrl), headers: await _headers()).timeout(const Duration(seconds: 30));
    print("KYC DETAILS :: ${res.statusCode} ${res.body}");
    final json = _decode(res.body);
    if (_ok(json)) return KycStatus.fromJson(_data(json), config);
    throw KycException(_msg(json));
  }

  // ---- POST /ekyc/verify ----------------------------------------------------
  /// vendor_type 1: pass [aadhaar]; returns ekycId + requestId (OTP sent).
  /// vendor_type 2: returns [EkycStart.link] to open in the browser.
  static Future<EkycStart> verify({String? aadhaar}) async {
    final res = await http
        .post(Uri.parse(verifyUrl),
            headers: await _headers(json: true),
            body: jsonEncode({if (aadhaar != null) 'document_number': aadhaar}))
        .timeout(const Duration(seconds: 45));
    print("EKYC VERIFY :: ${res.statusCode} ${res.body}");
    final json = _decode(res.body);
    if (!_ok(json)) throw KycException(_msg(json));

    final d = _data(json);
    final link = d['link']?.toString();
    final ekycId = d['ekyc_id']?.toString();
    final requestId = d['request_id']?.toString();
    final hasLink = link != null && link.isNotEmpty;
    if (!hasLink && (ekycId == null || requestId == null)) throw KycException(_msg(json));
    return EkycStart(
      vendorType: int.tryParse(d['vendor_type']?.toString() ?? ''),
      link: hasLink ? link : null,
      ekycId: ekycId,
      requestId: requestId,
      message: _msg(json),
    );
  }

  // ---- POST /ekyc/submit-aadhaar-otp ---------------------------------------
  static Future<String> submitOtp({required String ekycId, required String requestId, required String otp}) async {
    final res = await http
        .post(Uri.parse(submitOtpUrl),
            headers: await _headers(json: true),
            body: jsonEncode({
              'ekyc_id': int.tryParse(ekycId) ?? ekycId,
              'request_id': requestId,
              'aadhaar_otp': otp,
            }))
        .timeout(const Duration(seconds: 45));
    print("EKYC OTP :: ${res.statusCode} ${res.body}");
    final json = _decode(res.body);
    if (_ok(json)) return _msg(json);
    throw KycException(_msg(json));
  }

  // ---- POST /kyc/upload-document (multipart) --------------------------------
  static Future<String> upload({
    required KycCategory category,
    String? documentType,
    required List<File> files,
  }) async {
    final req = http.MultipartRequest('POST', Uri.parse(uploadUrl));
    req.headers.addAll(await _headers());
    req.fields['document'] = category.key;
    if (category.types.isNotEmpty && documentType != null) req.fields['document_type'] = documentType;
    for (final f in files) {
      req.files.add(await http.MultipartFile.fromPath('files[]', f.path));
    }
    final streamed = await req.send().timeout(const Duration(seconds: 120));
    final body = await streamed.stream.bytesToString();
    print("KYC UPLOAD :: ${streamed.statusCode} $body");
    final json = _decode(body);
    if (_ok(json)) return _msg(json);
    throw KycException(_msg(json));
  }
}

class KycException implements Exception {
  final String message;
  KycException(this.message);
  @override
  String toString() => message.isEmpty ? "Something went wrong. Please try again." : message;
}

class KycPermissions {
  final bool ekyc;
  final bool manual;
  const KycPermissions({required this.ekyc, required this.manual});
  bool get any => ekyc || manual;
}

/// GET /kyc-config
class KycConfig {
  final bool showEkyc; // show_ekyc && ekyc_enabled
  final bool showManual; // show_manual_kyc && documents not empty
  final int? vendorType;
  final int maxFileKb;
  final List<String> allowedTypes;
  final List<KycCategory> documents;

  const KycConfig({
    required this.showEkyc,
    required this.showManual,
    this.vendorType,
    this.maxFileKb = 5120,
    this.allowedTypes = const ['jpg', 'jpeg', 'png', 'pdf'],
    this.documents = const [],
  });

  static const none = KycConfig(showEkyc: false, showManual: false);

  KycPermissions get perms => KycPermissions(ekyc: showEkyc, manual: showManual);
  int get maxFileBytes => maxFileKb * 1024;
  String get maxFileText {
    final mb = maxFileKb / 1024;
    return mb == mb.roundToDouble() ? "${mb.round()} MB" : "${mb.toStringAsFixed(1)} MB";
  }

  bool get allowsPdf => allowedTypes.contains('pdf');

  /// "JPG, PNG or PDF"
  String get typesText {
    final t = allowedTypes.map((e) => e.toUpperCase()).where((e) => e != 'JPEG').toList();
    if (t.length <= 1) return t.join();
    return "${t.sublist(0, t.length - 1).join(', ')} or ${t.last}";
  }

  factory KycConfig.fromJson(Map<String, dynamic> j) {
    bool b(dynamic v) => v == true || v?.toString() == '1' || v?.toString() == 'true';
    final docs = (j['documents'] is List ? j['documents'] as List : const [])
        .whereType<Map>()
        .map((d) => KycCategory.fromJson(Map<String, dynamic>.from(d)))
        .where((c) => c.key.isNotEmpty)
        .toList();
    final types = (j['allowed_file_types'] is List ? j['allowed_file_types'] as List : const [])
        .map((e) => e.toString().toLowerCase())
        .toList();
    return KycConfig(
      showEkyc: b(j['show_ekyc']) && b(j['ekyc_enabled']),
      showManual: b(j['show_manual_kyc']) && docs.isNotEmpty,
      vendorType: int.tryParse(j['vendor_type']?.toString() ?? ''),
      maxFileKb: int.tryParse(j['max_file_size_kb']?.toString() ?? '') ?? 5120,
      allowedTypes: types.isEmpty ? const ['jpg', 'jpeg', 'png', 'pdf'] : types,
      documents: docs,
    );
  }
}

/// KYC rules for the app (from /kyc-config + /kyc-details):
///  - e-KYC needed when show_ekyc && ekyc_enabled; done when verified without mismatch
///  - documents needed when show_manual_kyc; done when every document has a file
///    (2nd file of ID / address proof is optional, offered with "Add back")
///  - both on -> KYC complete only when BOTH are done (subscriber can do them in any order)
///  - mismatch (kyc_status 2/3/4) -> shown as "e-KYC details don't match", never counted as complete
class KycPlan {
  final bool needsEkyc;
  final bool needsDocs;
  final bool ekycDone;
  final bool docsDone;
  final bool mismatch;
  final int docsUploaded;
  final int docsTotal;

  const KycPlan({
    required this.needsEkyc,
    required this.needsDocs,
    required this.ekycDone,
    required this.docsDone,
    required this.mismatch,
    required this.docsUploaded,
    required this.docsTotal,
  });

  bool get both => needsEkyc && needsDocs;
  bool get ekycLeft => needsEkyc && !ekycDone;
  bool get docsLeft => needsDocs && !docsDone;
  bool get done => !ekycLeft && !docsLeft && !(needsEkyc && mismatch);

  factory KycPlan.of(KycStatus s) {
    final p = s.perms;
    return KycPlan(
      needsEkyc: p.ekyc,
      needsDocs: p.manual,
      ekycDone: s.ekycVerified && !s.mismatch,
      docsDone: s.documentsDone,
      mismatch: p.ekyc && s.mismatch,
      docsUploaded: s.uploadedCount,
      docsTotal: s.documents.length,
    );
  }
}

/// Result of POST /ekyc/verify
class EkycStart {
  final int? vendorType;
  final String? link; // DigiLocker
  final String? ekycId; // OTP based
  final String? requestId;
  final String message;
  EkycStart({this.vendorType, this.link, this.ekycId, this.requestId, this.message = ''});
  bool get isLink => link != null && link!.isNotEmpty;
}

/// One document slot from /kyc-config "documents".
/// [key] is the API value for "document" (idproof, addressproof, photoproof, signatureproof).
class KycCategory {
  final String key;
  final String title;
  final int maxFiles;
  final List<String> types; // empty = no document_type needed

  const KycCategory(this.key, this.title, this.maxFiles, this.types);

  bool get isPhoto => key.toLowerCase().startsWith('photo');
  bool get isSignature => key.toLowerCase().startsWith('sign');

  factory KycCategory.fromJson(Map<String, dynamic> j) {
    final key = (j['document'] ?? '').toString();
    final label = (j['label'] ?? '').toString();
    return KycCategory(
      key,
      label.isEmpty ? key : _niceLabel(label),
      int.tryParse(j['max_files']?.toString() ?? '') ?? 1,
      (j['types'] is List ? j['types'] as List : const []).map((e) => e.toString()).toList(),
    );
  }

  /// "Id Proof" -> "ID proof", "Address Proof" -> "Address proof"
  static String _niceLabel(String s) {
    final words = s.trim().split(RegExp(r'\s+'));
    return [
      for (var i = 0; i < words.length; i++)
        words[i].toLowerCase() == 'id'
            ? 'ID'
            : i == 0
                ? words[i][0].toUpperCase() + words[i].substring(1).toLowerCase()
                : words[i].toLowerCase()
    ].join(' ');
  }

  @override
  bool operator ==(Object other) => other is KycCategory && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

class KycFile {
  final String url;
  final bool isPdf;
  const KycFile(this.url, this.isPdf);
}

/// One row from /kyc-details "documents", joined with its config.
class KycDocument {
  final KycCategory category;
  final String? documentType; // selected_type
  final List<KycFile> files;
  final int remaining;

  KycDocument({required this.category, this.documentType, this.files = const [], int? remaining})
      : remaining = remaining ?? category.maxFiles;

  bool get uploaded => files.isNotEmpty;
  int get fileCount => files.length;

  /// 1 of 2 files uploaded -> offer "Add back"
  bool get canAddMore => uploaded && remaining > 0 && category.maxFiles > 1;
}

/// GET /kyc-details (+ the config it was loaded with)
class KycStatus {
  final KycConfig config;

  /// 0 Pending, 1 Verified, 2 Mobile not matched, 3 Email not matched, 4 both
  final int kycStatus;

  /// is_verified from the server (true for any status != 0)
  final bool ekycVerified;
  final String mismatchMessage;
  final List<KycDocument> documents;

  KycStatus({
    required this.config,
    required this.kycStatus,
    required this.ekycVerified,
    this.mismatchMessage = '',
    required this.documents,
  });

  factory KycStatus.empty(KycConfig c) => KycStatus(config: c, kycStatus: 0, ekycVerified: false, documents: const []);

  KycPermissions get perms => config.perms;
  int? get vendorType => config.vendorType;
  bool get isDigilocker => vendorType == 2;

  /// e-KYC done, but Aadhaar mobile / email didn't match the account
  bool get mismatch => kycStatus >= 2;
  int get uploadedCount => documents.where((d) => d.uploaded).length;
  bool get documentsDone => documents.isNotEmpty && uploadedCount >= documents.length;

  /// Server message first (same as the portal), then a fallback.
  String get mismatchText {
    if (mismatchMessage.isNotEmpty) return mismatchMessage;
    switch (kycStatus) {
      case 2:
        return "Mobile number not verified in e-KYC Aadhaar card.";
      case 3:
        return "Email not verified in e-KYC Aadhaar card.";
      case 4:
        return "Mobile number and email not verified in e-KYC Aadhaar card.";
    }
    return '';
  }

  factory KycStatus.fromJson(Map<String, dynamic> j, KycConfig config) {
    // e-KYC (null when e-KYC is not enabled)
    final ek = j['ekyc'] is Map ? Map<String, dynamic>.from(j['ekyc']) : <String, dynamic>{};
    final status = int.tryParse(ek['kyc_status']?.toString() ?? '') ?? 0;
    final verified = ek['is_verified'] == true || status != 0;

    // documents: keep config order, fill in what the subscriber has uploaded
    final rows = <String, Map<String, dynamic>>{};
    for (final r in (j['documents'] is List ? j['documents'] as List : const []).whereType<Map>()) {
      rows[(r['document'] ?? '').toString()] = Map<String, dynamic>.from(r);
    }
    final docs = config.documents.map((c) {
      final r = rows[c.key];
      if (r == null) return KycDocument(category: c);
      final files = (r['files'] is List ? r['files'] as List : const [])
          .whereType<Map>()
          .map((f) => KycFile((f['url'] ?? '').toString(), f['is_pdf'] == true))
          .where((f) => f.url.isNotEmpty)
          .toList();
      final type = r['selected_type']?.toString();
      return KycDocument(
        category: c,
        documentType: (type == null || type.isEmpty) ? null : type,
        files: files,
        remaining: int.tryParse(r['remaining']?.toString() ?? ''),
      );
    }).toList();

    return KycStatus(
      config: config,
      kycStatus: status,
      ekycVerified: verified,
      mismatchMessage: (ek['mismatch_message'] ?? '').toString(),
      documents: docs,
    );
  }
}
