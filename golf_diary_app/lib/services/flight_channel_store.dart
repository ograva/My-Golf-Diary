import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/flight_session.dart';
import 'sync_constants.dart';

abstract class FlightChannelStore {
  Future<void> saveFlight(FlightSnapshot flight);

  Future<FlightSnapshot?> readFlight(String flightId);

  Stream<FlightSnapshot?> watchFlight(String flightId);
}

class MemoryFlightChannelStore implements FlightChannelStore {
  final Map<String, FlightSnapshot> flights = {};
  final Map<String, StreamController<FlightSnapshot?>> _watches = {};

  void _emit(String flightId) {
    final controller = _watches[flightId];
    if (controller == null || controller.isClosed) return;
    controller.add(flights[flightId]);
  }

  @override
  Future<void> saveFlight(FlightSnapshot flight) async {
    flights[flight.flightId] = flight;
    _emit(flight.flightId);
  }

  @override
  Future<FlightSnapshot?> readFlight(String flightId) async => flights[flightId];

  @override
  Stream<FlightSnapshot?> watchFlight(String flightId) {
    final controller = _watches.putIfAbsent(
      flightId,
      () => StreamController<FlightSnapshot?>.broadcast(),
    );
    scheduleMicrotask(() => controller.add(flights[flightId]));
    return controller.stream;
  }
}

class FirestoreFlightChannelStore implements FlightChannelStore {
  FirestoreFlightChannelStore({FirebaseFirestore? firestore})
      : _firestore = firestore ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: kFirestoreDatabaseId,
            );

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _flights =>
      _firestore.collection('flights');

  @override
  Future<void> saveFlight(FlightSnapshot flight) async {
    await _flights.doc(flight.flightId).set(flight.toMap());
  }

  @override
  Future<FlightSnapshot?> readFlight(String flightId) async {
    final snap = await _flights.doc(flightId).get();
    final data = snap.data();
    if (data == null) return null;
    return FlightSnapshot.fromMap(data);
  }

  @override
  Stream<FlightSnapshot?> watchFlight(String flightId) {
    return _flights.doc(flightId).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return FlightSnapshot.fromMap(data);
    });
  }
}

FlightChannelStore defaultFlightStore() {
  if (Firebase.apps.isEmpty) return MemoryFlightChannelStore();
  return FirestoreFlightChannelStore();
}
