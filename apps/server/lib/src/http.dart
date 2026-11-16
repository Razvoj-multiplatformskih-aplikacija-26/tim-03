import 'dart:convert';

import 'package:api_contract/api_contract.dart';
import 'package:relic/relic.dart';

final _problemMimeType = MimeType.parse(ProblemDto.mediaType);

Response json(int status, Object? body) =>
    Response(status, body: Body.fromString(jsonEncode(body), mimeType: MimeType.json));

Response problemResponse(ProblemDto problem) =>
    Response(problem.status, body: Body.fromString(jsonEncode(problem.toJson()), mimeType: _problemMimeType));

const maxBodyBytes = 16 * 1024;

final class UnsupportedMediaType implements Exception {
  const UnsupportedMediaType();
}

Future<Map<String, Object?>> readObject(Request request) async {
  if (request.mimeType != MimeType.json) throw const UnsupportedMediaType();
  return switch (jsonDecode(await request.readAsString(maxLength: maxBodyBytes))) {
    final Map<String, Object?> object => object,
    _ => throw const FormatException('Expected a JSON object'),
  };
}
