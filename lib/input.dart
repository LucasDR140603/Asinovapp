import 'package:asinovapp/variables.dart';
import 'package:flutter/material.dart';

class Input extends StatefulWidget {
  final String value;
  final String hint;
  final String label;
  final TextEditingController? controller;
  final Function(String)? change;
  final bool obscure;
  final int max;
  final TextInputType tipo;
  const Input({super.key,this.value="",this.hint="",this.label="",this.controller,this.change,this.obscure=false,this.max=-1,this.tipo=TextInputType.text});
  @override
  State<Input> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Input> {
  late String value=widget.value;
  late String hint=widget.hint;
  late String label=widget.label;
  late TextEditingController controller=widget.controller ?? TextEditingController(text: value);
  late Function(String) change=widget.change!;
  late bool obscure=widget.obscure;
  bool obscure2=true;
  late int max=widget.max;
  late TextInputType tipo=widget.tipo;
  @override
  void initState(){
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return TextField(
      cursorColor: gold,
      minLines: 1,
      maxLines: (tipo == TextInputType.number || tipo == TextInputType.numberWithOptions(decimal: true) || tipo == TextInputType.phone) ? 1 : (obscure ? 1 : 5),
      keyboardType:tipo,
      maxLength: max==-1?null:max,
      obscureText: obscure && obscure2,
      controller: controller,
      onChanged: change,
      style: TextStyle(color: gold),
      decoration: InputDecoration(
        labelText: label.isEmpty?null:label,
        hintText: hint,
        hintStyle: TextStyle(color: lightgold),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: lightgold)
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: lightgold)
        ),
        suffixIcon: obscure?IconButton(style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Color.fromARGB(0, 0, 0, 0))),onPressed: (){setState((){obscure2=!obscure2;});}, icon: Icon(obscure2?Icons.visibility:Icons.visibility_off,color: gold,)):null
      ),
    );
  }
}