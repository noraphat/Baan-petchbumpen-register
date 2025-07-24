import 'package:flutter/material.dart';
import '../models/reg_data.dart';
import '../services/db_helper.dart';
import '../services/address_service.dart';

class VisitorEditScreen extends StatefulWidget {
  final RegData visitor;

  const VisitorEditScreen({super.key, required this.visitor});

  @override
  State<VisitorEditScreen> createState() => _VisitorEditScreenState();
}

class _VisitorEditScreenState extends State<VisitorEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final AddressService _addressService = AddressService();
  
  // Form controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late TextEditingController _additionalAddressController;
  
  // Address dropdown values
  Province? _selectedProvince;
  District? _selectedDistrict;
  SubDistrict? _selectedSubDistrict;
  String _selectedGender = 'ชาย';
  
  bool _isLoading = false;
  bool _isAddressLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadAddressData();
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController(text: widget.visitor.first);
    _lastNameController = TextEditingController(text: widget.visitor.last);
    _phoneController = TextEditingController(text: widget.visitor.phone);
    _dobController = TextEditingController(text: widget.visitor.dob);
    _selectedGender = widget.visitor.gender;
  }

  Future<void> _loadAddressData() async {
    await _addressService.init();
    
    // Parse existing address
    final addressInfo = AddressInfo.fromFullAddress(widget.visitor.addr, _addressService);
    
    setState(() {
      if (addressInfo.provinceId != null) {
        _selectedProvince = _addressService.provinces
            .firstWhere((p) => p.id == addressInfo.provinceId, orElse: () => _addressService.provinces.first);
      }
      
      if (addressInfo.districtId != null && _selectedProvince != null) {
        _selectedDistrict = _addressService.districtsOf(_selectedProvince!.id)
            .firstWhere((d) => d.id == addressInfo.districtId, orElse: () => _addressService.districtsOf(_selectedProvince!.id).first);
      }
      
      if (addressInfo.subDistrictId != null && _selectedDistrict != null) {
        _selectedSubDistrict = _addressService.subsOf(_selectedDistrict!.id)
            .firstWhere((s) => s.id == addressInfo.subDistrictId, orElse: () => _addressService.subsOf(_selectedDistrict!.id).first);
      }
      
      _additionalAddressController = TextEditingController(text: addressInfo.additionalAddress ?? '');
      _isAddressLoaded = true;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _additionalAddressController.dispose();
    super.dispose();
  }

  void _onProvinceChanged(Province? province) {
    setState(() {
      _selectedProvince = province;
      _selectedDistrict = null;
      _selectedSubDistrict = null;
    });
  }

  void _onDistrictChanged(District? district) {
    setState(() {
      _selectedDistrict = district;
      _selectedSubDistrict = null;
    });
  }

  void _onSubDistrictChanged(SubDistrict? subDistrict) {
    setState(() {
      _selectedSubDistrict = subDistrict;
    });
  }

  String _buildFullAddress() {
    if (_selectedProvince == null || _selectedDistrict == null || _selectedSubDistrict == null) {
      return '';
    }
    
    final parts = [
      _selectedProvince!.nameTh,
      _selectedDistrict!.nameTh,
      _selectedSubDistrict!.nameTh,
    ];
    
    final additional = _additionalAddressController.text.trim();
    if (additional.isNotEmpty) {
      parts.add(additional);
    }
    
    return parts.join(', ');
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final dbHelper = DbHelper();
      
      // สร้าง RegData ที่อัปเดตแล้ว
      final updatedVisitor = widget.visitor.hasIdCard
          ? widget.visitor.copyWithEditable(
              phone: _phoneController.text.trim(),
            )
          : widget.visitor.copyWithAll(
              first: _firstNameController.text.trim(),
              last: _lastNameController.text.trim(),
              phone: _phoneController.text.trim(),
              dob: _dobController.text.trim(),
              addr: _buildFullAddress(),
              gender: _selectedGender,
            );
      
      await dbHelper.update(updatedVisitor);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลเรียบร้อยแล้ว')),
        );
        
        Navigator.pop(context, true); // ส่งค่า true กลับเพื่อบอกว่ามีการเปลี่ยนแปลง
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขข้อมูลผู้ปฏิบัติธรรม'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('บันทึก'),
          ),
        ],
      ),
      body: !_isAddressLoaded
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ข้อมูลส่วนตัว
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ข้อมูลส่วนตัว',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // ข้อมูลที่ไม่สามารถแก้ไขได้ (สำหรับคนมีบัตร)
                            if (widget.visitor.hasIdCard) ...[
                              _buildReadOnlyField('เลขบัตรประชาชน', widget.visitor.id),
                              const SizedBox(height: 16),
                              _buildReadOnlyField('ชื่อ', widget.visitor.first),
                              const SizedBox(height: 16),
                              _buildReadOnlyField('นามสกุล', widget.visitor.last),
                              const SizedBox(height: 16),
                              _buildReadOnlyField('วันเกิด', widget.visitor.dob),
                              const SizedBox(height: 16),
                              _buildReadOnlyField('เพศ', widget.visitor.gender),
                            ] else ...[
                              // ข้อมูลที่แก้ไขได้ (สำหรับคนไม่มีบัตร)
                              TextFormField(
                                controller: _firstNameController,
                                decoration: const InputDecoration(
                                  labelText: 'ชื่อ',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'กรุณากรอกชื่อ';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              TextFormField(
                                controller: _lastNameController,
                                decoration: const InputDecoration(
                                  labelText: 'นามสกุล',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'กรุณากรอกนามสกุล';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              TextFormField(
                                controller: _dobController,
                                decoration: const InputDecoration(
                                  labelText: 'วันเกิด',
                                  border: OutlineInputBorder(),
                                  hintText: 'เช่น 15 มกราคม 2530',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'กรุณากรอกวันเกิด';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              DropdownButtonFormField<String>(
                                value: _selectedGender,
                                decoration: const InputDecoration(
                                  labelText: 'เพศ',
                                  border: OutlineInputBorder(),
                                ),
                                items: ['ชาย', 'หญิง', 'อื่น ๆ']
                                    .map((gender) => DropdownMenuItem(
                                          value: gender,
                                          child: Text(gender),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() => _selectedGender = value!);
                                },
                              ),
                            ],
                            
                            const SizedBox(height: 16),
                            
                            // เบอร์โทรศัพท์ (แก้ไขได้เสมอ)
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'เบอร์โทรศัพท์',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // ที่อยู่ (แก้ไขได้สำหรับคนไม่มีบัตรเท่านั้น)
                    if (!widget.visitor.hasIdCard) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ที่อยู่',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // จังหวัด
                              DropdownButtonFormField<Province>(
                                value: _selectedProvince,
                                decoration: const InputDecoration(
                                  labelText: 'จังหวัด',
                                  border: OutlineInputBorder(),
                                ),
                                items: _addressService.provinces
                                    .map((province) => DropdownMenuItem(
                                          value: province,
                                          child: Text(province.nameTh),
                                        ))
                                    .toList(),
                                onChanged: _onProvinceChanged,
                                validator: (value) {
                                  if (value == null) {
                                    return 'กรุณาเลือกจังหวัด';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // อำเภอ
                              DropdownButtonFormField<District>(
                                value: _selectedDistrict,
                                decoration: const InputDecoration(
                                  labelText: 'อำเภอ',
                                  border: OutlineInputBorder(),
                                ),
                                items: _selectedProvince != null
                                    ? _addressService.districtsOf(_selectedProvince!.id)
                                        .map((district) => DropdownMenuItem(
                                              value: district,
                                              child: Text(district.nameTh),
                                            ))
                                        .toList()
                                    : [],
                                onChanged: _onDistrictChanged,
                                validator: (value) {
                                  if (value == null) {
                                    return 'กรุณาเลือกอำเภอ';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // ตำบล
                              DropdownButtonFormField<SubDistrict>(
                                value: _selectedSubDistrict,
                                decoration: const InputDecoration(
                                  labelText: 'ตำบล',
                                  border: OutlineInputBorder(),
                                ),
                                items: _selectedDistrict != null
                                    ? _addressService.subsOf(_selectedDistrict!.id)
                                        .map((subDistrict) => DropdownMenuItem(
                                              value: subDistrict,
                                              child: Text(subDistrict.nameTh),
                                            ))
                                        .toList()
                                    : [],
                                onChanged: _onSubDistrictChanged,
                                validator: (value) {
                                  if (value == null) {
                                    return 'กรุณาเลือกตำบล';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // ที่อยู่เพิ่มเติม
                              TextFormField(
                                controller: _additionalAddressController,
                                decoration: const InputDecoration(
                                  labelText: 'ที่อยู่เพิ่มเติม (เลขที่บ้าน, หมู่บ้าน)',
                                  border: OutlineInputBorder(),
                                  hintText: 'เช่น 123/45 หมู่บ้านสวนลิ้นจี่',
                                ),
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // แสดงที่อยู่แบบอ่านอย่างเดียวสำหรับคนมีบัตร
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ที่อยู่',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildReadOnlyField('ที่อยู่', widget.visitor.addr),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey[50],
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}