import 'dart:convert';

import 'package:asinovapp/input.dart';
import 'package:asinovapp/variables.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
class AddEditCentro extends StatefulWidget {
  final List<dynamic>? clientes;
  final dynamic centro;
  final Function(dynamic)? guardar;
  final Function(List<dynamic>)? guardar2;
  const AddEditCentro({super.key,this.centro,this.clientes,this.guardar,this.guardar2});
  @override
  State<AddEditCentro> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<AddEditCentro> {
  late List<dynamic> clientes=widget.clientes!;
  late dynamic centro=widget.centro;
  dynamic cliente=null;
  late Function(dynamic) guardar=widget.guardar!;
  late Function(List<dynamic>) guardar2=widget.guardar2!;
  @override
  void initState(){
    super.initState();
    set();
  }
  void set(){
    setState((){
      cliente=clientes.where((x)=>x['id']==centro['id_cliente']).toList()[0];
    });
  }
  void setCliente(dynamic x){
    setState(() {
      cliente=x;
    });
  }
  void addCliente(){
    Map<String,dynamic> nuevo={
      "id":Uuid().v4(),
      "nombre":"",
      "abierto":true
    };
    showDialog(barrierDismissible: false,context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Añadir Cliente"),
        content: Input(value: nuevo['nombre'],label: "Nombre",change: (s){setState((){nuevo['nombre']=s;});},),
        actions: [TextButton(onPressed: (){Navigator.of(context).pop();}, child: Text("Cancelar")),TextButton(onPressed: (){Navigator.of(context).pop();postCliente(nuevo);}, child: Text("Confirmar"))],
      );
    });
  }
  void postCliente(dynamic x){
    if (vacio(x['nombre'])){
      error(context,"Nombre obligatorio");
    }
    else{
      http.post(Uri.parse('${getUrlApi()}Clientes'),headers: {"Content-Type":"application/json"},body: jsonEncode(x)).then((res)=>{
        if (res.statusCode==500){
          error(context,"Cliente ya existente")
        }
        else if (res.statusCode==204){
          clientes.add(x),
          clientes.sort((x,y)=>x['nombre'].toString().compareTo(y['nombre'])),
          setState((){
            cliente=x;
          }),
          guardar2(clientes),
          Navigator.of(context).pop(),
        }
      });
    }
  }
  openSelector(BuildContext context,List<dynamic> lista, dynamic actual,Function(dynamic o) f,String title){
    String busqueda="";
    showDialog(context: context, builder: (BuildContext context){
      return StatefulBuilder(builder: (context,setState){
        return AlertDialog(
          title: Text(title),
          content: Column(mainAxisSize: MainAxisSize.min,children:[
            Input(value: busqueda,hint: "Buscar",change: (s){setState((){busqueda=s;});},),
            column(maxHeight: 200,barra: true,List<Widget>.from(lista.where((x)=>x['nombre'].toString().contains(busqueda)).map((x)=>
              RadioMenuButton(value: x,groupValue: actual,onChanged: (val){f(val);Navigator.of(context).pop();},child: Text(x['nombre'])),
            ))),
            if (title=="Seleccionar Cliente")
            ElevatedButton(onPressed: (){addCliente();}, child: Text("Añadir Cliente")),
          ]),
        );
      });
    });
  }
  void setValores(){
    setState((){
      centro['id_cliente']=cliente['id'];
      guardar(centro);
    });
  }
  @override
  Widget build(BuildContext context) {
    return column(ph:0,[
      column(barra: true,maxHeight: 500,spacing: 10,ph: 0,[
        selector((){openSelector(context, clientes, cliente, setCliente, "Seleccionar Cliente");}, "Cliente", cliente['nombre']),
        Input(value: centro['nombre'],label: "Nombre",change: (s){setState((){centro['nombre']=s;});},)
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [
        TextButton(onPressed: (){Navigator.of(context).pop();}, child: Text("Cancelar")),
        TextButton(onPressed: (){Navigator.of(context).pop();setValores();}, child: Text("Confirmar")),
      ],)
    ]);
  }
}