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
  String geofenceState = 'N/A';
  List<String> registeredGeofences = <String>[];
  String? id;
  double latitude = 50.00187;
  double longitude = 36.23866;
  double radius = 200.0;
  ReceivePort port = ReceivePort();
  final List<GeofenceEvent> triggers = <GeofenceEvent>[
    GeofenceEvent.enter,
    GeofenceEvent.exit
  ];
  final AndroidGeofencingSettings androidSettings = AndroidGeofencingSettings(
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
      port.sendPort,
      'geofencing_send_port',
    );
    port.listen((dynamic data) {
      print('Event: $data');
      setState(() {
        geofenceState = data;
      });
    });
    initPlatformState();
  }

  Future<void> registerGeofence() async {
    final PermissionStatus firstPermission =
        await Permission.locationWhenInUse.request();
    final PermissionStatus secondPermission =
        await Permission.locationAlways.request();
    if (firstPermission.isGranted && secondPermission.isGranted) {
      await GeofencingManager.registerGeofence(
        GeofenceRegion(
          id ?? 'mtv',
          latitude,
          longitude,
          radius,
          triggers,
          androidSettings: androidSettings,
        ),
        callback,
      );
      final List<String> registeredIds =
          await GeofencingManager.getRegisteredGeofenceIds();
      setState(() {
        registeredGeofences = registeredIds;
      });
    }
  }

  Future<void> unregisteGeofence() async {
    for (final String id in registeredGeofences) {
      await GeofencingManager.removeGeofenceById(id);
    }
    final List<String> registeredIds =
        await GeofencingManager.getRegisteredGeofenceIds();
    setState(() {
      registeredGeofences = registeredIds;
    });
  }

  @pragma('vm:entry-point')
  static Future<void> callback(
      List<String> ids, Location l, GeofenceEvent e) async {
    print('\x1B[32mFences: $ids Location $l Event: $e\x1B[0m');
    final SendPort? send =
        IsolateNameServer.lookupPortByName('geofencing_send_port');
    send?.send(e.toString());
  }

  Future<void> initPlatformState() async {
    print('Initializing...');
    await GeofencingManager.initialize();
    print('Initialization done');
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
              Text('Current state: $geofenceState'),
              Center(
                child: TextButton(
                  onPressed: registerGeofence,
                  child: const Text('Register'),
                ),
              ),
              Text('Registered Geofences: $registeredGeofences'),
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
                controller: TextEditingController(text: id),
                onChanged: (String? s) {
                  id = (s?.trim().isEmpty ?? true) ? null : s?.trim();
                },
              ),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Latitude',
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: latitude.toString()),
                onChanged: (String s) {
                  latitude = double.tryParse(s) ?? 0.0;
                },
              ),
              TextField(
                  decoration: const InputDecoration(hintText: 'Longitude'),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: longitude.toString()),
                  onChanged: (String s) {
                    longitude = double.tryParse(s) ?? 0.0;
                  }),
              TextField(
                  decoration: const InputDecoration(hintText: 'Radius'),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: radius.toString()),
                  onChanged: (String s) {
                    radius = double.tryParse(s) ?? 0.0;
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
