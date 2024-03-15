import 'package:advanced/core/theme/colors_theme.dart';
import 'package:advanced/features/advanced/presentation/controllers/drm_movie_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'views/movie_cell.dart';

class DrmContentPage extends GetView<DrmMovieController> {
  const DrmContentPage({Key? key}) : super(key: key);

  static const platform = MethodChannel('com.pallycon/startActivity');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: ThemeColor.white,
          title: const Text('PallyCon DRM SDK Sample',
              style: TextStyle(color: Colors.orange, fontFamily: 'Poppins')),
          elevation: 0,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Container(color: Colors.white30),
              controller.obx(
                (state) => ListView.builder(
                  itemCount: state?.length,
                  itemBuilder: (context, index) {
                    if (state == null) {
                      return const Text('');
                    }
                    final movie = state[index];
                    return MovieCell(
                        key: ValueKey(movie.contentId),
                        drmMovie: movie,
                        onPlayPressed: () {
                          _startPlayerForDownloaded(index);
                        }
                    );
                  },
                ),
                onLoading: const Center(child: CircularProgressIndicator()),
                onError: (error) => Center(
                  child: Text(
                    'Error: $error',
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Future<void> _startPlayerForDownloaded(int index) async {
    try {
      final objects = await controller.getObjectForContent(index);
      final String result =
          await platform.invokeMethod('StartSecondActivity', objects);
      debugPrint('Result: $result ');
    } on PlatformException catch (e) {
      debugPrint("Error: '${e.message}'.");
    }
  }
}
