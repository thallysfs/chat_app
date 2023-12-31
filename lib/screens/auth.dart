import 'dart:io';

import 'package:chatt_app/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _firebase = FirebaseAuth.instance;

class Auth extends StatefulWidget {
  const Auth({super.key});

  @override
  State<Auth> createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  // Essa chave é passada dentro do formulário e através dela terei acesso a todos
  //os dados do formulário
  final _form = GlobalKey<FormState>();

  var _isLogin = true;
  var _enteredEmail = '';
  var _enteredPassword = '';
  var _enteredUserName = '';
  File? _selectedImage;
  var _isLoading = false;

  void _submit() async {
    // o método vaidate retorna um booleno
    final isValid = _form.currentState!.validate();

    if (!isValid || _isLogin && _selectedImage == null) {
      return;
    }

    // essa função ativa o onSave que interage com todos os textField
    _form.currentState!.save();

    try {
      setState(() {
        _isLoading = true;
      });

      if (_isLogin) {
        // log user in
        final userCredentials = await _firebase.signInWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);
      } else {
        // register user
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);
        // upload de imagem
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCredentials.user!.uid}.jpeg');

        // pegar imagem e inserir em uma var
        await storageRef.putFile(_selectedImage!);
        final imageUrl = await storageRef.getDownloadURL();

        //salvar dados de usuário no firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredentials.user!.uid)
            .set({
          'username': _enteredUserName,
          'email': _enteredEmail,
          'image_url': imageUrl
        });
      }
      // o on antes define o tipo da excessão, isso deixa o código do erro igual ao da documentação do Firebase
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        // ...
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Falha na autenticação'),
        ),
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: 30,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                width: 200,
                child: Image.asset('assets/images/chat.png'),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                        key: _form,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // só será exibido se não estiver na tela de login
                            if (!_isLogin)
                              UserImagePicker(onPickImage: ((pickedImage) {
                                _selectedImage = pickedImage;
                              })),
                            TextFormField(
                              decoration: const InputDecoration(
                                  labelText: 'Endereço de e-mail'),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty ||
                                    !value.contains('@')) {
                                  return 'Por favor use um e-mail válido';
                                }
                                return null;
                              },
                              onSaved: (newValue) {
                                _enteredEmail = newValue!;
                              },
                            ),
                            if (!_isLogin)
                              TextFormField(
                                decoration:
                                    const InputDecoration(labelText: 'Nome'),
                                enableSuggestions: false,
                                textCapitalization: TextCapitalization.none,
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty ||
                                      value.trim().length < 4) {
                                    return 'Por favor use um nome válido (pelo menos 4 caracteres)';
                                  }
                                  return null;
                                },
                                onSaved: (newValue) {
                                  _enteredUserName = newValue!;
                                },
                              ),
                            TextFormField(
                              decoration: InputDecoration(labelText: 'Senha'),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.trim().length < 6) {
                                  return 'Senha precisa ter pelo menos 6 caracteres';
                                }
                                return null;
                              },
                              onSaved: (newValue) {
                                _enteredPassword = newValue!;
                              },
                            ),
                            const SizedBox(height: 12),
                            if (_isLoading) const CircularProgressIndicator(),
                            if (!_isLoading)
                              ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                ),
                                child: Text(_isLogin ? 'Login' : 'Cadastrar'),
                              ),
                            if (!_isLoading)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isLogin = !_isLogin;
                                  });
                                },
                                child: Text(_isLogin
                                    ? 'Criar uma conta'
                                    : 'Já tenho uma conta'),
                              ),
                          ],
                        )),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
