import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

part 'app/app_shell.dart';
part 'core/state/anshin_state.dart';
part 'shared/widgets/voice_capture_indicator.dart';
part 'features/dashboard/presentation/dashboard_screen.dart';
part 'features/transactions/presentation/transactions_screen.dart';
part 'features/budget/presentation/budget_screen.dart';
part 'features/streak/presentation/streak_screen.dart';
