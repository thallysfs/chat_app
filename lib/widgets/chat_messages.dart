import 'package:chatt_app/widgets/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  const ChatMessage({super.key});

  @override
  Widget build(BuildContext context) {
    // pegar usuário logado
    final authenticatedUser = FirebaseAuth.instance.currentUser!;

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
        // pegando dados da doc instanciada na linha 18
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
          itemBuilder: (ctx, index) {
            final chatMessage = loadedMessages[index].data();
            final nextChatMessage = index + 1 < loadedMessages.length
                ? loadedMessages[index + 1].data()
                : null;

            final currentMesageUserId = chatMessage['userId'];
            final nextMessageUserId =
                nextChatMessage != null ? nextChatMessage['userId'] : null;
            final nextUserIsSame = nextMessageUserId == currentMesageUserId;

            if (nextUserIsSame) {
              // renderizar mensagens enviada pelo usuário logado
              return MessageBubble.next(
                message: chatMessage['text'],
                isMe: authenticatedUser.uid == currentMesageUserId,
              );
              // mensagens de outros usuários
            } else {
              return MessageBubble.first(
                userImage: chatMessage['userImage0'],
                username: chatMessage['username'],
                message: chatMessage['text'],
                isMe: nextMessageUserId == currentMesageUserId,
              );
            }
          },
        );
      },
    );
  }
}
