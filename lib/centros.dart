import 'dart:convert';

import 'package:asinovapp/addeditcentro.dart';
import 'package:asinovapp/input.dart';
import 'package:asinovapp/radiobuttonlist.dart';
import 'package:asinovapp/variables.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
class Centros extends StatefulWidget {
  final Function(String)? filtrado;
  const Centros({super.key,this.filtrado});
  @override
  State<Centros> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Centros> {
  List<dynamic> clientes=[];
  List<String> ids_clientes=[];
  List<dynamic> centros=[];
  late Function(String) filtrado=widget.filtrado!;
  dynamic c=null;
  bool cargando=true;
  @override
  void initState(){
    super.initState();
    set();
  }
  dynamic getClienteByCentro(dynamic x){
    return clientes.where((y)=>x['id_cliente']==y['id']).toList()[0];
  }
  void set()async{
    clientes=await getLista("Clientes");
    clientes.sort((x,y)=>x['nombre'].toString().compareTo(y['nombre']));
    ids_clientes=List<String>.from(clientes.map((x)=>x['id']));
    centros=await getLista("Centros");
    centros.sort((x,y)=>x['nombre'].toString().compareTo(y['nombre']));
    centros.sort((x,y)=>getClienteByCentro(x)['nombre'].toString().compareTo(getClienteByCentro(y)['nombre']));
    setState((){
      cargando=false;
    });
  }
  void actualizar_clientes(List<String> ids,int index){
    setState((){
      ids_clientes=ids;
      filtrado("${clientes[index]['nombre']}");
    });
  }
  void limpiar(){
    setState((){
      ids_clientes=List.from(clientes.map((x)=>x['id']));
      filtrado("");
    });
  }
  void showClientes(){
    showDialog(context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Clientes"),
        content: RadiobuttonList(contexto: context,lista: clientes,ids: ids_clientes,actualizar: (ids,index){actualizar_clientes(ids,index);},)
      );
    });
  }
  void guardar(dynamic x){
    http.put(Uri.parse('${getUrlApi()}Centros'),headers: {"Content-Type":"application/json"},body: jsonEncode(x)).then((res)=>{
      if (res.statusCode==500){
          error(context,"Centro ya existente")
        }
        else if (res.statusCode==204){
          if (x['abierto']){
            centros[centros.indexWhere((y)=>y['id']==x['id'])]=x,
          }
          else{
            centros.removeAt(centros.indexWhere((y)=>y['id']==x['id'])),
          },
          centros.sort((x,y)=>x['nombre'].toString().compareTo(y['nombre'])),
          centros.sort((x,y)=>getClienteByCentro(x)['nombre'].toString().compareTo(getClienteByCentro(y)['nombre'])),
          setState((){
            
          }),
        }
    });
  }
  void guardar_nuevo(dynamic x){
    http.post(Uri.parse('${getUrlApi()}Centros'),headers: {"Content-Type":"application/json"},body: jsonEncode(x)).then((res)=>{
      if (res.statusCode==500){
          error(context,"Centro ya existente")
        }
        else if (res.statusCode==204){
          centros.add(x),
          centros.sort((x,y)=>x['nombre'].toString().compareTo(y['nombre'])),
          centros.sort((x,y)=>getClienteByCentro(x)['nombre'].toString().compareTo(getClienteByCentro(y)['nombre'])),
          setState((){
            
          }),
        }
    });
  }
  void guardar2(List<dynamic> cli){
    setState((){
      clientes=cli;
      List<String> ids_cli=ids_clientes;
      ids_clientes=List<String>.from(clientes.map((x)=>(!ids_cli.contains("") || ids_cli.contains(x['id']))?x['id']:""));
    });
  }
  void add(){
    Map<String,dynamic> x={
      "id":Uuid().v4(),
      "nombre":"",
      "id_cliente":clientes[0]['id'],
      "abierto":true
    };
    showDialog(barrierDismissible: false,context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Añadir centro"),
        content: AddEditCentro(centro: x,clientes: clientes,guardar: guardar_nuevo, guardar2: guardar2,),
      );
    });
  }
  void editar(dynamic x){
    showDialog(barrierDismissible: false,context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Editar ${x['nombre']}"),
        content: AddEditCentro(centro: x,clientes: clientes,guardar: guardar, guardar2: guardar2,),
      );
    });
  }
  void finalizar(dynamic x){
    x['abierto']=false;
    showDialog(context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Alerta"),
        content: Text("Va a finalizar un centro, ya no se mostrará así como tampoco sus proyectos y registros"),
        actions: [TextButton(onPressed: (){Navigator.of(context).pop();}, child: Text("Cancelar")),TextButton(onPressed: (){Navigator.of(context).pop();guardar(x);}, child: Text("Confirmar"))],
      );
    });
  }
  void eliminar(dynamic x){
    showDialog(context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Alerta"),
        content: Text("Va a eliminar un centro y con él sus proyectos y registros. Acción irreversible"),
        actions: [TextButton(onPressed: (){Navigator.of(context).pop();}, child: Text("Cancelar")),TextButton(onPressed: (){Navigator.of(context).pop();setState((){centros.remove(x);http.delete(Uri.https(url,'${api}Centros/${x['id']}'));});}, child: Text("Confirmar"))],
      );
    });
  }
  void seleccionar(dynamic x){
    setState((){
      c=x;
      showDialog(context: context, builder: (BuildContext context){
        return AlertDialog(
          content: column([
            ListTile(title: Text("Editar"),onTap: (){Navigator.of(context).pop();editar(x);},),
            ListTile(title: Text("Finalizar"),onTap: (){Navigator.of(context).pop();finalizar(x);},),
            ListTile(title: Text("Eliminar"),onTap: (){Navigator.of(context).pop();eliminar(x);},),
            ListTile(title: Text("Añadir Proyecto"),onTap: (){Navigator.of(context).pop();addProyecto(x);},),
          ]),
        );
      }).then((res)=>{
        setState((){
          c=null;
        })
      });
    });
  }
  void addProyecto(dynamic x){
    Map<String,dynamic> nuevo={
      "id":Uuid().v4(),
      "nombre":"",
      "id_centro":x['id'],
      "descripcion":"",
      "inicio":getFechaTexto(getTextoFecha2(DateTime.now())),
      "fin":null,
      "abierto":true
    };
    showDialog(barrierDismissible: false,context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Añadir Proyecto"),
        content: column([
          Input(value: nuevo['nombre'],label: "Nombre",change: (s){setState((){nuevo['nombre']=s;});},),
          Input(value: nuevo['descripcion'],label: "Descripción",change: (s){setState((){nuevo['descripcion']=s;});},),
        ]),
        actions: [
          TextButton(onPressed: (){Navigator.of(context).pop();}, child: Text("Cancelar")),
          TextButton(onPressed: (){Navigator.of(context).pop();
          if (vacio(nuevo['nombre']) || vacio(nuevo['descripcion'])){
            error(context,"Nombre y descripción obligatorios");
          }
          else{
            postProyecto(nuevo);
          }
          },child: Text("Añadir"),)
        ],
      );
    });
  }
  void postProyecto(dynamic x){
    http.post(Uri.parse('${getUrlApi()}Proyectos'),headers: {"Content-Type":"application/json"},body: jsonEncode(x)).then((res)=>{
      if (res.statusCode==500){
        error(context,"Proyecto ya existente")
      }
      else if (res.statusCode==204){
        Fluttertoast.showToast(msg: "Proyecto añadido")
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return cargando?Center(child: CircularProgressIndicator(),):Scaffold(
      appBar: AppBar(
        title: Text("Filtro",style: TextStyle(fontSize: 20),),
        backgroundColor: dark,
        foregroundColor: gold,
        surfaceTintColor: dark,
        actions: [
          TextButton(onPressed: (){limpiar();}, style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(dark),foregroundColor:  WidgetStatePropertyAll(gold)),child: Text("LIMPIAR"),),
          TextButton(onPressed: (){showClientes();}, style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(dark),foregroundColor:  WidgetStatePropertyAll(gold)), child: Text("CLIENTES"),),
        ],
      ),
      body: column(expand: true,border_top: true,spacing: 15,List<Widget>.from(centros.where((x)=>ids_clientes.contains(x['id_cliente'])).map((x)=>
        item(selected: c==x,(){seleccionar(x);}, x['nombre'], Text(getClienteByCentro(x)['nombre'],style: TextStyle(color: c==x?black:light),))
      ))),
      bottomNavigationBar: Container(padding: EdgeInsets.all(5),height: 60,decoration: BoxDecoration(color: dark3,border: BoxBorder.fromLTRB(top: BorderSide(color: light))),
        child: Row(mainAxisAlignment: MainAxisAlignment.end,children: [
          IconButton(onPressed: (){add();}, icon: Icon(Icons.add))
        ],),
      ),
    );
  }
}