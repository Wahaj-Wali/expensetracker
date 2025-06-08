import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerButtons extends StatelessWidget {
  final Function(ImageSource) onImagePicked;

  const ImagePickerButtons({Key? key, required this.onImagePicked})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => onImagePicked(ImageSource.camera),
            icon: Icon(Icons.camera_alt),
            label: Text('Camera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => onImagePicked(ImageSource.gallery),
            icon: Icon(Icons.photo),
            label: Text('Gallery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
