import 'package:flutter/material.dart';
import '../Models/stock.dart';
import '../services/stock_service.dart';

class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  final _searchController = TextEditingController();
  List<Stock> _searchResults = [];
  bool _isLoading = false; // To show a loading indicator
  final StockService _stockService = StockService();

  void _searchStocks(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('Fetching data for: $query');
      final stockData = await _stockService.fetchStockData(query);


      print('API Response: $stockData');


      final timeSeries = stockData['Time Series (1min)'];
      if (timeSeries != null && timeSeries.isNotEmpty) {
        final latestData = timeSeries.entries.first.value;
        final double currentPrice = double.parse(latestData['1. open']);
        final double percentageChange = ((currentPrice - double.parse(latestData['4. close'])) / double.parse(latestData['4. close'])) * 100;

        setState(() {
          _searchResults = [
            Stock(query, currentPrice, percentageChange),
          ];
          _isLoading = false;
        });

        print('Stock added: $query, $currentPrice, $percentageChange%'); // Debugging
      } else {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
        print('No time series data available');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      print('Error fetching stock data: $e'); // Debugging
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load stock data')));
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Stock'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for a stock',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => _searchStocks(_searchController.text),
                ),
              ),
              onChanged: (query) {
                if (query.isEmpty) {
                  setState(() {
                    _searchResults = [];
                  });
                }
              },
            ),
            SizedBox(height: 16),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : Expanded(
              child: ListView.separated(
                itemCount: _searchResults.length,
                separatorBuilder: (context, index) => Divider(color: Colors.grey[300]),
                itemBuilder: (context, index) {
                  final stock = _searchResults[index];
                  print(stock.symbol);
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 3.0),
                    title: Text(stock.symbol, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${stock.currentPrice} (${stock.percentageChange.toStringAsFixed(2)}%)',
                      style: TextStyle(
                        color: stock.percentageChange >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.add, color: Colors.green),
                      onPressed: () {
                        Navigator.pop(context, stock);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
