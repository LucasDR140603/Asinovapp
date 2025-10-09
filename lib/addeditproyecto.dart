import 'dart:convert';

import 'package:asinovapp/input.dart';
import 'package:asinovapp/variables.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
class AddEditProyecto extends StatefulWidget {
  final List<dynamic>? clientes;
  final List<dynamic>? centros;
  final dynamic proyecto;
  final dynamic usuario;
  final Function(dynamic)? guardar;
  final Function(List<dynamic>,List<dynamic>)? guardar2;
  const AddEditProyecto({super.key,this.clientes,this.centros,this.proyecto,this.usuario,this.guardar,this.guardar2});
  @override
  State<AddEditProyecto> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<AddEditProyecto> {
  late dynamic usuario=widget.usuario!;
  late List<dynamic> clientes=widget.clientes!;
  late List<dynamic> centros=widget.centros!;
  late Function(dynamic) guardar=widget.guardar!;
  late Function(List<dynamic>,List<dynamic>) guardar2=widget.guardar2!;
  dynamic cliente=null;
  dynamic centro=null;
  late dynamic proyecto=widget.proyecto;
  List<dynamic> clientes_con_centros=[];
  dynamic getClienteByCentro(dynamic x){
    return clientes.where((y)=>x['id_cliente']==y['id']).toList()[0];
  }
  dynamic getCentroByProyecto(dynamic x){
    return centros.where((y)=>x['id_centro']==y['id']).toList()[0];
  }
  dynamic getClienteByProyecto(dynamic x){
    return getClienteByCentro(getCentroByProyecto(x));
  }
  @override
  void initState(){
    super.initState();
    set();
  }
  void set(){
    setState((){
      clientes_con_centros=clientes.where((x)=>centros.where((y)=>y['id_cliente']==x['id']).toList().isNotEmpty).toList();
      centro=centros.where((x)=>x['id']==proyecto['id_centro']).toList()[0];
      cliente=getClienteByCentro(centro);
    });
  }
  void setCliente(dynamic x){
    setState((){
      cliente=x;
      centro=centros.where((x)=>x['id_cliente']==cliente['id']).toList()[0];
    });
  }
  void setCentro(dynamic x){
    setState((){
      centro=x;
    });
  }
  void addCliente(){
    String id_cliente=Uuid().v4();
    String id_centro=Uuid().v4();
    Map<String,dynamic> cli={
      "id":id_cliente,
      "nombre":"",
      "abierto":true
    };
    Map<String,dynamic> cen={
      "id":id_centro,
      "nombre":"",
      "id_cliente":id_cliente,
      "abierto":true
    };
    showDialog(barrierDismissible: false,context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Añadir cliente"),
        content: column([
          Input(label: "Cliente",value: cli['nombre'],change: (s){setState((){cli['nombre']=s;});},),
          Input(label: "Centro",value: cen['nombre'],change: (s){setState((){cen['nombre']=s;});},),
        ]),
        actions: [TextButton(onPressed: (){Navigator.of(context).pop();}, child: Text("Cancelar")),TextButton(onPressed: (){
          Navigator.of(context).pop();
          if (vacio(cli['nombre']) || vacio(cen['nombre'])){
            error(context, "Faltan Campos");
          }
          else{
            postCliente(cli,cen);
          }
        }, child: Text("Confirmar"))],
      );
    });
  }
  void addCentro(String id_cliente){
    String id_centro=Uuid().v4();
    Map<String,dynamic> cen={
      "id":id_centro,
      "nombre":"",
      "id_cliente":id_cliente,
      "abierto":true
    };
    showDialog(barrierDismissible: false,context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Añadir centro"),
        content: column([
          Input(label: "Centro",value: cen['nombre'],change: (s){setState((){cen['nombre']=s;});},),
        ]),
        actions: [TextButton(onPressed: (){Navigator.of(context).pop();}, child: Text("Cancelar")),TextButton(onPressed: (){
          Navigator.of(context).pop();
          if (vacio(cen['nombre'])){
            error(context, "Faltan Campos");
          }
          else{
            postCentro(cen);
          }
        }, child: Text("Confirmar"))],
      );
    });
  }
  void postCliente(dynamic cli,dynamic cen){
    http.post(Uri.parse('${getUrlApi()}Clientes'),headers: {"Content-Type":"application/json"},body: jsonEncode(cli)).then((res)=>{
      if (res.statusCode==500){
        error(context, "Cliente ya existente")
      }
      else if (res.statusCode==204){
        http.post(Uri.parse('${getUrlApi()}Centros'),headers: {"Content-Type":"application/json"},body: jsonEncode(cen)).then((res2)=>{
        if (res2.statusCode==500){
          error(context, "Centro ya existente")
        }
        else if (res2.statusCode==204){
          clientes.add(cli),
          centros.add(cen),
          clientes.sort((x,y)=>x['nombre'].toString().compareTo(y['nombre'])),
          centros.sort((x,y)=>x['nombre'].toString().compareTo(y['nombre'])),
          centros.sort((x,y)=>clientes.where((z)=>z['id']==x['id_cliente']).toList()[0]['nombre'].toString().compareTo(clientes.where((z)=>z['id']==y['id_cliente']).toList()[0]['nombre'].toString())),
          setState((){
            cliente=cli;
            centro=cen;
          }),
          guardar2(clientes,centros),
          Navigator.of(context).pop(),
        }
        })
      }
    });
  }
  void postCentro(dynamic cen){
    http.post(Uri.parse('${getUrlApi()}Centros'),headers: {"Content-Type":"application/json"},body: jsonEncode(cen)).then((res)=>{
      if (res.statusCode==500){
        error(context, "Centro ya existente")
      }
      else if (res.statusCode==204){
        centros.add(cen),
        centros.sort((x,y)=>x['nombre'].toString().compareTo(y['nombre'])),
        centros.sort((x,y)=>clientes.where((z)=>z['id']==x['id_cliente']).toList()[0]['nombre'].toString().compareTo(clientes.where((z)=>z['id']==y['id_cliente']).toList()[0]['nombre'].toString())),
        setState((){
          centro=cen;
        }),
        guardar2(clientes,centros),
        Navigator.of(context).pop(),
      }
    });
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
            if (usuario['administrador'] && title=="Seleccionar Cliente")
            ElevatedButton(onPressed: (){addCliente();}, child: Text("Añadir Cliente")),
            if (usuario['administrador'] && title=="Seleccionar Centro")
            ElevatedButton(onPressed: (){addCentro(cliente['id']);}, child: Text("Añadir Centro")),
          ]),
        );
      });
    });
  }
  void setValores(){
    setState((){
      proyecto['id_centro']=centro['id'];
      if (vacio(proyecto['nombre']) || vacio(proyecto['descripcion'])){
        error(context,"Nombre y descripción obligatorios");
      }
      else{
        guardar(proyecto);
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return column(ph: 0,[
      column(barra: true,maxHeight: 500,spacing: 10,ph: 0,[
        selector((){openSelector(context, clientes_con_centros, cliente, (x){setCliente(x);}, "Seleccionar Cliente");}, "Cliente", cliente['nombre']),
        selector((){openSelector(context, centros.where((x)=>x['id_cliente']==cliente['id']).toList(), centro, (x){setCentro(x);}, "Seleccionar Centro");}, "Centro", centro['nombre']),
        Input(value: proyecto['nombre'],label: "Nombre",change:(s){setState((){proyecto['nombre']=s;});},),
        Input(value: proyecto['descripcion'],label: "Descripción",change:(s){setState((){proyecto['descripcion']=s;});},),
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [
        TextButton(onPressed: (){Navigator.of(context).pop();}, child: Text("Cancelar")),
        TextButton(onPressed: (){Navigator.of(context).pop();setValores();}, child: Text("Confirmar")),
      ],)
    ]);
  }
}