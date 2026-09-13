import 'dart:async';
import 'dart:io';

/// Converts any caught exception into a detailed, human-readable string
/// that shows WHAT type of error it is and WHERE it likely came from,
/// instead of just printing the raw exception.
String describeError(Object e) {
  if (e is SocketException) {
    return "NETWORK ERROR (SocketException)\n"
        "Message: ${e.message}\n"
        "Address: ${e.address?.address ?? 'unknown'}\n"
        "OS Error: ${e.osError?.message ?? 'none'} (errno: ${e.osError?.errorCode ?? 'n/a'})\n"
        "→ Likely cause: DNS lookup failed OR device has no real internet route to the server.";
  } else if (e is TimeoutException) {
    return "TIMEOUT ERROR\n"
        "Message: ${e.message ?? 'Request took too long'}\n"
        "→ Likely cause: Server is slow to respond, or is asleep (Render free tier cold start), or network is too slow.";
  } else if (e is HttpException) {
    return "HTTP ERROR\n"
        "Message: ${e.message}\n"
        "URI: ${e.uri ?? 'unknown'}\n"
        "→ Likely cause: Server responded but with a malformed/unexpected response.";
  } else if (e is FormatException) {
    return "FORMAT ERROR (bad JSON)\n"
        "Message: ${e.message}\n"
        "→ Likely cause: Server sent back something that isn't valid JSON (e.g. an HTML error page instead of API response).";
  } else if (e is HandshakeException) {
    return "SSL/TLS ERROR (HandshakeException)\n"
        "Message: ${e.message}\n"
        "→ Likely cause: Certificate problem or a network proxy interfering with HTTPS.";
  } else {
    return "UNKNOWN ERROR (${e.runtimeType})\n"
        "Message: $e\n"
        "→ This error type wasn't specifically handled — check the full message above.";
  }
}
