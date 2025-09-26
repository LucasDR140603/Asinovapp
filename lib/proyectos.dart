import 'dart:convert';

import 'package:asinovapp/addeditproyecto.dart';
import 'package:asinovapp/input.dart';
import 'package:asinovapp/radiobuttonlist.dart';
import 'package:asinovapp/variables.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
class Proyectos extends StatefulWidget {
  final dynamic usuario;
  final Function(String)? filtrado;
  const Proyectos({super.key,this.usuario,this.filtrado});

  @override
  State<Proyectos> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Proyectos> {
  late dynamic usuario=widget.usuario;
  late Function(String) filtrado=widget.filtrado!;
  List<dynamic> clientes=[];
  List<dynamic> centros=[];
  List<dynamic> proyectos=[];
  List<dynamic> registros=[];
  List<String> ids_clientes=[];
  List<String> ids_centros=[];
  dynamic p=null;
  DateTime inicio=DateTime(2000);
  DateTime fin=DateTime.now();
  bool cargando=true;
  @override
  void initState(){
    super.initState();
    set();
  }
  dynamic getClienteByCentro(dynamic x){
    return clientes.where((y)=>x['id_cliente']==y['id']).toList()[0];
  }
  dynamic getCentroByProyecto(dynamic x){
    return centros.where((y)=>x['id_centro']==y['id']).toList()[0];
  }
  dynamic getClienteByProyecto(dynamic x){
    return getClienteByCentro(getCentroByProyecto(x));
  }
  dynamic getUltimoRegistro(dynamic x){
    List<dynamic> lista=registros.where((y)=>y['id_proyecto']==x['id']).toList();
    return lista.isEmpty?{"inicio":"0","fin":"0"}:lista[0];
  }
  dynamic getRegistroSinTerminar(dynamic x){
    return registros.where((y)=>y['id_proyecto']==x['id'] && y['fin']==null).toList()[0];
  }
  bool terminado(dynamic x){
    return registros.where((y)=>y['id_proyecto']==x['id'] && y['fin']==null).toList().isEmpty;
  }
  void set()async{
    clientes=await getLista("Clientes");
    clientes.sort((x,y)=>x['nombre'].toString().compareTo(y['nombre']));
    ids_clientes=List<String>.from(clientes.map((x)=>x['id']));
    centros=await getLista("Centros");
    centros.sort((x,y)=>x['nombre'].toString().compareTo(y['nombre']));
    centros.sort((x,y)=>getClienteByCentro(x)['nombre'].toString().compareTo(getClienteByCentro(y)['nombre']));
    ids_centros=List<String>.from(centros.map((x)=>x['id']));
    proyectos=await getLista("Proyectos");
    proyectos.sort((x,y)=>y['inicio'].toString().compareTo(x['inicio']));
    registros=await getLista("Usuarios/${usuario['id']}/Registros");
    registros.sort((x,y)=>y['inicio'].toString().compareTo(x['inicio']));
    proyectos.sort((x,y)=>getUltimoRegistro(y)['inicio'].toString().compareTo(getUltimoRegistro(x)['inicio']));
    setState((){
      cargando=false;
    });
  }
  void showF(DateTime initialdate,DateTime firstdate,DateTime lastdate, Function(DateTime) onDateChanged){
    DateTime fecha=initialdate;
    showDialog(barrierDismissible: false,context: context,builder: (BuildContext context){
      return AlertDialog(
        title: Text("Día de Inicio"),
        content:SizedBox(width: 300,height:300,child:CalendarDatePicker(
          initialDate: initialdate,
          firstDate: firstdate,
          lastDate: lastdate,
          onDateChanged: (value){
            fecha=DateTime(value.year,value.month,value.day,initialdate.hour,initialdate.minute);
          },
          )
        ),
        actions: [TextButton(onPressed: (){Navigator.of(context).pop();},child: Text("Cancelar"),),TextButton(onPressed: (){Navigator.of(context).pop();onDateChanged(fecha);},child: Text("Confirmar"),)],
      );
    });
  }
  void actualizar_clientes(List<String> ids,int index){
    setState((){
      ids_clientes=ids;
      ids_centros=List.from(centros.map((x)=>ids_clientes.contains(x['id_cliente']) && proyectos.where((y)=>y['id_centro']==x['id']).toList().isNotEmpty?x['id']:"no"));
      filtrado("${clientes[index]['nombre']}");
    });
  }
  void actualizar_centros(List<String> ids,int index){
    setState((){
      ids_centros=ids;
      filtrado("${clientes.where((x)=>x['id']==centros[index]['id_cliente']).toList()[0]['nombre']} > ${centros[index]['nombre']}");
    });
  }
  void limpiar(){
    setState((){
      ids_clientes=List.from(clientes.map((x)=>x['id']));
      ids_centros=List.from(centros.map((x)=>x['id']));
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
  void showCentros(){
    showDialog(context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Centros"),
        content: RadiobuttonList(contexto: context,lista: centros,ids: ids_centros,actualizar: (ids,index){actualizar_centros(ids,index);},)
        
      );
    });
  }
  void guardar_nuevo(dynamic x){
    setState((){
      proyectos.add(x);
      proyectos.sort((x,y)=>y['inicio'].toString().compareTo(x['inicio']));
      proyectos.sort((x,y)=>getUltimoRegistro(y)['inicio'].toString().compareTo(getUltimoRegistro(x)['inicio']));
      http.post(Uri.parse('${getUrlApi()}Proyectos'),headers: {"Content-Type":"application/json"},body: jsonEncode(x)).then((res)=>{
        if (res.statusCode==500){
          error(context, "Proyecto ya existente")
        }
      });
    });
  }
  void guardar(dynamic x){
    setState((){
      proyectos[proyectos.indexWhere((y)=>y['id']==x['id'])]=x;
      http.put(Uri.parse('${getUrlApi()}Proyectos'),headers: {"Content-Type":"application/json"},body: jsonEncode(x)).then((res)=>{
        if (res.statusCode==500){
          error(context, "Proyecto ya existente")
        }
      });
    });
  }
  void guardar2(List<dynamic> cli, List<dynamic> cen){
    setState((){
      clientes=cli;
      centros=cen;
      List<String> ids_cli=ids_clientes;
      ids_clientes=List<String>.from(clientes.map((x)=>(!ids_cli.contains("") || ids_cli.contains(x['id']))?x['id']:""));
      ids_centros=List.from(centros.map((x)=>ids_clientes.contains("")?ids_clientes.contains(x['id_cliente']) && proyectos.where((y)=>y['id_centro']==x['id']).toList().isNotEmpty?x['id']:"no":x['id']));
    });
  }
  void showDescripcion(dynamic x){
    String descripcion=x['descripcion']??"";
    showDialog(context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Descripción"),
        content: Input(value: descripcion,hint: "Descripción",change: (s){setState((){descripcion=s;});},),
        actions: [
          TextButton(onPressed: (){Navigator.of(context).pop();}, child: Text("Cancelar")),
          TextButton(onPressed: (){Navigator.of(context).pop();x['descripcion']=vacio(descripcion)?null:descripcion;guardar(x);}, child: Text("Confirmar")),
        ],
      );
    });
  }
  void iniciar(dynamic x){
    Map<String,dynamic> nuevo={
      "id":Uuid().v4(),
      "id_proyecto":x['id'],
      "inicio":getFechaTexto(getTextoFecha2(DateTime.now())),
      "fin":null,
      "descripcion":null,
      "observaciones":null,
      "id_usuario":usuario['id']
    };
    setState((){
      registros.insert(0,nuevo);
      proyectos.remove(x);
      proyectos.insert(0, x);
      http.post(Uri.parse('${getUrlApi()}Registros'),headers: {"Content-Type":"application/json"},body: jsonEncode(nuevo));
    });
  }
  void terminar(dynamic x){
    setState((){
      int indice=registros.indexOf(getRegistroSinTerminar(x));
      registros[indice]['fin']=getFechaTexto(getTextoFecha2(DateTime.now()));
      http.put(Uri.parse('${getUrlApi()}Registros'),headers: {"Content-Type":"application/json"},body: jsonEncode(registros[indice]));
    });
  }
  void edit(dynamic x){
    showDialog(barrierDismissible: false,context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Editar ${x['nombre']}"),
        content: AddEditProyecto(clientes: clientes,centros: centros,proyecto:x,guardar: guardar,guardar2: guardar2,),
      );
    });
  }
  void add(){
    Map<String,dynamic> nuevo={
      "id":Uuid().v4(),
      "nombre":"",
      "id_centro":centros[0]['id'],
      "descripcion":"",
      "inicio":getFechaTexto(getTextoFecha2(DateTime.now())),
      "fin":null,
      "abierto":true
    };
    showDialog(barrierDismissible: false,context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Añadir Proyecto"),
        content: AddEditProyecto(clientes: clientes,centros: centros,proyecto:nuevo,guardar: guardar_nuevo,guardar2: guardar2,),
      );
    });
  }
  void finalizar(dynamic x){
    showDialog(context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Alerta"),
        content: Text("Va a finalizar un proyecto, ya no se mostrará así como tampoco sus registros"),
        actions: [
          TextButton(onPressed: (){Navigator.of(context).pop();}, child: Text("Cancelar")),
          TextButton(onPressed: (){
            Navigator.of(context).pop();
            setState((){
              proyectos.remove(x);
              x['fin']=getFechaTexto(getTextoFecha2(DateTime.now()));
              x['abierto']=false;
              registros.removeWhere((y)=>y['id_proyecto']==x['id']);
              http.put(Uri.parse('${getUrlApi()}Proyectos'),headers: {"Content-Type":"application/json"},body: jsonEncode(x));
            });
          }, child: Text("Confirmar")),
        ],
      );
    });
  }
  void eliminar(dynamic x){
    showDialog(context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Alerta"),
        content: Text("Va a eliminar un proyecto y con él todos sus registros. Acción irreversible"),
        actions: [
          TextButton(onPressed: (){Navigator.of(context).pop();}, child: Text("Cancelar")),
          TextButton(onPressed: (){
            Navigator.of(context).pop();
            setState((){
              proyectos.remove(x);
              registros.removeWhere((y)=>y['id_proyecto']==x['id']);
              http.delete(Uri.https(url,'${api}Proyectos/${x['id']}'));
            });
          }, child: Text("Confirmar")),
        ],
      );
    });
  }
  void seleccionar(dynamic x){
    setState((){
      p=x;
      showDialog(context: context, builder: (BuildContext context){
        return AlertDialog(
          content: column([
          ListTile(title: Text(terminado(x)?"Iniciar":"Terminar"),onTap: (){Navigator.of(context).pop();terminado(x)?iniciar(x):terminar(x);},),
          ListTile(title: Text("Editar"),onTap:(){Navigator.of(context).pop();edit(x);}),
          ListTile(title: Text("Finalizar"),onTap:(){Navigator.of(context).pop();finalizar(x);}),
          ListTile(title: Text("Eliminar"),onTap:(){Navigator.of(context).pop();eliminar(x);})
        ]),
        );
      }).then((res)=>{
        setState((){
          p=null;
        })
      });
    });
  }
  double padding_botones=10;
  bool dentro_intervalo(dynamic x){
    DateTime inicio_proyecto=DateTime.parse(x['inicio']);
    return inicio.compareTo(DateTime.parse(x['inicio']))<=0 && DateTime(fin.year,fin.month,fin.day).compareTo(DateTime(inicio_proyecto.year,inicio_proyecto.month,inicio_proyecto.day))>=0;
  }
  @override
  Widget build(BuildContext context) {
    return cargando?Center(child:CircularProgressIndicator()):Scaffold(
      appBar: AppBar(
        title: Text("Filtro",style: TextStyle(fontSize: 20),),
        backgroundColor: dark,
        foregroundColor: gold,
        surfaceTintColor: dark,
        actions: [
          TextButton(onPressed: (){limpiar();}, style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(dark),foregroundColor:  WidgetStatePropertyAll(gold)),child: Text("LIMPIAR"),),
          TextButton(onPressed: (){showClientes();}, style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(dark),foregroundColor:  WidgetStatePropertyAll(gold)), child: Text("CLIENTES"),),
          if (ids_centros.where((x) => x=="no").isNotEmpty)
          TextButton(onPressed: (){showCentros();}, style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(dark),foregroundColor:  WidgetStatePropertyAll(gold)), child: Text("CENTROS")),
          if (ids_centros.where((x) => x=="").isNotEmpty)
          IconButton(onPressed: (){setState((){ids_centros=List<String>.from(centros.map((x)=>ids_clientes.contains(x['id_cliente'])?x['id']:"no"));filtrado(clientes.where((x)=>ids_clientes.contains(x['id'])).toList()[0]['nombre']);});}, icon: Icon(Icons.close),style: ButtonStyle(iconSize: WidgetStatePropertyAll(15),backgroundColor: WidgetStatePropertyAll(Color.fromARGB(0, 0, 0, 0)),iconColor: WidgetStatePropertyAll(Color.fromARGB(255,255,215,0))),)
        ],
      ),
      body: column(expand: true,border_top: true,spacing: 15,List<Widget>.from(proyectos.where((x)=>ids_centros.contains(x['id_centro']) && dentro_intervalo(x)).map((x)=>
        item(selected: p==x,finished: terminado(x),(){seleccionar(x);}, x['nombre'], 
          Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
          text('${getClienteByProyecto(x)['nombre']} - ${getCentroByProyecto(x)['nombre']}',color: p==x?black:terminado(x)?light:cyanAccent,subrayado: true),
          text('Fecha de creación: ${getStrFechaSinSegundos(getTextoFecha2(DateTime.parse(x['inicio'])))}',color: p==x?black:terminado(x)?light:cyanAccent),
          if(!terminado(x))
          text('Fecha de registro: ${getStrFechaSinSegundos(getTextoFecha2(DateTime.parse(getRegistroSinTerminar(x)['inicio'])))}',color: p==x?black:cyanAccent),
          ElevatedButton(onPressed: (){showDescripcion(x);},style: terminado(x)?bsgold(padding: padding_botones):bscyan(padding: padding_botones), child: Text("Descripción")),
        ],))
      ))),
      bottomNavigationBar: Container(padding: EdgeInsets.all(5),height: 60,decoration: BoxDecoration(color: dark3,border: BoxBorder.fromLTRB(top: BorderSide(color: light))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [
          Row(spacing: 10,children:[
            ElevatedButton(onPressed: (){showF(inicio,DateTime(2000),fin,(d){setState((){inicio=d;});});}, child: Text(getFechaTextoDia(getTextoFecha2(inicio)))),
            ElevatedButton(onPressed: (){showF(fin,inicio,DateTime.now(),(d){setState((){fin=d;});});}, child: Text(getFechaTextoDia(getTextoFecha2(fin)))),
          ]),
          IconButton(onPressed: (){add();}, icon: Icon(Icons.add))
        ],),
      ),
    );
  }
}