import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class CloudinaryService {
  final String cloudName = ""; // Your Cloud Name
  final String apiKey = ""; // Your API Key
  final String apiSecret = ""; // Your API Secret
  final String uploadPreset = ""; // Your upload preset

  Future<String?> uploadImage(File image) async {
    final String url = "https://api.cloudinary.com/v1_1/$cloudName/image/upload";

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000; // Use seconds, not milliseconds

      // Generate signature
      final String signature = _generateSignature({
        'timestamp': timestamp.toString(),
        'upload_preset': uploadPreset,
      });

      // Prepare multipart request
      final request = http.MultipartRequest("POST", Uri.parse(url));
      request.fields['upload_preset'] = uploadPreset;
      request.fields['api_key'] = apiKey;
      request.fields['timestamp'] = timestamp.toString();
      request.fields['signature'] = signature;
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      // Send the request
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final jsonResponse = jsonDecode(responseData.body);
        return jsonResponse["secure_url"]; // Return the secure URL
      } else {
        print("Cloudinary upload failed: ${response.reasonPhrase}");
        return null;
      }
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  String _generateSignature(Map<String, String> params) {
    final sortedParams = params.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key)); // Sort by key
    final paramString = sortedParams
        .map((e) => "${e.key}=${e.value}")
        .join("&"); // Generate query string
    final bytes = utf8.encode(paramString + apiSecret); // Append API secret
    return sha1.convert(bytes).toString(); // Generate SHA-1 hash
  }
}
