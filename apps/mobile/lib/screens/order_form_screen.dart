import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';
import 'package:use_cases/use_cases.dart';

import '../data/fake_data.dart';
import '../dependencies.dart';

/// Every check in this form is a call into the domain: R1 note, R2 nights, R3 period while typing. The order is sent
/// through [OrderFormBloc], and the repository decides R6 over every order.
class OrderFormScreen extends StatefulWidget {
  const OrderFormScreen({super.key, this.initialPetId});

  final PetId? initialPetId;

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nightsController = TextEditingController(text: '${StayLength.min}');
  final _noteController = TextEditingController();

  late final Clock _clock = context.read<AppDependencies>().clock;
  late final User _owner = context.read<AppDependencies>().owner;
  late final List<Pet> _pets = fakePets.where((pet) => pet.ownerId == _owner.id).toList();
  late Pet _pet = _pets.firstWhere((pet) => pet.id == widget.initialPetId, orElse: () => _pets.first);
  ServiceType _service = ServiceType.boarding;
  late DateTime _day = _firstDayWithFreeStart(_clock.now());
  DateTime? _start;

  @override
  void dispose() {
    _nightsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// How long the center needs the pet at the start: the whole visit, or one handover step for boarding.
  Duration get _startLength => _service.visitLength ?? ServicePeriod.step;

  List<DateTime> _startsOn(DateTime day) =>
      centerOpeningHours.startsOn(day, length: _startLength, step: ServicePeriod.step);

  DateTime _firstDayWithFreeStart(DateTime now) {
    final today = centerDay(now);
    for (var offset = 0; offset < 14; offset++) {
      final day = DateTime(today.year, today.month, today.day + offset);
      if (_startsOn(day).any((start) => start.isAfter(now))) return day;
    }
    return today;
  }

  int? get _nightsInput => int.tryParse(_nightsController.text);

  Result<ServicePeriod>? _period(DateTime? start) {
    if (start == null) return null;
    return ServicePeriod.parse(
      start,
      service: _service,
      now: _clock.now(),
      openingHours: centerOpeningHours,
      nights: StayLength.parse(_nightsInput ?? StayLength.min).valueOrNull ?? StayLength.shortest,
    );
  }

  String? _validateStart(DateTime? start) {
    if (start == null) return 'Izaberite vreme.';
    return _period(start)?.errorOrNull?.message;
  }

  String? _validateNights(String? value) {
    final nights = int.tryParse(value ?? '');
    if (nights == null) return 'Unesite broj noći.';
    return StayLength.parse(nights).errorOrNull?.message;
  }

  String? _validateNote(String? value) => OrderNote.parse(value ?? '').errorOrNull?.message;

  void _selectService(ServiceType service) {
    setState(() {
      _service = service;
      if (_start != null && !_startsOn(_day).contains(_start)) _start = null;
    });
  }

  Future<void> _pickDay() async {
    final today = centerDay(_clock.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: today,
      lastDate: DateTime(today.year, today.month, today.day + 90),
      selectableDayPredicate: (day) => centerOpeningHours.isOpenOn(day.weekday),
      helpText: _service == ServiceType.boarding ? 'Datum predaje' : 'Datum',
    );
    if (picked == null) return;
    setState(() {
      _day = picked;
      _start = null;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final note = OrderNote.parse(_noteController.text).valueOrNull!;
    context.read<OrderFormBloc>().add(
      OrderFormSubmitted(
        pet: _pet,
        service: _service,
        period: _period(_start)!.valueOrNull!,
        note: note.isEmpty ? null : note,
      ),
    );
  }

  /// What came back from sending: the screen shows it, the bloc has decided nothing on its own.
  void _onSent(BuildContext context, OrderFormState state) {
    switch (state) {
      case OrderFormSucceeded():
        HapticFeedback.mediumImpact();
        context.read<MyOrdersBloc>().add(const MyOrdersRefreshed());
        _showMessage('Nalog je poslat. Čeka potvrdu osoblja.');
        context.go('/orders');
      case OrderFormRejected(:final error):
        _showMessage(error.message);
      case OrderFormFailed():
        _showMessage('Nalog nije poslat. Proverite vezu i pokušajte ponovo.');
      case OrderFormEditing() || OrderFormSubmitting():
        break;
    }
  }

  /// What the chosen start means: when the visit ends, or when the pet goes home.
  String? _periodHint() {
    final period = _period(_start)?.valueOrNull;
    if (period == null) return null;
    return switch (_service.visitLength) {
      null => 'Preuzimanje: ${formatDateAndTime(period.end)}',
      final length => 'Traje ${durationLabel(length)}, do ${formatTime(period.end)}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBoarding = _service == ServiceType.boarding;
    final starts = _startsOn(_day);
    return BlocListener<OrderFormBloc, OrderFormState>(
      listener: _onSent,
      child: Scaffold(
        appBar: AppBar(title: const Text('Zakaži uslugu')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Label('Ljubimac'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final pet in _pets)
                          ChoiceChip(
                            avatar: const Icon(Icons.pets, size: 18),
                            label: Text(pet.name),
                            selected: pet == _pet,
                            onSelected: (_) => setState(() => _pet = pet),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _Label('Usluga'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final service in ServiceType.values)
                          ChoiceChip(
                            avatar: Icon(serviceIcon(service), size: 18),
                            label: Text(service.label),
                            selected: service == _service,
                            onSelected: (_) => _selectService(service),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _pickDay,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: isBoarding ? 'Datum predaje' : 'Datum',
                          suffixIcon: const Icon(Icons.calendar_month_outlined),
                        ),
                        child: Text(capitalize(formatLocalDate(_day)), style: theme.textTheme.bodyLarge),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<DateTime>(
                      // A new day or service brings a new list of starts, so the field starts over.
                      key: ValueKey((_day, _service)),
                      initialValue: _start,
                      items: [
                        for (final start in starts) DropdownMenuItem(value: start, child: Text(formatTime(start))),
                      ],
                      onChanged: (start) => setState(() => _start = start),
                      validator: _validateStart,
                      decoration: InputDecoration(
                        labelText: isBoarding ? 'Vreme predaje' : 'Vreme',
                        helperText: starts.isEmpty ? const OutsideOpeningHours().message : _periodHint(),
                      ),
                    ),
                    if (isBoarding) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nightsController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(labelText: 'Broj noći'),
                        validator: _validateNights,
                        // The pick-up time depends on the nights, so the start is checked again.
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      maxLength: OrderNote.maxLength,
                      maxLengthEnforcement: MaxLengthEnforcement.none,
                      minLines: 3,
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Napomena',
                        hintText: 'Nije obavezna. Na primer ishrana, lekovi ili navike ljubimca.',
                        alignLabelWithHint: true,
                      ),
                      validator: _validateNote,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SizedBox(
                width: double.infinity,
                child: BlocBuilder<OrderFormBloc, OrderFormState>(
                  builder: (context, state) => state is OrderFormSubmitting
                      ? const FilledButton(onPressed: null, child: Text('Slanje…'))
                      : FilledButton(onPressed: _submit, child: const Text('Pošalji nalog')),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(header: true, child: Text(text, style: Theme.of(context).textTheme.titleMedium)),
    );
  }
}
