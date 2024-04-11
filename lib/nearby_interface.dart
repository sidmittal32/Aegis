import 'package:aegis/constants.dart';
import 'package:aegis/selfdeclaration.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

import 'components/contact_card.dart';

class NearbyInterface extends StatefulWidget {
  static const String id = 'nearby_interface';

  const NearbyInterface({Key? key});

  @override
  State<NearbyInterface> createState() => _NearbyInterfaceState();
}

class _NearbyInterfaceState extends State<NearbyInterface> {
  Location location = Location();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Strategy strategy = Strategy.P2P_STAR;
  late User loggedInUser;
  String testText = '';
  final _auth = FirebaseAuth.instance;
  List<dynamic> contactTraces = [];
  List<dynamic> contactTimes = [];
  List<dynamic> contactLocations = [];
  List<String> profilePictureURLs = [
    'images/profile1.png',
    'images/profile2.png',
    'images/profile3.png',
    'images/profile4.png',
    'images/profile5.png',
    'images/profile6.png',
  ];

  int selectedProfileIndex = -1;

  @override
  void initState() {
    super.initState();
    deleteOldContacts(14);
    addContactsToList();
    getPermissions();
    checkInfectionStatusAndRedirect();
    getSelectedProfileIndex();
  }

  void checkInfectionStatusAndRedirect() async {
    await getCurrentUser();

    try {
      DocumentSnapshot snapshot = await _firestore.collection('users').doc(loggedInUser.email!).get();
      if (snapshot.exists && snapshot.data() is Map<String, dynamic> && (snapshot.data() as Map<String, dynamic>).containsKey('infection_status')) {
        // If infection status is set, no need to show the alert
        return;
      }
    } catch (e) {
      print('Error fetching infection status: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '')}');
    }

    // Show the alert if infection status is not set
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Alert"),
            content: const Text(
              "Your infection status is empty. Please fill the self-declaration form.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelfDeclaration(userEmail: loggedInUser.email!),
                    ),
                  );
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    });
  }

  void addContactsToList() async {
    await getCurrentUser();

    _firestore
        .collection('users')
        .doc(loggedInUser.email)
        .collection('met_with')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        String currUsername = doc.data()!['username'];
        DateTime? currTime = doc.data()!.containsKey('contact time')
            ? (doc.data()!['contact time'] as Timestamp).toDate()
            : null;
        String? currLocation = doc.data()!.containsKey('contact location')
            ? doc.data()!['contact location']
            : null;

        if (!contactTraces.contains(currUsername)) {
          contactTraces.add(currUsername);
          contactTimes.add(currTime);
          contactLocations.add(currLocation);
        }
      }
      setState(() {});
    });
  }

  void deleteOldContacts(int threshold) async {
    await getCurrentUser();
    DateTime timeNow = DateTime.now();

    _firestore
        .collection('users')
        .doc(loggedInUser.email)
        .collection('met_with')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        if (doc.data()!.containsKey('contact time')) {
          DateTime contactTime =
          (doc.data()!['contact time'] as Timestamp).toDate();
          if (timeNow.difference(contactTime).inDays > threshold) {
            doc.reference.delete();
          }
        }
      }
    });

    setState(() {});
  }

  bool discovering = false;

  void discovery() async {
    if (discovering) return;
    discovering = true;

    try {
      String email = loggedInUser.email!;
      bool a = await Nearby().startDiscovery(email, strategy,
          onEndpointFound: (id, name, serviceId) async {
            print('I saw id:$id with name:$name');

            var docRef = _firestore.collection('users').doc(email);

            docRef.collection('met_with').doc(name).set({
              'username': await getUsernameOfEmail(email: name),
              'contact time': DateTime.now(),
              'contact location': (await location.getLocation()).toString(),
            });
          }, onEndpointLost: (id) {
            print(id);
          });
      print('DISCOVERING: ${a.toString()}');
    } catch (e) {
      print(e);
      // Show error message to user
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    } finally {
      discovering = false;
    }
  }

  void getPermissions() async {
    var status = await Permission.location.request();
    if (status.isDenied) {
      // The user denied the location permission
      // Handle accordingly
    }

    status = await Permission.storage.request();
    if (status.isDenied) {
      // The user denied the storage permission
      // Handle accordingly
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

  Future<void> getSelectedProfileIndex() async {
    try {
      final user = await _auth.currentUser;
      if (user != null) {
        final userData = await _firestore.collection('users').doc(user.email).get();
        if (userData.exists && userData.data() != null && userData.data()!.containsKey('selectedProfileIndex')) {
          setState(() {
            selectedProfileIndex = userData.data()!['selectedProfileIndex'];
          });
        }
      }
    } catch (e) {
      print('Error fetching selected profile index: $e');
    }
  }

  Future<String> _getInfectionStatus(String email) async {
    // Fetch infection status for the given email from Firestore
    String status = 'Not-Infected';
    try {
      DocumentSnapshot snapshot =
      await _firestore.collection('users').doc(email).get();
      if (snapshot.exists) {
        Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;

        // Check if data is not null and contains the 'infected' key
        if (data != null && data.containsKey('infected')) {
          // Explicitly cast data['infected'] to bool and check its value
          status = (data['infected'] as bool) ? 'Infected' : 'Not-Infected';
        }
      }
    } catch (e) {
      print('Error fetching infection status: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '[Hidden]')}');
    }
    return status;
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
        child: FutureBuilder<void>(
          future: getSelectedProfileIndex(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else {
              return ListView(
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
                    currentAccountPicture: selectedProfileIndex != -1
                        ? CircleAvatar(
                      backgroundImage: AssetImage(profilePictureURLs[selectedProfileIndex]),
                    )
                        : const CircleAvatar(
                      backgroundImage: AssetImage('images/profile1.png'), // Default profile picture
                    ),
                  ),
                  ListTile(
                    title: const Text('Nearby Interface'),
                    onTap: () {
                    },
                  ),
                  ListTile(
                    title: const Text('Self Declaration Form'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelfDeclaration(userEmail: loggedInUser.email ?? ''),
                        ),
                      );
                    },
                  ),
                ],
              );
            }
          },
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 25.0,
                right: 25.0,
                bottom: 10.0,
                top: 30.0,
              ),
              child: Container(
                height: 100.0,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.deepPurple[500],
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 4.0,
                      spreadRadius: 0.0,
                      offset: Offset(2.0, 2.0),
                    )
                  ],
                ),
                child: const Row(
                  children: <Widget>[
                    Expanded(
                      child: Image(
                        image: AssetImage('images/corona.png'),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Your Contact Traces',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 21.0,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                backgroundColor: Colors.deepPurple[400],
                elevation: 5.0,
              ),
              onPressed: () async {
                try {
                  String email = loggedInUser.email!;
                  bool a = await Nearby().startAdvertising(
                    email,
                    strategy,
                    onConnectionInitiated: (id, info) {
                      // Handle connection initiation
                    },
                    onConnectionResult: (id, status) {
                      print(status);
                    },
                    onDisconnected: (id) {
                      print('Disconnected $id');
                    },
                  );

                  print('ADVERTISING ${a.toString()}');
                } catch (e) {
                  print(e);
                  // Show error message to user
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Error"),
                        content: Text(e.toString()),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text("OK"),
                          ),
                        ],
                      );
                    },
                  );
                }

                discovery();
              },
              child: const Text(
                'Start Tracing',
                style: kButtonTextStyle,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: ListView.builder(
                itemBuilder: (context, index) {
                  return FutureBuilder<String>(
                    future: _getInfectionStatus(contactTraces[index]),
                    builder: (context, snapshot) {
                      String infectionStatus = snapshot.data ?? 'Unknown';
                      return ContactCard(
                        imagePath: 'images/profile.jpeg',
                        email: contactTraces[index],
                        infection: infectionStatus,
                        contactUsername: contactTraces[index],
                        contactTime: contactTimes[index],
                        contactLocation: contactLocations[index],
                      );
                    },
                  );
                },
                itemCount: contactTraces.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}