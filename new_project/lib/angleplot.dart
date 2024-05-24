import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class angleChart extends StatefulWidget {
  @override
  _angleChartState createState() => _angleChartState();
}

class _angleChartState extends State<angleChart> {
  final Map<String, List<FlSpot>> _data1 = {};
  final Map<String, List<FlSpot>> _data2 = {};
  final Map<String, List<FlSpot>> _data3 = {};

  Timer? _timer;
  int _counter = 0;

  bool _showLine1 = false;
  bool _showLine2 = false;
  bool _showLine3 = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initializeData() {
    _data1["Line1"] = List.generate(7, (index) => FlSpot(index.toDouble(), (index + 1).toDouble()));
    _data2["Line2"] = List.generate(7, (index) => FlSpot(index.toDouble(), (index + 2).toDouble()));
    _data3["Line3"] = List.generate(7, (index) => FlSpot(index.toDouble(), (index + 3).toDouble()));
  }

  void _updateData() {
    setState(() {
      _counter++;
      _data1["Line1"]!.add(FlSpot(_counter.toDouble(), (_counter % 10).toDouble()));
      _data2["Line2"]!.add(FlSpot(_counter.toDouble(), ((_counter + 2) % 10).toDouble()));
      _data3["Line3"]!.add(FlSpot(_counter.toDouble(), ((_counter + 3) % 10).toDouble()));

      if (_data1["Line1"]!.length > 10) {
        _data1["Line1"]!.removeAt(0);
      }
      if (_data2["Line2"]!.length > 10) {
        _data2["Line2"]!.removeAt(0);
      }
      if (_data3["Line3"]!.length > 10) {
        _data3["Line3"]!.removeAt(0);
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _updateData();
    });
  }

  LineChart _buildLineChart(List<FlSpot> spots, Color color) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d)),
        ),
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 360,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 4,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(show: false),
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dynamic Line Charts Example'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showLine1 = !_showLine1;
                  });
                },
                child: Text(_showLine1 ? 'Hide Line 1' : 'Show Line 1'),
              ),
              if (_showLine1) ...[
                Text('Line 1', style: TextStyle(fontSize: 20)),
                SizedBox(height: 16),
                Container(
                  height: 200,
                  child: _buildLineChart(_data1["Line1"]!, Colors.blue),
                ),
                SizedBox(height: 32),
              ],
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showLine2 = !_showLine2;
                  });
                },
                child: Text(_showLine2 ? 'Hide Line 2' : 'Show Line 2'),
              ),
              if (_showLine2) ...[
                Text('Line 2', style: TextStyle(fontSize: 20)),
                SizedBox(height: 16),
                Container(
                  height: 200,
                  child: _buildLineChart(_data2["Line2"]!, Colors.red),
                ),
                SizedBox(height: 32),
              ],
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showLine3 = !_showLine3;
                  });
                },
                child: Text(_showLine3 ? 'Hide Line 3' : 'Show Line 3'),
              ),
              if (_showLine3) ...[
                Text('Line 3', style: TextStyle(fontSize: 20)),
                SizedBox(height: 16),
                Container(
                  height: 200,
                  child: _buildLineChart(_data3["Line3"]!, Colors.green),
                ),
                SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/*
void main() => runApp(MaterialApp(
  home: angleChart(),
));
*/