import 'package:completer_ex/completer_ex.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart';

typedef OnConverted = Future<void> Function(String text);
typedef OnError = void Function(SpeechRecognitionError error);

enum ListenState {
  listening,
  stopping,
  stopped,
}

class Speech {
  late OnConverted onConverted;
  late OnError onError;

  final speechInitialised = CompleterEx<Speech>();
  late stt.SpeechToText _speech;
  ListenState listeningState = ListenState.stopped;

  String _newItemText = '';

  bool get isListening => listeningState == ListenState.listening;

  Future<Speech> get isInitialised => speechInitialised.future;

  Future<bool> init(
      {required OnConverted onConverted, required OnError onError}) async {
    this.onConverted = onConverted;
    this.onError = onError;
    _speech = stt.SpeechToText();
    final available = await _speech.initialize(
        debugLogging: true,
        finalTimeout: Duration.zero,
        onStatus: (status) async {
          if (status == 'done') {
            final _state = listeningState;
            listeningState = ListenState.stopped;

            print('Status: done $_state text: $_newItemText');
            if (_state == ListenState.stopping) {
              //   listeningState = ListenState.stopped;
              //   onError(SpeechRecognitionError(
              //       'Nothing was heard. Try again.', false));
              // } else {
              if (_newItemText.isNotEmpty) {
                await deliver();
              }
            }
          }
          //  else if (status == 'notListening') {
          //   listeningState = ListenState.stopped;
          //   await _speech.stop();
          //   onError(SpeechRecognitionError(
          //       'Something went wrong. Try again', false));
          // }
        },
        onError: (e) {
          print('Errror: $e');
          listeningState = ListenState.stopped;
          if (e.errorMsg == 'error_speech_timeout') {
            e = SpeechRecognitionError('Nothing was heard. Try again.', false);
          } else if (e.errorMsg == 'error_no_match') {
            e = SpeechRecognitionError(
                "Sorry I didn't understand. Try again.", false);
          }
          onError(e);
        });

    if (!available) {
      speechInitialised.completeError(
          ListenFailedException('Unable to start the microphone listening'));
    } else {
      speechInitialised.complete(this);
    }
    return available;
  }

  Future<void> stop() async {
    print('stop called');
    // notify the listener to stop. The 'done' status
    // will be sent to the listener.
    listeningState = ListenState.stopping;
    await _speech.stop();
    // as a last resort we try to deliver any converted text.
    // The state engine of the speech engine is dodgy.
    await deliver();
  }

  bool delivered = false;

  Future<void> start() async {
    _newItemText = '';
    delivered = false;
    listeningState = ListenState.listening;
    await _speech.listen(
        onResult: (result) async {
          _newItemText = result.recognizedWords;
          print(
              'Words recongnized: state: $listeningState Text: $_newItemText');

          /// The text can come through after the 'done'status is sent.
          if (listeningState == ListenState.stopped) {
            if (_newItemText.isNotEmpty) {
              await deliver();
            }
          }
        },
        listenOptions: SpeechListenOptions(
            cancelOnError: true, listenMode: ListenMode.dictation));
  }

  Future<void> deliver() async {
    if (_newItemText.isNotEmpty && !delivered) {
      await onConverted(_newItemText);
      delivered = true;
    }
  }
}

class ListenFailedException implements Exception {
  ListenFailedException(this.message);
  final String message;
}
