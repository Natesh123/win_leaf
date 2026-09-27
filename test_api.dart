import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  String baseUrlWithSlash = 'https://winleafteas.com/';
  String baseUrlWithoutSlash = 'https://winleafteas.com';
  
  String consumerKey = 'ck_8188f9ed5b88b3f06b348c4e2f0adc2edeca50da';
  String consumerSecret = 'cs_57a0160062d4ba2cbb0ad4c8802becf95a7d5e1a';
  
  String creds = '$consumerKey:$consumerSecret';
  String encoded = base64Encode(utf8.encode(creds));
  String authHeader = 'Basic $encoded';
  
  print('Testing getCustomerData with double slash...');
  var res1 = await http.get(
    Uri.parse('$baseUrlWithSlash/wp-json/wc/v3/customers/1'),
    headers: {
      'Authorization': authHeader,
      'Content-Type': 'application/json',
    },
  );
  print('Double Slash Status: ${res1.statusCode}');
  // print('Double Slash Body: ${res1.body}');
  
  print('Testing getCustomerData with single slash...');
  var res2 = await http.get(
    Uri.parse('$baseUrlWithoutSlash/wp-json/wc/v3/customers/1'),
    headers: {
      'Authorization': authHeader,
      'Content-Type': 'application/json',
    },
  );
  print('Single Slash Status: ${res2.statusCode}');
  // print('Single Slash Body: ${res2.body}');

  print('Testing getSubscriptions with double slash...');
  var res3 = await http.get(
    Uri.parse('$baseUrlWithSlash/wp-json/wc/v1/subscriptions?customer=1'),
    headers: {
      'Authorization': authHeader,
      'Content-Type': 'application/json',
    },
  );
  print('Subscriptions Double Slash Status: ${res3.statusCode}');
  // print('Subscriptions Double Slash Body: ${res3.body}');
}
