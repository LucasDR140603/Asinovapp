import 'package:asinovapp/input.dart';
import 'package:asinovapp/variables.dart';
import 'package:flutter/material.dart';

class AddEditCliente extends StatefulWidget {
  final dynamic cliente;
  final Function(dynamic)? guardar;
  const AddEditCliente({super.key,this.cliente,this.guardar});

  @override
  State<AddEditCliente> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<AddEditCliente> {
  late dynamic cliente=widget.cliente;
  late Function(dynamic) guardar=widget.guardar!;
  void setValores(){
    if (vacio(cliente['nombre'])){
      error(context, "Nombre obligatorio");
    }
    else{
      guardar(cliente);
    }
  }
  @override
  Widget build(BuildContext context) {
    return column([
      Input(value: cliente['nombre'],label: "Nombre",change: (s){setState((){cliente['nombre']=s;});},),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [
        TextButton(onPressed: (){Navigator.of(context).pop();}, child: Text("Cancelar")),
        TextButton(onPressed: (){Navigator.of(context).pop();setValores();}, child: Text("Confirmar"))
      ],)
    ]);
  }
}