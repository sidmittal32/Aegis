import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'nearby_interface.dart';

class SelfDeclaration extends StatefulWidget {
  final String userEmail;

  const SelfDeclaration({super.key, required this.userEmail});

  @override
  _SelfDeclarationState createState() => _SelfDeclarationState();
}

class _SelfDeclarationState extends State<SelfDeclaration> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool? symptomSelected;
  bool? contactSelected;
  bool formSubmitted = false;
  bool hasInfectionStatus = false;
  bool isLoading = true;
  late User loggedInUser;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    checkInfectionStatus();
  }

  Future<void> checkInfectionStatus() async {
    try {
      final doc =
          await _firestore.collection('users').doc(widget.userEmail).get();
      if (doc.exists && doc.data()!.containsKey('infection_status')) {
        setState(() {
          hasInfectionStatus = true;
        });
      }
    } catch (e) {
      print(
          'Error updating infection status: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '')}');
      // Handle error
    } finally {
      setState(() {
        isLoading =
            false; // Update loading state regardless of success or failure
      });
    }
  }

  Future<void> _updateInfectionStatus(bool isInfected) async {
    try {
      // Update infection status in Firestore
      await _firestore.collection('users').doc(widget.userEmail).update({
        'infection_status': isInfected ? 'infected' : 'not infected',
      });
      setState(() {
        formSubmitted = true;
      });
    } catch (e) {
      print(
          'Error updating infection status: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '')}');
      // Handle error
    }
  }

  Future<String> getUsernameOfEmail({required String email}) async {
    String res = '';
    await _firestore.collection('users').doc(email).get().then((doc) {
      if (doc.exists) {
        res = doc.data()!['username'];
      } else {
        print("No such document!");
      }
    });
    return res;
  }

  Future<void> getCurrentUser() async {
    try {
      final user = await _auth.currentUser!;
      loggedInUser = user;
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(
                Icons.menu,
                color: Colors.deepPurple,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        centerTitle: true,
        title: Text(
          'Aegis',
          style: TextStyle(
            color: Colors.deepPurple[800],
            fontWeight: FontWeight.bold,
            fontSize: 28.0,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xff764abc)),
              accountName: FutureBuilder<String>(
                future: getUsernameOfEmail(email: loggedInUser.email ?? ''),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(
                      snapshot.data!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  } else {
                    return const SizedBox(); // Placeholder widget while loading
                  }
                },
              ),
              accountEmail: Text(
                loggedInUser.email ?? '', // Use the email as fallback
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundImage: AssetImage('images/logo.png'),
              ),
            ),
            ListTile(
              title: const Text('Nearby Interface'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NearbyInterface(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Self Declaration Form'),
              onTap: () {
              },
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(), // Show CircularProgressIndicator while loading
            )
          : hasInfectionStatus || formSubmitted
              ? const Center(
                  child: Text('The form will reopen in 14 days'),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question 1
                    ListTile(
                      title: const Text(
                          'Have you experienced any COVID-19 symptoms in the last 14 days?'),
                      subtitle: const Text(
                          'Select Yes if you have experienced any symptoms.'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Radio(
                            value: true,
                            groupValue: symptomSelected,
                            onChanged: (value) {
                              setState(() {
                                symptomSelected = value as bool?;
                              });
                            },
                          ),
                          const Text('Yes'),
                          Radio(
                            value: false,
                            groupValue: symptomSelected,
                            onChanged: (value) {
                              setState(() {
                                symptomSelected = value as bool?;
                              });
                            },
                          ),
                          const Text('No'),
                        ],
                      ),
                    ),
                    // Question 2
                    ListTile(
                      title: const Text(
                          'Have you been in close contact with anyone who tested positive for COVID-19 in the last 14 days?'),
                      subtitle: const Text(
                          'Select Yes if you have been in close contact with a positive case.'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Radio(
                            value: true,
                            groupValue: contactSelected,
                            onChanged: (value) {
                              setState(() {
                                contactSelected = value as bool?;
                              });
                            },
                          ),
                          const Text('Yes'),
                          Radio(
                            value: false,
                            groupValue: contactSelected,
                            onChanged: (value) {
                              setState(() {
                                contactSelected = value as bool?;
                              });
                            },
                          ),
                          const Text('No'),
                        ],
                      ),
                    ),
                    // Add more questions as needed
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton(
                            onPressed: () {
                              // If any of the selections is 'Yes', set infection status as infected; otherwise, set it as not infected
                              if (symptomSelected == true ||
                                  contactSelected == true) {
                                _updateInfectionStatus(true);
                              } else {
                                _updateInfectionStatus(false);
                              }
                            },
                            child: const Text('Submit'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
