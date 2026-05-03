// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Automated demo recorder for flutter_debounce_throttle.
///
/// Usage: dart scripts/record_demos.dart
void main() async {
  print('🚀 Starting Demo Automation...');

  final ffmpegFound = await _isCommandAvailable('ffmpeg');
  if (!ffmpegFound) {
    print('❌ Error: ffmpeg not found. Please install it first.');
    exit(1);
  }

  // 1. Detect Active Mobile Device
  print('🔍 Detecting active mobile device...');
  final device = await _detectMobileDevice();
  if (device == null) {
    print(
        '❌ Error: No active mobile device (iOS Simulator or Android Emulator) found.');
    exit(1);
  }

  print('✅ Using Device: ${device.name} (${device.id}) [${device.platform}]');

  // 2. Define tasks
  final tasks = [
    _DemoTask(
      name: 'demo_throttle_antispam',
      packagePath: 'packages/flutter_debounce_throttle/example',
      testName: 'demo_throttle_antispam',
    ),
    _DemoTask(
      name: 'demo_search_debounce',
      packagePath: 'packages/flutter_debounce_throttle/example',
      testName: 'demo_search_debounce',
    ),
    _DemoTask(
      name: 'demo_async_submit',
      packagePath: 'packages/flutter_debounce_throttle/example',
      testName: 'demo_async_submit',
    ),
    _DemoTask(
      name: 'demo_concurrency_replace',
      packagePath: 'packages/flutter_debounce_throttle/example',
      testName: 'demo_concurrency_replace',
    ),
    _DemoTask(
      name: 'demo_riverpod_debounce',
      packagePath: 'packages/flutter_debounce_throttle_riverpod/example',
      testName: 'demo_riverpod_debounce',
    ),
    _DemoTask(
      name: 'demo_riverpod_autodispose',
      packagePath: 'packages/flutter_debounce_throttle_riverpod/example',
      testName: 'demo_riverpod_autodispose',
    ),
    _DemoTask(
      name: 'demo_hooks_debounce',
      packagePath: 'packages/flutter_debounce_throttle_hooks/example',
      testName: 'demo_hooks_debounce',
    ),
  ];

  for (final task in tasks) {
    await _recordTask(task, device: device);
  }

  print('\n✅ All demos recorded and converted to GIF in docs/images/');
}

class _Device {
  final String id;
  final String name;
  final String platform;

  _Device({required this.id, required this.name, required this.platform});
}

class _DemoTask {
  final String name;
  final String packagePath;
  final String testName;

  _DemoTask({
    required this.name,
    required this.packagePath,
    required this.testName,
  });
}

Future<_Device?> _detectMobileDevice() async {
  final result = await Process.run('flutter', ['devices', '--machine']);
  if (result.exitCode != 0) return null;

  try {
    final List devices = jsonDecode(result.stdout);
    for (final d in devices) {
      final String id = d['id'];
      final String targetPlatform = d['targetPlatform'] ?? '';
      if (targetPlatform.contains('android') ||
          targetPlatform.contains('ios')) {
        return _Device(
          id: id,
          name: d['name'],
          platform: targetPlatform.contains('ios') ? 'ios' : 'android',
        );
      }
    }
  } catch (e) {
    print('  ⚠️ Error parsing devices: $e');
  }
  return null;
}

Future<void> _recordTask(_DemoTask task, {required _Device device}) async {
  print('\n🎬 Recording: ${task.name}');

  final videoFile =
      File('${Directory.current.path}/docs/images/${task.name}.mp4')
          .absolute
          .path;
  final gifFile = File('${Directory.current.path}/docs/images/${task.name}.gif')
      .absolute
      .path;

  Directory('docs/images').createSync(recursive: true);

  // 1. Start Recording in background
  Process? recordProcess;
  if (device.platform == 'android') {
    print('  - Starting Android screenrecord...');
    await Process.run(
        'adb', ['-s', device.id, 'shell', 'rm', '-f', '/sdcard/temp_rec.mp4']);
    recordProcess = await Process.start('adb',
        ['-s', device.id, 'shell', 'screenrecord', '/sdcard/temp_rec.mp4']);
  } else {
    print('  - Starting iOS simctl recordVideo...');
    // Use simpler command, and ensure output path is absolute
    recordProcess = await Process.start(
        'xcrun', ['simctl', 'io', device.id, 'recordVideo', videoFile]);
  }

  // Warm up recording
  await Future.delayed(const Duration(seconds: 1));

  // 2. Run Flutter Drive
  print('  - Running Flutter Drive...');
  final driveResult = await Process.run(
    'flutter',
    [
      'drive',
      '-d',
      device.id,
      '--target=lib/driver_main.dart',
      '--driver=test_driver/app_test.dart',
    ],
    workingDirectory: task.packagePath,
    environment: {
      ...Platform.environment,
      'TEST_NAME': task.testName,
    },
  );

  // 3. Stop Recording
  print('  - Stopping recording...');
  if (device.platform == 'android') {
    await Process.run(
        'adb', ['-s', device.id, 'shell', 'pkill', '-2', 'screenrecord']);
    await Future.delayed(const Duration(seconds: 3));
    print('  - Pulling video from device...');
    await Process.run(
        'adb', ['-s', device.id, 'pull', '/sdcard/temp_rec.mp4', videoFile]);
  } else {
    // Send Ctrl+C (SIGINT) to simctl to finalize video
    recordProcess.kill(ProcessSignal.sigint);
    await recordProcess.exitCode;
    // Wait for file system to sync
    await Future.delayed(const Duration(seconds: 2));
  }

  if (driveResult.exitCode != 0) {
    print('  ⚠️ Drive failed (Exit Code ${driveResult.exitCode})');
    // Don't skip conversion yet, file might still be there
  }

  // 4. Convert to GIF
  if (File(videoFile).existsSync()) {
    print('  - Converting to GIF using ffmpeg...');
    final ffmpegResult = await Process.run('ffmpeg', [
      '-y',
      '-i',
      videoFile,
      '-vf',
      'fps=30,scale=390:-1:flags=lanczos',
      '-c:v',
      'gif',
      gifFile,
    ]);

    if (ffmpegResult.exitCode == 0) {
      print('  ✅ Created: $gifFile');
      File(videoFile).deleteSync();
    } else {
      print('  ❌ FFmpeg failed');
    }
  } else {
    print('  ❌ Error: Video file was not created at: $videoFile');
    if (device.platform == 'ios') {
      print(
          '     Check if "xcrun simctl io ${device.id} recordVideo" works manually.');
    }
  }
}

Future<bool> _isCommandAvailable(String command) async {
  try {
    final result = await Process.run('which', [command]);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}
