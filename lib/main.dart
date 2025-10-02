import 'dart:convert';

import 'package:asinovapp/centros.dart';
import 'package:asinovapp/clientes.dart';
import 'package:asinovapp/datosusuario.dart';
import 'package:asinovapp/login.dart';
import 'package:asinovapp/proyectos.dart';
import 'package:asinovapp/refreshbutton.dart';
import 'package:asinovapp/register.dart';
import 'package:asinovapp/registros.dart';
import 'package:asinovapp/variables.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyApp>{
  UniqueKey key=UniqueKey();
  late SharedPreferences prefs;
  bool cargando=true;
  dynamic usuario=null;
  List<Widget> paginas=[];
  List<String> titulos=[];
  int index=0;
  String filtrado="";
  PageController controlador=PageController(initialPage: 0);
  Widget pagina=Text("");
  String titulo="";
  String titulo_datos_usuario="Datos de Usuario";
  void set({bool mantener=true})async{
    prefs=await SharedPreferences.getInstance();
    if (prefs.getString("id_usuario")!=null){
      List<dynamic> lista_usuarios=await usuarios_sin_perfil();
      if (lista_usuarios.where((x)=>x['id']==prefs.getString("id_usuario")).toList().isNotEmpty){
        var res=await http.get(Uri.https(url,'${api}Usuarios/${prefs.getString("id_usuario")}'));
        setState((){
          log(jsonDecode(res.body),mantener:mantener);
        });
      }
      else{
        logout();
      }
    }
    else{
      paginas=[Login(log: iniciar_sesion,),Register(log: registrar),];
      titulos=["Iniciar Sesión","Registrar"];
      titulo=titulos[0];
    }
    setState((){
      cargando=false;
    });
  }
  void iniciar_sesion(dynamic x){
    log(x,mantener:false);
  }
  void registrar(dynamic x){
    log(x,mantener: false);
  }
  void log(dynamic x,{bool mantener=true}){
    setState((){
      if (!mantener){
        index=0;
      }
      usuario=x;
      prefs.setString("id_usuario",x['id']);
      paginas=[Registros(usuario: usuario,),Proyectos(usuario:usuario,filtrado: (s){setState((){filtrado=s;});},),Centros(filtrado: (s){setState((){filtrado=s;});},),Clientes(filtrado:(s){setState((){filtrado=s;});})];
      titulos=["Registros","Proyectos","Centros","Clientes"];
      if (!mantener){
        pagina=paginas[0];
        titulo=titulos[0];
      }
    });
  }
  void logout()async {
    await prefs.remove("id_usuario");
    usuario=null;
    setState((){
      paginas=[Login(log: iniciar_sesion,),Register(log: registrar),];
      titulos=["Iniciar Sesión","Registrar"];
      titulo=titulos[0];
    });
  }
  @override 
  void initState() {
    super.initState();
    set(mantener:false);
  }
  void refrescar({bool mantener=true}){
    setState((){
      filtrado="";
      set(mantener: mantener);
      key=UniqueKey();
    });
  }
  void setPagina(String value){
    setState((){
      titulo=value;
      if (value==titulo_datos_usuario){
        pagina=DatosUsuario(usuario:usuario,log:log);
      }
      else{
        index=titulos.indexOf(value);
        pagina=paginas[index];
      }
      if(usuario==null){
        controlador.jumpToPage(index);
      }
      else{
        refrescar();
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: cargando?Center(child: CircularProgressIndicator(),):SafeArea(child:
          Scaffold(
            appBar: AppBar(
              toolbarHeight: 65,
              title: Stack(alignment: Alignment.centerLeft,children:[
                Text(titulo,style: TextStyle(color:black,fontSize: 20),),
                Column(crossAxisAlignment: CrossAxisAlignment.start,mainAxisSize: MainAxisSize.min,children:[SizedBox(height: 40,),Text(filtrado,style: TextStyle(fontSize: 12,color: black),)])
                ]
              ),
              actions: [
                if (usuario!=null)
                  RefreshButton(onPressed: (){refrescar();},),
                if (usuario!=null)
                  PopupMenuButton<String>(
                    icon: Text(usuario['nick'],style: TextStyle(color: Colors.black),),
                    onSelected: (value)=>{
                      if (value=='datos_usuario'){
                        setPagina(titulo_datos_usuario)
                      }
                      else if (value=='logout'){
                        Future.delayed(Duration(milliseconds: 500),()=>{
                          logout()
                        })
                      }
                    },
                    itemBuilder: (context)=>[
                      PopupMenuItem(value: "datos_usuario",child: Text(titulo_datos_usuario)),
                      PopupMenuItem(value:'logout',child: Text("Cerrar Sesión")),
                    ],
                  ),
                PopupMenuButton<String>(onSelected: (value)=>{setPagina(value)},itemBuilder: (context)=>List<PopupMenuItem<String>>.from(titulos.map((x)=>PopupMenuItem(value:x,child: Text(x),))))
              ],
            ),
            body: KeyedSubtree(
              key: key,
              child:PopScope(canPop: index==0 && titulo!=titulo_datos_usuario,onPopInvokedWithResult: (b,d){setPagina(titulos[0]);},child: usuario==null?
                PageView(onPageChanged: (value){setState((){index=value;titulo=titulos[value];});},controller: controlador,children:paginas)
                :pagina)
          )
        )
      ),
    );
  }
}