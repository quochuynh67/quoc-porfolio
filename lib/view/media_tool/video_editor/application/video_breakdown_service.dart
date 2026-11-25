import '../domain/video_editor_project.dart';

class VideoBreakdownService {
  const VideoBreakdownService();

  String buildVideoMarkdown(VideoEditorProject project) {
    final buffer = StringBuffer()
      ..writeln('# VIDEO.md — Media Studio Project')
      ..writeln()
      ..writeln('> Generated from the editable project model using the '
          'rea-video breakdown structure. This is deterministic project '
          'inspection, not AI-origin detection.')
      ..writeln()
      ..writeln('## Overview')
      ..writeln()
      ..writeln('- Duration: ${_time(project.duration)}')
      ..writeln('- Canvas: ${_ratio(project.aspectRatio)}')
      ..writeln('- Shots: ${project.clips.length}')
      ..writeln('- Overlays: ${project.overlays.length}')
      ..writeln('- Audio tracks: ${project.audioTracks.length}')
      ..writeln()
      ..writeln('## Shot timeline')
      ..writeln()
      ..writeln('| # | Time | Source | Type | Trim | Speed | Filter | Transition |')
      ..writeln('|---|---|---|---|---|---|---|---|');

    var cursor = Duration.zero;
    for (var index = 0; index < project.clips.length; index++) {
      final clip = project.clips[index];
      final end = cursor + clip.duration;
      buffer.writeln(
        '| ${index + 1} | ${_time(cursor)}–${_time(end)} | '
        '${_escape(clip.name)} | ${clip.type.name} | '
        '${clip.type == EditorAssetType.video ? '${_time(clip.trimStart)}–${_time(clip.trimEnd)}' : '—'} | '
        '${clip.speed.toStringAsFixed(2)}x | ${clip.filter.preset} | '
        '${index == 0 ? '—' : '${clip.transition.name}${clip.fx != null ? ' (${_escape(clip.fx!.name)})' : ''} ${(clip.transitionDuration.inMilliseconds / 1000).toStringAsFixed(1)}s'} |',
      );
      cursor = end;
    }

    buffer
      ..writeln()
      ..writeln('## Editing package')
      ..writeln();

    if (project.overlays.isEmpty) {
      buffer.writeln('- No text or sticker overlays.');
    } else {
      for (final overlay in project.overlays) {
        buffer.writeln(
          '- ${overlay.type.name}: "${overlay.label}" at '
          '${_time(overlay.start)}, duration ${_time(overlay.duration)}, '
          'position (${overlay.position.dx.toStringAsFixed(2)}, '
          '${overlay.position.dy.toStringAsFixed(2)}), '
          'scale ${overlay.scale.toStringAsFixed(2)}, '
          'enter ${overlay.enter.name}, exit ${overlay.exit.name}, '
          'loop ${overlay.loop.name}.',
        );
      }
    }

    buffer
      ..writeln()
      ..writeln('## Sound')
      ..writeln();
    if (project.audioTracks.isEmpty) {
      buffer.writeln('- No separate background music track.');
    } else {
      for (final track in project.audioTracks) {
        buffer.writeln(
          '- ${track.name}: gain ${(track.volume * 100).round()}%.',
        );
      }
    }

    buffer
      ..writeln()
      ..writeln('## Rhythm and transitions')
      ..writeln()
      ..writeln('- Average shot length: ${_averageShot(project)}.')
      ..writeln('- Cut points: ${_cutPoints(project)}.')
      ..writeln()
      ..writeln('## Remake checklist')
      ..writeln()
      ..writeln(
          '1. Prepare every original image/video listed in the shot table.')
      ..writeln('2. Rebuild the canvas at ${_ratio(project.aspectRatio)}.')
      ..writeln('3. Match shot durations and transitions in order.')
      ..writeln(
          '4. Recreate text/sticker overlays with normalized coordinates.')
      ..writeln(
          '5. Add the audio tracks and verify cut points against the beat.')
      ..writeln('6. Compare preview and export at every transition boundary.')
      ..writeln()
      ..writeln('## Deep analysis with rea-video CLI')
      ..writeln()
      ..writeln('For a rendered reference video, run:')
      ..writeln()
      ..writeln('```bash')
      ..writeln('.rea-video-venv/bin/rea-video survey reference.mp4 '
          '-o rea-video-output/reference')
      ..writeln('.rea-video-venv/bin/rea-video decompose reference.mp4 '
          '-o rea-video-output/reference --lang en')
      ..writeln('.rea-video-venv/bin/rea-video summary '
          'rea-video-output/reference/breakdown.json')
      ..writeln('```');

    return buffer.toString();
  }

  String _averageShot(VideoEditorProject project) {
    if (project.clips.isEmpty) return '0.0s';
    return '${(project.duration.inMilliseconds / project.clips.length / 1000).toStringAsFixed(1)}s';
  }

  String _cutPoints(VideoEditorProject project) {
    if (project.clips.length < 2) return 'none';
    var cursor = Duration.zero;
    final points = <String>[];
    for (var index = 0; index < project.clips.length - 1; index++) {
      cursor += project.clips[index].duration;
      points.add(_time(cursor));
    }
    return points.join(', ');
  }

  String _ratio(double ratio) {
    if ((ratio - 9 / 16).abs() < .01) return '9:16 portrait';
    if ((ratio - 16 / 9).abs() < .01) return '16:9 landscape';
    if ((ratio - 1).abs() < .01) return '1:1 square';
    return ratio.toStringAsFixed(3);
  }

  String _time(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    final tenths = (value.inMilliseconds.remainder(1000) / 100).floor();
    return '$minutes:$seconds.$tenths';
  }

  String _escape(String value) => value.replaceAll('|', r'\|');
}
