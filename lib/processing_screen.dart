import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'utils/ad_banner.dart';
import 'utils/ad_reward_interstitial.dart';

class ProcessingScreen extends StatefulWidget {
  final File image;
  final String selectedStyle;

  const ProcessingScreen({
    super.key,
    required this.image,
    required this.selectedStyle,
  });

  @override
  ProcessingScreenState createState() => ProcessingScreenState();
}

class ProcessingScreenState extends State<ProcessingScreen> {
  String? processedImageUrl;
  String? errorMessage;
  late String apiToken;
  final RewardedInterstitialAdManager _adManager = RewardedInterstitialAdManager();

  @override
  void initState() {
    super.initState();
    _loadApiToken().then((_) async {
      await _adManager.loadAd();
      await Future.delayed(const Duration(seconds: 2));
      _processImage();
    });
  }

  Future<void> _loadApiToken() async {
    final String configContent =
        await rootBundle.loadString('assets/config.json');
    final config = json.decode(configContent);
    apiToken = config['stabilityApiToken'];
  }

  Future<void> _processImage() async {
    await Future.delayed(const Duration(seconds: 1)); // 少し待機
    await _adManager.showAd(() async {
      const apiUrl =
          'https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/image-to-image';

      try {
        // 画像のサイズを確認
        final bytes = await widget.image.readAsBytes();
        final image = img.decodeImage(bytes);
        File imageFile = widget.image;

        // 許可されているサイズのリスト
        final allowedSizes = [
          [1024, 1024],
          [1152, 896],
          [1216, 832],
          [1344, 768],
          [1536, 640],
          [640, 1536],
          [768, 1344],
          [832, 1216],
          [896, 1152]
        ];

        // 画像のサイズが許可されていない場合、アスペクト比を維持しながらリサイズする
        if (!allowedSizes
            .any((size) => image!.width == size[0] && image.height == size[1])) {
          int targetWidth = 1024;
          int targetHeight = 1024;
          double aspectRatio = image!.width / image.height;

          // アスペクト比に基づいて、最も近い許可されたサイズを選択
          if (aspectRatio > 1) {
            if (aspectRatio > 1536 / 640) {
              targetWidth = 1536;
              targetHeight = 640;
            } else if (aspectRatio > 1344 / 768) {
              targetWidth = 1344;
              targetHeight = 768;
            } else if (aspectRatio > 1216 / 832) {
              targetWidth = 1216;
              targetHeight = 832;
            } else if (aspectRatio > 1152 / 896) {
              targetWidth = 1152;
              targetHeight = 896;
            }
          } else {
            if (aspectRatio < 640 / 1536) {
              targetWidth = 640;
              targetHeight = 1536;
            } else if (aspectRatio < 768 / 1344) {
              targetWidth = 768;
              targetHeight = 1344;
            } else if (aspectRatio < 832 / 1216) {
              targetWidth = 832;
              targetHeight = 1216;
            } else if (aspectRatio < 896 / 1152) {
              targetWidth = 896;
              targetHeight = 1152;
            }
          }

          final resizedImage = img.copyResize(image,
              width: targetWidth,
              height: targetHeight,
              interpolation: img.Interpolation.linear);

          final resizedBytes = img.encodePng(resizedImage);

          final tempDir = await Directory.systemTemp.createTemp();
          imageFile = File('${tempDir.path}/resized_image.png');
          await imageFile.writeAsBytes(resizedBytes);
        }

        var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
        request.headers['Authorization'] = 'Bearer $apiToken';
        request.headers['Accept'] = 'application/json';

        request.fields['text_prompts[0][text]'] =
            'Transform this image into ${widget.selectedStyle} style, maintaining the original composition and subject matter. Ensure the result looks like a ${widget.selectedStyle} artwork while preserving the essence of the original photo.';
        request.fields['cfg_scale'] = '10';
        request.fields['clip_guidance_preset'] = 'FAST_BLUE';
        request.fields['samples'] = '1';
        request.fields['steps'] = '50';

        request.files.add(await http.MultipartFile.fromPath(
          'init_image',
          imageFile.path,
        ));

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          final base64Image = responseData['artifacts'][0]['base64'];

          // Base64データをデコードして画像ファイルとして保存
          final imageBytes = base64Decode(base64Image);
          final tempDir = await Directory.systemTemp.createTemp();
          final tempFile = File('${tempDir.path}/processed_image.png');
          await tempFile.writeAsBytes(imageBytes);

          setState(() {
            processedImageUrl = tempFile.path;
          });
        } else {
          throw Exception('Failed to start image processing. Status code: ${response.statusCode}');
        }
      } catch (e) {
        setState(() {
          errorMessage = e.toString();
        });
      }
    });
  }

  Future<void> _shareImage() async {
    if (processedImageUrl != null) {
      await Share.shareXFiles([XFile(processedImageUrl!)],
          text: 'Image generated in ${widget.selectedStyle} style');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('There are no images to share.')),
      );
    }
  }

  Future<void> _saveImage() async {
    if (processedImageUrl != null) {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (status.isGranted) {
          await _saveImageToGallery();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You need to have permission to access the storage.')),
          );
        }
      } else {
        await _saveImageToGallery();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('There is no image to save.')),
      );
    }
  }

  Future<void> _saveImageToGallery() async {
    final result = await ImageGallerySaver.saveFile(processedImageUrl!);
    if (result['isSuccess']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The image has been saved to your gallery.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save image.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.selectedStyle} style',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: processedImageUrl != null ? _shareImage : null,
          ),
          TextButton(
            onPressed: processedImageUrl != null ? _saveImage : null,
            child: Text(
              'Save',
              style: TextStyle(
                color: processedImageUrl != null ? Colors.blue : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: processedImageUrl != null
                ? Image.file(
                    File(processedImageUrl!),
                    fit: BoxFit.contain,
                  )
                : errorMessage != null
                    ? Text('Error: $errorMessage')
                    : const CircularProgressIndicator(),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: processedImageUrl != null
                ? () {
                    setState(() {
                      processedImageUrl = null;
                      errorMessage = null;
                    });
                    _processImage();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
            ),
            child: const Text(
              'Regenerate',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
          TextButton(
            onPressed: processedImageUrl != null
                ? () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }
                : null,
            child: Text(
              'Back to Photo Selection',
              style: TextStyle(
                color: processedImageUrl != null ? Colors.blue : Colors.grey,
              ),
            ),
          ),
        ],
      ),
      bottomSheet: const AdBanner(),
    );
  }
}
