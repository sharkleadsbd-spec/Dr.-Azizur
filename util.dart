import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const kBlue = Color(0xFF1565C0);
final ValueNotifier<bool> bn = ValueNotifier(false); // false = English, true = Bangla

const _t = <String, List<String>>{
  'appName': ['Doctor Appointment Manager', 'ডাক্তার অ্যাপয়েন্টমেন্ট ম্যানেজার'],
  'doctor': ['Doctor', 'ডাক্তার'],
  'assistant': ['Assistant', 'সহকারী'],
  'username': ['Username', 'ইউজারনেম'],
  'password': ['Password', 'পাসওয়ার্ড'],
  'signIn': ['Sign in', 'প্রবেশ করুন'],
  'invalidLogin': ['Invalid username or password', 'ইউজারনেম বা পাসওয়ার্ড ভুল'],
  'demoHint': ['Demo logins: doctor / Doctor@123, assistant / Assist@123', 'ডেমো লগইন: doctor / Doctor@123, assistant / Assist@123'],
  'dashboard': ['Dashboard', 'ড্যাশবোর্ড'],
  'newAppt': ['New Appointment', 'নতুন অ্যাপয়েন্টমেন্ট'],
  'records': ['Records', 'রেকর্ড'],
  'today': ['Today', 'আজ'],
  'allTime': ['All time', 'সর্বমোট'],
  'totalAppts': ['Appointments', 'অ্যাপয়েন্টমেন্ট'],
  'newPatients': ['New patients', 'নতুন রোগী'],
  'oldPatients': ['Old patients', 'পুরাতন রোগী'],
  'patientName': ['Patient name', 'রোগীর নাম'],
  'age': ['Age', 'বয়স'],
  'yrs': ['yrs', 'বছর'],
  'phone': ['Phone number', 'ফোন নম্বর'],
  'patientType': ['Patient type', 'রোগীর ধরন'],
  'newPatient': ['New Patient', 'নতুন রোগী'],
  'oldPatient': ['Old Patient', 'পুরাতন রোগী'],
  'apptDate': ['Appointment date', 'অ্যাপয়েন্টমেন্টের তারিখ'],
  'serial': ['Serial', 'সিরিয়াল'],
  'notes': ['Additional notes (optional)', 'অতিরিক্ত নোট (ঐচ্ছিক)'],
  'review': ['Review', 'পর্যালোচনা'],
  'confirmAppt': ['Confirm Appointment', 'অ্যাপয়েন্টমেন্ট নিশ্চিত করুন'],
  'editInfo': ['Edit Information', 'তথ্য সম্পাদনা'],
  'saved': ['Saved. Serial', 'সংরক্ষিত। সিরিয়াল'],
  'updated': ['Information updated', 'তথ্য আপডেট হয়েছে'],
  'speak': ['Tap mic and say: name, age, phone', 'মাইক চেপে বলুন: নাম, বয়স, ফোন'],
  'listening': ['Listening… tap to stop', 'শুনছি… থামাতে চাপুন'],
  'heard': ['Heard', 'শোনা গেছে'],
  'verifyVoice': ['Fields filled from voice. Please verify before confirming.', 'ভয়েস থেকে তথ্য বসানো হয়েছে। নিশ্চিত করার আগে যাচাই করুন।'],
  'micUnavailable': ['Speech recognition is unavailable or permission denied', 'স্পিচ রিকগনিশন চালু নেই বা অনুমতি দেওয়া হয়নি'],
  'noBangla': ['Bangla voice pack not found; using device default language', 'বাংলা ভয়েস প্যাক পাওয়া যায়নি; ডিভাইসের ডিফল্ট ভাষা ব্যবহার হচ্ছে'],
  'search': ['Search name or phone', 'নাম বা ফোন দিয়ে খুঁজুন'],
  'all': ['All', 'সব'],
  'status': ['Status', 'অবস্থা'],
  'Confirmed': ['Confirmed', 'নিশ্চিত'],
  'Completed': ['Completed', 'সম্পন্ন'],
  'Cancelled': ['Cancelled', 'বাতিল'],
  'noRecords': ['No records found', 'কোনো রেকর্ড নেই'],
  'history': ['Appointment history', 'অ্যাপয়েন্টমেন্টের ইতিহাস'],
  'backup': ['Backup / export database', 'ডাটাবেস ব্যাকআপ / এক্সপোর্ট'],
  'restore': ['Restore database', 'ডাটাবেস রিস্টোর'],
  'logout': ['Log out', 'লগআউট'],
  'backupDone': ['Backup created', 'ব্যাকআপ তৈরি হয়েছে'],
  'restoreConfirm': ['Restoring replaces ALL current data. Continue?', 'রিস্টোর করলে বর্তমান সব ডাটা প্রতিস্থাপিত হবে। চালিয়ে যাবেন?'],
  'restoreDone': ['Database restored', 'ডাটাবেস রিস্টোর হয়েছে'],
  'invalidName': ['Enter a valid name (min 2 characters)', 'সঠিক নাম লিখুন (কমপক্ষে ২ অক্ষর)'],
  'invalidAge': ['Enter age between 1 and 120', '১ থেকে ১২০ এর মধ্যে বয়স লিখুন'],
  'invalidPhone': ['Enter a valid 11-digit mobile number (01XXXXXXXXX)', 'সঠিক ১১ সংখ্যার মোবাইল নম্বর দিন (01XXXXXXXXX)'],
  'duplicate': ['This patient already has an active appointment on this date', 'এই রোগীর এই তারিখে ইতোমধ্যে অ্যাপয়েন্টমেন্ট আছে'],
  'phoneUsed': ['This phone number belongs to another patient', 'এই ফোন নম্বর অন্য রোগীর'],
  'saveChanges': ['Save changes', 'পরিবর্তন সংরক্ষণ'],
  'editAppt': ['Edit appointment', 'অ্যাপয়েন্টমেন্ট সম্পাদনা'],
  'nextSerial': ['Serial number', 'সিরিয়াল নম্বর'],
  'clear': ['Clear', 'মুছুন'],
  'language': ['বাংলা / English', 'English / বাংলা'],
  'error': ['Error', 'ত্রুটি'],
  'cancel': ['Cancel', 'বাতিল'],
  'ok': ['OK', 'ঠিক আছে'],
  'dateRange': ['Date range', 'তারিখের সীমা'],
};

String t(String k) => (_t[k] ?? [k, k])[bn.value ? 1 : 0];
String ymd(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
void snack(BuildContext c, String m) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

String enDigits(String s) {
  const b = '০১২৩৪৫৬৭৮৯';
  var o = s;
  for (var i = 0; i < 10; i++) {
    o = o.replaceAll(b[i], '$i');
  }
  return o;
}

String? normalizePhone(String v) {
  var s = enDigits(v).replaceAll(RegExp(r'[\s\-]'), '');
  if (s.startsWith('+88')) {
    s = s.substring(3);
  } else if (s.startsWith('88') && s.length == 13) {
    s = s.substring(2);
  }
  return RegExp(r'^01[3-9]\d{8}$').hasMatch(s) ? s : null;
}

class VoiceResult {
  String name = '', age = '', phone = '';
}

/// Extracts name / age / phone from a spoken sentence (Bangla or English).
VoiceResult parseVoice(String raw) {
  final r = VoiceResult();
  var s = enDigits(raw).toLowerCase();
  // 1) age by keyword
  final ageKw = RegExp(r'(?:বয়স|age)\s*:?\s*(\d{1,3})|(\d{1,3})\s*(?:বছর|years?|yrs?)');
  final m = ageKw.firstMatch(s);
  if (m != null) {
    r.age = (m.group(1) ?? m.group(2))!;
    s = s.replaceRange(m.start, m.end, ' ');
  }
  // 2) phone: join digit groups spoken separately
  s = s.replaceAllMapped(RegExp(r'(?<=\d)[\s\-]+(?=\d)'), (_) => '');
  final pm = RegExp(r'(?:\+?88)?01[3-9]\d{8}').firstMatch(s);
  if (pm != null) {
    r.phone = normalizePhone(pm.group(0)!) ?? '';
    s = s.replaceRange(pm.start, pm.end, ' ');
  }
  // 3) fallback age: a lone small number
  if (r.age.isEmpty) {
    for (final n in RegExp(r'(?<=^|\s)\d{1,3}(?=\s|$)').allMatches(s)) {
      final v = int.parse(n.group(0)!);
      if (v >= 1 && v <= 120) {
        r.age = '$v';
        s = s.replaceRange(n.start, n.end, ' ');
        break;
      }
    }
  }
  // 4) name = what remains minus keywords
  final kw = RegExp(
      r'(?<=^|\s)(?:নাম|আমার|বয়স|ফোন|মোবাইল|নম্বর|নাম্বার|বছর|হলো|হল|name|my|is|age|phone|mobile|number|years?|old)(?=\s|$)');
  s = s.replaceAll(kw, ' ').replaceAll(RegExp(r'[\d:,.\-+]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  r.name = s.split(' ').where((w) => w.isNotEmpty).map((w) => RegExp(r'^[a-z]').hasMatch(w) ? w[0].toUpperCase() + w.substring(1) : w).join(' ');
  return r;
}
