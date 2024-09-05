import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../Models/stock.dart';
import '../Services/stock_service.dart';

class ChartScreen extends StatefulWidget {
  final Stock stock;

  ChartScreen({required this.stock});

  @override
  _ChartScreenState createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  int _timeFrame = 1; // 1 day, 1 week, 1 month
  List<FlSpot> _chartData = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchStockData();
  }

  Future<void> _fetchStockData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final stockService = StockService();
      final data = await stockService.fetchStockData(widget.stock.symbol);

      print('API Response: $data');

      if (data.isNotEmpty) {
        setState(() {
          _chartData = _mapApiDataToChartSpots(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No data available for the selected time frame.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load stock data: $e';
      });
      print(_errorMessage);
    }
  }

  List<FlSpot> _mapApiDataToChartSpots(Map<String, dynamic> apiData) {
    List<FlSpot> spots = [];
    final timeSeries = apiData['Time Series (1min)'] ?? {};

    if (timeSeries.isEmpty) {
      print('No data available');
      return spots;
    }

    int index = 0;
    timeSeries.forEach((timestamp, values) {
      try {
        final price = double.parse(values['4. close']); // Use closing price
        spots.add(FlSpot(index.toDouble(), price));
        index++;
      } catch (e) {
        print('Error parsing data: $e');
      }
    });

    return spots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stock.symbol),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage))
          : _chartData.isEmpty
          ? Center(child: Text('No data available'))
          : SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ToggleButtons(
                isSelected: [
                  _timeFrame == 1,
                  _timeFrame == 2,
                  _timeFrame == 3,
                ],
                onPressed: (int index) {
                  setState(() {
                    _timeFrame = index + 1;
                    _fetchStockData(); // Fetch new data when time frame changes
                  });
                },
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('1 day'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('1 week'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('1 month'),
                  ),
                ],
                borderRadius: BorderRadius.circular(10.0),
                color: Colors.blueGrey,
                selectedColor: Colors.white,
                fillColor: Colors.blueAccent,
                splashColor: Colors.blue,
                highlightColor: Colors.blue.withOpacity(0.2),
                borderColor: Colors.blueGrey,
              ),
            ),
            Container(
              height: 550,
              width: 450,
              padding: const EdgeInsets.fromLTRB(8.0, 40, 8, 30),
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: _chartData,
                      isCurved: true,
                      barWidth: 3,
                      belowBarData: BarAreaData(show: false),
                      color: Colors.orange,
                      dotData: FlDotData(show: true),
                      aboveBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.withOpacity(0.2),
                            Colors.transparent
                          ],
                          stops: [0.5, 1.0],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('');
                        },
                        interval: _getIntervaly(),
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.min || value == meta.max) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text('${value.toStringAsFixed(1)}'),
                          );
                        },
                        interval: _getIntervaly(),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: _getInterval(),
                        getTitlesWidget: (value, meta) {
                          if (_timeFrame == 1) {
                            int hours = 9 + (value ~/ 10).toInt();
                            if (hours >= 9 && hours <= 15) {
                              return Text('${hours.toString().padLeft(2, '0')}:00');
                            }
                            return Container();
                          } else if (_timeFrame == 2) {
                            // Ensure value is within 7 days
                            int dayIndex = value.toInt() % 7;
                            List<String> daysOfWeek = ['0d', '1d', '2d', '3d', '4d', '5d', '6d', '7d'];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(daysOfWeek[dayIndex]),
                            );
                          } else {
                            int weekNumber = (value.toInt() ~/ 7) + 1;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('${weekNumber}w'),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey, width: 1),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 10,
                    verticalInterval: 1,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 50, 13, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    height: 50,
                    width: 150,
                    child: ElevatedButton(
                      onPressed: () {
                        // Add to Cart functionality
                      },
                      child: Text(
                        'SELL',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 50,
                    width: 150,
                    child: ElevatedButton(
                      onPressed: () {
                        // Add to Cart functionality
                      },
                      child: Text(
                        'BUY',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getInterval() {
    if (_timeFrame == 1) {
      return 15.0;
    } else if (_timeFrame == 2) {
      return 15.0;
    } else {
      return 17.0;
    }
  }

  double _getIntervaly() {
    if (_timeFrame == 1) {
      return 1.0;
    } else if (_timeFrame == 2) {
      return 2.0;
    } else {
      return 1.0;
    }
  }
}
