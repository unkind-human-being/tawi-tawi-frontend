import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../core/constants/integrate api services/shu/shu_api_constant.dart';
import '../../../auth/auth_provider.dart';

class SocialHealthEventsScreen extends StatefulWidget {
  const SocialHealthEventsScreen({super.key});

  @override
  State<SocialHealthEventsScreen> createState() =>
      _SocialHealthEventsScreenState();
}

class _SocialHealthEventsScreenState extends State<SocialHealthEventsScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedType;

  List<Map<String, dynamic>> _events = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Map<String, String> query = <String, String>{};

      if (_selectedType != null && _selectedType!.trim().isNotEmpty) {
        query['type'] = _selectedType!;
      }

      final Map<String, dynamic> response = await _getJson(
        ShuApiConstants.events,
        queryParameters: query,
      );

      final List<dynamic> rawEvents = _extractList(response);

      final List<Map<String, dynamic>> events = rawEvents
          .whereType<Map<String, dynamic>>()
          .map((Map<String, dynamic> item) => Map<String, dynamic>.from(item))
          .toList();

      events.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
        final DateTime aDate = _readDateTime(
          a,
          <String>['startDate', 'eventDate', 'scheduledAt', 'createdAt'],
        );
        final DateTime bDate = _readDateTime(
          b,
          <String>['startDate', 'eventDate', 'scheduledAt', 'createdAt'],
        );

        return aDate.compareTo(bDate);
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _events = events;
      });
    } on _SocialHealthEventsException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Unable to load RHU events.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _getJson(
    String url, {
    Map<String, String>? queryParameters,
  }) async {
    final String token = context.read<AuthProvider>().token ?? '';

    final Uri uri = Uri.parse(url).replace(
      queryParameters:
          queryParameters == null || queryParameters.isEmpty ? null : queryParameters,
    );

    final http.Response response = await http
        .get(
          uri,
          headers: <String, String>{
            'Accept': 'application/json',
            if (token.trim().isNotEmpty) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 30));

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _postJson(
    String url, {
    required Map<String, dynamic> body,
  }) async {
    final String token = context.read<AuthProvider>().token ?? '';

    final http.Response response = await http
        .post(
          Uri.parse(url),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (token.trim().isNotEmpty) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final String body = response.body.trim();

    Map<String, dynamic> decoded = <String, dynamic>{};

    if (body.isNotEmpty) {
      if (body.startsWith('<!DOCTYPE html') || body.startsWith('<html')) {
        throw const _SocialHealthEventsException(
          'Backend returned HTML instead of JSON. Check the Social Health gateway route.',
        );
      }

      try {
        final dynamic parsed = jsonDecode(body);

        if (parsed is Map<String, dynamic>) {
          decoded = parsed;
        }
      } catch (_) {
        throw const _SocialHealthEventsException(
          'Invalid backend response. Expected JSON from RHU API.',
        );
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final String message = _readString(decoded, <String>['message', 'error']);

    throw _SocialHealthEventsException(
      message.trim().isEmpty ? 'Request failed. Please try again.' : message,
    );
  }

  List<dynamic> _extractList(Map<String, dynamic> response) {
    final dynamic data = response['data'];

    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      final dynamic events = data['events'];
      final dynamic records = data['records'];
      final dynamic results = data['results'];
      final dynamic docs = data['docs'];
      final dynamic items = data['items'];

      if (events is List) return events;
      if (records is List) return records;
      if (results is List) return results;
      if (docs is List) return docs;
      if (items is List) return items;
    }

    final dynamic events = response['events'];

    if (events is List) {
      return events;
    }

    return <dynamic>[];
  }

  Future<void> _changeType(String? value) async {
    setState(() {
      _selectedType = value == 'all' ? null : value;
    });

    await _loadEvents();
  }

  Future<void> _openRegisterSheet(Map<String, dynamic> event) async {
    final bool? registered = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _EventRegistrationSheet(
          event: event,
          onSubmit: ({
            required String attendeeName,
            required String contactNumber,
            required String email,
            required String notes,
          }) async {
            final String eventId = _readString(event, <String>['_id', 'id']);

            if (eventId.trim().isEmpty) {
              throw const _SocialHealthEventsException('Event ID was not found.');
            }

            await _postJson(
              ShuApiConstants.eventRegistration(Uri.encodeComponent(eventId)),
              body: <String, dynamic>{
                'attendeeName': attendeeName,
                'contactNumber': contactNumber,
                'email': email,
                'notes': notes,
              },
            );
          },
        );
      },
    );

    if (registered == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event registration submitted successfully.'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );

      await _loadEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        title: const Text(
          'RHU Events',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _isLoading ? null : _loadEvents,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadEvents,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              _HeaderCard(totalEvents: _events.length),
              const SizedBox(height: 18),
              _TypeFilter(
                selectedType: _selectedType,
                onChanged: _changeType,
              ),
              const SizedBox(height: 18),
              if (_errorMessage != null)
                _ErrorCard(
                  message: _errorMessage!,
                  onRetry: _loadEvents,
                )
              else if (_isLoading)
                const _LoadingCard()
              else if (_events.isEmpty)
                const _EmptyCard()
              else
                ..._events.map((Map<String, dynamic> event) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _EventCard(
                      event: event,
                      onRegister: () {
                        _openRegisterSheet(event);
                      },
                    ),
                  );
                }),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.totalEvents,
  });

  final int totalEvents;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF0F766E),
            Color(0xFF115E59),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
            child: const Icon(
              Icons.event_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'RHU Events',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'View medical missions, vaccination schedules, seminars, and public health activities.',
                  style: TextStyle(
                    color: Color(0xFFE0F2F1),
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$totalEvents event/s loaded',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeFilter extends StatelessWidget {
  const _TypeFilter({
    required this.selectedType,
    required this.onChanged,
  });

  final String? selectedType;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedType ?? 'all',
      decoration: const InputDecoration(
        labelText: 'Event type',
        prefixIcon: Icon(Icons.filter_list_rounded),
        filled: true,
        fillColor: Colors.white,
      ),
      items: const <DropdownMenuItem<String>>[
        DropdownMenuItem<String>(
          value: 'all',
          child: Text('All event types'),
        ),
        DropdownMenuItem<String>(
          value: 'medical_mission',
          child: Text('Medical Mission'),
        ),
        DropdownMenuItem<String>(
          value: 'vaccination',
          child: Text('Vaccination'),
        ),
        DropdownMenuItem<String>(
          value: 'deworming',
          child: Text('Deworming'),
        ),
        DropdownMenuItem<String>(
          value: 'seminar',
          child: Text('Seminar'),
        ),
        DropdownMenuItem<String>(
          value: 'health_checkup',
          child: Text('Health Checkup'),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.onRegister,
  });

  final Map<String, dynamic> event;
  final VoidCallback onRegister;

  bool get _registrationRequired {
    return _readBool(event, 'registrationRequired', fallback: false);
  }

  bool get _isFull {
    return _readBool(event, 'isFull', fallback: false);
  }

  bool get _isOpen {
    final String status = _readString(event, <String>['status']).toLowerCase();

    if (status.trim().isEmpty) {
      return true;
    }

    return status == 'open' || status == 'published' || status == 'active';
  }

  @override
  Widget build(BuildContext context) {
    final List<String> requirements = _readStringList(event['requirements']);

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(
          color: Color(0xFFCCFBF1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.health_and_safety_rounded,
                    color: Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _eventTitle(event),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${_prettyEventType(_readString(event, <String>['type', 'eventType']))} • ${_prettyEnum(_readString(event, <String>['status']))}',
                        style: const TextStyle(
                          color: Color(0xFF0F766E),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _readString(event, <String>['description', 'details', 'content']),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            _InfoLine(
              icon: Icons.schedule_rounded,
              text: _formatSchedule(event),
            ),
            const SizedBox(height: 8),
            _InfoLine(
              icon: Icons.location_on_rounded,
              text: _readString(
                event,
                <String>['locationDisplay', 'location', 'venue', 'address'],
                fallback: 'Location not specified',
              ),
            ),
            const SizedBox(height: 8),
            _InfoLine(
              icon: Icons.groups_rounded,
              text: _registrationText(event),
            ),
            if (_readString(event, <String>['contactPerson', 'contactNumber'])
                .trim()
                .isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              _InfoLine(
                icon: Icons.phone_rounded,
                text:
                    '${_readString(event, <String>['contactPerson'])} ${_readString(event, <String>['contactNumber'])}'
                        .trim(),
              ),
            ],
            if (requirements.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              Text(
                'Requirements',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: requirements.map((String item) {
                  return Chip(
                    label: Text(item),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                ),
                onPressed:
                    _registrationRequired && !_isFull && _isOpen ? onRegister : null,
                icon: const Icon(Icons.how_to_reg_rounded),
                label: Text(
                  !_registrationRequired
                      ? 'No Registration Required'
                      : _isFull
                          ? 'Registration Full'
                          : !_isOpen
                              ? 'Registration Closed'
                              : 'Register for Event',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventRegistrationSheet extends StatefulWidget {
  const _EventRegistrationSheet({
    required this.event,
    required this.onSubmit,
  });

  final Map<String, dynamic> event;
  final Future<void> Function({
    required String attendeeName,
    required String contactNumber,
    required String email,
    required String notes,
  }) onSubmit;

  @override
  State<_EventRegistrationSheet> createState() =>
      _EventRegistrationSheetState();
}

class _EventRegistrationSheetState extends State<_EventRegistrationSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _attendeeNameController =
      TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _attendeeNameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final FormState? form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.onSubmit(
        attendeeName: _attendeeNameController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        email: _emailController.text.trim(),
        notes: _notesController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } on _SocialHealthEventsException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Unable to submit event registration.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.84,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (
        BuildContext context,
        ScrollController scrollController,
      ) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 30,
            ),
            children: <Widget>[
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Register for Event',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                _eventTitle(widget.event),
                style: const TextStyle(
                  color: Color(0xFF0F766E),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              if (_errorMessage != null) ...<Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFF991B1B),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _attendeeNameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Attendee name',
                        prefixIcon: Icon(Icons.person_rounded),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Attendee name is required.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contactNumberController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Contact number',
                        prefixIcon: Icon(Icons.phone_rounded),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_rounded),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes / concerns',
                        prefixIcon: Icon(Icons.notes_rounded),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Submit Registration',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          icon,
          color: const Color(0xFF6B7280),
          size: 17,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text.trim().isEmpty ? 'N/A' : text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFDC2626),
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to load events',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          children: <Widget>[
            Icon(
              Icons.event_busy_rounded,
              color: Color(0xFF0F766E),
              size: 54,
            ),
            SizedBox(height: 16),
            Text(
              'No public events',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'RHU events and public health activities will appear here once published.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(22),
        child: Row(
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(
              child: Text('Loading public events...'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialHealthEventsException implements Exception {
  const _SocialHealthEventsException(this.message);

  final String message;
}

String _eventTitle(Map<String, dynamic> event) {
  return _fallback(
    _readString(event, <String>['title', 'name'], fallback: 'RHU Event'),
  );
}

String _registrationText(Map<String, dynamic> event) {
  final bool registrationRequired = _readBool(
    event,
    'registrationRequired',
    fallback: false,
  );

  final bool isFull = _readBool(event, 'isFull', fallback: false);

  if (!registrationRequired) {
    return 'No registration required';
  }

  if (isFull) {
    return 'Registration full';
  }

  final String remainingSlots = _readString(
    event,
    <String>['remainingSlots', 'availableSlots'],
  );

  if (remainingSlots.trim().isNotEmpty) {
    return '$remainingSlots slot/s remaining';
  }

  return 'Registration required';
}

String _formatSchedule(Map<String, dynamic> event) {
  final DateTime start = _readDateTime(
    event,
    <String>['startDate', 'eventDate', 'scheduledAt'],
  );

  final DateTime end = _readDateTime(
    event,
    <String>['endDate', 'scheduledEndAt'],
  );

  if (start.year <= 1971 && end.year <= 1971) {
    return 'Schedule not specified';
  }

  if (start.year > 1971 && end.year <= 1971) {
    return _formatDateTime(start);
  }

  if (start.year <= 1971 && end.year > 1971) {
    return _formatDateTime(end);
  }

  return '${_formatDateTime(start)} - ${_formatTime(end)}';
}

String _prettyEventType(String value) {
  switch (value) {
    case 'medical_mission':
      return 'Medical Mission';
    case 'vaccination':
      return 'Vaccination';
    case 'deworming':
      return 'Deworming';
    case 'seminar':
      return 'Seminar';
    case 'health_checkup':
      return 'Health Checkup';
    default:
      return _prettyEnum(value);
  }
}

String _prettyEnum(String value) {
  if (value.trim().isEmpty) {
    return 'N/A';
  }

  return value
      .split('_')
      .where((String item) => item.trim().isNotEmpty)
      .map((String item) {
    return item[0].toUpperCase() + item.substring(1);
  }).join(' ');
}

String _fallback(String value) {
  if (value.trim().isEmpty || value.trim() == 'null') {
    return 'N/A';
  }

  return value.trim();
}

bool _readBool(
  Map<String, dynamic> json,
  String key, {
  required bool fallback,
}) {
  final dynamic value = json[key];

  if (value is bool) {
    return value;
  }

  if (value is String) {
    return value.toLowerCase() == 'true';
  }

  return fallback;
}

List<String> _readStringList(dynamic value) {
  if (value is List) {
    return value
        .map((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty && item != 'null')
        .toList();
  }

  if (value is String && value.trim().isNotEmpty) {
    return value
        .split(',')
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList();
  }

  return <String>[];
}

DateTime _readDateTime(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final String key in keys) {
    final dynamic value = json[key];

    if (value == null) {
      continue;
    }

    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      continue;
    }
  }

  return DateTime.fromMillisecondsSinceEpoch(0);
}

String _formatDateTime(DateTime dateTime) {
  if (dateTime.year <= 1971) {
    return 'N/A';
  }

  final String year = dateTime.year.toString().padLeft(4, '0');
  final String month = dateTime.month.toString().padLeft(2, '0');
  final String day = dateTime.day.toString().padLeft(2, '0');

  final int hour12 = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final String minute = dateTime.minute.toString().padLeft(2, '0');
  final String period = dateTime.hour >= 12 ? 'PM' : 'AM';

  return '$year-$month-$day $hour12:$minute $period';
}

String _formatTime(DateTime dateTime) {
  final int hour12 = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final String minute = dateTime.minute.toString().padLeft(2, '0');
  final String period = dateTime.hour >= 12 ? 'PM' : 'AM';

  return '$hour12:$minute $period';
}

String _readString(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  for (final String key in keys) {
    final dynamic value = json[key];

    if (value == null) {
      continue;
    }

    if (value is Map<String, dynamic>) {
      final String nestedValue = _readString(
        value,
        <String>['name', 'title', 'fullName', 'email', '_id', 'id'],
      );

      if (nestedValue.trim().isNotEmpty) {
        return nestedValue;
      }
    }

    final String text = value.toString().trim();

    if (text.isNotEmpty && text != 'null') {
      return text;
    }
  }

  return fallback;
}