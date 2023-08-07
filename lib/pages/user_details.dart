import './details.dart';
import '../components.dart';
import '../services.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserDetails extends StatefulWidget {
  const UserDetails({super.key});

  @override
  State<UserDetails> createState() => _UserDetailsState();
}

class _UserDetailsState extends State<UserDetails> {
  ImageService imageService = ImageService();
  HTTPService httpService = HTTPService(url: 'http://173.249.8.98');

  File? _image;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _image = null;
    isProcessing = false;
  }

  @override
  void dispose() {
    _image = null;
    isProcessing = false;
    super.dispose();
  }

  Future<void> postData() async {
    if (_image != null) {
      File image = _image as File;
      http.Response finalResponse = await httpService.postScannedImage(image, ':5005/parse');
      if(!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(builder: (context) => Details(
        response: finalResponse,
        image: _image as File,
      ),));
      _image = null;
      isProcessing = false;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                      child: AspectRatio(
                        aspectRatio: 16.0 / 9.0,
                        child:
                            (_image != null) ? Center(child: Image.file(_image as File)) : const Center(child: Text("No Image")),
                    ),
                ),
                GestureDetector(
                  onTap: () async {
                    _image = await imageService.getImage();
                    setState(() {});
                  },
                  child: customButton(
                    color: Colors.blue,
                    child: customText(
                      data: "Pick Image",
                      color: Colors.white,
                      size: 20.0,
                    ),
                  ),
                ),
                if (_image != null)
                  GestureDetector(
                    onTap: () async {
                      setState(() {isProcessing = true;});
                      await postData();
                    },
                    child: customButton(
                      color: Colors.green,
                      child: customText(
                        data: "Submit",
                        color: Colors.white,
                        size: 20.0,
                      ),
                    ),
                  ),
              ],
            ),
            if(isProcessing) Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.black54,
              ),
              child: const CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}
