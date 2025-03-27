import 'package:flutter/material.dart';
import 'package:tadiago/more/models/others_models.dart';
import 'package:tadiago/more/services/other_service.dart';

class OtherProvider with ChangeNotifier {
  final OtherService _othersService = OtherService();
  String? _error;
  String? get error => _error;

  Future<bool> reportAbus(Abus abus) async {
    try {
      await _othersService.reportAbus(abus);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = "Erreur inattendue : $e";
      notifyListeners();
      return false;
    }
  }

  Future<bool> contactUs(Contact contact) async {
    try {
      await _othersService.contactUs(contact);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = "Erreur inattendue : $e";
      debugPrint("Erreur inattendue : $e");
      notifyListeners();
      return false;
    }
  }
}
