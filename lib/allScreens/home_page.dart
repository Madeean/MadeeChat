import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:madee_chat_app/allConstants/color_constants.dart';
import 'package:madee_chat_app/allConstants/constants.dart';
import 'package:madee_chat_app/allModels/popup_choices.dart';
import 'package:madee_chat_app/allModels/user_chat.dart';
import 'package:madee_chat_app/allProviders/auth_provider.dart';
import 'package:madee_chat_app/allProviders/home_provider.dart';
import 'package:madee_chat_app/allScreens/chat_page.dart';
import 'package:madee_chat_app/allScreens/login_page.dart';
import 'package:madee_chat_app/allScreens/settings_page.dart';
import 'package:madee_chat_app/allWidgets/loading_view.dart';
import 'package:madee_chat_app/main.dart';
import 'package:madee_chat_app/utilities/debounce.dart';
import 'package:madee_chat_app/utilities/utilities.dart';
import 'package:provider/src/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final ScrollController listScrollController = ScrollController();

  int _limit = 20;
  int _limitIncrement = 20;
  String _textSearch = "";
  bool isLoading = false;

  late String currentUserId;
  late AuthProvider authProvider;
  late HomeProvider homeProvider;

  Debouncer searchDebouncer = Debouncer(miliseconds: 300);
  StreamController<bool> btnClearController = StreamController<bool>();
  TextEditingController searchBarTec = TextEditingController();

  void scrollListener() {
    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    btnClearController.close();
  }

  @override
  void initState() {
    super.initState();
    authProvider = context.read<AuthProvider>();
    homeProvider = context.read<HomeProvider>();

    if (authProvider.getUserFirebaseId()?.isNotEmpty == true) {
      currentUserId = authProvider.getUserFirebaseId()!;
    } else {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false);
    }

    listScrollController.addListener(scrollListener);
  }

  List<PopupChoices> choices = <PopupChoices>[
    PopupChoices(title: "Settings", icon: Icons.settings),
    PopupChoices(title: "Sign out", icon: Icons.exit_to_app),
  ];

  Future<void> handleSignOut() async {
    authProvider.handleSignOut();
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => LoginPage()));
  }

  void onItemMenuPress(PopupChoices choice) {
    if (choice.title == "Sign out") {
      handleSignOut();
    } else {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => SettingsPage()));
    }
  }

  Future<void> openDialog() async {
    switch (await showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          clipBehavior: Clip.hardEdge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: EdgeInsets.zero,
          children: [
            Container(
              color: ColorConstants.themeColor,
              padding: EdgeInsets.only(bottom: 10, top: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: 10),
                    child: Icon(
                      Icons.exit_to_app,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Exit App',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Are you sure to exit app?',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  )
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 0);
              },
              child: Row(
                children: [
                  Container(
                    margin: EdgeInsets.only(right: 10),
                    child: Icon(
                      Icons.cancel,
                      color: ColorConstants.primaryColor,
                    ),
                  ),
                  Text(
                    'Cancel',
                    style: TextStyle(
                      color: ColorConstants.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 1);
              },
              child: Row(
                children: [
                  Container(
                    margin: EdgeInsets.only(right: 10),
                    child: Icon(
                      Icons.check_circle,
                      color: ColorConstants.primaryColor,
                    ),
                  ),
                  Text(
                    'Yes',
                    style: TextStyle(
                      color: ColorConstants.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    )) {
      case 0:
        break;
      case 1:
        exit(0);
    }
  }

  Future<bool> onBackPress() {
    openDialog();
    return Future.value(false);
  }

  Widget buildPopupMenu() {
    return PopupMenuButton<PopupChoices>(
      icon: Icon(
        Icons.more_vert,
        color: Colors.grey,
      ),
      onSelected: onItemMenuPress,
      itemBuilder: (BuildContext context) {
        return choices.map(
          (PopupChoices choice) {
            return PopupMenuItem<PopupChoices>(
              value: choice,
              child: Row(
                children: [
                  Icon(
                    choice.icon,
                    color: ColorConstants.primaryColor,
                  ),
                  Container(
                    width: 10,
                  ),
                  Text(
                    choice.title,
                    style: TextStyle(color: ColorConstants.primaryColor),
                  )
                ],
              ),
            );
          },
        ).toList();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isWhite ? Colors.white : Colors.black,
      appBar: AppBar(
        backgroundColor: isWhite ? Colors.white : Colors.black,
        leading: IconButton(
          icon: Switch(
            value: isWhite,
            onChanged: (value) {
              setState(() {
                isWhite = value;
                print(isWhite);
              });
            },
            activeTrackColor: Colors.grey,
            activeColor: Colors.white,
            inactiveTrackColor: Colors.grey,
            inactiveThumbColor: Colors.black45,
          ),
          onPressed: () => "",
        ),
        actions: [
          buildPopupMenu(),
        ],
      ),
      body: WillPopScope(
        onWillPop: onBackPress,
        child: Stack(
          children: [
            Column(
              children: [
                buildSearchBar(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: homeProvider.getStreamFireStore(
                        FirestoreConstants.pathUserCollection,
                        _limit,
                        _textSearch),
                    builder: (BuildContext context,
                        AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.hasData) {
                        if ((snapshot.data?.docs.length ?? 0) > 0) {
                          return ListView.builder(
                            padding: EdgeInsets.all(10),
                            itemBuilder: (context, index) =>
                                BuildItem(context, snapshot.data?.docs[index]),
                            itemCount: snapshot.data?.docs.length,
                            controller: listScrollController,
                          );
                        } else {
                          return const Center(
                            child: Text(
                              "no user found ...",
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }
                      } else {
                        return Center(
                          child: CircularProgressIndicator(
                            color: Colors.grey,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              child: isLoading ? LoadingView() : SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSearchBar() {
    return Container(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            color: ColorConstants.greyColor,
            size: 20,
          ),
          SizedBox(
            width: 5,
          ),
          Expanded(
            child: TextFormField(
              textInputAction: TextInputAction.search,
              controller: searchBarTec,
              onChanged: (value) {
                if (value.isNotEmpty) {
                  btnClearController.add(true);
                  setState(() {
                    _textSearch = value;
                  });
                } else {
                  btnClearController.add(false);
                  setState(() {
                    _textSearch = "";
                  });
                }
              },
              decoration: InputDecoration.collapsed(
                hintText: "search here...",
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: ColorConstants.greyColor,
                ),
              ),
              style: TextStyle(fontSize: 13),
            ),
          ),
          StreamBuilder(
            stream: btnClearController.stream,
            builder: (context, snapshot) {
              return snapshot.data == true
                  ? GestureDetector(
                      onTap: () {
                        searchBarTec.clear();
                        btnClearController.add(false);
                        setState(() {
                          _textSearch = "";
                        });
                      },
                      child: const Icon(
                        Icons.clear_rounded,
                        color: ColorConstants.greyColor,
                        size: 20,
                      ),
                    )
                  : SizedBox.shrink();
            },
          ),
        ],
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: ColorConstants.greyColor2,
      ),
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
      margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
    );
  }

  Widget BuildItem(context, DocumentSnapshot? document) {
    if (document != null) {
      UserChat userChat = UserChat.fromDocument(document);
      if (userChat.id == currentUserId) {
        return SizedBox.shrink();
      } else {
        return Container(
          margin: EdgeInsets.only(bottom: 10, left: 5, right: 5),
          child: TextButton(
            style: ButtonStyle(
              backgroundColor:
                  MaterialStateProperty.all<Color>(Colors.grey.withOpacity(.2)),
              shape: MaterialStateProperty.all<OutlinedBorder>(
                  RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(10),
                ),
              )),
            ),
            onPressed: () {
              if (Utilities.isKeyboardShowing()) {
                Utilities.closeKeyboard(context);
              }
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ChatPage(
                            peerId: userChat.id,
                            peerAvatar: userChat.photoUrl,
                            peerNickname: userChat.nickname,
                          )));
            },
            child: Row(
              children: [
                Material(
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                  clipBehavior: Clip.hardEdge,
                  child: userChat.photoUrl.isNotEmpty
                      ? Image.network(
                          userChat.photoUrl,
                          fit: BoxFit.cover,
                          width: 50,
                          height: 50,
                          loadingBuilder: (context, Widget child,
                              ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(
                                color: Colors.grey,
                                value: loadingProgress.expectedTotalBytes !=
                                            null &&
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, object, stackTrace) {
                            return const Icon(
                              Icons.account_circle,
                              size: 50,
                              color: ColorConstants.greyColor,
                            );
                          },
                        )
                      : const Icon(
                          Icons.account_circle,
                          size: 50,
                          color: ColorConstants.greyColor,
                        ),
                ),
                Flexible(
                  child: Container(
                    margin: EdgeInsets.only(left: 20),
                    child: Column(
                      children: [
                        Container(
                          alignment: Alignment.centerLeft,
                          margin: EdgeInsets.fromLTRB(10, 0, 0, 5),
                          child: Text(
                            "${userChat.nickname}",
                            maxLines: 1,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                          child: Text(
                            "${userChat.aboutMe}",
                            maxLines: 1,
                            style: TextStyle(
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      return SizedBox.shrink();
    }
  }
}
