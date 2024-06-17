import 'package:completer_ex/completer_ex.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart';

typedef OnConverted = void Function(String text);
typedef OnError = void Function(SpeechRecognitionError error);

enum ListenState {
  listening,
  stopping,
  stopped,
}

class Speech {
  final speechInitialised = CompleterEx<Speech>();
  late stt.SpeechToText _speech;
  ListenState listeningState = ListenState.stopped;

  String _newItemText = '';

  bool get isListening => listeningState == ListenState.listening;

  Future<Speech> get isInitialised => speechInitialised.future;

  Future<bool> init(
      {required OnConverted onConverted, required OnError onError}) async {
    _speech = stt.SpeechToText();
    final available = await _speech.initialize(
        debugLogging: true,
        finalTimeout: Duration.zero,
        onStatus: (status) {
          if (status == 'done') {
            assert(listeningState == ListenState.stopping,
                'We should on receive done after we call stop');
            onConverted(_newItemText);
            print('done');
            _newItemText = '';
            listeningState = ListenState.stopped;
          }
        },
        onError: (e) => onError(e));

    if (!available) {
      speechInitialised.completeError(
          ListenFailedException('Unable to start the microphone listening'));
    } else {
      speechInitialised.complete(this);
    }
    return available;
  }

  Future<void> stop() async {
    // notify the listener to stop. The 'done' status
    // will be sent to the listener.
    await _speech.stop();
    listeningState = ListenState.stopping;
  }

  Future<void> listen() async {
    await _speech.listen(
        onResult: (result) {
          _newItemText = result.recognizedWords;
          print('Updated Text: $_newItemText');
        },
        listenOptions: SpeechListenOptions(cancelOnError: true));
    listeningState = ListenState.listening;
  }
}

class ListenFailedException implements Exception {
  ListenFailedException(this.message);
  final String message;
}
