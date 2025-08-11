import 'package:flutter/material.dart';
import '../models/reg_data.dart';
import '../services/stay_service.dart';
import '../services/validation_service.dart';
import '../services/menu_settings_service.dart';
import '../services/printer_service.dart';
import '../services/db_helper.dart';

/// Unified registration dialog for both ID card and manual registration
/// This dialog implements the unified logic requirements from the specification
class UnifiedRegistrationDialog extends StatefulWidget {
  final RegData regData;
  final bool isEditMode;
  final StayRecord? existingStay;
  final RegAdditionalInfo? existingAdditionalInfo;
  final Function(RegAdditionalInfo) onCompleted;

  const UnifiedRegistrationDialog({
    super.key,
    required this.regData,
    required this.isEditMode,
    this.existingStay,
    this.existingAdditionalInfo,
    required this.onCompleted,
  });

  @override
  State<UnifiedRegistrationDialog> createState() =>
      _UnifiedRegistrationDialogState();
}

class _UnifiedRegistrationDialogState extends State<UnifiedRegistrationDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _phoneController = TextEditingController();

  // Equipment counts
  int _shirtCount = 1;
  int _pantsCount = 1;
  int _matCount = 1;
  int _pillowCount = 1;
  int _blanketCount = 1;
  bool _withChildren = false;
  int _childrenCount = 1;

  // Dates
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Initialize form data based on mode (create/edit)
  void _initializeData() {
    // Always load phone from regData
    _phoneController.text = widget.regData.phone;

    if (widget.isEditMode && widget.existingStay != null) {
      // Edit mode - load existing data
      _startDate = widget.existingStay!.startDate;
      _endDate = widget.existingStay!.endDate;
      _notesController.text = widget.existingStay!.note ?? '';

      // Load equipment info if available
      if (widget.existingAdditionalInfo != null) {
        final info = widget.existingAdditionalInfo!;
        _shirtCount = info.shirtCount ?? 1;
        _pantsCount = info.pantsCount ?? 1;
        _matCount = info.matCount ?? 1;
        _pillowCount = info.pillowCount ?? 1;
        _blanketCount = info.blanketCount ?? 1;
        _withChildren = info.withChildren;
        _childrenCount = info.childrenCount ?? 1;
        _locationController.text = info.location ?? '';
      }
    } else {
      // Create mode - set defaults
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, now.day);
      _endDate = _startDate!.add(const Duration(days: 7));
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  /// Select date with date picker
  Future<void> _selectDate(bool isStartDate) async {
    final currentDate = isStartDate ? _startDate : _endDate;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = selectedDate;
          // Auto-adjust end date if needed
          if (_endDate != null && _endDate!.isBefore(selectedDate)) {
            _endDate = selectedDate.add(const Duration(days: 1));
          }
        } else {
          if (selectedDate.isBefore(_startDate!)) {
            _showErrorDialog('วันสิ้นสุดต้องอยู่หลังวันเริ่มต้น');
            return;
          }
          _endDate = selectedDate;
        }
      });
    }
  }

  /// Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ข้อผิดพลาด'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  /// Show success message
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  /// Save registration data using unified services
  Future<void> _saveRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      _showErrorDialog('กรุณาเลือกวันที่เริ่มต้นและสิ้นสุด');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Validate using unified validation service
      final validationError =
          await ValidationService.validateRegistrationUpdate(
            visitorId: widget.regData.id,
            newStart: _startDate!,
            newEnd: _endDate!,
            isEditMode: widget.isEditMode,
          );

      if (validationError != null) {
        _showErrorDialog(validationError);
        return;
      }

      // Update phone if changed (only if not locked by ID card)
      final updatedPhone = _phoneController.text.trim();
      if (updatedPhone != widget.regData.phone && !widget.regData.hasIdCard) {
        final updatedRegData = widget.regData.copyWithEditable(
          phone: updatedPhone,
        );
        await DbHelper().update(updatedRegData);
      }

      // Create additional info data
      final additionalInfo = RegAdditionalInfo.create(
        regId: widget.regData.id,
        visitId: '', // Will be set by the service
        shirtCount: _shirtCount,
        pantsCount: _pantsCount,
        matCount: _matCount,
        pillowCount: _pillowCount,
        blanketCount: _blanketCount,
        location: _locationController.text.trim(),
        withChildren: _withChildren,
        childrenCount: _withChildren ? _childrenCount : 0,
      );

      StayRecord resultStay;

      if (widget.isEditMode && widget.existingStay != null) {
        // Update existing stay using unified service
        final visitId =
            '${widget.regData.id}_${widget.existingStay!.createdAt.millisecondsSinceEpoch}';

        await StayService.updateStayAndAdditionalInfo(
          stayId: widget.existingStay!.id!,
          visitorId: widget.regData.id,
          newStart: _startDate!,
          newEnd: _endDate!,
          visitId: visitId,
          additionalInfo: additionalInfo.copyWith(visitId: visitId),
          note: _notesController.text.trim(),
        );

        resultStay = widget.existingStay!.copyWith(
          startDate: _startDate,
          endDate: _endDate,
          note: _notesController.text.trim(),
        );
      } else {
        // Create new stay using unified service
        resultStay = await StayService.createStayAndAdditionalInfo(
          visitorId: widget.regData.id,
          startDate: _startDate!,
          endDate: _endDate!,
          additionalInfo: additionalInfo,
          note: _notesController.text.trim(),
        );
      }

      // Print receipt if white robe menu is enabled
      final isWhiteRobeEnabled = await MenuSettingsService().isWhiteRobeEnabled;
      if (isWhiteRobeEnabled) {
        final regData = await DbHelper().fetchById(widget.regData.id);
        if (regData != null) {
          // Create final visitId for printing
          final printVisitId =
              '${widget.regData.id}_${resultStay.createdAt.millisecondsSinceEpoch}';
          final finalAdditionalInfo = additionalInfo.copyWith(
            visitId: printVisitId,
          );

          await PrinterService().printReceipt(
            regData,
            additionalInfo: finalAdditionalInfo,
            stayRecord: resultStay,
          );
        }
      }

      // Show success and close dialog
      _showSuccessMessage(
        widget.isEditMode
            ? 'อัปเดตข้อมูลเรียบร้อยแล้ว'
            : 'ลงทะเบียนเรียบร้อยแล้ว',
      );

      // Create final additional info for callback
      final callbackVisitId =
          '${widget.regData.id}_${resultStay.createdAt.millisecondsSinceEpoch}';
      final callbackAdditionalInfo = additionalInfo.copyWith(
        visitId: callbackVisitId,
      );

      widget.onCompleted(callbackAdditionalInfo);
    } catch (e) {
      _showErrorDialog('เกิดข้อผิดพลาด: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Build counter row for equipment
  Widget _buildCounterRow(String label, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  value.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: value < 10 ? () => onChanged(value + 1) : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    widget.regData.hasIdCard ? Icons.credit_card : Icons.person,
                    color: widget.regData.hasIdCard
                        ? Colors.blue
                        : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.isEditMode
                          ? 'แก้ไขข้อมูลการเข้าพัก'
                          : 'ลงทะเบียนเข้าพัก',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // User info card
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ข้อมูลผู้ลงทะเบียน',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'ชื่อ-นามสกุล: ${widget.regData.first} ${widget.regData.last}',
                                    ),
                                    Text('เลขบัตร: ${widget.regData.id}'),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _phoneController,
                                      decoration: const InputDecoration(
                                        labelText: 'เบอร์โทรศัพท์',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.phone),
                                      ),
                                      keyboardType: TextInputType.phone,
                                      enabled: !widget.regData.hasIdCard,
                                      validator:
                                          ValidationService.validatePhone,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Text('สถานะบัตร: '),
                                        Chip(
                                          label: Text(
                                            widget.regData.hasIdCard
                                                ? 'มีบัตรประชาชน'
                                                : 'ไม่มีบัตร',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          backgroundColor:
                                              widget.regData.hasIdCard
                                              ? Colors.green.shade100
                                              : Colors.orange.shade100,
                                        ),
                                      ],
                                    ),
                                    if (widget.regData.hasIdCard)
                                      const Text(
                                        '* ข้อมูลถูกล็อคจากบัตรประชาชน',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Date selection
                            Text(
                              'ระยะเวลาการพัก',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectDate(true),
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'วันเข้าพัก',
                                        border: OutlineInputBorder(),
                                        suffixIcon: Icon(Icons.calendar_today),
                                      ),
                                      child: Text(
                                        _startDate != null
                                            ? _formatDate(_startDate!)
                                            : 'เลือกวันที่',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectDate(false),
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'วันออก',
                                        border: OutlineInputBorder(),
                                        suffixIcon: Icon(Icons.calendar_today),
                                      ),
                                      child: Text(
                                        _endDate != null
                                            ? _formatDate(_endDate!)
                                            : 'เลือกวันที่',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Equipment sections
                            Text(
                              'เสื้อผ้าชุดขาว',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    _buildCounterRow('เสื้อขาว', _shirtCount, (
                                      value,
                                    ) {
                                      setState(() => _shirtCount = value);
                                    }),
                                    _buildCounterRow('กางเกงขาว', _pantsCount, (
                                      value,
                                    ) {
                                      setState(() => _pantsCount = value);
                                    }),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            Text(
                              'อุปกรณ์การนอน',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    _buildCounterRow('เสื่อ', _matCount, (
                                      value,
                                    ) {
                                      setState(() => _matCount = value);
                                    }),
                                    _buildCounterRow('หมอน', _pillowCount, (
                                      value,
                                    ) {
                                      setState(() => _pillowCount = value);
                                    }),
                                    _buildCounterRow('ผ้าห่ม', _blanketCount, (
                                      value,
                                    ) {
                                      setState(() => _blanketCount = value);
                                    }),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Additional information
                            Text(
                              'ข้อมูลเพิ่มเติม',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),

                            TextFormField(
                              controller: _locationController,
                              decoration: const InputDecoration(
                                labelText: 'ห้อง/ศาลา/สถานที่พัก',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),

                            CheckboxListTile(
                              title: const Text('มาพร้อมเด็ก'),
                              value: _withChildren,
                              onChanged: (value) {
                                setState(() {
                                  _withChildren = value ?? false;
                                  if (!_withChildren) _childrenCount = 1;
                                });
                              },
                            ),

                            if (_withChildren) ...[
                              const SizedBox(height: 8),
                              _buildCounterRow('จำนวนเด็ก', _childrenCount, (
                                value,
                              ) {
                                setState(() => _childrenCount = value);
                              }),
                            ],

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'หมายเหตุ',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),

                            const SizedBox(height: 20),

                            // Save button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _saveRegistration,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: Text(
                                widget.isEditMode
                                    ? 'อัปเดตข้อมูล'
                                    : 'ยืนยันการลงทะเบียน',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
