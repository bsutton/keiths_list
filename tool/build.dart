#! /home/bsutton/.dswitch/active/dart

import 'package:args/args.dart';
import 'package:dcli/dcli.dart';

void main(List<String> args) {
  final parser = ArgParser()
    ..addFlag('build', abbr: 'b', help: 'build the apk')
    ..addFlag('install', abbr: 'i', help: 'install the apk');

  final results = parser.parse(args);

  var build = results['build'] as bool;
  var install = results['install'] as bool;

  if (!build && !install) {
    /// no switches passed so do it all.
    build = install = true;
  }

  var needPubGet = true;

  if (build) {
    if (needPubGet) {
      _runPubGet();
      needPubGet = false;
    }
    buildApk();
  }

  if (install) {
    if (needPubGet) {
      _runPubGet();
      needPubGet = false;
    }
    installApk();
  }
}

void _runPubGet() {
  DartSdk().runPubGet(DartProject.self.pathToProjectRoot);
}

void installApk() {
  'flutter install'.run;
}

void buildApk() {
// TODO(bsutton): the rich text editor includes randome icons
// so tree shaking of icons isn't possible. Can we fix this?
  'flutter build apk --no-tree-shake-icons'.run;
}
