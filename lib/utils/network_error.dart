import 'dart:async';

bool isNetworkError(Object error) {
  if (error is TimeoutException) return true;

  final runtimeType = error.runtimeType.toString().toLowerCase();
  final message = error.toString().toLowerCase();
  if (message.startsWith('exception:')) return true;
  const markers = [
    'socketexception',
    'clientexception',
    'authretryablefetchexception',
    'timeoutexception',
    'httpexception',
    'handshakeexception',
    'networkexception',
    'failed host lookup',
    'failed to fetch',
    'network request failed',
    'connection refused',
    'connection reset',
    'connection aborted',
    'connection error',
    'connection timed out',
    'connection closed',
    'network is unreachable',
    'no internet connection',
    'no address associated with hostname',
    'unable to resolve host',
    'could not resolve host',
    'name or service not known',
    'nodename nor servname provided',
  ];

  return markers.any(
    (marker) => runtimeType.contains(marker) || message.contains(marker),
  );
}
