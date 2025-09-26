import 'dart:convert';

import 'package:asinovapp/addeditcliente.dart';
import 'package:asinovapp/input.dart';
import 'package:asinovapp/variables.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
class Clientes extends StatefulWidget {
  final Function(String)? filtrado;
  const Clientes({super.key,this.filtrado});

  @override
  State<Clientes> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Clientes> {
  List<dynamic> clientes=[];
  late Function(String) filtrado=widget.filtrado!;
  dynamic c=null;
  bool cargando=true;
  @override
  void initState(){
    super.initState();
    set();
  }
  void set()async{
    clientes=await getLista('Clientes');
    clientes.sort((x,y)=>x['nombre'].toString().compareTo(y['nombre']));
    setState((){
      cargando=false;
    });
  }
  void guardar_nuevo(dynamic x){
    http.post(Uri.parse('${getUrlApi()}Clientes'),headers: {"Content-Type":"application/json"},body: jsonEncode(x)).then((res)=>{
      if (res.statusCode==500){
          error(context,"Cliente ya existente")
        }
        else if (res.statusCode==204){
          clientes.add(x),
          clientes.sort((x,y)=>x['nombre'].toString().compareTo(y['nombre'])),
          setState((){
            
          }),
        }
    });
  }
  void guardar(dynamic x){
    http.put(Uri.parse('${getUrlApi()}Clientes'),headers: {"Content-Type":"application/json"},body: jsonEncode(x)).then((res)=>{
      if (res.statusCode==500){
          error(context,"Cliente ya existente")
        }
        else if (res.statusCode==204){
          if (x['abierto']){
            clientes[clientes.indexWhere((y)=>y['id']==x['id'])]=x,
          }
          else{
            clientes.removeAt(clientes.indexWhere((y)=>y['id']==x['id'])),
          },
          clientes.sort((x,y)=>x['nombre'].toString().compareTo(y['nombre'])),
          setState((){
            
          }),
        }
    });
  }
  void add(){
    Map<String,dynamic> x={
      "id":Uuid().v4(),
      "nombre":"",
      "abierto":true
    };
    showDialog(barrierDismissible: false,context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Añadir centro"),
        content: AddEditCliente(cliente: x,guardar: guardar_nuevo,),
      );
    });
  }
  void editar(dynamic x){
    showDialog(barrierDismissible: false,context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Editar ${x['nombre']}"),
        content: AddEditCliente(cliente:x,guardar: guardar),
      );
    });
  }
  void finalizar(dynamic x){
    x['abierto']=false;
    showDialog(context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Alerta"),
        content: Text("Va a finalizar un cliente, ya no se mostrará así como tampoco sus centros, proyectos y registros"),
        actions: [TextButton(onPressed: (){Navigator.of(context).pop();}, child: Text("Cancelar")),TextButton(onPressed: (){Navigator.of(context).pop();guardar(x);}, child: Text("Confirmar"))],
      );
    });
  }
  void eliminar(dynamic x){
    showDialog(context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Alerta"),
        content: Text("Va a eliminar un cliente y con él sus centros, proyectos y registros. Acción irreversible"),
        actions: [TextButton(onPressed: (){Navigator.of(context).pop();}, child: Text("Cancelar")),TextButton(onPressed: (){Navigator.of(context).pop();setState((){http.delete(Uri.https(url,'${api}Clientes/${x['id']}'));clientes.remove(x);});}, child: Text("Confirmar"))],
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
            ListTile(title: Text("Añadir Centro"),onTap: (){Navigator.of(context).pop();addCentro(x);},),
          ]),
        );
      }).then((res)=>{
        setState((){
          c=null;
        })
      });
    });
  }
  void addCentro(dynamic x){
    Map<String,dynamic> nuevo={
      "id":Uuid().v4(),
      "nombre":"",
      "id_cliente":x['id'],
      "abierto":true
    };
    showDialog(barrierDismissible: false,context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Añadir Centro"),
        content: Input(value: nuevo['nombre'],label: "Nombre",change: (s){setState((){nuevo['nombre']=s;});},),
        actions: [
          TextButton(onPressed: (){Navigator.of(context).pop();}, child: Text("Cancelar")),
          TextButton(onPressed: (){Navigator.of(context).pop();
          if (vacio(nuevo['nombre'])){
            error(context,"Nombre obligatorio");
          }
          else{
            postCentro(nuevo);
          }
          },child: Text("Añadir"),)
        ],
      );
    });
  }
  void postCentro(dynamic x){
    http.post(Uri.parse('${getUrlApi()}Centros'),headers: {"Content-Type":"application/json"},body: jsonEncode(x)).then((res)=>{
      if (res.statusCode==500){
        error(context,"Centro ya existente")
      }
      else if (res.statusCode==204){
        Fluttertoast.showToast(msg: "Centro añadido")
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return cargando?Center(child: CircularProgressIndicator(),):Scaffold(
      body: column(expand: true,spacing: 15,List<Widget>.from(clientes.map((x)=>
        singleitem(selected: c==x,(){seleccionar(x);}, x['nombre'])
      ))),
      bottomNavigationBar: Container(padding: EdgeInsets.all(5),height: 60,decoration: BoxDecoration(color: dark3,border: BoxBorder.fromLTRB(top: BorderSide(color: light))),
        child: Row(mainAxisAlignment: MainAxisAlignment.end,children: [
          IconButton(onPressed: (){add();}, icon: Icon(Icons.add))
        ],),
      ),
    );
  }
}