import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
const Color gold=Color.fromARGB(255, 255, 215, 0);
const Color lightgold=Color.fromARGB(125, 255, 215, 0);
const Color dark=Color.fromARGB(255, 35,35,45);
const Color dark2=Color.fromARGB(255, 20, 18, 24);
const Color dark3=Color.fromARGB(255, 30,30,40);
const Color black=Colors.black;
const Color light=Color.fromARGB(255, 230, 224, 223);
const Color white38=Colors.white38;
const Color cyanAccent=Colors.cyanAccent;
const Color transparent=Color.fromARGB(0,0,0,0);
const String url='www.asinova.es';
const String api='/webapi/api/';
String getUrlApi(){
  return 'https://${url+api}';
}
ButtonStyle bsgold({double padding=10}){
  return ButtonStyle(padding: WidgetStatePropertyAll(EdgeInsetsGeometry.all(padding)),backgroundColor: WidgetStatePropertyAll(gold),foregroundColor: WidgetStatePropertyAll(Colors.black),overlayColor: WidgetStatePropertyAll(Colors.black12),iconColor: WidgetStatePropertyAll(black));
}
ButtonStyle bscyan({double padding=10}){
  return ButtonStyle(padding: WidgetStatePropertyAll(EdgeInsetsGeometry.all(padding)),backgroundColor: WidgetStatePropertyAll(cyanAccent),foregroundColor: WidgetStatePropertyAll(Colors.black),overlayColor: WidgetStatePropertyAll(Colors.black12));
}
ThemeData theme=ThemeData(
  brightness: Brightness.dark,
  primaryColor: gold,
  textButtonTheme: TextButtonThemeData(style: bsgold()),
  iconButtonTheme: IconButtonThemeData(style: bsgold()),
  appBarTheme: AppBarTheme(foregroundColor: Colors.black,backgroundColor: gold,titleTextStyle: TextStyle(fontSize: 15,color: gold)),
  progressIndicatorTheme: ProgressIndicatorThemeData(color: gold),
  dialogTheme: DialogThemeData(
    titleTextStyle: TextStyle(color: gold,fontSize: 30,fontWeight: FontWeight.bold),
    contentTextStyle: TextStyle(fontSize: 15)
  ),
  scaffoldBackgroundColor: dark2,
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: gold,
    foregroundColor: black
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(foregroundColor: WidgetStatePropertyAll(gold))
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.fromMap(<WidgetState,Color>{WidgetState.selected:dark}),
    trackColor: WidgetStateProperty.fromMap(<WidgetState,Color>{WidgetState.selected:gold})
  ),
  datePickerTheme: DatePickerThemeData(
    todayBackgroundColor: WidgetStateProperty.fromMap(<WidgetState,Color>{
      WidgetState.selected:gold
    }),
    dayBackgroundColor: WidgetStateProperty.fromMap(<WidgetState,Color>{
      WidgetState.selected:gold,
    }),
  ),
  radioTheme: RadioThemeData(fillColor: WidgetStateProperty.fromMap(<WidgetStatesConstraint,Color>{
    WidgetState.selected:gold
  })),
  checkboxTheme: CheckboxThemeData(fillColor: WidgetStateProperty.fromMap(<WidgetStatesConstraint,Color>{
    WidgetState.selected:gold
  })),
  listTileTheme: ListTileThemeData(
    titleTextStyle: TextStyle(fontSize: 18),
    contentPadding: EdgeInsets.fromLTRB(15, 5, 15, 5),
    minTileHeight: 0,
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: gold,
    labelTextStyle: WidgetStatePropertyAll(TextStyle(color: black),),
    textStyle: TextStyle(color: black),
    
  ),
);
String encriptar(String texto){
  return base64Encode(sha256.convert(utf8.encode(texto)).bytes);
}
void error(BuildContext context,String mensaje){
  showDialog(context: context, builder: (BuildContext context){
    return AlertDialog(
      title: Text("ERROR"),
      content: Text(mensaje),
      actions: [TextButton(onPressed: (){Navigator.of(context).pop();}, child: Text("OK"))],
    );
  });
}
Widget column(List<Widget> children,{double maxHeight=double.infinity,double ph=10,double pv=0,double spacing=5,bool border_top=false,bool barra=false,bool expand=false}){
  SingleChildScrollView scroll=SingleChildScrollView(child:Column(crossAxisAlignment: CrossAxisAlignment.stretch,mainAxisSize: expand?MainAxisSize.max:MainAxisSize.min,spacing: spacing,children:[SizedBox(height: 0,),...children,SizedBox(height: 0,)],),);
  Container contenedor=Container(constraints: BoxConstraints(maxHeight: maxHeight),decoration: BoxDecoration(border: border_top?BoxBorder.fromLTRB(top: BorderSide(color: light)):null),padding: EdgeInsets.fromLTRB(ph, pv, ph, pv),child: barra?Scrollbar(thumbVisibility: true,child: scroll):scroll);
  return expand?SizedBox.expand(child:contenedor):contenedor;
}
Widget scroller(Widget child,{double maxHeight=double.infinity,double ph=10,double pv=0,bool barra=false}){
  return Container(constraints: BoxConstraints(maxHeight: maxHeight),padding: EdgeInsets.fromLTRB(ph, pv, ph, pv),child: Scrollbar(thumbVisibility: barra,child: SingleChildScrollView(child:child),));
}
RegExp numeros=RegExp(r'\d');
RegExp simbolos=RegExp(r'[^\w\s]');
bool comprobar_clave(String texto){
  return texto.replaceAll(" ", "").length>=8 && texto.toLowerCase()!=texto && texto.toUpperCase()!=texto && numeros.hasMatch(texto) && simbolos.hasMatch(texto);
}
bool comprobar_telefono(String texto){
  return texto.replaceAll(" ", "").length==9 && numeros.hasMatch(texto) && texto.toLowerCase()==texto && texto.toUpperCase()==texto && !simbolos.hasMatch(texto);
}
bool vacio(String texto){
  return texto.replaceAll(" ", "").isEmpty;
}
Future<List<dynamic>> usuarios_sin_perfil({bool cerrados=false})async{
  var res=await http.get(Uri.https(url,'${api}Usuarios/sin-perfil${cerrados?'/abierto-cerrado':''}'));
  return List.castFrom(jsonDecode(res.body));
}
Future<List<String>> repeticiones(String nick, String email, String clave, String tlfno)async{
  List<String> campos=[nick,email,clave,tlfno];
  List<String> nombres_campos=['nick','email','clave','telefono'];
  List<dynamic> usuarios=await usuarios_sin_perfil(cerrados: true);
  return nombres_campos.where((x)=>usuarios.where((y)=>y[x]==(x=='clave'?encriptar(campos[nombres_campos.indexOf(x)]):campos[nombres_campos.indexOf(x)])).toList().isNotEmpty).toList();
}
Future<List<String>> repeticiones_usuario(String nick, String email, String clave, String tlfno,dynamic usuario)async{
  List<String> campos=[nick,email,clave,tlfno];
  List<String> nombres_campos=['nick','email','clave','telefono'];
  List<dynamic> usuarios=await usuarios_sin_perfil(cerrados: true);
  return nombres_campos.where((x)=>usuarios.where((y)=>y['id']!=usuario['id'] && (y[x]==(x=='clave'?encriptar(campos[nombres_campos.indexOf(x)]):campos[nombres_campos.indexOf(x)]))).toList().isNotEmpty).toList();
}
String primera_mayuscula(String texto){
  return texto.substring(0, 1).toUpperCase() + texto.substring(1);
}
String mensaje_duplicados(List<String> duplicados){
  return "${primera_mayuscula(duplicados.reduce((v,e)=>v+(e==duplicados.last?" y ":', ')+e))} ${duplicados.length>1?'repetidos':duplicados[0]=='clave'?'repetida':'repetido'}";
}
List<String> vacios(List<String> campos){
  return campos.where((x)=>vacio(x)).toList();
}
Widget text(String texto,{Color color=light,double size=15,bool subrayado=false}){
  return Text(texto,style: TextStyle(color: color,fontSize: size,decoration: subrayado?TextDecoration.underline:TextDecoration.none,decorationColor: color),);
}
Widget item(Function() onTap,String title,Widget child,{bool selected=false,bool finished=true}){
  return InkWell(onTap: (){onTap();},child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),border: BoxBorder.all(width: 1,color: finished?white38:cyanAccent),backgroundBlendMode: BlendMode.lighten,color: selected?gold:finished?dark:black),
    padding: EdgeInsets.all(10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,mainAxisSize: MainAxisSize.min,children: [
      Text(title,style: TextStyle(fontSize: 25,color: selected?black:finished?gold:cyanAccent,fontWeight: FontWeight.bold),),
      child
    ],),
  ),);
}
Widget singleitem(Function() onTap,String title,{bool selected=false,bool finished=true}){
  return InkWell(onTap: (){onTap();},child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),border: BoxBorder.all(width: 1,color: finished?white38:cyanAccent),backgroundBlendMode: BlendMode.lighten,color: selected?gold:finished?dark:black),
    padding: EdgeInsets.all(10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,mainAxisSize: MainAxisSize.min,children: [
      Text(title,style: TextStyle(fontSize: 25,color: selected?black:finished?gold:cyanAccent,fontWeight: FontWeight.bold),),
    ],),
  ),);
}
Widget selector(Function() onTap,String title,String text){
  return InkWell(onTap: (){onTap();},child: Container(width: double.infinity,decoration: BoxDecoration(color: Colors.white10,border: Border.all(color: gold)),padding: EdgeInsets.all(7),child:Column(crossAxisAlignment: CrossAxisAlignment.start,children:[Text(title,style: TextStyle(fontSize: 20),),Text(text,softWrap: true,overflow: TextOverflow.visible,style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: gold),),],),));
}
String getTextoFecha(String texto){
  List<String> amd=texto.split("T")[0].split("-");
  List<String> hms=texto.split("T")[1].split(":");
  return amd[2]+"/"+amd[1]+"/"+amd[0]+" "+hms[0]+":"+hms[1];
}
String getTextoFecha2(DateTime fecha){
  return '${fecha.day.toString().padLeft(2,'0')}/${fecha.month.toString().padLeft(2,'0')}/${fecha.year.toString().padLeft(2,'0')} ${fecha.hour.toString().padLeft(2,'0')}:${fecha.minute.toString().padLeft(2,'0')}';
}
DateTime getFechaActual(){
  return DateTime(DateTime.now().year,DateTime.now().month,DateTime.now().day);
}
String getFechaTexto(String texto){
  List<String> amd=texto.split(" ")[0].split("/");
  List<String> hms=texto.split(" ")[1].split(":");
  String anho=amd[2];
  String mes=amd[1].padLeft(2,'0');
  String dia=amd[0].padLeft(2,'0');
  String hora=hms[0].padLeft(2,'0');
  String minuto=hms[1].padLeft(2,'0');
  return anho+"-"+mes+"-"+dia+"T"+hora+":"+minuto;
}
DateTime getFecha(String texto){
  return DateTime.parse(getFechaTexto(texto));
}
String getStrFechaSinSegundos(String texto){
  String amd=texto.split(" ")[0];
  List<String> hms=texto.split(" ")[1].split(":");
  return amd+" "+hms[0]+":"+hms[1];
}

String getFechaTextoDia(String texto){
  return texto.split(" ")[0];
}
String getFechaTextoHora(String texto){
  return getStrFechaSinSegundos(texto).split(" ")[1];
}
Future<List<dynamic>> getLista(String x)async{
  var res=await http.get(Uri.https(url,api+x));
  return List.castFrom(jsonDecode(res.body));
}
String getHorasMinutos(Duration d){
  String str=d.toString();
  List<String> campos=str.split(":");
  return "${campos[0]}:${campos[1]}";
}
