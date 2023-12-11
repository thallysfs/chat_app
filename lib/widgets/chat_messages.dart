import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  const ChatMessage({super.key});

  @override
  Widget build(BuildContext context) {
    // Aqui usarei a estratégia do Stream para modificar o widget dependendo do valor
    // perceba que o Firestore possui suporte a essa funcionalidade, portanto será usado
    // no parâmetro estream
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chat')
          .orderBy(
            'createdAt',
            descending: true,
          )
          .snapshots(),
      builder: (ctx, chatSnapshots) {
        // verifico se a conexão esta aguardando alguma mudança na collection chat
        if (chatSnapshots.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // verifico se a collection possui dados
        if (!chatSnapshots.hasData || chatSnapshots.data!.docs.isEmpty) {
          return const Center(
            child: Text('No existe mensagens!'),
          );
        }

        if (chatSnapshots.hasError) {
          return const Center(
            child: Text('Algo deu errado!'),
          );
        }

        final loadedMessages = chatSnapshots.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.only(
            bottom: 40,
            left: 13,
            right: 13,
          ),
          // reverse joga o conteúdo para baixo ao invés do padrão que é no top
          reverse: true,
          itemCount: loadedMessages.length,
          itemBuilder: (ctx, index) => {
            final chatMessage = loadedMessages[index].data();
          },
        );
      },
    );
  }
}
