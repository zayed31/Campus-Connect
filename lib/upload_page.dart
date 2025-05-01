import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'cloudinary_service.dart'; // Ensure this is the correct path

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final TextEditingController captionController = TextEditingController();
  File? _selectedImage;
  bool isUploading = false;

  /// Function to request storage permissions
  Future<void> requestStoragePermissions() async {
    if (await Permission.storage.isGranted) {
      print('Storage permission granted.');
    } else {
      PermissionStatus status = await Permission.storage.request();
      if (status.isGranted) {
        print('Storage permission granted after request.');
      } else if (status.isPermanentlyDenied) {
        print('Storage permission permanently denied. Redirecting to settings.');
        await openAppSettings();
      } else {
        print('Storage permission denied.');
      }
    }
  }

  /// Function to pick an image from the gallery
  Future<void> pickImage() async {
    await requestStoragePermissions();

    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accessing gallery: $e')),
      );
    }
  }

  /// Function to upload the post
  Future<void> uploadPost() async {
    if (_selectedImage == null || captionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image and enter a caption.')),
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      // Upload the image to Cloudinary
      final cloudinary = CloudinaryService();
      final String? imageUrl = await cloudinary.uploadImage(_selectedImage!);

      if (imageUrl == null) {
        throw 'Image upload failed. Please try again.';
      }

      // Get the current authenticated user's details
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw 'User is not authenticated.';

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      String username = userDoc['username'] ?? 'Unknown User';
      String profilePicture = userDoc['DP'] ?? '';

      // Save the post to Firestore
      await FirebaseFirestore.instance.collection('posts').add({
        'username': username,
        'profilePicture': profilePicture,
        'imageUrl': imageUrl,
        'caption': captionController.text.trim(),
        'likes': 0,
        'likedBy': [],
        'timestamp': FieldValue.serverTimestamp(),
        'userId': currentUser.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post uploaded successfully!')),
      );

      // Clear the fields after successful upload
      setState(() {
        _selectedImage = null;
        captionController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading post: $e')),
      );
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Post'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_selectedImage != null)
              Image.file(
                _selectedImage!,
                height: 200,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Select Image'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: captionController,
              decoration: const InputDecoration(
                labelText: 'Enter caption',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isUploading ? null : uploadPost,
              child: isUploading
                  ? const CircularProgressIndicator()
                  : const Text('Upload Post'),
            ),
          ],
        ),
      ),
    );
  }
}