import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/foundation.dart';

class ImageLabeler extends ValueNotifier<Label> {
	
	
	ImageLabeler._() : super(null);
	
	static CameraController _controller;
	static bool _isDetecting = false;
	
	static final ImageLabeler instance = ImageLabeler._();
	
	final LabelDetector detector = FirebaseVision.instance.labelDetector(
		LabelDetectorOptions(
			confidenceThreshold: 0.75
		),
	);
	
	void init() async {
		if (_controller != null) return;
		
		final List<CameraDescription> cameras = await availableCameras();
		
		CameraDescription backCamera;
		for (CameraDescription camera in cameras) {
			if (camera.lensDirection == CameraLensDirection.back) {
				backCamera = camera;
				break;
			}
		}
		
		if (backCamera == null) throw ArgumentError("No back camera found.");
		
		_controller = new CameraController(backCamera, ResolutionPreset.medium);
		_controller.initialize().then((_) {
			_controller.startImageStream((CameraImage image) {
				if (!_isDetecting) {
					_isDetecting = true;
					_runDetection(image);
				}
			});
		});
	}
	
	@override
	void dispose() {
		super.dispose();
		suspend();
	}
	
	void suspend() {
		_controller?.dispose();
		_controller = null;
		value = null;
	}
	
	void _runDetection(CameraImage image) async {
		final int numBytes =
		image.planes.fold(0, (count, plane) => count += plane.bytes.length);
		final Uint8List allBytes = Uint8List(numBytes);
		
		int nextIndex = 0;
		for (int i = 0; i < image.planes.length; i++) {
			allBytes.setRange(nextIndex, nextIndex + image.planes[i].bytes.length,
				image.planes[i].bytes);
			nextIndex += image.planes[i].bytes.length;
		}
		
		try {
			final List<Label> labels = await detector.detectInImage(
				FirebaseVisionImage.fromBytes(
					allBytes,
					FirebaseVisionImageMetadata(
						rawFormat: image.format.raw,
						size: Size(image.width.toDouble(), image.height.toDouble()),
						rotation: ImageRotation.rotation270,
						planeData: image.planes
							.map((plane) =>
							FirebaseVisionImagePlaneMetadata(
								bytesPerRow: plane.bytesPerRow,
								height: plane.height,
								width: plane.width,
							))
							.toList()),
				),
			);
			
			if (labels.isNotEmpty) {
				value = labels[0];
			}
		} catch (exception) {
			print(exception);
		} finally {
			_isDetecting = false;
		}
	}
}