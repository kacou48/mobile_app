import 'package:dio/dio.dart';
//import 'package:flutter/material.dart';
import 'package:tadiago/more/models/others_models.dart';
import 'package:tadiago/utils/constant.dart';

class OtherService {
  static const String baseUrl = myBaseUrl;

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    contentType: 'application/json',
    responseType: ResponseType.json,
    validateStatus: (status) {
      return status! < 500;
    },
  ));

  Future<Map<String, dynamic>> reportAbus(Abus abus) async {
    final response = await _dio.post(
      '/api/others/abus/',
      data: abus.toJson(),
    );

    if (response.statusCode == 201) {
      return {'success': true, 'message': 'Abuse reported successfully!'};
    } else {
      return {'success': false, 'message': 'Failed to report abuse.'};
    }
  }

  Future<Map<String, dynamic>> contactUs(Contact contact) async {
    final response = await _dio.post(
      '/api/others/contact/',
      data: contact.toJson(),
    );

    if (response.statusCode == 201) {
      return {'success': true, 'message': 'Abuse reported successfully!'};
    } else {
      return {'success': false, 'message': 'Failed to report abuse.'};
    }
  }
}
