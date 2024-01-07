import 'dart:convert';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:share_plus/share_plus.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  dynamic text = '';
  List<dynamic> chats = [
    "Hello! I'm here to assist you. Would you like me to help you create a song? Feel free to provide any specific themes, emotions, or lyrics you have in mind, and let's get started on crafting your unique song together!/////false",
  ];
  bool animate = true;
  TextEditingController _textEditingController = TextEditingController();
  Future<void> gettext() async {
    const apiUrl = 'http://35.226.106.100:8080/random_paragraph';
    print('pass');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'prompt': chats[1].toString().split('/////')[0]}),
      );
      print(chats[1].toString().split('/////')[0]);

      print('Response: ${response.body}');
      print(response.body + 'helllo');
      chats.removeAt(0);
      setState(() {
        text = jsonDecode(response.body.toString());
        chats.insert(0, text["random_paragraph"] + "/////false");
      });
      print(chats.length.toString() + 'helllo');
    } catch (error) {
      print(error.toString() + 'cath');
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //gettext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff080808),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => Home(),
                ),
              );
            },
          ),
        ],
        title: Text(
          "  MeloGPT",
          style: TextStyle(
              color: Color(0xff458BE7),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              fontStyle: FontStyle.italic),
        ),
        //centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Stack(
          children: [
            ListView.builder(
              reverse: true,
              padding: EdgeInsets.only(bottom: 80),
              physics: BouncingScrollPhysics(),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: chats[index].split('/////')[1] == 'true'
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 1.4,
                        child: Column(
                          children: [
                            ChatBubble(
                              shadowColor: Colors.transparent,
                              backGroundColor:
                                  chats[index].split('/////')[1] == 'true'
                                      ? const Color(0xff458BE7)
                                      : const Color.fromARGB(255, 37, 37, 37),
                              alignment:
                                  chats[index].split('/////')[1] == 'true'
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                              clipper: ChatBubbleClipper3(
                                  type: chats[index].split('/////')[1] == 'true'
                                      ? BubbleType.sendBubble
                                      : BubbleType.receiverBubble),
                              child: chats[index].split('/////')[0] == 'Loading'
                                  ? LoadingAnimationWidget.staggeredDotsWave(
                                      color: Colors.white,
                                      size: 30,
                                    )
                                  : (chats[index].split('/////')[1] ==
                                                  'false' &&
                                              index == 0) &&
                                          animate == true
                                      ? AnimatedTextKit(
                                          animatedTexts: [
                                            TypewriterAnimatedText(
                                              chats[index].split('/////')[0],
                                              textAlign: TextAlign.start,
                                              textStyle: TextStyle(
                                                  fontSize: 14.0,
                                                  color: Colors.white
                                                  //fontWeight: FontWeight.bold,
                                                  ),
                                              speed: const Duration(
                                                  milliseconds: 20),
                                            ),
                                          ],
                                          onFinished: () {
                                            setState(() {
                                              animate = false;
                                            });
                                          },
                                          totalRepeatCount: 1,
                                          pause: const Duration(
                                              milliseconds: 1000),
                                          displayFullTextOnTap: true,
                                          stopPauseOnTap: true,
                                        )
                                      : Text(
                                          chats[index].split('/////')[0],
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14.0,
                                          ),
                                        ),
                            ),
                            Visibility(
                              visible:
                                  chats[index].split('/////')[1] == 'false' &&
                                          chats[index].split('/////')[0] !=
                                              'Loading' &&
                                          index != chats.length - 1
                                      ? true
                                      : false,
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Row(
                                  children: [
                                    IconButton(
                                        onPressed: () {
                                          Share.share(
                                              chats[index].split('/////')[0]);
                                        },
                                        icon: Icon(
                                          CupertinoIcons.share,
                                          color: Colors.white,
                                          size: 18,
                                        )),
                                    IconButton(
                                        onPressed: () {
                                          setState(() {
                                            chats.insert(0, chats[index + 1]);
                                            chats.insert(
                                                0, "Loading" + "/////false");
                                            animate = true;
                                          });
                                          gettext();
                                        },
                                        icon: Icon(
                                          Icons.replay_outlined,
                                          color: Colors.white,
                                          size: 20,
                                        )),
                                    IconButton(
                                        onPressed: () async {
                                          await Clipboard.setData(ClipboardData(
                                              text: chats[index]
                                                  .split('/////')[0]));
                                        },
                                        icon: Icon(
                                          Icons.copy,
                                          color: Colors.white,
                                          size: 18,
                                        )),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 110.0,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0xff121212),
                      Colors.black
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                // height: 120,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Container(
                          width: MediaQuery.of(context).size.width / 1.3,
                          decoration: BoxDecoration(
                              color: Color(0xff1A1A1A),
                              borderRadius: BorderRadius.circular(10)),
                          child: TextField(
                            controller: _textEditingController,
                            maxLines: 5,
                            minLines: 1,
                            style: TextStyle(color: Colors.white),
                            onChanged: (t) {
                              setState(() {});
                            }, // Set text color
                            decoration: InputDecoration(
                                suffixIcon: _textEditingController.text
                                            .trimLeft()
                                            .trimRight() !=
                                        ''
                                    ? IconButton(
                                        onPressed: () {
                                          _textEditingController.clear();
                                          setState(() {});
                                        },
                                        icon: Icon(
                                          CupertinoIcons.clear,
                                          color: Colors.white,
                                          size: 15,
                                        ),
                                      )
                                    : IconButton(
                                        onPressed: () {},
                                        icon: Icon(
                                          CupertinoIcons.lightbulb,
                                          color: Colors.white,
                                          size: 15,
                                        ),
                                      ),
                                focusColor: Colors.transparent,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                // Set label color
                                hintText: 'Type a message to MeloGPT',
                                hintStyle:
                                    TextStyle(color: Colors.grey, fontSize: 14),
                                border: InputBorder.none),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: chats[0].split('/////')[0] == 'Loading'
                                ? SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: LoadingAnimationWidget.inkDrop(
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                        color: Color(0xff458BE7),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: IconButton(
                                      icon: const Icon(
                                          CupertinoIcons.paperplane,
                                          color: Colors.white),
                                      onPressed: () {
                                        // Add your send message logic here
                                        if (_textEditingController.text
                                                .trimLeft()
                                                .trimRight() !=
                                            '') {
                                          setState(() {
                                            chats.insert(
                                                0,
                                                _textEditingController.text
                                                        .toString() +
                                                    "/////true");
                                            chats.insert(
                                                0, "Loading" + "/////false");
                                            animate = true;
                                          });
                                          print(animate);
                                          _textEditingController.clear();
                                          gettext();
                                        }
                                      },
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ]),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: 140.0,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black,
                      Color.fromARGB(255, 10, 10, 10),
                      Colors.transparent
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
