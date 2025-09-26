import 'dart:convert';
import 'dart:math';
import 'package:asinovapp/variables.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'input.dart';
class Login extends StatefulWidget {
  final Function(dynamic)? log;
  const Login({super.key,this.log});

  @override
  State<Login> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Login> {
  late Function(dynamic) log=widget.log!;
  String user="";
  String clave="";
  String clave_repe="";
  String codigo="";
  @override
  void initState(){
    super.initState();
  }
  void setCodigoRecuperacion(String s){
    setState((){
      codigo=s;
    });
  }
  void comprobar_cod(String str,dynamic usuario){
    bool acierto=codigo==str;
    if (acierto){
      user=usuario['email'];
    }
    showDialog(barrierDismissible: !acierto,context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text(acierto?"Cambiar Contraseña":"Error"),
        content:acierto?Column(mainAxisSize: MainAxisSize.min,children: [
          Input(change:(s){setState((){clave=s;});},hint: "Contraseña",obscure: true,),
          Input(change:(s){setState((){clave_repe=s;});},hint: "Repetir contraseña",obscure: true,),
        ],):Text("Código Incorrecto"),
        actions: [
          if(acierto)
            TextButton(onPressed: (){Navigator.of(context).pop();setState((){user="";clave="";clave_repe="";});}, child: Text("Cancelar")),
          TextButton(onPressed: (){if(acierto){if(clave==clave_repe && comprobar_clave(clave)){Navigator.of(context).pop();actualizar(usuario,clave);}else{error_claves();}}else{Navigator.of(context).pop();}}, child: Text(acierto?"Guardar":"OK"))
            ],
      );
    });
  }
  void actualizar(usuario,clave)async{
    var nuevo=jsonDecode((await http.get(Uri.https('www.asinova.es','/webapi/api/Usuarios/${usuario['id']}'))).body);
    nuevo['clave']=encriptar(clave);
    var response=await http.put(Uri.parse('https://www.asinova.es/webapi/api/Usuarios'),headers: {'Content-Type':'application/json'},body:jsonEncode(nuevo));
    if (response.statusCode==204){
      log(nuevo);
    }
    else if (response.statusCode==500){
      error(context,"Esta contraseña ya existe");
    }
  }
  void error_claves(){
    error(context,"Las contraseñas deben coincidir y tener 8 caracteres, una mayúscula, una minúsucula, un nº y un símbolo");
  }
  void codigo_recuperacion(String u)async{
    var lista=await getLista('Usuarios/sin-perfil');
    var posiblesUsuarios=lista.where((x)=>((x['nick'].toString().toLowerCase()==u.toLowerCase() || x['email'].toString().toLowerCase()==u.toLowerCase())));
    if (posiblesUsuarios.isEmpty){
      error(context,'Usuario no encontrado');
    }
    else{
      dynamic u=posiblesUsuarios.toList()[0];
      String email=u['email'];
      var random=Random();
      int cod=random.nextInt(10000);
      String strcod=cod.toString().padLeft(4,'0');
      Map<String,dynamic> correo={
        "para":email,
        "asunto":"Código de Recuperación",
        "mensaje":strcod
      };
      await http.post(Uri.parse('https://www.asinova.es/gmail'),headers: {'Content-Type':'application/json'},body:jsonEncode(correo));
      showDialog(barrierDismissible: false,context: context, builder: (BuildContext context){
          return AlertDialog(
            title: Text('CODIGO DE RECUPERACIÓN'),
            content: Column(mainAxisSize: MainAxisSize.min,children:[
              Text("Código enviado a ${email}"),
              Input(max: 4,tipo: TextInputType.number,change: (s){setCodigoRecuperacion(s);},),
            ]),
            actions: [TextButton(onPressed: (){Navigator.of(context).pop();}, child: Text("Cancelar")),TextButton(onPressed: (){Navigator.of(context).pop();comprobar_cod(strcod,u);}, child: Text("Enviar"))],
          );
        });
    }
  }
  void enviar(){
    String u="";
    showDialog(context: context, builder: (BuildContext context){
      return AlertDialog(
        title: Text("Enviar código a usuario:"),
        content:Input(hint: "Nick o Email",change: (s){setState((){u=s;});},),
        actions: [TextButton(onPressed: (){codigo_recuperacion(u);Navigator.of(context).pop();}, child: Text("Enviar"))],
      );
    });
  }
  void loguear()async{
    String clave_encriptada=encriptar(clave);
    String id="";
    List<dynamic> lista=await getLista('Usuarios/sin-perfil');
    if (lista.where((x)=>(x['nick'].toString().toLowerCase()==user.toLowerCase() || x['email'].toString().toLowerCase()==user.toLowerCase()) && x['clave']==clave_encriptada).toList().isNotEmpty){
      id=lista.where((x)=>(x['nick'].toString().toLowerCase()==user.toLowerCase() || x['email'].toString().toLowerCase()==user.toLowerCase()) && x['clave']==clave_encriptada).toList()[0]['id'];
      var res2=await http.get(Uri.https('www.asinova.es','/webapi/api/Usuarios/${id}'));
      log(jsonDecode(res2.body));
    }
    else{
      error(context, "Usuario o contraseña incorrectos");
    }
  }
  @override
  Widget build(BuildContext context) {
    return column([
      Input(value: user,hint: "Nick o email",change: (s){setState((){user=s;});},),
      Input(value: clave,hint: "Contraseña",change: (s){setState((){clave=s;});},obscure: true,),
      TextButton(onPressed: (){loguear();}, child: Text("Iniciar Sesión")),
      ElevatedButton(onPressed: (){enviar();}, child: Text("Contraseña olvidada"))
    ]);
  }
}