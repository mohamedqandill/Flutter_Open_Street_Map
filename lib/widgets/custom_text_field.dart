import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({super.key, required this.textEditingController});
  final TextEditingController textEditingController;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 15),
        child: TextFormField(
          controller: textEditingController,
          decoration: const InputDecoration(
            hintText: "Search...",
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
