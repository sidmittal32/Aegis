import 'package:flutter/material.dart';

class BottomSheetText extends StatelessWidget {
  const BottomSheetText({super.key,
    required this.question,
    required this.result,
  });

  final String question;
  final String result;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: <TextSpan>[
          TextSpan(
              text: '$question: ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22.0,
              )),
          TextSpan(
            text: '$result',
            style: const TextStyle(
              fontSize: 20.0,
            ),
          ),
        ],
      ),
    );
  }
}