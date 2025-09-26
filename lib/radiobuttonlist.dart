import 'package:flutter/material.dart';
import 'input.dart';

class RadiobuttonList extends StatefulWidget {
  final List<dynamic>? lista;
  final List<String>? ids;
  final BuildContext? contexto;
  final Function(List<String>,int)? actualizar;
  const RadiobuttonList({super.key,this.lista,this.ids,this.contexto,this.actualizar});

  @override
  State<RadiobuttonList> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<RadiobuttonList> {
  late List<dynamic> lista=widget.lista!;
  late List<String> ids=widget.ids!;
  late Function(List<String>,int) actualizar=widget.actualizar!;
  void check_radiobutton(dynamic val,int index){
    for (int i=0; i<ids.length; i++){
      if (ids[i]!="no"){
        ids[i]="";
      }
    }
    ids[index]=val;
    actualizar(ids,index);
  }
  String busqueda="";
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min,children: [
      Container(constraints: BoxConstraints(maxHeight: widget.contexto!=null?MediaQuery.of(widget.contexto!).size.height-250:500),
      child: Column(mainAxisSize: MainAxisSize.min,
      children: [
        Input(hint: "Buscar",value: busqueda,change: (s){setState((){busqueda=s;});},),
        Container(constraints: BoxConstraints(maxHeight: 200),child:Scrollbar(thumbVisibility: true,child: SingleChildScrollView(child: Column(children:
          List<Widget>.from(lista.where((x)=>ids[lista.indexOf(x)]!="no" && x['nombre'].toString().contains(busqueda)).map((x)=>RadioMenuButton(value: x['id'], groupValue: ids.where((y)=>y!="" && y!="no").toList().length==1?ids.where((y)=>y!="" && y!="no").toList()[0]:"todos", onChanged: (val){check_radiobutton(val,lista.indexOf(x));Navigator.of(context).pop();}, child: Text(x['nombre']))),)
        ),)),),
    ]))],);
  }
}