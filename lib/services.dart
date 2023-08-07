import './model.dart' as model;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as parser;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart' as provider;
import 'package:edge_detection/edge_detection.dart' as detector;
import 'package:flutter_email_sender/flutter_email_sender.dart' as sender;
import 'package:fluttertoast/fluttertoast.dart' as toast;
import 'package:permission_handler/permission_handler.dart' as handler;

void showToast(String msg){
  toast.Fluttertoast.showToast(
    msg: msg,
    toastLength: toast.Toast.LENGTH_LONG,
    gravity: toast.ToastGravity.BOTTOM,
    timeInSecForIosWeb: 1,
    backgroundColor: Colors.black,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}

Future<handler.PermissionStatus> tryAccessCamera() async {
  await handler.Permission.camera.request();
  return await handler.Permission.camera.status;
}

class ImageService{
  Future<File?> getImage() async {
    var status = await tryAccessCamera();
    if(status == handler.PermissionStatus.denied ||
      status == handler.PermissionStatus.permanentlyDenied){
      showToast("PERMISSION DENIED");
      status = await tryAccessCamera();
      if(status == handler.PermissionStatus.denied ||
        status == handler.PermissionStatus.permanentlyDenied){
        showToast("GRANT CAMERA");
        await handler.openAppSettings();
      }
      return null;
    }
    String imagePath = join(
        (await provider.getApplicationSupportDirectory()).path,
        "${(DateTime.now().millisecondsSinceEpoch / 1000).round()}.png");
    bool imageStored = await detector.EdgeDetection.detectEdge(
      imagePath,
      androidScanTitle: "Capture an Image",
      androidCropTitle: "Enhance the Image",
    );
    if (!imageStored) return null;
    return File(imagePath);
  }
}

class HTTPService {
  String url;

  HTTPService({required this.url});

  Future<http.Response> postScannedImage(File image, String path) async {
    String fileExtension = extension(image.path);
    fileExtension = fileExtension.split('.')[1];
    http.MultipartRequest request = http.MultipartRequest('POST', Uri.parse(url + path));
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        image.path,
        contentType: parser.MediaType('application', fileExtension),
      ),
    );
    http.StreamedResponse res = await request.send();
    http.Response response = await http.Response.fromStream(res);
    return response;
  }

  Future<bool> postData(http.Response finalResponse, File image, String path) async {
    if (finalResponse.statusCode >= 200 && finalResponse.statusCode < 300) {
      String fileExtension = extension(image.path);
      fileExtension = fileExtension.split('.')[1];
      Map map = {
        "data" : '"${finalResponse.body.toString()}"',
        "filename" : '"output.$fileExtension"',
        "file" : '''"${base64.encode(image.readAsBytesSync())}"''',
      };
      http.Response response = await http.post(
        Uri.parse(url+path),
        headers: {"Content-Type": "application/json"},
        body: json.encode(map),
      );
      showToast("Received ${response.statusCode.toString()} Status");
      if (response.statusCode >= 200 && response.statusCode < 300) {
        showToast("SUCCESS");
      } else {
        showToast("FAILED");
      }
      return true;
    } else if (finalResponse.statusCode >= 500 &&
        finalResponse.statusCode < 600) {
      showToast("WRONG IMAGE");
      return false;
    } else if (finalResponse.statusCode >= 400 &&
        finalResponse.statusCode < 500) {
      showToast("SERVER ISSUE. PLEASE TRY AGAIN LATER");
      return false;
    } else {
      showToast("PLEASE TRY AGAIN");
      return false;
    }
  }
}

class User{
  Map<String,dynamic> detailsList = {};
  http.Response response;

  User({required this.response});

  Future<Map<String,dynamic>> getUser() async {
    detailsList.clear();
    final data = await jsonDecode((response).body.toString())['info'];
    for(Map<String,dynamic> i in data.cast()){
      model.Model user = model.Model(
        name: i['name'] ?? [" "],
        address: i['address'] ?? [" "],
        phoneNumber: i['phone_number'] ?? [" "],
        email: i['email'] ?? [" "],
        designation: i['designation'] ?? [" "],
        companyName: i['company_name'] ?? [" "],
        website: i['website'] ?? [" "],
      );
      detailsList.addEntries(user.toJson().entries);
    }
    return detailsList;
  }
}

class EmailService{
  Future<void> sendEmail(String recepient, Map<String, dynamic> detailsList) async {  
    final sender.Email email = sender.Email(
      body: detailsList.toString(),
      subject: 'SCAN VISITING CARD',
      recipients: [recepient],
      isHTML: false,
    );
    try {
      await sender.FlutterEmailSender.send(email);
      showToast('MAIL SENT');
    } catch (e) {
      showToast(e.toString());
    }
  }
}