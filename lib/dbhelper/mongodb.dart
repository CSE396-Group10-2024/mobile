import 'package:cengproject/dbhelper/constant.dart';
import 'package:cengproject/local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart';

class MongoDatabase {
  // ignore: prefer_typing_uninitialized_variables
  static var db;

  static Future<void> connect() async {
    try {
      // Establish the database connection
      db = await Db.create(MONGO_CONN_URL);
      await db!.open();
      if (kDebugMode) {
        print('Database connection opened.');
      }

      // Check the server status to confirm connection
      var status = await db!.serverStatus();
      if (status != null) {
        if (kDebugMode) {
          print('Connected to database');
        }
      } else {
        if (kDebugMode) {
          print('Failed to retrieve server status');
        }
        return;
      }
    } catch (e) {
      // Handle any errors that occur during connection or querying
      if (kDebugMode) {
        print('An error occurred: $e');
      }
    }
  }

  static Future<bool> authenticateUser(String username, String password) async {
    try {
      var collection = db!.collection(CAREGIVER_COLLECTION);
      var user = await collection.findOne(where.eq('username', username));
      if (user != null) {
        var storedPassword = user['password'];
        if (storedPassword == password) {
          return true;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('An error occurred during authentication: $e');
      }
    }
    return false;
  }

  static Future<Map<String, dynamic>?> getUser(String username) async {
    try {
      var collection = db!.collection(CAREGIVER_COLLECTION);
      var user = await collection.findOne({'username': username});
      return user;
    } catch (e) {
      if (kDebugMode) {
        print('An error occurred while getting user: $e');
      }
      return null;
    }
  }

  static Stream<List<Map<String, dynamic>>> getCarePatientsStream(String caregiverId) async* {
    var objectId = ObjectId.parse(caregiverId);
    while (await db!.serverStatus() != null) {
      try {
        var caregiver = await db!
            .collection(CAREGIVER_COLLECTION)
            .findOne(where.id(objectId));
        
        if (caregiver == null || !caregiver.containsKey('care_patients')) {
          yield [];
        } else {
          var patientIds = List<String>.from(caregiver['care_patients']);
          var objectIds = patientIds.map((id) => ObjectId.parse(id)).toList();
          var patients = await db!
              .collection(PATIENT_COLLECTION)
              .find(where.oneFrom('_id', objectIds))
              .toList();
          yield patients;
        }
      } catch (e) {
        if (kDebugMode) {
          print('An error occurred while fetching care patients: $e');
        }
        yield [];
      }
      await Future.delayed(const Duration(seconds: 10)); // Fetch new data every 2 seconds
    }
  }

  static Stream<List<Map<String, dynamic>>> getNotifications(String caregiverId) async* {
  var objectId = ObjectId.parse(caregiverId);
  while (await db!.serverStatus() != null) {
    try {
      var caregiver = await db!
          .collection(CAREGIVER_COLLECTION)
          .findOne(where.id(objectId));
      
      if (caregiver == null || !caregiver.containsKey('notifications')) {
        yield [];
      } else {
        var notifications = List<Map<String, dynamic>>.from(caregiver['notifications']);
        yield notifications;
      }
    } catch (e) {
      if (kDebugMode) {
        print('An error occurred while fetching notifications: $e');
      }
      yield [];
    }
    await Future.delayed(const Duration(seconds: 5)); // Fetch new data every 5 seconds
  }
}

  static Future<bool> createUser(String username, String password) async {
    try {
      var existingUser = await db!
          .collection(CAREGIVER_COLLECTION)
          .findOne(where.eq('username', username));
      if (existingUser != null) {
        return false; // User already exists
      }

      var newUser = {
        'username': username,
        'password': password,
        'care_patients': [],
        'notifications': []
      };

      await db!.collection(CAREGIVER_COLLECTION).insertOne(newUser);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('An error occurred during user creation: $e');
      }
      return false;
    }
  }

  static Future<Map<String, dynamic>> addPatient(String caregiverId, String patientNumber) async {
  try {
    var caregiverCollection = db!.collection(CAREGIVER_COLLECTION);
    var patientCollection = db!.collection(PATIENT_COLLECTION);

    // Check if the patient exists
    var patient = await patientCollection.findOne({'patient_number': patientNumber});
    if (patient == null) {
      if (kDebugMode) {
        print('Patient does not exist.');
      }
      return {'success': false, 'status': 1}; // Patient does not exist
    }

    var patientId = patient['_id'] as ObjectId;
    // ignore: deprecated_member_use
    String patientIdString = patientId.toHexString();

    // Check if the patient is already in the caregiver's list
    var caregiver = await caregiverCollection.findOne(where.id(ObjectId.fromHexString(caregiverId)));
      if (caregiver != null && caregiver['care_patients'] != null) {
        List<String> carePatients = List<String>.from(caregiver['care_patients']);
        if (carePatients.contains(patientIdString)) {
          if (kDebugMode) {
            print('Patient already in caregiver\'s care_patients list.');
          }
          return {'success': false, 'status': 2}; // Patient already in the list
        }
      }

      // Check if the patient already has a personal caregiver
      if (patient['personal_caregiver'] != null && patient['personal_caregiver'].isNotEmpty) {
        if (kDebugMode) {
          print('Patient belongs to another caregiver.');
        }
        return {'success': false, 'status': 3}; // Patient belongs to another caregiver
      }

      // Update the caregiver's array of care_patients with ObjectId as string
      await caregiverCollection.updateOne(
        where.id(ObjectId.fromHexString(caregiverId)),
        modify.push('care_patients', patientIdString),
      );

      // Update the patient's personal_caregiver field with the caregiver's ID
      await patientCollection.updateOne(
        where.id(patientId),
        modify.set('personal_caregiver', caregiverId),
      );

      if (kDebugMode) {
        print('Patient added to caregiver\'s care_patients list and personal_caregiver updated.');
      }
      return {'success': true, 'status': 0}; // Patient added successfully
    } catch (e) {
      if (kDebugMode) {
        print('Error adding patient: $e');
      }
      return {'success': false, 'status': -1}; // Error occurred
    }
  }

  static Future<Map<String, String>> getConnectionAddress(String patientNumber) async {
    try {
      var patientCollection = db!.collection(PATIENT_COLLECTION);
      var patient = await patientCollection.findOne(where.eq('patient_number', patientNumber));
      if (patient != null) {
        var connectionAddress = patient['connection_address'];
        if (connectionAddress != null && connectionAddress.contains(':')) {
          var parts = connectionAddress.split(':');
          return {
            'ip': parts[0],
            'port': parts[1]
          };
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('An error occurred while fetching the connection address: $e');
      }
    }
    return {};
  }

  static Stream<void> checkVideoConnectionRequest(String patientId) async* {
    var objectId = ObjectId.parse(patientId);
    while (await db!.serverStatus() != null) {
      try {
        var patient = await db!
            .collection(PATIENT_COLLECTION)
            .findOne(where.id(objectId));

        if (patient != null && patient['requested_video_connection'] == true) {
          // Update the requested_video_connection field to false
          await db!.collection(PATIENT_COLLECTION).update(
              where.id(objectId),
              modify.set('requested_video_connection', false));

          // Extract and format the requested_connection_time
          String requestedConnectionTime = patient['requested_connection_time'];
          DateTime dateTime = DateTime.parse(requestedConnectionTime);
          String formattedTime = '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

          // Show local notification
          String roomNumber = patient['room_number'];
          String patientNum = patient['patient_number'];
          String payload = 'Room: $roomNumber, Patient: $patientNum, Time: $formattedTime'; // Example payload
          await LocalNotifications.showNotification(
              'Video Connection Request',
              'Room: $roomNumber, Patient: $patientNum, Time: $formattedTime',
              payload);
        }
      } catch (e) {
        if (kDebugMode) {
          print('An error occurred while checking video connection request: $e');
        }
      }

      // Wait for 5 seconds before checking again
      await Future.delayed(const Duration(seconds: 7));
      yield null;
    }
  }

  static Future<void> disconnect() async {
    if (db != null) {
      await db!.close();
      if (kDebugMode) {
        print('Database connection closed.');
      }
    }
  }
}
