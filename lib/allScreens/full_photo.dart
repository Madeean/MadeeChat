import 'package:flutter/material.dart';
import 'package:madee_chat_app/allConstants/app_constants.dart';
import 'package:madee_chat_app/allConstants/color_constants.dart';
import 'package:madee_chat_app/main.dart';
import 'package:photo_view/photo_view.dart';

class FullPhotoPage extends StatelessWidget {
  final String url;
  FullPhotoPage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isWhite ? Colors.white : Colors.black,
      appBar: AppBar(
        backgroundColor: isWhite ? Colors.white : Colors.grey[900],
        iconTheme: IconThemeData(
          color: ColorConstants.primaryColor,
        ),
        title: Text(
          AppConstants.fullPhotoTitle,
          style: TextStyle(
            color: ColorConstants.primaryColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        child: PhotoView(
          imageProvider: NetworkImage(url),
        ),
      ),
    );
  }
}
