import 'dart:io';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:new_chat/components/loading_view.dart';
import 'package:new_chat/constants/app_constants.dart';
import 'package:new_chat/constants/color_constants.dart';
import 'package:new_chat/constants/firestore_constants.dart';
import 'package:new_chat/constants/text_field_constants.dart';
import 'package:new_chat/model/chat_user.dart';
import 'package:new_chat/providers/profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController? displayNameController;
  TextEditingController? aboutMeController;
  final TextEditingController _phoneController = TextEditingController();

  late String currentUserId;
  String dialCodeDigits = '+00';
  String id = '';
  String displayName = '';
  String photoUrl = '';
  String phoneNumber = '';
  String aboutMe = '';

  bool isLoading = false;
  File? avatarImageFile;
  late ProfileProvider profileProvider;

  final FocusNode focusNodeNickname = FocusNode();

  @override
  void initState() {
    super.initState();
    profileProvider = context.read<ProfileProvider>();
  }

  void readLocal() {
    setState(() {
      id = profileProvider.getPrefs(FirestoreConstants.id) ?? '';
      displayName =
          profileProvider.getPrefs(FirestoreConstants.displayName) ?? '';
      photoUrl = profileProvider.getPrefs(FirestoreConstants.photoUrl) ?? '';
      phoneNumber =
          profileProvider.getPrefs(FirestoreConstants.phoneNumber) ?? '';
      aboutMe = profileProvider.getPrefs(FirestoreConstants.aboutMe) ?? '';
    });
    displayNameController = TextEditingController(text: displayName);
    aboutMeController = TextEditingController(text: aboutMe);
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();

    XFile? pickedFile =
        await imagePicker.pickImage(source: ImageSource.gallery).catchError(
      (onError) {
        Fluttertoast.showToast(
          msg: onError.toString(),
        );
      },
    );

    File? image;
    if (pickedFile != null) {
      image = File(pickedFile.path);
    }
    if (image != null) {
      setState(() {
        avatarImageFile = image;
        isLoading = false;
      });
      uploadFile();
    }
  }

  Future uploadFile() async {
    String fileName = id;
    UploadTask uploadTask =
        profileProvider.uploadImageFile(avatarImageFile!, fileName);

    try {
      TaskSnapshot snapshot = await uploadTask;
      photoUrl = await snapshot.ref.getDownloadURL();
      ChatUser updateInfo = ChatUser(
        id: id,
        photoUrl: photoUrl,
        displayName: displayName,
        phoneNumber: phoneNumber,
        aboutMe: aboutMe,
      );

      profileProvider
          .updateFirestoreData(
        FirestoreConstants.pathUserCollection,
        id,
        updateInfo.toJson(),
      )
          .then(
        (value) async {
          await profileProvider.setPrefs(FirestoreConstants.photoUrl, photoUrl);
          setState(() {
            isLoading = false;
          });
        },
      );
    } on FirebaseException catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(
        msg: e.toString(),
      );
    }
  }

  void updateFirestoreData() {
    focusNodeNickname.unfocus();
    setState(() {
      isLoading = true;
      if (dialCodeDigits != '+00' && _phoneController.text != '') {
        phoneNumber = dialCodeDigits + _phoneController.text.toString();
      }
    });

    ChatUser updateInfo = ChatUser(
      id: id,
      photoUrl: photoUrl,
      displayName: displayName,
      phoneNumber: phoneNumber,
      aboutMe: aboutMe,
    );
    profileProvider
        .updateFirestoreData(
      FirestoreConstants.pathUserCollection,
      id,
      updateInfo.toJson(),
    )
        .then((value) async {
      await profileProvider.setPrefs(
          FirestoreConstants.displayName, displayName);
      await profileProvider.setPrefs(
          FirestoreConstants.phoneNumber, phoneNumber);
      await profileProvider.setPrefs(
        FirestoreConstants.photoUrl,
        photoUrl,
      );
      await profileProvider.setPrefs(FirestoreConstants.aboutMe, aboutMe);

      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: 'UpdateSuccess');
    }).catchError(
      (onError) {
        Fluttertoast.showToast(msg: onError.toString());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppConstants.profileTitle,
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: getImage,
                  child: Container(
                    alignment: Alignment.center,
                    child: avatarImageFile == null
                        ? photoUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.network(
                                  photoUrl,
                                  fit: BoxFit.cover,
                                  width: 120,
                                  height: 120,
                                  errorBuilder: (context, object, stackTrace) {
                                    return const Icon(
                                      Icons.account_circle,
                                      size: 50,
                                      color: AppColors.greyColor,
                                    );
                                  },
                                  loadingBuilder: (
                                    BuildContext context,
                                    Widget child,
                                    ImageChunkEvent? loadingProgress,
                                  ) {
                                    if (loadingProgress == null) {
                                      return child;
                                    }

                                    return SizedBox(
                                      width: 90,
                                      height: 90,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.grey,
                                          value: loadingProgress
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
                            : const Icon(Icons.account_circle,
                                size: 90, color: AppColors.greyColor)
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: Image.file(
                              avatarImageFile!,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                    margin: const EdgeInsets.all(20),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Nome',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                        color: AppColors.spaceCadet,
                      ),
                    ),
                    TextField(
                      decoration: kTextInputDecoration.copyWith(
                        hintText: 'Escreva seu nome',
                      ),
                      controller: displayNameController,
                      onChanged: (value) {
                        displayName = value;
                      },
                      focusNode: focusNodeNickname,
                    ),
                    vertical15,
                    const Text(
                      'Selecione o código do país',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                        color: AppColors.spaceCadet,
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.black,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: CountryCodePicker(
                        onChanged: (country) {
                          setState(() {
                            dialCodeDigits = country.dialCode!;
                          });
                        },
                        initialSelection: 'BR',
                        showCountryOnly: false,
                        showOnlyCountryWhenClosed: false,
                        favorite: const ['+55', 'BR', '91', 'PA'],
                      ),
                    ),
                    vertical15,
                    const Text(
                      'Numero de telefone',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                        color: AppColors.spaceCadet,
                      ),
                    ),
                    TextField(
                      decoration: kTextInputDecoration.copyWith(
                        hintText: 'Numero de telefone',
                        prefix: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            dialCodeDigits,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      controller: _phoneController,
                      maxLength: 12,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: updateFirestoreData,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Atulaizar informaçõe'),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            child: isLoading ? const LoadingView() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
