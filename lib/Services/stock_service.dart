import 'dart:convert';
import 'package:http/http.dart' as http;

class StockService {
  final String apiKey = 'BER703A7EOC2P4AK'; // Replace with your Alpha Vantage API key

  Future<Map<String, dynamic>> fetchStockData(String symbol) async {
    final url = 'https://www.alphavantage.co/query?function=TIME_SERIES_INTRADAY&symbol=$symbol&interval=1min&apikey=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load stock data');
    }
  }
}

