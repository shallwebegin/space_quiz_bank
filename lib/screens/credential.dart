// ignore_for_file: sized_box_for_whitespace, use_build_context_synchronously

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:kivi_app/screens/adminastor.dart';
import 'package:kivi_app/screens/categories.dart';
import 'package:kivi_app/screens/student.dart';
import 'package:kivi_app/widgets/user_image_picker.dart';

class CredentialScreen extends StatefulWidget {
  const CredentialScreen({super.key});

  @override
  State<CredentialScreen> createState() => _CredentialScreenState();
}

class _CredentialScreenState extends State<CredentialScreen> {
  var isLogin = true;
  var _enteredEmail = '';
  var _enteredPassword = '';
  var _enteredUsername = '';
  var isAuthentication = false;
  var isManager = false;
  final _form = GlobalKey<FormState>();

  void credentialUser() async {
    final isValid = _form.currentState!.validate();
    if (!isValid) {
      return;
    }
    _form.currentState!.save();
    try {
      setState(() {
        isAuthentication = true;
      });
      if (isLogin) {
        final userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
                email: _enteredEmail, password: _enteredPassword);
        if (isManager && !isUserManager(userCredential.user!)) {
          showAlertDialog(
              context, 'Hata', 'Yonetici Yetkisine Sahip Değilsiniz');
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => isManager
                  ? const AdminastorPage()
                  : const CategoriesScreen(mevcutDersler: []),
            ),
          );
        }
      } else {
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: _enteredEmail, password: _enteredPassword);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCredential.user!.uid}.jpg');
        await storageRef.putFile(
          pickedImage!,
          SettableMetadata(contentType: 'image/jpg'),
        );
        final imageUrl = await storageRef.getDownloadURL();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'username': _enteredUsername,
          'email': _enteredEmail,
          'image_url': imageUrl,
        });
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        //....
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Authentication Failed'),
        ),
      );
    } finally {
      setState(() {
        isAuthentication = false;
      });
    }
  }

  bool isUserManager(User user) {
    return user.email != null && user.email!.contains('@yonetici.com');
  }

  void showAlertDialog(BuildContext context, String title, String message) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Tamam'),
              ),
            ],
          );
        });
  }

  File? pickedImage;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Opacity(
            opacity: 0.77,
            child: Container(
              child: Image.asset(
                'assets/images/kivi.jpg',
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Card(
              margin: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _form,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Hero(
                        tag: 'logo',
                        child: Container(
                          height: 100,
                          child: Image.asset('assets/images/Group.png'),
                        ),
                      ),
                      if (!isLogin)
                        UserImagePicker(
                          onPickImage: (image) {
                            pickedImage = image;
                          },
                        ),
                      TextFormField(
                        decoration:
                            const InputDecoration(labelText: 'Email Address'),
                        keyboardType: TextInputType.emailAddress,
                        textCapitalization: TextCapitalization.none,
                        autocorrect: false,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty ||
                              !value.contains('@')) {
                            return 'Lütfen Düzgün bir Mail adresi giriniz';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _enteredEmail = value!;
                        },
                      ),
                      if (!isLogin)
                        TextFormField(
                          decoration:
                              const InputDecoration(labelText: 'Username'),
                          autocorrect: false,
                          validator: (value) {
                            if (value == null || value.trim().length < 4) {
                              return 'Lütfen Düzgün bir Username giriniz';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _enteredUsername = value!;
                          },
                        ),
                      TextFormField(
                        decoration:
                            const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.trim().length < 6) {
                            return 'Lütfen Düzgün bir password giriniz';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _enteredPassword = value!;
                        },
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      if (isAuthentication) const CircularProgressIndicator(),
                      if (!isAuthentication)
                        ElevatedButton(
                          onPressed: credentialUser,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer),
                          child: Text(isLogin ? 'Login' : 'SignUp'),
                        ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isLogin = !isLogin;
                          });
                        },
                        child: Text(isLogin
                            ? 'Create an account'
                            : 'I already have an account'),
                      ),
                      if (isLogin)
                        CheckboxListTile(
                          value: isManager,
                          title: const Text('Yonetici Giriş'),
                          onChanged: (value) {
                            setState(
                              () {
                                isManager = value!;
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
