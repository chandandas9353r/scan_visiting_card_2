// ignore_for_file: unnecessary_null_comparison, unused_element

import '../components.dart';
import '../services.dart' as services;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Details extends StatefulWidget {
  final http.Response response;
  final File image;
  Details({super.key, required this.response, required this.image}){
    final services.HTTPService httpService = services.HTTPService(url: 'http://173.249.8.98');
    httpService.postData(response, image, ':5020/data');
  }
  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  bool isDeletingData = false;
  Map<String,dynamic>? _data;
  Map<String,dynamic>? _response;
  List<TextEditingController> controller1D = [];
  List<TextEditingController> controller2D = [];
  bool popScreen(BuildContext context) {
    Navigator.of(context).pop(context);
    return true;
  }
  Future<Map<String, dynamic>?> getUser() async => _response;
  void deleteData(int index1D, int index2D) => _response?.values.elementAt(index1D).remove(_response?.values.elementAt(index1D)[index2D]);
  @override
  Widget build(BuildContext context) {
    services.User user = services.User(response: widget.response);
    File image = widget.image;
    return WillPopScope(
      onWillPop: () async => popScreen(context),
      child: Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: const Text("USER DETAILS"),
        centerTitle: true,
        scrolledUnderElevation: 1,
        elevation: 5,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(20.0),
            right: Radius.circular(20.0),
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 20.0),
              child: Flex(
                direction: Axis.vertical,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 20.0),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: AspectRatio(
                      aspectRatio: 16.0 / 9.0,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                        ),
                        child: (image != null)
                        ? Image.file(image)
                        : const Text("No Image"),
                      ),
                    ),
                  ),
                  Expanded(
                    child: FutureBuilder(
                      future: (_response == null) ? user.getUser() : getUser(),
                      builder: (context, snapshot) {
                        _response = snapshot.data;
                        for(int i = 0; i < (_response?.length ?? 0); i++) {
                          if(_response!.entries.elementAt(i).value.isEmpty) _response!.addAll({_response!.keys.elementAt(i) : [""]});
                        }
                        controller1D = List.generate(_response?.length ?? 0, (index) => TextEditingController(text: ""));
                        return drawList();
                      },
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      String recepient = _response?['email'][0] ?? "";
                      services.EmailService emailService = services.EmailService();
                      await emailService.sendEmail(recepient, _response as Map<String,dynamic>);
                    },
                    child: customButton(
                      color: Colors.green,
                      marginTop: 30.0,
                      child: customText(
                        data: "SEND EMAIL",
                        color: Colors.white,
                        size: 20.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if(isDeletingData) GestureDetector(
            onTap: () => setState(() {isDeletingData = false;}),
            child: Container(
              decoration: BoxDecoration(
                color: (isDeletingData) ? Colors.black45 : Colors.transparent,
              ),
            ),
          ),
          if(isDeletingData) Container(
            alignment: Alignment.center,
            child: deleteDataDialog(response: _data as Map<String,dynamic>),
          ),
        ],
      ),
    ),
    );
  }

  Widget deleteDataDialog({required Map<String,dynamic> response}) {
    String data = response['response'].values.elementAt(response['index'])[response['id']];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.all(70.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 20.0),
                alignment: Alignment.center,
                child: Text(
                  '''Do you want to delete "$data"?''',
                  style: const TextStyle(
                    fontSize: 20.0
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: GestureDetector(
                        onTap: () => setState(() {isDeletingData = false;}),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(15.0),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(10.0)),
                          ),
                          child: const Text(
                            "CANCEL",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                            ),
                          ),
                        ),
                    ),
                  ),
                  Flexible(
                    child: GestureDetector(
                        onTap: () {
                          deleteData(
                            response['index'],
                            response['id'],
                          );
                          setState(() {isDeletingData = false;});
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(15.0),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: const BorderRadius.only(bottomRight: Radius.circular(10.0)),
                          ),
                          child: const Text(
                            "OK",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                            ),
                          ),
                        ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget drawList(){
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: _response?.length ?? 0,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        int length = _response?.values.elementAt(index).length;
        (length <= 1)
        ? controller1D[index].text = (length == 1) ? _response?.values.elementAtOrNull(index)[0] : ""
        : controller2D = List.generate(length, (i) => TextEditingController(text: _response?.values.elementAtOrNull(index)[i]));
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _response?.keys.elementAt(index).toUpperCase().replaceAll("_", " ").replaceAll(" ", "\n") as String,
              style: const TextStyle(
                color: Colors.black,
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for(int i = 0; i < length; i++) Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: TextField(
                              textAlign: TextAlign.end,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.all(0.0),
                                border: InputBorder.none
                              ),
                              controller: (length > 1) ? controller2D[i] : controller1D[index],
                              onChanged: (value) {
                                _response?.values.elementAt(index)[i] = value;
                              },
                              onEditingComplete: () {
                                setState(() {});
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                              onTapOutside: (event) {
                                setState(() {});
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                              readOnly: false,
                              showCursor: true,
                              enableInteractiveSelection: true,
                              keyboardType: TextInputType.text,
                              maxLines: null,
                            ),
                          ),
                          if(length > 1 || length <= 1 && _response?.values.elementAt(index)[i] != "") GestureDetector(
                            onTap: () {
                              _data = {
                                'response' : _response,
                                'index' : index,
                                'id' : i,
                              };
                              FocusManager.instance.primaryFocus?.unfocus();
                              setState(() {isDeletingData = true;});
                            },
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.red.shade800,
                            ),
                          ),
                        ],
                      ),
                      if (i != length - 1) const Divider(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}