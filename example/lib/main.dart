// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:geofencing/geofencing.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ReceivePort _port = ReceivePort();
  final List<String> _geofenceStates = [];
  List<String> _registeredGeofences = <String>[];
  String? _id;
  double _latitude = 50.00187;
  double _longitude = 36.23866;
  double _radius = 200.0;
  final List<GeofenceEvent> _triggers = <GeofenceEvent>[GeofenceEvent.enter, GeofenceEvent.exit];
  final AndroidGeofencingSettings _androidSettings = AndroidGeofencingSettings(
    initialTrigger: <GeofenceEvent>[
      GeofenceEvent.enter,
      GeofenceEvent.exit,
    ],
    loiteringDelay: 0,
    notificationResponsiveness: 0,
  );

  @override
  void initState() {
    super.initState();
    IsolateNameServer.registerPortWithName(
      _port.sendPort,
      'geofencing_send_port',
    );
    _port.listen((dynamic data) {
      print('Incoming: $data');
      setState(() {
        _geofenceStates.add(data);
      });
    });
    initPlatformState();
  }

  Future<void> registerGeofence() async {
    final PermissionStatus firstPermission = await Permission.locationWhenInUse.request();
    final PermissionStatus secondPermission = await Permission.locationAlways.request();
    if (firstPermission.isGranted && secondPermission.isGranted) {
      await GeofencingManager.registerGeofence(
        GeofenceRegion(
          _id ?? 'mtv',
          _latitude,
          _longitude,
          _radius,
          _triggers,
          androidSettings: _androidSettings,
        ),
        callback,
      );
      final List<String> registeredIds = await GeofencingManager.getRegisteredGeofenceIds();
      setState(() {
        _registeredGeofences = registeredIds;
      });
    }
  }

  Future<void> unregisteGeofence() async {
    for (final String id in _registeredGeofences) {
      await GeofencingManager.removeGeofenceById(id);
    }
    final List<String> registeredIds = await GeofencingManager.getRegisteredGeofenceIds();
    setState(() {
      _registeredGeofences = registeredIds;
    });
  }

  @pragma('vm:entry-point')
  static Future<void> callback(List<String> ids, Location l, GeofenceEvent e) async {
    print('\x1B[32mFences: $ids Location $l Event: $e\x1B[0m');
    final SendPort? send = IsolateNameServer.lookupPortByName('geofencing_send_port');
    send?.send('$ids - $e');
  }

  Future<void> initPlatformState() async {
    print('Initializing...');
    await GeofencingManager.initialize();
    print('Initialization done');
    final List<String> registeredIds = await GeofencingManager.getRegisteredGeofenceIds();
    setState(() {
      _registeredGeofences = registeredIds;
    });
  }

  String? numberValidator(String? value) {
    if (value == null) {
      return null;
    }
    final num? a = num.tryParse(value);
    if (a == null) {
      return '"$value" is not a valid number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Geofencing Example'),
        ),
        body: Container(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Last events: $_geofenceStates',
                textAlign: TextAlign.center,
              ),
              Center(
                child: TextButton(
                  onPressed: registerGeofence,
                  child: const Text('Register'),
                ),
              ),
              Text('Registered Geofences: $_registeredGeofences'),
              Center(
                child: TextButton(
                  onPressed: unregisteGeofence,
                  child: const Text('Unregister'),
                ),
              ),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'ID',
                ),
                keyboardType: TextInputType.text,
                controller: TextEditingController(text: _id),
                onChanged: (String? s) {
                  _id = (s?.trim().isEmpty ?? true) ? null : s?.trim();
                },
              ),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Latitude',
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: _latitude.toString()),
                onChanged: (String s) {
                  _latitude = double.tryParse(s) ?? 0.0;
                },
              ),
              TextField(
                  decoration: const InputDecoration(hintText: 'Longitude'),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: _longitude.toString()),
                  onChanged: (String s) {
                    _longitude = double.tryParse(s) ?? 0.0;
                  }),
              TextField(
                  decoration: const InputDecoration(hintText: 'Radius'),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: _radius.toString()),
                  onChanged: (String s) {
                    _radius = double.tryParse(s) ?? 0.0;
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
