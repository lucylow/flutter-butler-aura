import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

/// Custom exception for network-related errors
class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  NetworkException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() => 'NetworkException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Custom exception for API-related errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errorData;

  ApiException(this.message, {this.statusCode, this.errorData});

  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Configuration for HTTP client
class HttpClientConfig {
  final Duration timeout;
  final int maxRetries;
  final Duration retryDelay;
  final bool enableLogging;
  final Map<String, String> defaultHeaders;

  const HttpClientConfig({
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.enableLogging = true,
    this.defaultHeaders = const {},
  });
}

/// Improved HTTP client with retry logic, timeout, and better error handling
class AppHttpClient {
  final HttpClientConfig config;
  late final http.Client _client;
  final List<Function(http.Request)> _requestInterceptors = [];
  final List<Function(http.Response)> _responseInterceptors = [];

  AppHttpClient({HttpClientConfig? config})
      : config = config ?? const HttpClientConfig() {
    _client = RetryClient(
      http.Client(),
      retries: this.config.maxRetries,
      delay: (attempt) => this.config.retryDelay * attempt,
      when: (response) => _shouldRetry(response),
      onRetry: (request, response, retryCount) {
        if (this.config.enableLogging) {
          debugPrint('🔄 Retrying request (attempt $retryCount/${this.config.maxRetries}): ${request.url}');
        }
      },
    );
  }

  /// Check if a response should be retried
  bool _shouldRetry(http.BaseResponse response) {
    if (response.statusCode >= 500) {
      return true; // Retry server errors
    }
    if (response.statusCode == 429) {
      return true; // Retry rate limit errors
    }
    return false;
  }

  /// Add a request interceptor
  void addRequestInterceptor(Function(http.Request) interceptor) {
    _requestInterceptors.add(interceptor);
  }

  /// Add a response interceptor
  void addResponseInterceptor(Function(http.Response) interceptor) {
    _responseInterceptors.add(interceptor);
  }

  /// Execute request interceptors
  void _applyRequestInterceptors(http.Request request) {
    for (final interceptor in _requestInterceptors) {
      interceptor(request);
    }
  }

  /// Execute response interceptors
  void _applyResponseInterceptors(http.Response response) {
    for (final interceptor in _responseInterceptors) {
      interceptor(response);
    }
  }

  /// Perform a GET request
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final uri = queryParameters != null && queryParameters.isNotEmpty
          ? url.replace(queryParameters: {
              ...url.queryParameters,
              ...queryParameters.map((k, v) => MapEntry(k, v.toString())),
            })
          : url;

      final request = http.Request('GET', uri);
      request.headers.addAll({
        ...config.defaultHeaders,
        ...?headers,
      });

      _applyRequestInterceptors(request);

      if (config.enableLogging) {
        debugPrint('📤 GET ${request.url}');
      }

      final response = await _client
          .send(request)
          .timeout(config.timeout)
          .then(http.Response.fromStream);

      _applyResponseInterceptors(response);

      if (config.enableLogging) {
        debugPrint('📥 GET ${request.url} - ${response.statusCode}');
      }

      _validateResponse(response);
      return response;
    } on TimeoutException {
      throw NetworkException('Request timeout after ${config.timeout.inSeconds}s');
    } on http.ClientException catch (e) {
      throw NetworkException('Network error: ${e.message}', originalError: e);
    } catch (e) {
      throw NetworkException('Unexpected error: ${e.toString()}', originalError: e);
    }
  }

  /// Perform a POST request
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    try {
      final request = http.Request('POST', url);
      request.headers.addAll({
        ...config.defaultHeaders,
        'Content-Type': 'application/json',
        ...?headers,
      });

      if (body != null) {
        if (body is Map || body is List) {
          request.body = jsonEncode(body);
        } else if (body is String) {
          request.body = body;
        } else {
          request.body = body.toString();
        }
      }

      _applyRequestInterceptors(request);

      if (config.enableLogging) {
        debugPrint('📤 POST ${request.url}');
        if (body != null && config.enableLogging) {
          debugPrint('   Body: ${request.body}');
        }
      }

      final response = await _client
          .send(request)
          .timeout(config.timeout)
          .then(http.Response.fromStream);

      _applyResponseInterceptors(response);

      if (config.enableLogging) {
        debugPrint('📥 POST ${request.url} - ${response.statusCode}');
      }

      _validateResponse(response);
      return response;
    } on TimeoutException {
      throw NetworkException('Request timeout after ${config.timeout.inSeconds}s');
    } on http.ClientException catch (e) {
      throw NetworkException('Network error: ${e.message}', originalError: e);
    } catch (e) {
      throw NetworkException('Unexpected error: ${e.toString()}', originalError: e);
    }
  }

  /// Perform a PUT request
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    try {
      final request = http.Request('PUT', url);
      request.headers.addAll({
        ...config.defaultHeaders,
        'Content-Type': 'application/json',
        ...?headers,
      });

      if (body != null) {
        if (body is Map || body is List) {
          request.body = jsonEncode(body);
        } else if (body is String) {
          request.body = body;
        } else {
          request.body = body.toString();
        }
      }

      _applyRequestInterceptors(request);

      if (config.enableLogging) {
        debugPrint('📤 PUT ${request.url}');
      }

      final response = await _client
          .send(request)
          .timeout(config.timeout)
          .then(http.Response.fromStream);

      _applyResponseInterceptors(response);

      if (config.enableLogging) {
        debugPrint('📥 PUT ${request.url} - ${response.statusCode}');
      }

      _validateResponse(response);
      return response;
    } on TimeoutException {
      throw NetworkException('Request timeout after ${config.timeout.inSeconds}s');
    } on http.ClientException catch (e) {
      throw NetworkException('Network error: ${e.message}', originalError: e);
    } catch (e) {
      throw NetworkException('Unexpected error: ${e.toString()}', originalError: e);
    }
  }

  /// Perform a DELETE request
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    try {
      final request = http.Request('DELETE', url);
      request.headers.addAll({
        ...config.defaultHeaders,
        ...?headers,
      });

      _applyRequestInterceptors(request);

      if (config.enableLogging) {
        debugPrint('📤 DELETE ${request.url}');
      }

      final response = await _client
          .send(request)
          .timeout(config.timeout)
          .then(http.Response.fromStream);

      _applyResponseInterceptors(response);

      if (config.enableLogging) {
        debugPrint('📥 DELETE ${request.url} - ${response.statusCode}');
      }

      _validateResponse(response);
      return response;
    } on TimeoutException {
      throw NetworkException('Request timeout after ${config.timeout.inSeconds}s');
    } on http.ClientException catch (e) {
      throw NetworkException('Network error: ${e.message}', originalError: e);
    } catch (e) {
      throw NetworkException('Unexpected error: ${e.toString()}', originalError: e);
    }
  }

  /// Send a streaming request
  Future<http.StreamedResponse> send(http.Request request) async {
    try {
      request.headers.addAll(config.defaultHeaders);
      _applyRequestInterceptors(request);

      if (config.enableLogging) {
        debugPrint('📤 STREAM ${request.method} ${request.url}');
      }

      final response = await _client.send(request).timeout(config.timeout);

      if (config.enableLogging) {
        debugPrint('📥 STREAM ${request.method} ${request.url} - ${response.statusCode}');
      }

      return response;
    } on TimeoutException {
      throw NetworkException('Request timeout after ${config.timeout.inSeconds}s');
    } on http.ClientException catch (e) {
      throw NetworkException('Network error: ${e.message}', originalError: e);
    } catch (e) {
      throw NetworkException('Unexpected error: ${e.toString()}', originalError: e);
    }
  }

  /// Validate response and throw appropriate exceptions
  void _validateResponse(http.Response response) {
    if (response.statusCode >= 400) {
      Map<String, dynamic>? errorData;
      try {
        final body = response.body;
        if (body.isNotEmpty) {
          errorData = jsonDecode(body) as Map<String, dynamic>?;
        }
      } catch (e) {
        // Ignore JSON parsing errors
      }

      final message = errorData?['error']?['message'] ??
          errorData?['message'] ??
          'Request failed with status ${response.statusCode}';

      throw ApiException(
        message.toString(),
        statusCode: response.statusCode,
        errorData: errorData,
      );
    }
  }

  /// Close the HTTP client and release resources
  void close() {
    _client.close();
  }
}
