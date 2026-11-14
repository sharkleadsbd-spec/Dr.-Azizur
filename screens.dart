import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'auth.dart';
import 'db.dart';
import 'util.dart';

/// Rebuilds its child whenever the language changes.
class Lang extends StatelessWidget {
  final Widget Function(BuildContext) b;
  const Lang(this.b, {super.key});
  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<bool>(valueListenable: bn, builder: (c, _, __) => b(c));
}

// ───────────────────────── Login ─────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  String role = 'doctor';
  final u = TextEditingController(), p = TextEditingController();
  String? err;
  bool busy = false, hide = true;

  Future<void> _go() async {
    setState(() { busy = true; err = null; });
    final ok = await Auth.login(role, u.text.trim(), p.text);
    if (!mounted) return;
    if (!ok) {
      setState(() { busy = false; err = t('invalidLogin'); });
      return;
    }
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => role == 'doctor' ? const DoctorHome() : const AssistantHome()));
  }

  @override
  Widget build(BuildContext context) => Lang((c) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                        onPressed: () => bn.value = !bn.value, icon: const Icon(Icons.translate), label: Text(t('language'))),
                  ),
                  const Icon(Icons.medical_services_rounded, size: 72, color: kBlue),
                  const SizedBox(height: 8),
                  Text(t('appName'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kBlue)),
                  const SizedBox(height: 24),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'doctor', icon: const Icon(Icons.medical_information), label: Text(t('doctor'))),
                      ButtonSegment(value: 'assistant', icon: const Icon(Icons.support_agent), label: Text(t('assistant'))),
                    ],
                    selected: {role},
                    onSelectionChanged: (s) => setState(() => role = s.first),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: u, decoration: InputDecoration(labelText: t('username'), prefixIcon: const Icon(Icons.person))),
                  const SizedBox(height: 12),
                  TextField(
                    controller: p,
                    obscureText: hide,
                    onSubmitted: (_) => _go(),
                    decoration: InputDecoration(
                      labelText: t('password'),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                          icon: Icon(hide ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => hide = !hide)),
                    ),
                  ),
                  if (err != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(err!, style: const TextStyle(color: Colors.red))),
                  const SizedBox(height: 16),
                  FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: kBlue, padding: const EdgeInsets.all(14)),
                      onPressed: busy ? null : _go,
                      child: busy ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(t('signIn'))),
                  const SizedBox(height: 16),
                  Text(t('demoHint'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ]),
              ),
            ),
          ),
        ),
      ));
}

// ───────────────────────── Homes ─────────────────────────
List<Widget> appActions(BuildContext c, {required bool doctor, required VoidCallback refresh}) => [
      IconButton(tooltip: t('language'), icon: const Icon(Icons.translate), onPressed: () => bn.value = !bn.value),
      PopupMenuButton<String>(
        onSelected: (v) async {
          if (v == 'backup') {
            await doBackup(c);
          } else if (v == 'restore') {
            await doRestore(c, refresh);
          } else {
            Navigator.pushAndRemoveUntil(c, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'backup', child: Text(t('backup'))),
          if (doctor) PopupMenuItem(value: 'restore', child: Text(t('restore'))),
          PopupMenuItem(value: 'logout', child: Text(t('logout'))),
        ],
      ),
    ];

Future<void> doBackup(BuildContext c) async {
  try {
    final path = await Db.I.backup();
    await Share.shareXFiles([XFile(path)], text: 'Doctor Appointment Manager backup');
    if (c.mounted) snack(c, '${t('backupDone')}: $path');
  } catch (e) {
    if (c.mounted) snack(c, '${t('error')}: $e');
  }
}

Future<void> doRestore(BuildContext c, VoidCallback refresh) async {
  final yes = await showDialog<bool>(
      context: c,
      builder: (d) => AlertDialog(content: Text(t('restoreConfirm')), actions: [
            TextButton(onPressed: () => Navigator.pop(d, false), child: Text(t('cancel'))),
            FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(t('ok'))),
          ]));
  if (yes != true) return;
  try {
    final r = await FilePicker.platform.pickFiles(type: FileType.any);
    final path = r?.files.single.path;
    if (path == null) return;
    await Db.I.restore(File(path));
    refresh();
    if (c.mounted) snack(c, t('restoreDone'));
  } catch (e) {
    if (c.mounted) snack(c, '${t('error')}: $e');
  }
}

class DoctorHome extends StatefulWidget {
  const DoctorHome({super.key});
  @override
  State<DoctorHome> createState() => _DoctorHomeState();
}

class _DoctorHomeState extends State<DoctorHome> {
  int tab = 0, tick = 0;
  void refresh() => setState(() => tick++);
  @override
  Widget build(BuildContext context) => Lang((c) => Scaffold(
        appBar: AppBar(title: Text('${t('doctor')} · ${tab == 0 ? t('dashboard') : t('records')}'), actions: appActions(c, doctor: true, refresh: refresh)),
        body: tab == 0 ? Dash(key: ValueKey('d$tick'), doctor: true) : Records(key: ValueKey('r$tick'), doctor: true),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) => setState(() => tab = i),
          destinations: [
            NavigationDestination(icon: const Icon(Icons.dashboard_outlined), selectedIcon: const Icon(Icons.dashboard), label: t('dashboard')),
            NavigationDestination(icon: const Icon(Icons.folder_open), selectedIcon: const Icon(Icons.folder), label: t('records')),
          ],
        ),
      ));
}

class AssistantHome extends StatefulWidget {
  const AssistantHome({super.key});
  @override
  State<AssistantHome> createState() => _AssistantHomeState();
}

class _AssistantHomeState extends State<AssistantHome> {
  int tab = 0, tick = 0;
  void refresh() => setState(() => tick++);
  @override
  Widget build(BuildContext context) {
    return Lang((c) {
      final titles = [t('dashboard'), t('newAppt'), t('records')];
      final pages = <Widget>[
        Dash(key: ValueKey('d$tick'), doctor: false),
        AppointmentForm(key: ValueKey('f$tick'), onDone: () => setState(() { tab = 0; tick++; })),
        Records(key: ValueKey('r$tick'), doctor: false),
      ];
      return Scaffold(
        appBar: AppBar(title: Text('${t('assistant')} · ${titles[tab]}'), actions: appActions(c, doctor: false, refresh: refresh)),
        body: pages[tab],
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) => setState(() { tab = i; if (i != 1) tick++; }),
          destinations: [
            NavigationDestination(icon: const Icon(Icons.dashboard_outlined), selectedIcon: const Icon(Icons.dashboard), label: t('dashboard')),
            NavigationDestination(icon: const Icon(Icons.person_add_alt), selectedIcon: const Icon(Icons.person_add), label: t('newAppt')),
            NavigationDestination(icon: const Icon(Icons.list_alt), selectedIcon: const Icon(Icons.list_alt), label: t('records')),
          ],
        ),
      );
    });
  }
}

// ───────────────────────── Shared widgets ─────────────────────────
Color statusColor(String s) => s == 'Completed' ? Colors.green : (s == 'Cancelled' ? Colors.red : kBlue);

class StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  const StatCard(this.label, this.value, this.color, this.icon, {super.key});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text('$value', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          ]),
        ),
      );
}

class ApptTile extends StatelessWidget {
  final Appt a;
  final bool showDate;
  final VoidCallback onTap;
  const ApptTile(this.a, {super.key, this.showDate = false, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          onTap: onTap,
          isThreeLine: true,
          leading: CircleAvatar(
              backgroundColor: kBlue, foregroundColor: Colors.white,
              child: Text(a.serialLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${a.age} ${t('yrs')} • ${a.phone}\n${showDate ? '${a.date} • ' : ''}${t(a.type == 'New' ? 'newPatient' : 'oldPatient')}'),
          trailing: Chip(
            label: Text(t(a.status), style: TextStyle(color: statusColor(a.status), fontSize: 11)),
            side: BorderSide(color: statusColor(a.status)),
            backgroundColor: Colors.white,
            visualDensity: VisualDensity.compact,
          ),
        ),
      );
}

Future<void> showHistory(BuildContext c, Appt a) => showModalBottomSheet(
      context: c,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(c).size.height * 0.7),
          child: FutureBuilder<List<Appt>>(
            future: Db.I.history(a.patientId),
            builder: (ctx, snap) {
              if (!snap.hasData) return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
              return ListView(shrinkWrap: true, padding: const EdgeInsets.all(16), children: [
                Text(a.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${a.age} ${t('yrs')} • ${a.phone}'),
                const Divider(),
                Text(t('history'), style: const TextStyle(fontWeight: FontWeight.w600, color: kBlue)),
                for (final h in snap.data!)
                  ListTile(
                    dense: true,
                    leading: Text(h.serialLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                    title: Text('${h.date} • ${t(h.type == 'New' ? 'newPatient' : 'oldPatient')}'),
                    subtitle: h.notes.isEmpty ? null : Text(h.notes),
                    trailing: Text(t(h.status), style: TextStyle(color: statusColor(h.status))),
                  ),
              ]);
            },
          ),
        ),
      ),
    );

Future<void> openEdit(BuildContext c, Appt a) => Navigator.push(
    c,
    MaterialPageRoute(
        builder: (rc) => Lang((x) => Scaffold(
            appBar: AppBar(title: Text(t('editAppt'))),
            body: AppointmentForm(edit: a, onDone: () => Navigator.pop(rc))))));

Future<void> onTapAppt(BuildContext c, Appt a, bool doctor, Future<void> Function() reload) async {
  if (doctor) return showHistory(c, a);
  await showModalBottomSheet(
    context: c,
    builder: (sc) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(title: Text('${a.serialLabel} · ${a.name}', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(a.phone)),
        ListTile(
            leading: const Icon(Icons.edit, color: kBlue),
            title: Text(t('editInfo')),
            onTap: () async { Navigator.pop(sc); await openEdit(c, a); await reload(); }),
        for (final s in ['Confirmed', 'Completed', 'Cancelled'])
          if (s != a.status)
            ListTile(
                leading: Icon(s == 'Confirmed' ? Icons.check_circle : (s == 'Completed' ? Icons.task_alt : Icons.cancel), color: statusColor(s)),
                title: Text(t(s)),
                onTap: () async { Navigator.pop(sc); await Db.I.setStatus(a.id, s); await reload(); }),
      ]),
    ),
  );
}

// ───────────────────────── Dashboard ─────────────────────────
class Dash extends StatefulWidget {
  final bool doctor;
  const Dash({super.key, required this.doctor});
  @override
  State<Dash> createState() => _DashState();
}

class _DashState extends State<Dash> {
  Map<String, int> s = {};
  List<Appt> list = [];
  bool loading = true;

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    final d = ymd(DateTime.now());
    final st = await Db.I.stats(d);
    final l = await Db.I.query(date: d);
    if (!mounted) return;
    setState(() { s = st; list = l; loading = false; });
  }

  Widget row(String p, String title) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 8, bottom: 2), child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: kBlue))),
        Row(children: [
          Expanded(child: StatCard(t('totalAppts'), s['${p}Total'] ?? 0, kBlue, Icons.event_note)),
          Expanded(child: StatCard(t('newPatients'), s['${p}New'] ?? 0, Colors.teal, Icons.fiber_new)),
          Expanded(child: StatCard(t('oldPatients'), s['${p}Old'] ?? 0, Colors.indigo, Icons.history)),
        ]),
      ]);

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        row('t', '${t('today')} • ${ymd(DateTime.now())}'),
        if (widget.doctor) row('a', t('allTime')),
        const SizedBox(height: 12),
        Text(t('totalAppts'), style: const TextStyle(fontWeight: FontWeight.w600, color: kBlue)),
        if (list.isEmpty) Padding(padding: const EdgeInsets.all(32), child: Center(child: Text(t('noRecords')))),
        for (final a in list) ApptTile(a, onTap: () => onTapAppt(context, a, widget.doctor, load)),
      ]),
    );
  }
}

// ───────────────────────── Records (search / filter / history) ─────────────────────────
class Records extends StatefulWidget {
  final bool doctor;
  const Records({super.key, required this.doctor});
  @override
  State<Records> createState() => _RecordsState();
}

class _RecordsState extends State<Records> {
  final q = TextEditingController();
  String? type, status;
  DateTimeRange? range;
  List<Appt> list = [];
  bool loading = true;

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    final l = await Db.I.query(
      search: enDigits(q.text.trim()),
      type: type,
      status: status,
      from: range == null ? null : ymd(range!.start),
      to: range == null ? null : ymd(range!.end),
    );
    if (!mounted) return;
    setState(() { list = l; loading = false; });
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: q,
            onChanged: (_) => load(),
            decoration: InputDecoration(
                hintText: t('search'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: q.text.isEmpty ? null : IconButton(icon: const Icon(Icons.clear), onPressed: () { q.clear(); load(); })),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            for (final o in [[null, 'all'], ['New', 'newPatient'], ['Old', 'oldPatient']])
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(label: Text(t(o[1]!)), selected: type == o[0], onSelected: (_) { type = o[0]; load(); }),
              ),
            DropdownButton<String?>(
              value: status,
              hint: Text(t('status')),
              items: [
                DropdownMenuItem<String?>(value: null, child: Text('${t('status')}: ${t('all')}')),
                for (final s in ['Confirmed', 'Completed', 'Cancelled']) DropdownMenuItem<String?>(value: s, child: Text(t(s))),
              ],
              onChanged: (v) { status = v; load(); },
            ),
            IconButton(
              tooltip: t('dateRange'),
              icon: Icon(Icons.date_range, color: range == null ? null : kBlue),
              onPressed: () async {
                final r = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 730)));
                if (r != null) { range = r; load(); }
              },
            ),
            if (range != null) TextButton(onPressed: () { range = null; load(); }, child: Text(t('clear'))),
          ]),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : list.isEmpty
                  ? Center(child: Text(t('noRecords')))
                  : ListView(padding: const EdgeInsets.all(12), children: [
                      for (final a in list) ApptTile(a, showDate: true, onTap: () => onTapAppt(context, a, widget.doctor, load)),
                    ]),
        ),
      ]);
}

// ───────────────────────── Appointment form (+ voice + confirmation) ─────────────────────────
class AppointmentForm extends StatefulWidget {
  final Appt? edit;
  final VoidCallback onDone;
  const AppointmentForm({super.key, this.edit, required this.onDone});
  @override
  State<AppointmentForm> createState() => _FormState();
}

class _FormState extends State<AppointmentForm> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController(), _age = TextEditingController(), _phone = TextEditingController(), _notes = TextEditingController();
  String _type = 'New';
  DateTime _date = DateTime.now();
  final _speech = stt.SpeechToText();
  bool _listening = false;
  String _heard = '';

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    if (e != null) {
      _name.text = e.name; _age.text = '${e.age}'; _phone.text = e.phone; _notes.text = e.notes;
      _type = e.type; _date = DateTime.parse(e.date);
    }
  }

  @override
  void dispose() { _speech.stop(); super.dispose(); }

  Future<void> _mic() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    final ok = await _speech.initialize(
      onError: (e) { if (mounted) setState(() => _listening = false); },
      onStatus: (s) { if (mounted && (s == 'done' || s == 'notListening')) setState(() => _listening = false); },
    );
    if (!ok) { if (mounted) snack(context, t('micUnavailable')); return; }
    final locales = await _speech.locales();
    String? id;
    for (final pref in ['bn_bd', 'bn_in', 'bn']) {
      for (final l in locales) {
        if (l.localeId.toLowerCase().replaceAll('-', '_').startsWith(pref)) { id = l.localeId; break; }
      }
      if (id != null) break;
    }
    if (id == null && mounted) snack(context, t('noBangla'));
    setState(() { _listening = true; _heard = ''; });
    await _speech.listen(
      localeId: id,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      onResult: (r) {
        if (!mounted) return;
        setState(() => _heard = r.recognizedWords);
        if (r.finalResult) _apply(r.recognizedWords);
      },
    );
  }

  void _apply(String text) {
    final v = parseVoice(text);
    setState(() {
      if (v.name.isNotEmpty) _name.text = v.name;
      if (v.age.isNotEmpty) _age.text = v.age;
      if (v.phone.isNotEmpty) _phone.text = v.phone;
    });
    snack(context, t('verifyVoice')); // nothing is saved until the user confirms
  }

  Future<void> _review() async {
    if (!_key.currentState!.validate()) return;
    final name = _name.text.trim();
    final age = int.parse(enDigits(_age.text.trim()));
    final phone = normalizePhone(_phone.text)!;
    final ds = ymd(_date);
    final serial = widget.edit?.serial ?? await Db.I.nextSerial(ds);
    if (!mounted) return;
    final yes = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (d) => AlertDialog(
        title: Text(t('review')),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${t('nextSerial')}: ${serial.toString().padLeft(3, '0')}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBlue)),
          const SizedBox(height: 8),
          Text('${t('patientName')}: $name'),
          Text('${t('age')}: $age'),
          Text('${t('phone')}: $phone'),
          Text('${t('patientType')}: ${t(_type == 'New' ? 'newPatient' : 'oldPatient')}'),
          Text('${t('apptDate')}: $ds'),
          if (_notes.text.trim().isNotEmpty) Text('${t('notes')}: ${_notes.text.trim()}'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: Text(t('editInfo'))),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: kBlue), onPressed: () => Navigator.pop(d, true), child: Text(t('confirmAppt'))),
        ],
      ),
    );
    if (yes != true) return;
    try {
      if (widget.edit == null) {
        final a = await Db.I.createAppointment(name: name, age: age, phone: phone, type: _type, date: ds, notes: _notes.text.trim());
        if (mounted) snack(context, '${t('saved')} ${a.serialLabel}');
      } else {
        await Db.I.updateAppointment(widget.edit!, name: name, age: age, phone: phone, type: _type, notes: _notes.text.trim());
        if (mounted) snack(context, t('updated'));
      }
      widget.onDone();
    } catch (e) {
      final m = e.toString().contains('duplicate') ? t('duplicate') : e.toString().contains('phoneUsed') ? t('phoneUsed') : '${t('error')}: $e';
      if (mounted) snack(context, m);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.edit != null;
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (!editing)
        Card(
          color: const Color(0xFFE3F0FF),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: _listening ? Colors.red : kBlue, minimumSize: const Size(56, 56)),
                icon: Icon(_listening ? Icons.stop : Icons.mic, color: Colors.white),
                onPressed: _mic,
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_listening ? t('listening') : t('speak'), style: const TextStyle(fontWeight: FontWeight.w600)),
                if (_heard.isNotEmpty) Text('${t('heard')}: $_heard', style: const TextStyle(fontSize: 12)),
              ])),
            ]),
          ),
        ),
      const SizedBox(height: 8),
      Form(
        key: _key,
        child: Column(children: [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: t('patientName'), prefixIcon: const Icon(Icons.person)),
            validator: (v) => (v == null || v.trim().length < 2) ? t('invalidName') : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _age,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: t('age'), prefixIcon: const Icon(Icons.cake)),
            validator: (v) {
              final n = int.tryParse(enDigits((v ?? '').trim()));
              return (n == null || n < 1 || n > 120) ? t('invalidAge') : null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: t('phone'), prefixIcon: const Icon(Icons.phone)),
            validator: (v) => normalizePhone(v ?? '') == null ? t('invalidPhone') : null,
          ),
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerLeft, child: Text(t('patientType'), style: const TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'New', icon: const Icon(Icons.fiber_new), label: Text(t('newPatient'))),
                ButtonSegment(value: 'Old', icon: const Icon(Icons.history), label: Text(t('oldPatient'))),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.black26), borderRadius: BorderRadius.circular(4)),
            leading: const Icon(Icons.calendar_month, color: kBlue),
            title: Text(t('apptDate')),
            subtitle: Text(ymd(_date)),
            enabled: !editing, // date (and serial) are fixed once issued
            onTap: () async {
              final today = DateTime.now();
              final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(today.year, today.month, today.day),
                  lastDate: today.add(const Duration(days: 365)));
              if (d != null) setState(() => _date = d);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notes,
            maxLines: 3,
            decoration: InputDecoration(labelText: t('notes'), prefixIcon: const Icon(Icons.notes)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: kBlue, padding: const EdgeInsets.all(14)),
              onPressed: _review,
              icon: const Icon(Icons.fact_check),
              label: Text(editing ? t('saveChanges') : t('review')),
            ),
          ),
        ]),
      ),
    ]);
  }
}
