import 'package:flutter/material.dart';
import 'package:cengproject/dbhelper/mongodb.dart';

class AddPatientPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const AddPatientPage({super.key, required this.user});

  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  final TextEditingController _patientNumberController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _addPatient() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    String patientNumber = _patientNumberController.text;

    try {
      var result = await MongoDatabase.addPatient(
        widget.user['_id'].toHexString(),
        patientNumber,
      );

      if (result['success']) {
        Navigator.pop(context, true); // Pass 'true' to indicate success
      } else {
        switch (result['status']) {
          case 1:
            setState(() {
              _errorMessage = 'Patient does not exist.';
            });
            break;
          case 2:
            setState(() {
              _errorMessage = 'Patient already in caregiver\'s list.';
            });
            break;
          case 3:
            setState(() {
              _errorMessage = 'Patient belongs to another caregiver.';
            });
            break;
          default:
            setState(() {
              _errorMessage = 'An unexpected error occurred.';
            });
        }
      }
    } catch (e) {
      print('Error adding patient: $e');
      setState(() {
        _errorMessage = 'Error adding patient: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    // Clear the error message after 5 seconds
    if (_errorMessage.isNotEmpty) {
      Future.delayed(const Duration(seconds: 5), () {
        setState(() {
          _errorMessage = '';
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Patient',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 34, 43, 170),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: const Color.fromARGB(255, 34, 43, 170),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _inputField("Patient Number", _patientNumberController),
            const SizedBox(height: 32),
            _isLoading ? const CircularProgressIndicator() : _addButton(),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(String hintText, TextEditingController controller) {
    var border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: const BorderSide(color: Colors.white),
    );

    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.3),
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white),
        border: border,
        enabledBorder: border,
        focusedBorder: border,
      ),
    );
  }

  Widget _addButton() {
    return ElevatedButton(
      onPressed: _addPatient,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color.fromARGB(255, 18, 170, 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const SizedBox(
        width: double.infinity,
        child: Text(
          "Add Patient",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }
}
