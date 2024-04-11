import 'dart:math';

import 'package:aegis/components/rounded_button.dart';
import 'package:aegis/constants.dart';
import 'package:aegis/nearby_interface.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class RegistrationScreen extends StatefulWidget {
  static const String id = 'registration_screen';

  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _auth = FirebaseAuth.instance;
  late FirebaseFirestore _firestore;
  bool showSpinner = false;
  late String email;
  late String password;
  late String confirmPassword; // New variable for confirming password
  late String userName;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
  }

  Future<void> _showErrorDialog(String message) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectRandomProfilePicture() async {
    final int randomIndex = Random().nextInt(6); // Generating a random index between 0 and 5
    try {
      final user = await _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.email).update({
          'selectedProfileIndex': randomIndex,
        });
        setState(() {
          showSpinner = false;
          Navigator.pushNamed(context, NearbyInterface.id);
        });
      }
    } catch (e) {
      setState(() {
        showSpinner = false;
      });
      print('Error selecting random profile picture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/bg1.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: ModalProgressHUD(
          inAsyncCall: showSpinner,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    userName = value;
                  },
                  decoration: kTextFieldDecoration.copyWith(hintText: 'Username'),
                ),
                const SizedBox(
                  height: 8.0,
                ),
                TextField(
                  keyboardType: TextInputType.emailAddress,
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    email = value;
                  },
                  decoration: kTextFieldDecoration.copyWith(hintText: 'Enter your email'),
                ),
                const SizedBox(
                  height: 8.0,
                ),
                TextField(
                  obscureText: true,
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    password = value;
                  },
                  decoration: kTextFieldDecoration.copyWith(hintText: 'Enter your password'),
                ),
                const SizedBox(
                  height: 8.0,
                ),
                TextField( // New text field for confirming password
                  obscureText: true,
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    confirmPassword = value;
                  },
                  decoration: kTextFieldDecoration.copyWith(hintText: 'Re-enter your password'),
                ),
                const SizedBox(
                  height: 24.0,
                ),
                RoundedButton(
                  title: 'Register',
                  colour: Colors.deepPurpleAccent,
                  onPressed: () async {
                    if (password != confirmPassword) {
                      // Passwords do not match, show error dialog
                      _showErrorDialog('Passwords do not match');
                      return;
                    }

                    setState(() {
                      showSpinner = true;
                    });

                    try {
                      final newUser = await _auth.createUserWithEmailAndPassword(email: email, password: password);
                      await _firestore.collection('users').doc(email).set({
                        'username': userName,
                      });

                      await _selectRandomProfilePicture(); // Selecting a random profile picture after registration

                    } catch (e) {
                      setState(() {
                        showSpinner = false;
                      });
                      _showErrorDialog(e.toString().replaceAll(RegExp(r'\[.*?\]'), ''));
                      print(e);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}