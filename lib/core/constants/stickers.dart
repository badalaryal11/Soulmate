class Stickers {
  static const List<Map<String, String>> stickerData = [
    {
      'url':
          'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExbDVtc2Vqa3RocWtlaGczMWE0NmxlaXRnODJ4cjdwd2YxcTJlaDUzMyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/26FLdmIp6wJr91JAI/giphy.gif',
      'desc':
          'Patrick Star looking enamored with hands on cheeks, surrounded by pixel hearts',
    },
    {
      'url':
          'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExcGxtZmxhNjZpdHJmMGExdXpnd3J5NXB2NzR6ZGNsbnAxdXR1dWF6bCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/MDJ9IbxxvDUQM/giphy.gif',
      'desc':
          'Pleading cat looking up with an outstretched paw asking for something',
    },
    {
      'url':
          'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExenF2emtxMzFxdXV6MzhpdGVldXZvcGV0MWtiam9uYnJwNXgyYXB6eSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/l4pTfx2qLszoacZRS/giphy.gif',
      'desc':
          'Sassy gnome in a pink swimsuit and green sunglasses dancing smoothly',
    },
    {
      'url':
          'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExdXQyOHE0bHExdGpnZW94YnRvdGR0NGQ3am9nZG13amIzejdmaGQwZiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/3o7TKoWXm3okO1kgHC/giphy.gif',
      'desc': 'Red hearts joyfully falling from the top downwards',
    },
    {
      'url':
          'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExcm5nZHB0ZXFtaDFhMmhtdnhrNXVxc2NueHpvamZ1eDJucDNsOTNnbyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/7kn27lnYSAE9O/giphy.gif',
      'desc':
          'A yellow puppet character, wide-eyed and overjoyed, laughing loudly with a wide-open mouth',
    },
    {
      'url':
          'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNmNxdmQ3dDhybjFmOHp3anl6aDdzZWYxaTN1Mm13ZGg5NnB4eXZpdSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/R6gvnAxj2ISzJdbA63/giphy.gif',
      'desc':
          'Asian man smiling warmly and making a small heart shape with his hands',
    },
    {
      'url':
          'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExYzlqMDhzMjdzeWR5dzc0ejhmcTVyNm5yeWFzbnF3enlxMWg0a24weiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/KztT2c4u8mYYUiMKdJ/giphy.gif',
      'desc': 'Red heart glowing and beating',
    },
    {
      'url': 'https://media.tenor.com/WyYsbi0fei8AAAAC/love-mochi.gif',
      'desc': 'cute peach cat mochi love squeeze',
    },
    {
      'url': 'https://media.tenor.com/_reUPa03zXsAAAAC/love-shine-on.gif',
      'desc': 'happy glowing cat shining with love',
    },
    {
      'url': 'https://media.tenor.com/kqHNV9zBRM8AAAAC/dog-happy-dog.gif',
      'desc': 'a very happy dog shaking its hips',
    },
    {
      'url': 'https://media.tenor.com/d9PoZm99CTgAAAAC/sadcat-crying-cat.gif',
      'desc': 'a very sad crying cat',
    },
    {
      'url': 'https://media.tenor.com/Ydqpw1Nn2JkAAAAC/quby-sad.gif',
      'desc': 'a sad little quby cartoon character',
    },
    {
      'url': 'https://media.tenor.com/T7fRyJXgmB8AAAAC/cute-cat.gif',
      'desc': 'a cute cat waving hello',
    },
  ];

  static final String systemPromptMapping = _buildSystemPromptMapping();

  static String _buildSystemPromptMapping() {
    final buffer = StringBuffer();
    buffer.writeln(
      "If the user sends a message formatted exactly as [USER_STICKER:<index>], it means they sent a visual sticker. Treat it exactly as if they sent an image of the following description:",
    );
    for (int i = 0; i < stickerData.length; i++) {
      buffer.writeln("Index $i: ${stickerData[i]['desc']}");
    }
    return buffer.toString();
  }
}
