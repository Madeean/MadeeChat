import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:madee_chat_app/allConstants/app_constants.dart';
import 'package:madee_chat_app/allConstants/color_constants.dart';
import 'package:madee_chat_app/allConstants/constants.dart';
import 'package:madee_chat_app/allModels/user_chat.dart';
import 'package:madee_chat_app/allProviders/setting_provider.dart';
import 'package:madee_chat_app/allWidgets/widgets.dart';
import 'package:madee_chat_app/main.dart';
import 'package:provider/src/provider.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isWhite ? Colors.white : Colors.black,
      appBar: AppBar(
        backgroundColor: isWhite ? Colors.white : Colors.black,
        iconTheme: const IconThemeData(
          color: ColorConstants.primaryColor,
        ),
        title: Text(
          AppConstants.settingsTitle,
          style: TextStyle(color: ColorConstants.primaryColor),
        ),
        centerTitle: true,
      ),
      body: SettingsPageState(),
    );
  }
}

class SettingsPageState extends StatefulWidget {
  @override
  State<SettingsPageState> createState() => _SettingsPageStateState();
}

class _SettingsPageStateState extends State<SettingsPageState> {
  TextEditingController? controllerNickname;
  TextEditingController? controllerAboutMe;

  String dialCodeDigits = "+00";
  final TextEditingController _controller = TextEditingController();

  String id = '';
  String nickname = '';
  String aboutMe = '';
  String photoUrl = '';
  String phoneNumber = '';

  bool isloading = false;
  File? avatarImageFile;
  late SettingProvider settingProvider;

  final FocusNode focusNodeNickname = FocusNode();
  final FocusNode focusNodeAboutMe = FocusNode();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    settingProvider = context.read<SettingProvider>();
    readLocal();
  }

  void readLocal() {
    setState(() {
      id = settingProvider.getPref(FirestoreConstants.id) ?? "";
      nickname = settingProvider.getPref(FirestoreConstants.nickname) ?? "";
      aboutMe = settingProvider.getPref(FirestoreConstants.aboutMe) ?? "";
      photoUrl = settingProvider.getPref(FirestoreConstants.photoUrl) ?? "";
      phoneNumber =
          settingProvider.getPref(FirestoreConstants.phoneNumber) ?? "";
    });
    controllerNickname = TextEditingController(text: nickname);
    controllerAboutMe = TextEditingController(text: aboutMe);
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    PickedFile? pickedFile = await imagePicker
        // ignore: deprecated_member_use
        .getImage(source: ImageSource.gallery)
        .catchError((err) {
      Fluttertoast.showToast(msg: err.toString());
    });
    File? image;
    if (pickedFile != null) {
      image = File(pickedFile.path);
    }
    if (image != null) {
      setState(() {
        avatarImageFile = image;
        isloading = true;
      });
      uploadFile();
    }
  }

  Future uploadFile() async {
    String fileName = id;
    UploadTask uploadTask =
        settingProvider.uploadFile(avatarImageFile!, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask;
      photoUrl = await snapshot.ref.getDownloadURL();

      UserChat updateInfo = UserChat(
        id: id,
        aboutMe: aboutMe,
        nickname: nickname,
        photoUrl: photoUrl,
        phoneNumber: phoneNumber,
      );
      settingProvider
          .updateDataFirestore(
              FirestoreConstants.pathUserCollection, id, updateInfo.toJson())
          .then((value) async {
        await settingProvider.setPref(FirestoreConstants.photoUrl, photoUrl);
        setState(() {
          isloading = false;
        });
      }).catchError((err) {
        setState(() {
          isloading = false;
        });
        Fluttertoast.showToast(msg: err.toString());
      });
    } on FirebaseException catch (e) {
      setState(() {
        isloading = false;
      });
      Fluttertoast.showToast(msg: e.message ?? e.toString());
    }
  }

  void handleUpdateData() {
    focusNodeNickname.unfocus();
    focusNodeAboutMe.unfocus();

    setState(() {
      isloading = true;

      if (dialCodeDigits != "+00" && _controller.text != "") {
        phoneNumber = dialCodeDigits + _controller.text.toString();
      }
    });
    UserChat updateInfo = UserChat(
      id: id,
      photoUrl: photoUrl,
      nickname: nickname,
      aboutMe: aboutMe,
      phoneNumber: phoneNumber,
    );
    settingProvider
        .updateDataFirestore(
            FirestoreConstants.pathUserCollection, id, updateInfo.toJson())
        .then((value) async {
      await settingProvider.setPref(FirestoreConstants.nickname, nickname);
      await settingProvider.setPref(FirestoreConstants.aboutMe, aboutMe);
      await settingProvider.setPref(FirestoreConstants.photoUrl, photoUrl);
      await settingProvider.setPref(
          FirestoreConstants.phoneNumber, phoneNumber);

      setState(() {
        isloading = false;
      });
      Fluttertoast.showToast(msg: "update success");
    }).catchError((e) {
      setState(() {
        isloading = false;
      });

      Fluttertoast.showToast(msg: e.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        SingleChildScrollView(
          padding: EdgeInsets.only(left: 15, right: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoButton(
                onPressed: getImage,
                child: Container(
                  margin: EdgeInsets.all(20),
                  child: avatarImageFile == null
                      ? photoUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(45),
                              child: Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                width: 90,
                                height: 90,
                                errorBuilder: (context, object, stackTrace) {
                                  return Icon(
                                    Icons.account_circle,
                                    size: 90,
                                    color: ColorConstants.greyColor,
                                  );
                                },
                                loadingBuilder: (BuildContext context,
                                    Widget child,
                                    ImageChunkEvent? loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 90,
                                    height: 90,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.grey,
                                        value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null &&
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.account_circle,
                              size: 90,
                              color: ColorConstants.greyColor,
                            )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(45),
                          child: Image.file(
                            avatarImageFile!,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    child: Text(
                      'Name',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.primaryColor),
                    ),
                    margin: EdgeInsets.only(left: 10, bottom: 5, top: 10),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 30, right: 30),
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(primaryColor: ColorConstants.primaryColor),
                      child: TextField(
                        style: TextStyle(color: Colors.grey),
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: ColorConstants.greyColor2),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: ColorConstants.primaryColor),
                          ),
                          hintText: 'Write your name...',
                          contentPadding: EdgeInsets.all(5),
                          hintStyle: TextStyle(color: ColorConstants.greyColor),
                        ),
                        controller: controllerNickname,
                        onChanged: (value) {
                          nickname = value;
                        },
                        focusNode: focusNodeNickname,
                      ),
                    ),
                  ),
                  Container(
                    child: Text(
                      'About me',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.primaryColor),
                    ),
                    margin: EdgeInsets.only(left: 10, top: 30, bottom: 5),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 30, right: 30),
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(primaryColor: ColorConstants.primaryColor),
                      child: TextField(
                        style: TextStyle(color: Colors.grey),
                        decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: ColorConstants.greyColor2),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: ColorConstants.primaryColor),
                          ),
                          hintText: 'Write something about yourself...',
                          contentPadding: EdgeInsets.all(5),
                          hintStyle: TextStyle(color: ColorConstants.greyColor),
                        ),
                        controller: controllerAboutMe,
                        onChanged: (value) {
                          aboutMe = value;
                        },
                        focusNode: focusNodeAboutMe,
                      ),
                    ),
                  ),
                  Container(
                    child: Text(
                      'Phone No',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.primaryColor),
                    ),
                    margin: EdgeInsets.only(left: 10, top: 30, bottom: 5),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 30, right: 30),
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(primaryColor: ColorConstants.primaryColor),
                      child: TextField(
                        style: TextStyle(color: Colors.grey),
                        enabled: false,
                        decoration: InputDecoration(
                          hintText: phoneNumber,
                          contentPadding: EdgeInsets.all(5),
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 10, top: 30, bottom: 5),
                    child: SizedBox(
                      width: 400,
                      height: 60,
                      child: CountryCodePicker(
                        onChanged: (country) {
                          setState(() {
                            dialCodeDigits = country.dialCode!;
                          });
                        },
                        initialSelection: "IT",
                        showCountryOnly: false,
                        showOnlyCountryWhenClosed: false,
                        favorite: ["+1", "US", "+92", "PAK"],
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 30, right: 30),
                    child: TextField(
                      style: TextStyle(color: Colors.grey),
                      decoration: InputDecoration(
                          enabledBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: ColorConstants.greyColor2),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: ColorConstants.primaryColor),
                          ),
                          hintText: "Phone Number",
                          hintStyle: TextStyle(color: Colors.grey),
                          prefix: Padding(
                            padding: EdgeInsets.all(4),
                            child: Text(
                              dialCodeDigits,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )),
                      maxLength: 12,
                      keyboardType: TextInputType.number,
                      controller: _controller,
                    ),
                  ),
                ],
              ),
              Container(
                margin: EdgeInsets.only(top: 50, bottom: 50),
                child: TextButton(
                  onPressed: handleUpdateData,
                  child: Text(
                    'Update Now',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        ColorConstants.primaryColor),
                    padding: MaterialStateProperty.all<EdgeInsets>(
                      EdgeInsets.fromLTRB(30, 10, 30, 10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(child: isloading ? LoadingView() : SizedBox.shrink()),
      ],
    );
  }
}
