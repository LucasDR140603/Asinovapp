import 'dart:convert';

import 'package:asinovapp/addeditregistro.dart';
import 'package:asinovapp/input.dart';
import 'package:asinovapp/variables.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
class Registros extends StatefulWidget {
  final dynamic usuario;
  const Registros({super.key,this.usuario});
  @override
  State<Registros> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Registros> {
  late dynamic usuario=widget.usuario;
  bool cargando=true;
  List<dynamic> clientes=[];
  List<dynamic> centros=[];
  List<dynamic> proyectos=[];
  List<dynamic> registros=[];
  List<dynamic> gastos=[];
  dynamic r=null;
  DateTime inicio=getFechaActual();
  DateTime fin=getFechaActual();
  List<String> textos_duraciones=["Día","Semana","Mes","Año"];
  String duracion_actual="Día";
  List<String> dias_semana=["Lunes","Martes","Miércoles","Jueves","Viernes","Sábado","Domingo",];
  List<String> meses=["Enero","Febrero","Marzo","Abril","Mayo","Junio","Julio","Agosto","Septiembre","Octubre","Noviembre","Diciembre",];
  int getDiasAnho(int posicion){
    int anho=inicio.year+posicion;
    bool bisiesto=anho%4==0 && !(anho%100==0 && anho%400!=0);
    return bisiesto?366:365;
  }
  int getDiasMes(int posicion){
    int mes=inicio.month+posicion;
    if (mes==0){
      mes=12;
    }
    else if (mes==13){
      mes=1;
    }
    int anho=inicio.year;
    bool bisiesto=anho%4==0 && !(anho%100==0 && anho%400!=0);
    return mes==2?bisiesto?29:28:(mes%2==1 && mes<=7) || (mes%2==0 && mes>7)?31:30;
  }
  int getDiasMesDeterminado(int mes){
    if (mes==0){
      mes=12;
    }
    else if (mes==13){
      mes=1;
    }
    int anho=inicio.year;
    bool bisiesto=anho%4==0 && !(anho%100==0 && anho%400!=0);
    return mes==2?bisiesto?29:28:(mes%2==1 && mes<=7) || (mes%2==0 && mes>7)?31:30;
  }
  int getDuracion(int posicion){
    int dias=0;
    switch (textos_duraciones.indexOf(duracion_actual)){
      case 0:
        dias=1;
        break;
      case 1:
        dias=7;
        break;
      case 2:
        dias=getDiasMes(posicion);
        break;
      case 3:
        dias=getDiasAnho(posicion);
        break;
    }
    return dias;
  }
  void set()async{
    clientes=await getLista('Clientes');
    clientes.sort((x,y)=>x['nombre'].toString().compareTo(y['nombre']));
    centros=await getLista('Centros');
    centros.sort((x,y)=>x['nombre'].toString().compareTo(y['nombre']));
    centros.sort((x,y)=>clientes.where((z)=>z['id']==x['id_cliente']).toList()[0]['nombre'].toString().compareTo(clientes.where((z)=>z['id']==y['id_cliente']).toList()[0]['nombre'].toString()));
    proyectos=await getLista('Proyectos');
    proyectos.sort((x,y)=>x['nombre'].toString().compareTo(y['nombre']));
    proyectos.sort((x,y)=>centros.where((z)=>z['id']==x['id_centro']).toList()[0]['nombre'].toString().compareTo(centros.where((z)=>z['id']==y['id_centro']).toList()[0]['nombre'].toString()));
    proyectos.sort((x,y)=>clientes.where((c)=>c['id']==centros.where((z)=>z['id']==x['id_centro']).toList()[0]['id_cliente']).toList()[0]['nombre'].toString().compareTo(clientes.where((c)=>c['id']==centros.where((z)=>z['id']==y['id_centro']).toList()[0]['id_cliente']).toList()[0]['nombre']));
    registros=await getLista('Usuarios/${usuario['id']}/Registros/ccpu');
    registros.sort((x,y)=>getFecha(y['inicio']).compareTo(getFecha(x['inicio'])));
    gastos=await getLista('Usuarios/${usuario['id']}/Gastos');
    gastos.sort((x,y)=>getFecha(registros.where((r)=>r['id']==y['id_registro']).toList()[0]['inicio']).compareTo(getFecha(registros.where((r)=>r['id']==x['id_registro']).toList()[0]['inicio'])));
    setState((){
      cargando=false;
    });
  }
  bool terminado(dynamic x){
    return x['fin']!=null;
  }
  bool dentro_intervalo(dynamic x){
    DateTime f=getFecha(x['fin']);
    return inicio.compareTo(getFecha(x['inicio']))<=0 && fin.compareTo(DateTime(f.year,f.month,f.day))>=0;
  }
  bool contieneGastos(dynamic x){
    bool g=false;
    if (gastos.where((y)=>y['id_registro']==x['id']).toList().isNotEmpty){
      dynamic gasto=gastos.where((y)=>y['id_registro']==x['id']).toList()[0];
      g=gasto['km']+gasto['desplazamiento']+gasto['manutencion']+gasto['alojamiento']>0;
    }
    return g;
  }
  @override
  void initState(){
    super.initState();
    set();
  }
  Map<String,dynamic> getRegistroApi(dynamic x){
    return {
      "id":x['id'],
      "id_proyecto":x['id_proyecto'],
      "inicio":getFechaTexto(x['inicio']),
      "fin":x['fin']==null?null:getFechaTexto(x['fin']),
      "descripcion":x['descripcion'],
      "observaciones":x['observaciones'],
      "id_usuario":x['id_usuario']
    };
  }
  void terminar(x){
    setState((){
      x['fin']=getTextoFecha2(DateTime.now());
      registros[registros.indexWhere((y)=>y['id']==x['id'])]=x;
      http.put(Uri.parse('${getUrlApi()}Registros'),headers: {"Content-Type":"application/json"},body: jsonEncode(getRegistroApi(x)));
    });
  }
  void borrar(x){
    setState((){
      registros.remove(x);
      http.delete(Uri.https(url,'${api}Registros/${x['id']}'));
    });
  }
  void seleccionar(dynamic x){
    setState((){
      r=x;
    });
    showDialog(context: context, builder: (BuildContext context){
      return AlertDialog(
        content: column([
          if(!terminado(x))
          ListTile(title: Text("Terminar"),onTap: (){Navigator.of(context).pop();terminar(x);},),
          ListTile(title: Text("Editar"),onTap:(){Navigator.of(context).pop();edit(x);}),
          ListTile(title: Text("Borrar"),onTap:(){Navigator.of(context).pop();borrar(x);})
        ]),
      );
    }).then((value){
      setState((){
        r=null;
      });
    },);
  }
  void guardar_nuevo(dynamic nuevo,dynamic gasto){
    setState((){
      if (nuevo['fin']==null && registros.where((x)=>!terminado(x)).toList().isNotEmpty){
        dynamic sin_acabar=registros.where((x)=>!terminado(x)).toList()[0];
        registros.remove(sin_acabar);
        sin_acabar['fin']=getTextoFecha2(DateTime.now());
        registros.add(sin_acabar);
      }
      registros.add(nuevo);
      gastos.add(gasto);
      registros.sort((x,y)=>getFecha(y['inicio']).compareTo(getFecha(x['inicio'])));
      gastos.sort((x,y)=>getFecha(registros.where((r)=>r['id']==y['id_registro']).toList()[0]['inicio']).compareTo(getFecha(registros.where((r)=>r['id']==x['id_registro']).toList()[0]['inicio'])));
      http.post(Uri.parse('${getUrlApi()}Registros'),headers: {"Content-Type":"application/json"},body: jsonEncode(getRegistroApi(nuevo)));
      http.post(Uri.parse('${getUrlApi()}Gastos'),headers: {"Content-Type":"application/json"},body: jsonEncode(gasto));
    });
  }
  void guardar(dynamic nuevo,dynamic gasto){
    setState((){
      registros[registros.indexWhere((x)=>x['id']==nuevo['id'])]=nuevo;
      gastos.removeWhere((x)=>x['id_registro']==nuevo['id']);
      gastos.add(gasto);
      registros.sort((x,y)=>getFecha(y['inicio']).compareTo(getFecha(x['inicio'])));
      gastos.sort((x,y)=>getFecha(registros.where((r)=>r['id']==y['id_registro']).toList()[0]['inicio']).compareTo(getFecha(registros.where((r)=>r['id']==x['id_registro']).toList()[0]['inicio'])));
      http.put(Uri.parse('${getUrlApi()}Registros'),headers: {"Content-Type":"application/json"},body: jsonEncode(getRegistroApi(nuevo)));
      http.post(Uri.parse('${getUrlApi()}Gastos'),headers: {"Content-Type":"application/json"},body: jsonEncode(gasto));
    });
  }
  void guardar2(List<dynamic> cli,List<dynamic> cen, List<dynamic> pro){
    setState((){
      clientes=cli;
      centros=cen;
      proyectos=pro;
    });
  }
  Map<String,dynamic> getGasto(dynamic x){
    bool g=gastos.where((y)=>y['id_registro']==x['id']).toList().isNotEmpty;
    return g?gastos.where((y)=>y['id_registro']==x['id']).toList()[0]:{
      "id_registro":x['id'],
      "km":0.0,
      "desplazamiento":0.0,
      "manutencion":0.0,
      "alojamiento":0.0
    };
  }
  add(){
    DateTime actual=DateTime.now();
    bool hay_registros=registros.isNotEmpty;
    Map<String,dynamic> nuevo={
      "id":Uuid().v4(),
      "cliente":hay_registros?registros[0]['cliente']:clientes[0]['nombre'],
      "centro":hay_registros?registros[0]['centro']:centros[0]['nombre'],
      "proyecto":hay_registros?registros[0]['proyecto']:proyectos[0]['nombre'],
      "id_proyecto":hay_registros?registros[0]['id_proyecto']:proyectos[0]['id'],
      "usuario":usuario['nick'],
      "id_usuario":usuario['id'],
      "inicio": "${inicio.day.toString().padLeft(2,"0")}/${inicio.month.toString().padLeft(2,"0")}/${inicio.year} ${actual.hour.toString().padLeft(2,"0")}:${actual.minute.toString().padLeft(2,"0")}",
      "fin":inicio.day<actual.day?"${inicio.day.toString().padLeft(2,"0")}/${inicio.month.toString().padLeft(2,"0")}/${inicio.year} ${actual.hour.toString().padLeft(2,"0")}:${actual.minute.toString().padLeft(2,"0")}":null,
      "descripcion":null,
      "observaciones":null,
    };
    showDialog(barrierDismissible: false,context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Añadir Registro"),
        content: AddEditRegistro(clientes: clientes, centros: centros, proyectos: proyectos,registros: registros,gastos: gastos, registro: nuevo, usuario: usuario, guardar: (x,y){guardar_nuevo(x,y);},guardar2:(cli,cen,pro){guardar2(cli, cen, pro);}),
      );
    });
  }
  void edit(dynamic x){
    showDialog(barrierDismissible: false,context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Añadir Registro"),
        content: AddEditRegistro(clientes: clientes, centros: centros, proyectos: proyectos,registros: registros,gastos: gastos, registro: x, usuario: usuario, guardar: (x,y){guardar(x,y);},guardar2:(cli,cen,pro){guardar2(cli, cen, pro);}),
      );
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
          TextButton(onPressed: (){Navigator.of(context).pop();x['descripcion']=vacio(descripcion)?null:descripcion;guardar(x, getGasto(x));}, child: Text("Confirmar")),
        ],
      );
    });
  }
  void showObservaciones(dynamic x){
    String observaciones=x['observaciones']??"";
    TextEditingController controlador=TextEditingController(text: observaciones);
    List<String> lista_observaciones=List<String>.from(registros.where((x)=>x['observaciones']!=null).take(10).map((x)=>x['observaciones']));
    showDialog(context: context, builder: (BuildContext context){
      return StatefulBuilder(builder: (context,setState){
        return AlertDialog(
          title: Text("Observaciones"),
          content: column([
            Input(controller: controlador,value: observaciones,hint: "Observaciones",change: (s){setState((){observaciones=s;});},),
            ElevatedButton(onPressed: (){
              showDialog(context: context, builder: (BuildContext context){
                return AlertDialog(
                  title: Text("Historial de Observaciones"),
                  content: column(barra: true,maxHeight: 200,List<Widget>.from(lista_observaciones.map((x)=>
                    ListTile(onTap: (){Navigator.of(context).pop();setState((){observaciones=x;controlador.text=x;});},title: Text(x),)
                  ))),
                );
              });
            }, child: Text("Historial"))
          ]),
          actions: [
            TextButton(onPressed: (){Navigator.of(context).pop();}, child: Text("Cancelar")),
            TextButton(onPressed: (){Navigator.of(context).pop();x['observaciones']=vacio(observaciones)?null:observaciones;guardar(x, getGasto(x));}, child: Text("Confirmar")),
          ],
        );
      });
    });
  }
  void showGastos(dynamic x){
    dynamic gasto=getGasto(x);
    TextEditingController c_km=TextEditingController(text: gasto['km'].toString());
    TextEditingController c_desplazamiento=TextEditingController(text: gasto['desplazamiento'].toString());
    TextEditingController c_manutencion=TextEditingController(text: gasto['manutencion'].toString());
    TextEditingController c_alojamiento=TextEditingController(text: gasto['alojamiento'].toString());
    List<dynamic> lista_gastos=gastos.where((x)=>x['km']+x['desplazamiento']+x['manutencion']+x['alojamiento']>0).take(10).toList();
    showDialog(context: context, builder: (BuildContext context){
      return StatefulBuilder(builder: (context,setState){
        return AlertDialog(
          title: Text("Gastos"),
          content: column(ph: 0,[
            Input(controller: c_km,value: gasto['km'].toString(),label: "Km",change: (s){setState((){gasto['km']=double.parse("0"+s);});},),
            Input(controller: c_desplazamiento,value: gasto['desplazamiento'].toString(),label: "Desplazamiento",change: (s){setState((){gasto['desplazamiento']=double.parse("0"+s);});},),
            Input(controller: c_manutencion,value: gasto['manutencion'].toString(),label: "Manutencion",change: (s){setState((){gasto['manutencion']=double.parse("0"+s);});},),
            Input(controller: c_alojamiento,value: gasto['alojamiento'].toString(),label: "Alojamiento",change: (s){setState((){gasto['alojamiento']=double.parse("0"+s);});},),
            ElevatedButton(onPressed: (){
              showDialog(context: context, builder: (BuildContext context){
                return AlertDialog(
                  title: Text("Historial de Gastos"),
                  content: scroller(ph: 0,DataTable(
                    columnSpacing: 5,
                    horizontalMargin: 0,
                    showCheckboxColumn: false,
                    columns: [DataColumn(label: Text("Km")),DataColumn(label:Text("Desplazamiento")),DataColumn(label:Text("Manutención")),DataColumn(label:Text("Alojamiento"))],
                    rows: List<DataRow>.from(lista_gastos.map((e)=>(DataRow(onSelectChanged: (b){Navigator.of(context).pop();
                      setState((){
                        gasto['km']=e['km'];
                        gasto['desplazamiento']=e['desplazamiento'];
                        gasto['manutencion']=e['manutencion'];
                        gasto['alojamiento']=e['alojamiento'];
                        c_km.text=gasto['km'].toString();
                        c_desplazamiento.text=gasto['desplazamiento'].toString();
                        c_manutencion.text=gasto['manutencion'].toString();
                        c_alojamiento.text=gasto['alojamiento'].toString();
                      });
                    },cells: [
                      DataCell(Text(e['km'].toString())),
                      DataCell(Text(e['desplazamiento'].toString())),
                      DataCell(Text(e['manutencion'].toString())),
                      DataCell(Text(e['alojamiento'].toString())),
                    ]))))
                  )),
                );
              });
            }, child: Text("Historial"))
          ]),
          actions: [
            TextButton(onPressed: (){Navigator.of(context).pop();}, child: Text("Cancelar")),
            TextButton(onPressed: (){Navigator.of(context).pop();guardar(x, gasto);}, child: Text("Confirmar")),
          ],
        );
      }); 
    });
  }
  void setDia(){
    showDatePicker(context: context,initialDate: inicio, firstDate: DateTime(2000), lastDate: DateTime(inicio.year,12,31),).then((date)=>{
      setState((){
        if (date!=null){
          inicio=date;
          fin=date;
        }
      })
    });
  }
  void setSemana(){
    
  }
  void showDuraciones(){
    showDialog(context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Duraciones"),
        content: column(List<Widget>.from(textos_duraciones.map((x)=>ListTile(title: Text(x),onTap: (){setState((){
          duracion_actual=x;
          DateTime actual=DateTime.now();
          int inicio_dia=duracion_actual=="Día"?actual.day:duracion_actual=="Semana"?actual.day-(actual.weekday-1):1;
          int fin_dia=duracion_actual=="Día"?actual.day:duracion_actual=="Semana"?actual.day+(7-actual.weekday):duracion_actual=="Mes"?getDiasMes(0):31;
          int inicio_mes=duracion_actual=="Año"?1:duracion_actual=="Semana" && actual.day<(actual.weekday)?actual.month-1:actual.month;
          int fin_mes=duracion_actual=="Año"?12:duracion_actual=="Semana" && actual.day+(7-actual.weekday)>getDiasMesDeterminado(actual.month)?actual.month+1:actual.month;
          int anho=actual.year;
          inicio=DateTime(anho,inicio_mes,inicio_dia);
          fin=DateTime(anho,fin_mes,fin_dia);
          Navigator.of(context).pop();
        });},)))),
      );
    });
  }
  DateTime restar(DateTime fecha,int position){
    DateTime fecha0=DateTime(fecha.year,fecha.month,fecha.day);
    DateTime nueva=fecha0.subtract(Duration(days:getDuracion(position)));
    if (nueva.hour!=0){
      nueva=nueva.subtract(Duration(hours: nueva.hour));
      if (fecha0.difference(nueva).inHours>getDuracion(position)*24){
        nueva=nueva.add(Duration(days:1));
        nueva=DateTime(nueva.year,nueva.month,nueva.day);
      }
    }
    return nueva;
  }
  DateTime sumar(DateTime fecha,int position){
    DateTime fecha0=DateTime(fecha.year,fecha.month,fecha.day);
    DateTime nueva=fecha0.add(Duration(days: getDuracion(position)));
    if(nueva.hour!=0){
      nueva=nueva.subtract(Duration(hours: nueva.hour));
      if (fecha0.difference(nueva).inHours<getDuracion(position)*24){
        nueva=nueva.add(Duration(days:1));
      }
    }
    return nueva;
  }
  bool mostrable(dynamic x){
    return !terminado(x) || (terminado(x) && dentro_intervalo(x));
  }
  Duration getDuration(dynamic x){
    return getFecha(x['fin']).difference(getFecha(x['inicio']));
  }
  double padding_botones=10;
  @override
  Widget build(BuildContext context) {
    return cargando?Center(child:CircularProgressIndicator()):Scaffold(
      appBar: AppBar(actionsPadding: EdgeInsets.all(10),backgroundColor: dark,foregroundColor: gold,surfaceTintColor: dark,
      title: Text("Duración total: ${registros.where((x)=>mostrable(x) && terminado(x)).isNotEmpty?getHorasMinutos(List<Duration>.from(registros.where((x)=>mostrable(x) && terminado(x)).map((x)=>getDuration(x))).reduce((value,element)=>(value+element))):'00:00'}"),
      actions: [
        //Text('${getTextoFecha2(inicio)} - ${getTextoFecha2(fin)}    '),
        duracion_actual=="Día"?
        ElevatedButton(style: ButtonStyle(shadowColor: WidgetStatePropertyAll(transparent),backgroundColor: WidgetStatePropertyAll(transparent),padding: WidgetStatePropertyAll(EdgeInsets.zero)),onPressed: (){setDia();},child:Text('${dias_semana[inicio.weekday-1]} ${getFechaTextoDia(getTextoFecha2(inicio))}'))
        :duracion_actual=="Semana"?
        ElevatedButton(style: ButtonStyle(shadowColor: WidgetStatePropertyAll(transparent),backgroundColor: WidgetStatePropertyAll(transparent),padding: WidgetStatePropertyAll(EdgeInsets.zero)),onPressed:(){},child:Text('${getFechaTextoDia(getTextoFecha2(inicio))} - ${getFechaTextoDia(getTextoFecha2(fin))}'))
        :duracion_actual=="Mes"?
        ElevatedButton(style: ButtonStyle(shadowColor: WidgetStatePropertyAll(transparent),backgroundColor: WidgetStatePropertyAll(transparent),padding: WidgetStatePropertyAll(EdgeInsets.zero)),onPressed: (){},child:Text('${meses[inicio.month-1]} ${inicio.year}'))
        :ElevatedButton(style: ButtonStyle(shadowColor: WidgetStatePropertyAll(transparent),backgroundColor: WidgetStatePropertyAll(transparent),padding: WidgetStatePropertyAll(EdgeInsets.zero)),onPressed: (){},child:Text('${inicio.year}'))
      ],),
      body: GestureDetector(
        onHorizontalDragEnd: (details)=>{
            if (details.primaryVelocity!=null){
              setState((){
                if (details.primaryVelocity!>0){
                  fin=restar(fin,0);
                  inicio=restar(inicio,-1);
                }
                else if (details.primaryVelocity!<0){
                  fin=sumar(fin,1);
                  inicio=sumar(inicio,0);
                }
              })
            }
        },
        child:column(expand:true,border_top: true,spacing: 15,
        [...List<Widget>.from(registros.where((x)=>mostrable(x)).map((x)=>
        item(finished:terminado(x),selected: r==x,(){seleccionar(x);},x['proyecto'],
        Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
          text('${x['cliente']} - ${x['centro']}',color: r==x?black:terminado(x)?light:cyanAccent,subrayado: true),
          text(getStrFechaSinSegundos(x['inicio'])+(terminado(x)?' - ${getStrFechaSinSegundos(x['fin'])}':''),color: r==x?black:terminado(x)?light:cyanAccent),
          text('Duración: ${terminado(x)?getHorasMinutos(getFecha(x['fin']).difference(getFecha(x['inicio']))):'En Curso'}',color: r==x?black:terminado(x)?light:cyanAccent),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [
            ElevatedButton(onPressed: (){showDescripcion(x);},style: terminado(x)?bsgold(padding: padding_botones):bscyan(padding: padding_botones), child: Row(spacing: 2.5,children:[Text("Desc."),Icon(x['descripcion']==null?Icons.chat_bubble_outline:Icons.message)])),
            ElevatedButton(onPressed: (){showObservaciones(x);},style: terminado(x)?bsgold(padding: padding_botones):bscyan(padding: padding_botones), child: Row(spacing: 2.5,children:[Text("Obs."),Icon(x['observaciones']==null?Icons.chat_bubble_outline:Icons.message)])),
            ElevatedButton(onPressed: (){showGastos(x);},style: terminado(x)?bsgold(padding: padding_botones):bscyan(padding: padding_botones), child: Row(spacing: 2.5,children:[Text("Gast."),Icon(!contieneGastos(x)?Icons.chat_bubble_outline:Icons.message)]))
          ],)
        ],)
        )
      )),
      SizedBox(height: 75,)
      ])),
      floatingActionButton: FloatingActionButton(onPressed: (){add();},child: Icon(Icons.add)),
      bottomNavigationBar: Container(padding: EdgeInsets.all(5),height: 60,decoration: BoxDecoration(color: dark3,border: BoxBorder.fromLTRB(top: BorderSide(color: light))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [
          ElevatedButton(onPressed: (){setState((){
            fin=restar(fin,0);
            inicio=restar(inicio,-1);
          });}, child: Text("◄",style: TextStyle(fontSize: 20),)),
          ElevatedButton(onPressed: (){showDuraciones();}, child: Text(duracion_actual)),
          ElevatedButton(onPressed: (){setState((){
            fin=sumar(fin,1);
            inicio=sumar(inicio,0);
          });}, child: Text("►",style: TextStyle(fontSize: 20),))
        ],),
      ),
    );
  }
}