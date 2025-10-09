import 'dart:convert';

import 'package:asinovapp/input.dart';
import 'package:asinovapp/variables.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
class AddEditRegistro extends StatefulWidget {
  final List<dynamic>? clientes;
  final List<dynamic>? centros;
  final List<dynamic>? proyectos;
  final List<dynamic>? registros;
  final List<dynamic>? gastos;
  final dynamic registro;
  final dynamic usuario;
  final Function(dynamic,dynamic)? guardar;
  final Function(List<dynamic>,List<dynamic>,List<dynamic>)? guardar2;
  const AddEditRegistro({super.key,this.clientes,this.centros,this.proyectos,this.registros,this.gastos,this.registro,this.usuario,this.guardar, this.guardar2});
  @override
  State<AddEditRegistro> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<AddEditRegistro> {
  late List<dynamic> clientes=widget.clientes!;
  late List<dynamic> centros=widget.centros!;
  late List<dynamic> proyectos=widget.proyectos!;
  late List<dynamic> registros=widget.registros!;
  late List<dynamic> gastos=widget.gastos!;
  late dynamic registro=widget.registro!;
  late dynamic usuario=widget.usuario!;
  late Function(dynamic,dynamic) guardar=widget.guardar!;
  late Function(List<dynamic>,List<dynamic>,List<dynamic>) guardar2=widget.guardar2!;
  dynamic cliente=null;
  dynamic centro=null;
  dynamic proyecto=null;
  List<dynamic> clientes_con_proyectos=[];
  List<dynamic> centros_con_proyectos=[];
  String descripcion="";
  String observaciones="";
  dynamic gasto;
  DateTime actual=DateTime.now();
  bool terminado=false;
  List<String> lista_observaciones=[];
  List<dynamic> lista_gastos=[];
  TextEditingController controlador_observaciones=TextEditingController();
  TextEditingController c_km=TextEditingController();
  TextEditingController c_desplazamiento=TextEditingController();
  TextEditingController c_manutencion=TextEditingController();
  TextEditingController c_alojamiento=TextEditingController();
  void set(){
    setState((){
      cliente=clientes.where((x)=>x['nombre']==registro['cliente']).toList()[0];
      centro=centros.where((x)=>x['nombre']==registro['centro']).toList()[0];
      proyecto=proyectos.where((x)=>x['nombre']==registro['proyecto']).toList()[0];
      clientes_con_proyectos=clientes.where((x)=>centros.where((y)=>y['id_cliente']==x['id'] && proyectos.where((z)=>z['id_centro']==y['id']).toList().isNotEmpty).toList().isNotEmpty).toList();
      centros_con_proyectos=centros.where((x)=>proyectos.where((z)=>z['id_centro']==x['id']).toList().isNotEmpty).toList();
      descripcion=registro['descripcion']??"";
      observaciones=registro['observaciones']??"";
      controlador_observaciones.text=observaciones;
      lista_observaciones=List<String>.from(registros.where((x)=>x['observaciones']!=null).take(10).map((x)=>x['observaciones']));
      lista_gastos=gastos.where((x)=>x['km']+x['desplazamiento']+x['manutencion']+x['alojamiento']>0).take(10).toList();
      terminado=registro['fin']!=null;
      gasto=gastos.where((x)=>x['id_registro']==registro['id']).toList().isEmpty?<String,dynamic>{
        "id_registro":registro['id'],
        "km":0.0,
        "desplazamiento":0.0,
        "manutencion":0.0,
        "alojamiento":0.0
      }:gastos.where((x)=>x['id_registro']==registro['id']).toList()[0];
      c_km.text=gasto['km'].toString();
      c_desplazamiento.text=gasto['desplazamiento'].toString();
      c_manutencion.text=gasto['manutencion'].toString();
      c_alojamiento.text=gasto['alojamiento'].toString();
    });
  }
  void setCliente(dynamic x){
    setState((){
      cliente=x;
      centro=centros.where((x)=>x['id_cliente']==cliente['id'] && proyectos.where((y)=>y['id_centro']==x['id']).toList().isNotEmpty).toList()[0];
      proyecto=proyectos.where((x)=>x['id_centro']==centro['id']).toList()[0];
    });
  }
  void setCentro(dynamic x){
    setState((){
      centro=x;
      proyecto=proyectos.where((x)=>x['id_centro']==centro['id']).toList()[0];
    });
  }
  void setProyecto(dynamic x){
    setState((){
      proyecto=x;
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
            if (usuario['administrador'] && title=="Seleccionar Proyecto")
            ElevatedButton(onPressed: (){addProyecto(centro['id']);}, child: Text("Añadir Proyecto")),
          ]),
        );
      });
    });
  }
  void postCliente(dynamic cli,dynamic cen,dynamic pro){
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
          http.post(Uri.parse('${getUrlApi()}Proyectos'),headers: {"Content-Type":"application/json"},body: jsonEncode(pro)).then((res3)=>{
            if (res3.statusCode==500){
              error(context, "Proyecto ya existente")
            }
            else if (res3.statusCode==204){
              clientes.add(cli),
              centros.add(cen),
              proyectos.add(pro),
              clientes.sort((x,y)=>x['nombre'].toString().compareTo(y['nombre'])),
              centros.sort((x,y)=>x['nombre'].toString().compareTo(y['nombre'])),
              centros.sort((x,y)=>clientes.where((z)=>z['id']==x['id_cliente']).toList()[0]['nombre'].toString().compareTo(clientes.where((z)=>z['id']==y['id_cliente']).toList()[0]['nombre'].toString())),
              proyectos.sort((x,y)=>x['nombre'].toString().compareTo(y['nombre'])),
              proyectos.sort((x,y)=>centros.where((z)=>z['id']==x['id_centro']).toList()[0]['nombre'].toString().compareTo(centros.where((z)=>z['id']==y['id_centro']).toList()[0]['nombre'].toString())),
              proyectos.sort((x,y)=>clientes.where((c)=>c['id']==centros.where((z)=>z['id']==x['id_centro']).toList()[0]['id_cliente']).toList()[0]['nombre'].toString().compareTo(clientes.where((c)=>c['id']==centros.where((z)=>z['id']==y['id_centro']).toList()[0]['id_cliente']).toList()[0]['nombre'])),
              clientes_con_proyectos=clientes.where((x)=>centros.where((y)=>y['id_cliente']==x['id'] && proyectos.where((z)=>z['id_centro']==y['id']).toList().isNotEmpty).toList().isNotEmpty).toList(),
              centros_con_proyectos=centros.where((x)=>proyectos.where((z)=>z['id_centro']==x['id']).toList().isNotEmpty).toList(),
              setState((){
                cliente=cli;
                centro=cen;
                proyecto=pro;
              }),
              guardar2(clientes,centros,proyectos),
              Navigator.of(context).pop(),
            }
            })
          }
        })
      }
    });
  }
  void addCliente(){
    String id_cliente=Uuid().v4();
    String id_centro=Uuid().v4();
    String id_proyecto=Uuid().v4();
    DateTime actual=DateTime.now();
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
    Map<String,dynamic> pro={
      "id":id_proyecto,
      "nombre":"",
      "id_centro":id_centro,
      "descripcion":"",
      "inicio":getFechaTexto('${actual.day}/${actual.month}/${actual.year} ${actual.hour}:${actual.minute}'),
      "fin":null,
      "abierto":true,
    };
    showDialog(barrierDismissible: false,context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Añadir cliente"),
        content: column([
          Input(label: "Cliente",value: cli['nombre'],change: (s){setState((){cli['nombre']=s;});},),
          Input(label: "Centro",value: cen['nombre'],change: (s){setState((){cen['nombre']=s;});},),
          Input(label: "Proyecto",value: pro['nombre'],change: (s){setState((){pro['nombre']=s;});},),
          Input(label: "Descripción del Proyecto",value: pro['descripcion'],change: (s){setState((){pro['descripcion']=s;});},),
        ]),
        actions: [TextButton(onPressed: (){Navigator.of(context).pop();}, child: Text("Cancelar")),TextButton(onPressed: (){
          Navigator.of(context).pop();
          if (vacio(cli['nombre']) || vacio(cen['nombre']) || vacio(pro['nombre']) || vacio(pro['descripcion'])){
            error(context, "Faltan Campos");
          }
          else{
            postCliente(cli,cen,pro);
          }
        }, child: Text("Confirmar"))],
      );
    });
  }
  void postCentro(dynamic cen,dynamic pro){
    http.post(Uri.parse('${getUrlApi()}Centros'),headers: {"Content-Type":"application/json"},body: jsonEncode(cen)).then((res)=>{
      if (res.statusCode==500){
        error(context, "Centro ya existente")
      }
      else if (res.statusCode==204){
        http.post(Uri.parse('${getUrlApi()}Proyectos'),headers: {"Content-Type":"application/json"},body: jsonEncode(pro)).then((res2)=>{
        if (res2.statusCode==500){
          error(context, "Proyecto ya existente")
        }
        else if (res2.statusCode==204){
          centros.add(cen),
          proyectos.add(pro),
          centros.sort((x,y)=>x['nombre'].toString().compareTo(y['nombre'])),
          centros.sort((x,y)=>clientes.where((z)=>z['id']==x['id_cliente']).toList()[0]['nombre'].toString().compareTo(clientes.where((z)=>z['id']==y['id_cliente']).toList()[0]['nombre'].toString())),
          proyectos.sort((x,y)=>x['nombre'].toString().compareTo(y['nombre'])),
          proyectos.sort((x,y)=>centros.where((z)=>z['id']==x['id_centro']).toList()[0]['nombre'].toString().compareTo(centros.where((z)=>z['id']==y['id_centro']).toList()[0]['nombre'].toString())),
          proyectos.sort((x,y)=>clientes.where((c)=>c['id']==centros.where((z)=>z['id']==x['id_centro']).toList()[0]['id_cliente']).toList()[0]['nombre'].toString().compareTo(clientes.where((c)=>c['id']==centros.where((z)=>z['id']==y['id_centro']).toList()[0]['id_cliente']).toList()[0]['nombre'])),
          centros_con_proyectos=centros.where((x)=>proyectos.where((z)=>z['id_centro']==x['id']).toList().isNotEmpty).toList(),
          setState((){
            centro=cen;
            proyecto=pro;
          }),
          guardar2(clientes,centros,proyectos),
          Navigator.of(context).pop(),
          }
        })
      }
    });
  }
  void postProyecto(dynamic pro){
    http.post(Uri.parse('${getUrlApi()}Proyectos'),headers: {"Content-Type":"application/json"},body: jsonEncode(pro)).then((res)=>{
      if (res.statusCode==500){
        error(context, "Proyecto ya existente")
      }
      else if (res.statusCode==204){
        proyectos.add(pro),
        proyectos.sort((x,y)=>x['nombre'].toString().compareTo(y['nombre'])),
        proyectos.sort((x,y)=>centros.where((z)=>z['id']==x['id_centro']).toList()[0]['nombre'].toString().compareTo(centros.where((z)=>z['id']==y['id_centro']).toList()[0]['nombre'].toString())),
        proyectos.sort((x,y)=>clientes.where((c)=>c['id']==centros.where((z)=>z['id']==x['id_centro']).toList()[0]['id_cliente']).toList()[0]['nombre'].toString().compareTo(clientes.where((c)=>c['id']==centros.where((z)=>z['id']==y['id_centro']).toList()[0]['id_cliente']).toList()[0]['nombre'])),
        setState((){
          proyecto=pro;
        }),
        guardar2(clientes,centros,proyectos),
        Navigator.of(context).pop(),
      }
    });
  }
  void addCentro(String id_cliente){
    String id_centro=Uuid().v4();
    String id_proyecto=Uuid().v4();
    DateTime actual=DateTime.now();
    Map<String,dynamic> cen={
      "id":id_centro,
      "nombre":"",
      "id_cliente":id_cliente,
      "abierto":true
    };
    Map<String,dynamic> pro={
      "id":id_proyecto,
      "nombre":"",
      "id_centro":id_centro,
      "descripcion":"",
      "inicio":getFechaTexto('${actual.day}/${actual.month}/${actual.year} ${actual.hour}:${actual.minute}'),
      "fin":null,
      "abierto":true,
    };
    showDialog(barrierDismissible: false,context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Añadir centro"),
        content: column([
          Input(label: "Centro",value: cen['nombre'],change: (s){setState((){cen['nombre']=s;});},),
          Input(label: "Proyecto",value: pro['nombre'],change: (s){setState((){pro['nombre']=s;});},),
          Input(label: "Descripción del Proyecto",value: pro['descripcion'],change: (s){setState((){pro['descripcion']=s;});},),
        ]),
        actions: [TextButton(onPressed: (){Navigator.of(context).pop();}, child: Text("Cancelar")),TextButton(onPressed: (){
          Navigator.of(context).pop();
          if (vacio(cen['nombre']) || vacio(pro['nombre']) || vacio(pro['descripcion'])){
            error(context, "Faltan Campos");
          }
          else{
            postCentro(cen,pro);
          }
        }, child: Text("Confirmar"))],
      );
    });
  }
  void addProyecto(String id_centro){
    String id_proyecto=Uuid().v4();
    DateTime actual=DateTime.now();
    Map<String,dynamic> pro={
      "id":id_proyecto,
      "nombre":"",
      "id_centro":id_centro,
      "descripcion":"",
      "inicio":getFechaTexto('${actual.day}/${actual.month}/${actual.year} ${actual.hour}:${actual.minute}'),
      "fin":null,
      "abierto":true,
    };
    showDialog(barrierDismissible: false,context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Añadir proyecto"),
        content: column([
          Input(label: "Proyecto",value: pro['nombre'],change: (s){setState((){pro['nombre']=s;});},),
          Input(label: "Descripción del Proyecto",value: pro['descripcion'],change: (s){setState((){pro['descripcion']=s;});},),
        ]),
        actions: [TextButton(onPressed: (){Navigator.of(context).pop();}, child: Text("Cancelar")),TextButton(onPressed: (){
          Navigator.of(context).pop();
          if (vacio(pro['nombre']) || vacio(pro['descripcion'])){
            error(context, "Faltan Campos");
          }
          else{
            postProyecto(pro);
          }
        }, child: Text("Confirmar"))],
      );
    });
  }
  @override
  void initState(){
    super.initState();
    set();
  }
  void setInicio(DateTime f){
    setState((){
      registro['inicio']=getTextoFecha2(f);
    });
  }
  void setFin(DateTime f){
    setState((){
      registro['fin']=getTextoFecha2(f);
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
  void showH(DateTime initialdate,DateTime firstdate,DateTime lastdate, Function(DateTime) onDateChanged)async{
    TimeOfDay initial=TimeOfDay(hour: initialdate.hour,minute: initialdate.minute);
    TimeOfDay? picked=await showTimePicker(context: context, initialTime: initial);
    if (picked!=null){
      DateTime fecha=DateTime(initialdate.year,initialdate.month,initialdate.day,picked.hour,picked.minute);
      if (fecha.compareTo(firstdate)<0){
        fecha=firstdate;
      }
      if (fecha.compareTo(lastdate)>0){
        fecha=lastdate;
      }
      onDateChanged(fecha);
    }
  }
  showObservaciones(){
    showDialog(context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Historial de Observaciones"),
        content: column(barra: true,maxHeight: 200,List<Widget>.from(lista_observaciones.map((x)=>
          ListTile(onTap: (){Navigator.of(context).pop();setState((){observaciones=x;controlador_observaciones.text=x;});},title: Text(x),)
        ))),
      );
    });
  }
  setGastos(dynamic x){
    setState((){
      gasto['km']=x['km'];
      gasto['desplazamiento']=x['desplazamiento'];
      gasto['manutencion']=x['manutencion'];
      gasto['alojamiento']=x['alojamiento'];
      c_km.text=gasto['km'].toString();
      c_desplazamiento.text=gasto['desplazamiento'].toString();
      c_manutencion.text=gasto['manutencion'].toString();
      c_alojamiento.text=gasto['alojamiento'].toString();
    });
  }
  showGastos(){
    showDialog(context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Historial de Gastos"),
        content: scroller(DataTable(
          columnSpacing: 5,
          horizontalMargin: 0,
          showCheckboxColumn: false,
          columns: [DataColumn(label: Text("Km")),DataColumn(label:Text("Desplazamiento")),DataColumn(label:Text("Manutención")),DataColumn(label:Text("Alojamiento"))],
          rows: List<DataRow>.from(lista_gastos.map((e)=>(DataRow(onSelectChanged: (b){Navigator.of(context).pop();setGastos(e);},cells: [
            DataCell(Text(e['km'].toString())),
            DataCell(Text(e['desplazamiento'].toString())),
            DataCell(Text(e['manutencion'].toString())),
            DataCell(Text(e['alojamiento'].toString())),
          ]))))
        )),
      );
    });
  }
  setValores(){
    setState((){
      registro['descripcion']=vacio(descripcion)?null:descripcion;
      registro['observaciones']=vacio(observaciones)?null:observaciones;
      registro['cliente']=cliente['nombre'];
      registro['centro']=centro['nombre'];
      registro['proyecto']=proyecto['nombre'];
      registro['id_proyecto']=proyecto['id'];
      guardar(registro,gasto);
    });
  }
  @override
  Widget build(BuildContext context) {
    return column(ph: 0,[column(barra: true,maxHeight: 500,spacing: 10,ph: 0,[
      selector((){openSelector(context, clientes_con_proyectos, cliente, (x){setCliente(x);}, "Seleccionar Cliente");}, "Cliente", cliente['nombre']),
      selector((){openSelector(context, centros_con_proyectos.where((x)=>x['id_cliente']==cliente['id']).toList(), centro, (x){setCentro(x);}, "Seleccionar Centro");}, "Centro", centro['nombre']),
      selector((){openSelector(context, proyectos.where((x)=>x['id_centro']==centro['id']).toList(), proyecto, (x){setProyecto(x);}, "Seleccionar Proyecto");}, "Proyecto", proyecto['nombre']),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [
        Text("Inicio"),
        Row(spacing: 10,children: [
          TextButton(onPressed: (){showF(getFecha(registro['inicio']), DateTime(2000),registro['fin']!=null?getFecha(registro['fin']):DateTime.now(), setInicio);}, child: Text(getFechaTextoDia(registro['inicio']))),
          TextButton(onPressed: (){showH(getFecha(registro['inicio']), DateTime(2000),registro['fin']!=null?getFecha(registro['fin']):DateTime.now(), setInicio);}, child: Text(getFechaTextoHora(registro['inicio']))),
        ],),
      ],),
      if(!terminado)
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children:[Text('Terminado'),Switch(value: registro['fin']!=null, onChanged: (b){
        DateTime actual=DateTime.now();
        DateTime inicio=getFecha(registro['inicio']);
        setState((){registro['fin']=b?"${inicio.day.toString().padLeft(2,"0")}/${inicio.month.toString().padLeft(2,"0")}/${inicio.year} ${actual.hour.toString().padLeft(2,"0")}:${actual.minute.toString().padLeft(2,"0")}":null;});}),]),
      if(registro['fin']!=null)
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [
        Text("Fin"),
        Row(spacing: 10,children: [
          TextButton(onPressed: (){showF(getFecha(registro['fin']), getFecha(registro['inicio']),DateTime.now(), setFin);}, child: Text(getFechaTextoDia(registro['fin']))),
          TextButton(onPressed: (){showH(getFecha(registro['fin']), getFecha(registro['inicio']),DateTime.now(), setFin);}, child: Text(getFechaTextoHora(registro['fin']))),
        ],),
      ],),
      Input(value: descripcion,hint: "Descripción",change: (s){setState((){descripcion=s;});},),
      Input(controller: controlador_observaciones,value: observaciones,hint: "Observaciones",change: (s){setState((){observaciones=s;});},),
      ElevatedButton(onPressed: (){showObservaciones();}, child: Text("Historial de Observaciones")),
      Input(controller: c_km,value: gasto['km'].toString(),label: "Km",change: (s){setState((){gasto['km']=double.parse("0"+s);});},),
      Input(controller: c_desplazamiento,value: gasto['desplazamiento'].toString(),label: "Desplazamiento",change: (s){setState((){gasto['desplazamiento']=double.parse("0"+s);});},),
      Input(controller: c_manutencion,value: gasto['manutencion'].toString(),label: "Manutencion",change: (s){setState((){gasto['manutencion']=double.parse("0"+s);});},),
      Input(controller: c_alojamiento,value: gasto['alojamiento'].toString(),label: "Alojamiento",change: (s){setState((){gasto['alojamiento']=double.parse("0"+s);});},),
      
      ElevatedButton(onPressed: (){showGastos();}, child: Text("Historial de Gastos")),
    ]),
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [
        TextButton(onPressed: (){Navigator.of(context).pop();}, child: Text("Cancelar")),
        TextButton(onPressed: (){Navigator.of(context).pop();setValores();}, child: Text("Confirmar")),
      ],)
    ]);
  }
}