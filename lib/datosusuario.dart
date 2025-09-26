import 'dart:convert';

import 'package:asinovapp/input.dart';
import 'package:asinovapp/variables.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
class DatosUsuario extends StatefulWidget {
  final dynamic usuario;
  final Function(dynamic)? log;
  const DatosUsuario({super.key,this.usuario,this.log});

  @override
  State<DatosUsuario> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<DatosUsuario> {
  late dynamic usuario=widget.usuario;
  late Function(dynamic) log=widget.log!;
  XFile? foto;
  String nick="";
  String nombre="";
  String apellido1="";
  String apellido2="";
  String clave="";
  String clave_repe="";
  String email="";
  String telefono="";
  void photo(String val)async{
    foto=await ImagePicker().pickImage(source: val=="camara"?ImageSource.camera:ImageSource.gallery);
    List<int> bytes=await foto!.readAsBytes();
    usuario['perfil']=base64Encode(bytes);
    await http.put(Uri.parse('https://www.asinova.es/webapi/api/Usuarios'),headers: {"Content-Type":"application/json"},body: jsonEncode(usuario));
    log(usuario);
  }
  void show(){
    setState((){
      showDialog(context: context, builder: (BuildContext context){
        return AlertDialog(
          title: Text("Opciones de cambio de perfil"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioMenuButton(value: "camara", groupValue: "", onChanged: (val){Navigator.of(context).pop();photo(val!);},child: Text("Cámara"),),
              RadioMenuButton(value: "galeria", groupValue: "", onChanged: (val){Navigator.of(context).pop();photo(val!);},child: Text("Galería"),),
            ]
          ),
          actions: [TextButton(onPressed: (){Navigator.of(context).pop();}, child: Text("Cerrar"))],
        );
      });
    });
  }
  @override
  void initState(){
    super.initState();
    setState((){
      nick=usuario['nick'];
      nombre=usuario['nombre'];
      apellido1=usuario['apellido1'];
      apellido2=usuario['apellido2'];
      email=usuario['email'];
      telefono=usuario['telefono'];
    });
  }
  void registrar()async{
    String mensaje="";
    if (vacio(nombre) || vacio(apellido1) || vacio(apellido2) || vacio(nick) || !comprobar_clave(clave) || clave!=clave_repe || vacio(email) || !comprobar_telefono(telefono)){
      if (vacio(nombre)){
        mensaje+="Falta el nombre";
      }
      else if(vacio(apellido1)){
        mensaje+="Falta el 1º apellido";
      }
      else if(vacio(apellido2)){
        mensaje+="Falta el 2º apellido";
      }
      else if (vacio(nick)){
        mensaje+="Falta el nick";
      }
      else if (!comprobar_clave(clave)){
        mensaje+="La contraseña debe tener como mínimo 8 caracteres, una mayúscula, una minúscula, un nº y un símbolo";
      }
      else if (clave!=clave_repe){
        mensaje+="Las contraseñas no coinciden";
      }
      else if (vacio(email)){
        mensaje+="Falta el email";
      }
      else if (vacio(telefono)){
        mensaje+="Falta el teléfono";
      }
      else if (!comprobar_telefono(telefono)){
        mensaje+="Teléfono incorrecto";
      }
      error(context, mensaje);
    }
    else{
      List<String> duplicados=await repeticiones_usuario(nick, email, clave, telefono,usuario);
      if (duplicados.isNotEmpty){
        error(context, mensaje_duplicados(duplicados));
      }
      else{
        Map<String,dynamic> nuevo={
          "id":usuario['id'],
          "nombre":nombre,
          "apellido1":apellido1,
          "apellido2":apellido2,
          "nick":nick,
          "clave":encriptar(clave),
          "email":email,
          "telefono":telefono,
          "administrador":usuario['administrador'],
          "operativo":true,
          "perfil":usuario['perfil']
        };
        await http.put(Uri.parse('${getUrlApi()}Usuarios'),headers: {'Content-Type':'application/json'},body:jsonEncode(nuevo));
        log(nuevo);
      }
    }
  }
  double imgsize=100;
  @override
  Widget build(BuildContext context) {
    return column([
      Center(child:ClipRRect(borderRadius: BorderRadius.circular(2000),child:Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (){show();},
          child: Container(padding: EdgeInsets.all(10),child:ClipRRect(borderRadius: BorderRadius.circular(2000),child:usuario['perfil']==null?Image.asset("assets/img/ic_user.png",width: imgsize,fit: BoxFit.cover,):Image.memory(width: imgsize,height: imgsize,fit:BoxFit.fill,base64Decode(usuario['perfil'])),
        )),
      )))),
      Input(value: nick,label: "Nick",change: (s){setState((){nick=s;});},),
      Input(value: nombre,label: "Nombre",change: (s){setState((){nombre=s;});},),
      Input(value: apellido1,label: "1º Apellido",change: (s){setState((){apellido1=s;});},),
      Input(value: apellido2,label: "2º Apellido",change: (s){setState((){apellido2=s;});},),
      Input(value:clave,label: "Contraseña",obscure: true,change: (s){setState((){clave=s;});},),
      Input(value:clave,label: "Repetir Contraseña",obscure: true,change: (s){setState((){clave_repe=s;});},),
      Input(value: email,label: "Email",change: (s){setState((){email=s;});},),
      Input(value: telefono,tipo: TextInputType.phone, max:9,label: "Teléfono",change: (s){setState((){telefono=s;});},),
      Row(mainAxisSize: MainAxisSize.min,spacing: 10,children:[Icon(Icons.verified),Text('Administrador: ${usuario['administrador']?'Sí':'No'}',textScaler: TextScaler.linear(1))],),
      Row(mainAxisAlignment: MainAxisAlignment.center,children: [TextButton(onPressed: (){registrar();}, child: Text("Confirmar"))],)
    ]);
  }
}