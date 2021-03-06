import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _toDoList = [];

  Map<String, dynamic> ultimoRemovido;
  int _posUltimoRemovido;

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  final toDoController = TextEditingController();

  void addTodo() {
    setState(() {
      if (toDoController.text != '') {
        Map<String, dynamic> newTodo = Map();
        newTodo['title'] = toDoController.text;
        newTodo['ok'] = false;
        _toDoList.add(newTodo);
        _saveData();
        toDoController.clear();
      }
    });
  }

  Future<Null> refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _toDoList.sort((a, b) {
        if (a['ok'] && !b['ok'])
          return 1;
        else if (!a['ok'] && b['ok'])
          return -1;
        else
          return 0;
      });

      _saveData();
    });

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de tarefas'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(20, 5, 20, 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: toDoController,
                    decoration: InputDecoration(
                        labelText: 'Nova tarefa',
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  ),
                ),
                Container(
                    margin: EdgeInsets.only(top: 12, left: 10),
                    child: RaisedButton(
                      color: Colors.blueAccent,
                      child: Icon(Icons.add, size: 30),
                      textColor: Colors.white,
                      onPressed: addTodo,
                    ))
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
            onRefresh: refresh,
            child: ListView.builder(
                padding: EdgeInsets.only(top: 10),
                itemCount: _toDoList.length,
                itemBuilder: buildItem),
          ))
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      onDismissed: (direction) {
        setState(() {
          ultimoRemovido = Map.from(_toDoList[index]);
          _posUltimoRemovido = index;
          _toDoList.removeAt(index);

          _saveData();

          final snackBar = SnackBar(
            duration: Duration(seconds: 3),
            content: Text('Tarefa ${ultimoRemovido['title']}\' removida!'),
            action: SnackBarAction(
              label: 'Desfazer',
              onPressed: () {
                setState(() {
                  _toDoList.insert(_posUltimoRemovido, ultimoRemovido);
                  _saveData();
                });
              },
            ),
          );

          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snackBar);
        });
      },
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]['title']),
        value: _toDoList[index]['ok'],
        onChanged: (c) {
          setState(() {
            _toDoList[index]['ok'] = c;
            _saveData();
          });
        },
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]['ok'] ? Icons.check : Icons.error),
        ),
      ),
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/data.json');
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();

    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
