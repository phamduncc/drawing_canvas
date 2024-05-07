import 'dart:ui';

import 'package:flutter/material.dart' hide Image;
import 'package:drawing_canvas/main.dart';
import 'package:drawing_canvas/view/drawing_canvas/drawing_canvas.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

import 'drawing_canvas/models/drawing_mode.dart';
import 'drawing_canvas/models/sketch.dart';
import 'drawing_canvas/widgets/canvas_side_bar.dart';
import 'drawing_canvas/widgets/color_palette.dart';

class DrawingPage extends HookWidget {
  const DrawingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedColor = useState(Colors.black);
    final strokeSize = useState<double>(10);
    final eraserSize = useState<double>(30);
    final drawingMode = useState(DrawingMode.pencil);
    final filled = useState<bool>(false);
    final polygonSides = useState<int>(3);
    final rad = useState<int>(0);
    final backgroundImage = useState<Image?>(null);

    final canvasGlobalKey = GlobalKey();

    ValueNotifier<Sketch?> currentSketch = useState(null);
    ValueNotifier<List<Sketch>> allSketches = useState([]);

    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 150),
      initialValue: 1,
    );

    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final undoRedoStack = useState(UndoRedoStack(
      sketchesNotifier: allSketches,
      currentSketchNotifier: currentSketch,
    ));

    Future<void> save() async {
      RenderRepaintBoundary boundary =
      canvasGlobalKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
      Image image = await boundary.toImage();
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List? pngBytes = byteData?.buffer.asUint8List();

      //Request permissions if not already granted
      if (!(await Permission.storage.status.isGranted)) {
        await Permission.storage.request();
      }
      if(pngBytes!=null) {
        final result = await ImageGallerySaver.saveImage(
            Uint8List.fromList(pngBytes),
            quality: 60,
            name: "canvas_image");
        print(result);
        if(result["isSuccess"] ?? false){
          const snackBar = SnackBar(content: Text('Lưu thành công!'));

          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          undoRedoStack.value.clear();
        }
      }
    }

    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          height: height,
          width: width,
          child: Column(
            children: [
              Stack(
                children: [
                  SizedBox(
                    width: width,
                    height: width+kToolbarHeight,
                  ),
                  Positioned(
                    top: kToolbarHeight,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationZ(3.141592653897931 * rad.value / 2),
                      child: DrawingCanvas(
                        width: width,
                        height: width,
                        drawingMode: drawingMode,
                        selectedColor: selectedColor,
                        strokeSize: strokeSize,
                        eraserSize: eraserSize,
                        sideBarController: animationController,
                        currentSketch: currentSketch,
                        allSketches: allSketches,
                        canvasGlobalKey: canvasGlobalKey,
                        filled: filled,
                        polygonSides: polygonSides,
                        backgroundImage: backgroundImage,
                      ),
                    ),
                  ),

                  ///
                  /// drawer widget with animation slider
                  // Positioned(
                  //   top: kToolbarHeight+width,
                  //   // left: -5,
                  //   child: Container(
                  //     width: MediaQuery.of(context).size.width,
                  //     // width: double.maxFinite,
                  //     height: 400,
                  //     decoration: BoxDecoration(
                  //       color: kCanvasColor,
                  //       borderRadius: const BorderRadius.horizontal(
                  //           right: Radius.circular(10)),
                  //       boxShadow: [
                  //         BoxShadow(
                  //           color: Colors.grey.shade200,
                  //           blurRadius: 3,
                  //           offset: const Offset(3, 3),
                  //         ),
                  //       ],
                  //     ),
                  //     child: ListView(
                  //       padding: const EdgeInsets.all(10.0),
                  //       // controller: scrollController,
                  //       children: [
                  //         const SizedBox(height: 10),
                  //         const Text(
                  //           'Shapes',
                  //           style: TextStyle(fontWeight: FontWeight.bold),
                  //         ),
                  //         const Divider(),
                  //         Wrap(
                  //           alignment: WrapAlignment.start,
                  //           spacing: 5,
                  //           runSpacing: 5,
                  //           children: [
                  //             _IconBox(
                  //               iconData: FontAwesomeIcons.pencil,
                  //               selected: drawingMode.value == DrawingMode.pencil,
                  //               onTap: () => drawingMode.value = DrawingMode.pencil,
                  //               tooltip: 'Pencil',
                  //             ),
                  //             _IconBox(
                  //               selected: drawingMode.value == DrawingMode.line,
                  //               onTap: () => drawingMode.value = DrawingMode.line,
                  //               tooltip: 'Line',
                  //               child: Column(
                  //                 mainAxisAlignment: MainAxisAlignment.center,
                  //                 children: [
                  //                   Container(
                  //                     width: 22,
                  //                     height: 2,
                  //                     color: drawingMode.value == DrawingMode.line
                  //                         ? Colors.grey[900]
                  //                         : Colors.grey,
                  //                   ),
                  //                 ],
                  //               ),
                  //             ),
                  //             _IconBox(
                  //               iconData: Icons.hexagon_outlined,
                  //               selected: drawingMode.value == DrawingMode.polygon,
                  //               onTap: () =>
                  //                   drawingMode.value = DrawingMode.polygon,
                  //               tooltip: 'Polygon',
                  //             ),
                  //             _IconBox(
                  //               iconData: FontAwesomeIcons.eraser,
                  //               selected: drawingMode.value == DrawingMode.eraser,
                  //               onTap: () => drawingMode.value = DrawingMode.eraser,
                  //               tooltip: 'Eraser',
                  //             ),
                  //             _IconBox(
                  //               iconData: FontAwesomeIcons.square,
                  //               selected: drawingMode.value == DrawingMode.square,
                  //               onTap: () => drawingMode.value = DrawingMode.square,
                  //               tooltip: 'Square',
                  //             ),
                  //             _IconBox(
                  //               iconData: FontAwesomeIcons.circle,
                  //               selected: drawingMode.value == DrawingMode.circle,
                  //               onTap: () => drawingMode.value = DrawingMode.circle,
                  //               tooltip: 'Circle',
                  //             ),
                  //           ],
                  //         ),
                  //         AnimatedSwitcher(
                  //           duration: const Duration(milliseconds: 150),
                  //           child: drawingMode.value == DrawingMode.polygon
                  //               ? Row(
                  //                   children: [
                  //                     const Text(
                  //                       'Polygon Sides: ',
                  //                       style: TextStyle(fontSize: 12),
                  //                     ),
                  //                     Slider(
                  //                       value: polygonSides.value.toDouble(),
                  //                       min: 3,
                  //                       max: 8,
                  //                       onChanged: (val) {
                  //                         polygonSides.value = val.toInt();
                  //                       },
                  //                       label: '${polygonSides.value}',
                  //                       divisions: 5,
                  //                     ),
                  //                   ],
                  //                 )
                  //               : const SizedBox.shrink(),
                  //         ),
                  //         const SizedBox(height: 10),
                  //         const Text(
                  //           'Colors',
                  //           style: TextStyle(fontWeight: FontWeight.bold),
                  //         ),
                  //         const Divider(),
                  //         ColorPalette(
                  //           selectedColor: selectedColor,
                  //         ),
                  //         const SizedBox(height: 20),
                  //         const Text(
                  //           'Size',
                  //           style: TextStyle(fontWeight: FontWeight.bold),
                  //         ),
                  //         const Divider(),
                  //         Row(
                  //           children: [
                  //             const Text(
                  //               'Stroke Size: ',
                  //               style: TextStyle(fontSize: 12),
                  //             ),
                  //             Slider(
                  //               value: strokeSize.value,
                  //               min: 0,
                  //               max: 50,
                  //               onChanged: (val) {
                  //                 strokeSize.value = val;
                  //               },
                  //             ),
                  //           ],
                  //         ),
                  //         Row(
                  //           children: [
                  //             const Text(
                  //               'Eraser Size: ',
                  //               style: TextStyle(fontSize: 12),
                  //             ),
                  //             Slider(
                  //               value: eraserSize.value,
                  //               min: 0,
                  //               max: 80,
                  //               onChanged: (val) {
                  //                 eraserSize.value = val;
                  //               },
                  //             ),
                  //           ],
                  //         ),
                  //         const SizedBox(height: 10,),
                  //         const Divider(),
                  //       ],
                  //     ),
                  //   ),
                  // ),

                  ///
                  /// app bar on the top
                  Positioned(
                    // top: 40,
                    // right: 10,
                    child: Container(
                      color: Colors.amber,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                              onPressed: () {
                                undoRedoStack.value.undo();
                              },
                              icon: const Icon(Icons.undo)),
                          IconButton(
                              onPressed: () {
                                rad.value++;
                              },
                              icon: const Icon(Icons.rotate_90_degrees_ccw)),
                          IconButton(
                              onPressed: () {
                                undoRedoStack.value.redo();
                              },
                              icon: const Icon(Icons.redo)),
                          ElevatedButton.icon(
                            onPressed: () {
                              undoRedoStack.value.clear();
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text("Clear"),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              save();
                            },
                            icon: const Icon(Icons.save),
                            label: const Text("Save"),
                          ),
                          const SizedBox(width: 10,)
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  // width: double.maxFinite,
                  height: 200,
                  decoration: BoxDecoration(
                    color: kCanvasColor,
                    borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(10)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 3,
                        offset: const Offset(3, 3),
                      ),
                    ],
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(10.0),
                    // controller: scrollController,
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        'Shapes',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          _IconBox(
                            iconData: FontAwesomeIcons.pencil,
                            selected: drawingMode.value == DrawingMode.pencil,
                            onTap: () => drawingMode.value = DrawingMode.pencil,
                            tooltip: 'Pencil',
                          ),
                          _IconBox(
                            selected: drawingMode.value == DrawingMode.line,
                            onTap: () => drawingMode.value = DrawingMode.line,
                            tooltip: 'Line',
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 22,
                                  height: 2,
                                  color: drawingMode.value == DrawingMode.line
                                      ? Colors.grey[900]
                                      : Colors.grey,
                                ),
                              ],
                            ),
                          ),
                          _IconBox(
                            iconData: Icons.hexagon_outlined,
                            selected: drawingMode.value == DrawingMode.polygon,
                            onTap: () =>
                            drawingMode.value = DrawingMode.polygon,
                            tooltip: 'Polygon',
                          ),
                          _IconBox(
                            iconData: FontAwesomeIcons.eraser,
                            selected: drawingMode.value == DrawingMode.eraser,
                            onTap: () => drawingMode.value = DrawingMode.eraser,
                            tooltip: 'Eraser',
                          ),
                          _IconBox(
                            iconData: FontAwesomeIcons.square,
                            selected: drawingMode.value == DrawingMode.square,
                            onTap: () => drawingMode.value = DrawingMode.square,
                            tooltip: 'Square',
                          ),
                          _IconBox(
                            iconData: FontAwesomeIcons.circle,
                            selected: drawingMode.value == DrawingMode.circle,
                            onTap: () => drawingMode.value = DrawingMode.circle,
                            tooltip: 'Circle',
                          ),
                        ],
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: drawingMode.value == DrawingMode.polygon
                            ? Row(
                          children: [
                            const Text(
                              'Polygon Sides: ',
                              style: TextStyle(fontSize: 12),
                            ),
                            Slider(
                              value: polygonSides.value.toDouble(),
                              min: 3,
                              max: 8,
                              onChanged: (val) {
                                polygonSides.value = val.toInt();
                              },
                              label: '${polygonSides.value}',
                              divisions: 5,
                            ),
                          ],
                        )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Colors',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      ColorPalette(
                        selectedColor: selectedColor,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Size',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      Row(
                        children: [
                          const Text(
                            'Stroke Size: ',
                            style: TextStyle(fontSize: 12),
                          ),
                          Slider(
                            value: strokeSize.value,
                            min: 0,
                            max: 50,
                            onChanged: (val) {
                              strokeSize.value = val;
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text(
                            'Eraser Size: ',
                            style: TextStyle(fontSize: 12),
                          ),
                          Slider(
                            value: eraserSize.value,
                            min: 0,
                            max: 80,
                            onChanged: (val) {
                              eraserSize.value = val;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10,),
                      const Divider(),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData? iconData;
  final Widget? child;
  final bool selected;
  final VoidCallback onTap;
  final String? tooltip;

  const _IconBox({
    super.key,
    this.iconData,
    this.child,
    this.tooltip,
    required this.selected,
    required this.onTap,
  })  : assert(child != null || iconData != null);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 35,
          width: 35,
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? Colors.grey[900]! : Colors.grey,
              width: 1.5,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(5)),
          ),
          child: Tooltip(
            message: tooltip,
            preferBelow: false,
            child: child ??
                Icon(
                  iconData,
                  color: selected ? Colors.grey[900] : Colors.grey,
                  size: 20,
                ),
          ),
        ),
      ),
    );
  }
}
