import 'package:to_csv/to_csv.dart' as exportCSV;

List<String> header = ['time', 'state', 'prox', 'dist', 'computed angle'];

List<List<String>> listOfLists = []; //Outter List which contains the data List
List<String> data1 = [
  '1',
  'Bilal Saeed',
  '1374934',
  '912839812'
]; //Inner list which contains Data i.e Row
List<String> data2 = [
  '2',
  'Ahmar',
  '21341234',
  '192834821'
]; //Inner list which contains Data i.e Row
List<String> data3 = ['2', 'Ahmar', '21341234', '192834821'];
List<String> data4 = ['2', 'Ahmar', '21341234', '192834821'];
