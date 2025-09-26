import 'package:flutter/material.dart';

class RefreshButton extends StatefulWidget {
  final Function()? onPressed;
  const RefreshButton({super.key,this.onPressed});

  @override
  State<RefreshButton> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<RefreshButton> with TickerProviderStateMixin{
  late Function() onPressed=widget.onPressed!;
  late AnimationController rotacionController=AnimationController(vsync: this,duration: Duration(milliseconds: 500));
  late Animation<double> rotacion=Tween<double>(begin: 0,end: 1).animate(rotacionController);
  @override
  void initState(){
    super.initState();
  }
  @override 
  void dispose() {
    rotacionController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: rotacion, builder: (context,child){
        return Transform.rotate(angle: rotacion.value*2*3.1416,child: child,);
      },
      child:
        IconButton(
          onPressed: () {
            rotacionController.forward(from: 0);
            onPressed();
          },
          icon: Icon(Icons.autorenew),
        )
      );
  }
}