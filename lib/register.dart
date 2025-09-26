import 'dart:convert';

import 'package:asinovapp/input.dart';
import 'package:asinovapp/variables.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart' as uuid;
class Register extends StatefulWidget {
  final Function(dynamic)? log;
  const Register({super.key,this.log});

  @override
  State<Register> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Register> {
  late Function(dynamic) log=widget.log!;
  String nombre="";
  String apellido1="";
  String apellido2="";
  String nick="";
  String clave="";
  String clave_repe="";
  String email="";
  String telefono="";
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
      List<String> duplicados=await repeticiones(nick, email, clave, telefono);
      if (duplicados.isNotEmpty){
        error(context, mensaje_duplicados(duplicados));
      }
      else{
        Map<String,dynamic> usuario={
          "id":uuid.Uuid().v4(),
          "nombre":nombre,
          "apellido1":apellido1,
          "apellido2":apellido2,
          "nick":nick,
          "clave":encriptar(clave),
          "email":email,
          "telefono":telefono,
          "administrador":false,
          "operativo":true,
          "perfil":null
        };
        await http.post(Uri.parse('${getUrlApi()}Usuarios'),headers: {'Content-Type':'application/json'},body:jsonEncode(usuario));
        log(usuario);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return column([
      Input(hint: "Nombre",change: (s){setState((){nombre=s;});},),
      Input(hint: "1º Apellido",change: (s){setState((){apellido1=s;});},),
      Input(hint: "2º Apellido",change: (s){setState((){apellido2=s;});},),
      Input(hint: "Nick",change: (s){setState((){nick=s;});},),
      Input(hint: "Contraseña",obscure: true,change: (s){setState((){clave=s;});},),
      Input(hint: "Repetir Contraseña",obscure: true,change: (s){setState((){clave_repe=s;});},),
      Input(hint: "Email",change: (s){setState((){email=s;});},),
      Input(hint: "Teléfono",tipo: TextInputType.phone, max:9,change: (s){setState((){telefono=s;});},),
      TextButton(onPressed: (){registrar();}, child: Text("Registrar"))
    ]);
  }
}