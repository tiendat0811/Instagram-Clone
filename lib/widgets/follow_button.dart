import 'package:flutter/material.dart';

class FollowButton extends StatelessWidget {
  final Function()? function;
  final Function()? functionChat;
  final Color backgroundColor;
  final Color borderColor;
  final String text;
  final Color textColor;

  const FollowButton(
      {Key? key,
      required this.backgroundColor,
      required this.borderColor,
      required this.text,
      required this.textColor,
      this.function,
      this.functionChat})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.only(top: 2),
          child: TextButton(
            onPressed: function,
            child: Container(
              height: 30,
              width: MediaQuery.of(context).size.height * 0.15,
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              alignment: Alignment.center,
              child: Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        if(text != "Sign Out" && text != "Follow"  && text != " Following " && text != "Delete")
        Container(
          padding: const EdgeInsets.only(top: 2),
          child: TextButton(
            onPressed: functionChat,
            child: Container(
              height: 30,
              width: MediaQuery.of(context).size.height * 0.15,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              alignment: Alignment.center,
              child: Text(
                "Chat",
                style: TextStyle(
                  color:Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
