import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/attendance.dart';
import '../models/medical_record.dart';
import '../models/medication.dart';
import '../models/patient.dart';
import '../models/sync_request_dto.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/medical_record_repository.dart';
import '../repositories/medication_repository.dart';
import '../repositories/patient_repository.dart';
import '../services/api_config.dart';
import '../services/network_service.dart';
import '../services/session_service.dart';
import '../services/sync_service.dart';
import '../widgets/custom_button.dart';

// Formatador de mascara automatica de CPF (000.000.000-00)
class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 11) text = text.substring(0, 11);

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Formatador de mascara automatica de Data de Nascimento (DD/MM/YYYY)
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 8) text = text.substring(0, 8);

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(text[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Tela de formulario de cadastro local de novo atendimento de emergencia.
class AttendanceFormScreen extends StatefulWidget {
  const AttendanceFormScreen({super.key});

  @override
  State<AttendanceFormScreen> createState() => _AttendanceFormScreenState();
}

class _AttendanceFormScreenState extends State<AttendanceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Repositorios e Servicos
  final PatientRepository _patientRepository = PatientRepository();
  final MedicalRecordRepository _medicalRecordRepository = MedicalRecordRepository();
  final AttendanceRepository _attendanceRepository = AttendanceRepository();
  final MedicationRepository _medicationRepository = MedicationRepository();
  final SessionService _sessionService = SessionService();
  final SyncService _syncService = SyncService();
  final NetworkService _networkService = NetworkService();

  // Controladores do Paciente
  final TextEditingController _cpfController = TextEditingController();
  final FocusNode _cpfFocusNode = FocusNode();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  String? _selectedGender;

  // Controlador do Prontuario
  final TextEditingController _observationsController = TextEditingController();

  // Controladores do Atendimento
  String? _selectedTriage;
  final TextEditingController _glasgowController = TextEditingController(text: '15');
  final TextEditingController _bpController = TextEditingController();
  final TextEditingController _hrController = TextEditingController();
  final TextEditingController _o2Controller = TextEditingController();

  // Medicamentos
  List<Medication> _availableMedications = [];
  final List<Map<String, String>> _selectedMedications = [];
  Medication? _selectedMedicationItem;
  final TextEditingController _doseController = TextEditingController();

  bool _isSearchingPatient = false;
  bool _isPatientFound = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableMedications();

    // Quando o campo de CPF perde o foco, dispara a busca automatica pelo paciente
    _cpfFocusNode.addListener(() {
      if (!_cpfFocusNode.hasFocus) {
        _searchPatientByCpf(showNotFoundMessage: true);
      }
    });
  }

  @override
  void dispose() {
    _cpfFocusNode.dispose();
    _cpfController.dispose();
    _nameController.dispose();
    _birthDateController.dispose();
    _observationsController.dispose();
    _glasgowController.dispose();
    _bpController.dispose();
    _hrController.dispose();
    _o2Controller.dispose();
    _doseController.dispose();
    super.dispose();
  }

  // Converte data no formato DD/MM/YYYY para o formato de banco YYYY-MM-DD
  String? _convertBrDateToIso(String? brDate) {
    if (brDate == null || brDate.trim().isEmpty) return null;
    final clean = brDate.trim();
    final parts = clean.split('/');
    if (parts.length == 3 && parts[2].length == 4) {
      return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
    }
    return brDate;
  }

  // Converte data ISO8601 (YYYY-MM-DD) para o formato brasileiro DD/MM/YYYY
  String _convertIsoDateToBr(String? isoDate) {
    if (isoDate == null || isoDate.trim().isEmpty) return '';
    try {
      final parts = isoDate.split('T')[0].split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (_) {}
    return isoDate;
  }

  // Carrega o catalogo de medicamentos do SQLite local para selecao no atendimento.
  Future<void> _loadAvailableMedications() async {
    final list = await _medicationRepository.getAllMedications();
    if (!mounted) return;
    setState(() {
      _availableMedications = list;
    });
  }

  // Busca paciente por CPF no banco SQLite local.
  Future<void> _searchPatientByCpf({bool showNotFoundMessage = false}) async {
    final cleanCpf = _cpfController.text.replaceAll(RegExp(r'\D'), '');
    if (cleanCpf.length != 11) return;

    if (_isSearchingPatient) return;

    setState(() {
      _isSearchingPatient = true;
    });

    final patient = await _patientRepository.getPatientByCpf(cleanCpf);
    final record = await _medicalRecordRepository.getMedicalRecordByCpf(cleanCpf);

    if (!mounted) return;

    if (patient != null) {
      setState(() {
        _nameController.text = patient.name;
        _birthDateController.text = _convertIsoDateToBr(patient.birthDate);
        _selectedGender = patient.gender;
        _isPatientFound = true;
        if (record != null) {
          _observationsController.text = record.observations ?? '';
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paciente encontrado'),
          backgroundColor: Colors.blue,
        ),
      );
    } else {
      setState(() {
        _isPatientFound = false;
      });
      if (showNotFoundMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paciente não encontrado. Preencha os dados abaixo para cadastrá-lo.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    setState(() {
      _isSearchingPatient = false;
    });
  }

  // Adiciona um medicamento selecionado à lista do atendimento.
  void _addMedication() {
    if (_selectedMedicationItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um medicamento do catálogo.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final String doseInput = _doseController.text.trim();
    final String finalDose = doseInput.isNotEmpty
        ? doseInput
        : (_selectedMedicationItem!.concentration ?? 'Dose padrão');

    setState(() {
      _selectedMedications.add({
        'name': _selectedMedicationItem!.name,
        'dose': finalDose,
      });
      _selectedMedicationItem = null;
      _doseController.clear();
    });
  }

  // Salva o paciente, prontuario e atendimento no SQLite local e envia a API se estiver ONLINE.
  Future<void> _saveAttendance() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final String cleanCpf = _cpfController.text.replaceAll(RegExp(r'\D'), '');
    final String nowIso = DateTime.now().toIso8601String().split('.').first;
    final int activeProfId = (await _sessionService.getActiveProfessionalId()) ?? 1;

    try {
      // 1. Instancia e Salva o Paciente no SQLite Local
      final patient = Patient(
        cpf: cleanCpf,
        name: _nameController.text.trim(),
        birthDate: _convertBrDateToIso(_birthDateController.text),
        gender: _selectedGender,
      );
      await _patientRepository.savePatient(patient);

      // 2. Instancia e Salva o Prontuario Medico no SQLite Local
      final record = MedicalRecord(
        patientCpf: cleanCpf,
        openingDate: nowIso,
        observations: _observationsController.text.trim().isNotEmpty
            ? _observationsController.text.trim()
            : null,
      );
      await _medicalRecordRepository.saveMedicalRecord(record);

      // 3. Prepara a String/JSON de medicamentos ministrados
      final String? medsJson = _selectedMedications.isNotEmpty
          ? jsonEncode(_selectedMedications)
          : null;

      // 4. Instancia e Salva o Atendimento no SQLite Local (inicialmente synchronized = false)
      final attendance = Attendance(
        patientCpf: cleanCpf,
        attendanceDatetime: nowIso,
        professionalId: activeProfId,
        glasgowScale: int.tryParse(_glasgowController.text) ?? 15,
        triageClassification: _selectedTriage ?? 'VERDE',
        bloodPressure: _bpController.text.trim().isNotEmpty
            ? _bpController.text.trim()
            : null,
        heartRate: int.tryParse(_hrController.text),
        oxygenSaturation: int.tryParse(_o2Controller.text),
        administeredMedications: medsJson,
        synchronized: false,
      );
      await _attendanceRepository.saveAttendance(attendance);

      bool isSyncedNow = false;

      // 5. Se o modo ONLINE estiver ativo, tenta enviar para a API Spring Boot imediatamente
      if (_networkService.isOnline) {
        try {
          final syncDto = SyncRequestDTO(
            patient: patient,
            record: record,
            attendance: attendance,
          );

          final String syncUrl = '${ApiConfig.baseUrl}/attendances/sync';
          final Map<String, String> headers = {
            'Content-Type': 'application/json',
          };
          final String? token = await _sessionService.getAuthToken();
          if (token != null && token.isNotEmpty) {
            headers['Authorization'] = token;
          }

          final response = await http.post(
            Uri.parse(syncUrl),
            headers: headers,
            body: jsonEncode(syncDto.toJson()),
          ).timeout(const Duration(seconds: 8));

          if (response.statusCode == 200 || response.statusCode == 201) {
            await _attendanceRepository.markAsSynchronized(cleanCpf, nowIso);
            isSyncedNow = true;
          }
        } catch (_) {
          // Se houver oscilacao na rede, mantem como pendente no SQLite local sem travar o socorrista
        }
      }

      // Notifica o app para recarregar as abas reativas
      _syncService.notifyDataChanged();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSyncedNow
                ? 'Atendimento registrado e sincronizado com a nuvem!'
                : 'Atendimento registrado localmente com sucesso!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar atendimento localmente: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Novo Atendimento',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- BLOCO 1: PACIENTE ---
              _buildSectionTitle('1. Dados do Paciente'),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade300, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _cpfController,
                      focusNode: _cpfFocusNode,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        CpfInputFormatter(),
                      ],
                      onChanged: (val) {
                        final clean = val.replaceAll(RegExp(r'\D'), '');
                        if (clean.length == 11) {
                          _searchPatientByCpf(showNotFoundMessage: true);
                        } else if (_isPatientFound || _nameController.text.isNotEmpty) {
                          setState(() {
                            _isPatientFound = false;
                            _nameController.clear();
                            _birthDateController.clear();
                            _selectedGender = null;
                            _observationsController.clear();
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'CPF',
                        prefixIcon: const Icon(Icons.badge),
                        border: const OutlineInputBorder(),
                        suffixIcon: _isSearchingPatient
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : null,
                      ),
                      validator: (value) {
                        final clean = (value ?? '').replaceAll(RegExp(r'\D'), '');
                        if (clean.length != 11) {
                          return 'Informe um CPF válido com 11 dígitos.';
                        }
                        return null;
                      },
                    ),
                    if (_isPatientFound) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Paciente já cadastrado no banco local',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      readOnly: _isPatientFound,
                      decoration: InputDecoration(
                        labelText: 'Nome Completo',
                        prefixIcon: const Icon(Icons.person),
                        border: const OutlineInputBorder(),
                        fillColor: _isPatientFound ? Colors.grey.shade100 : Colors.white,
                        filled: _isPatientFound,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, informe o nome do paciente.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _birthDateController,
                      readOnly: _isPatientFound,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        DateInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Data de Nascimento',
                        hintText: 'DD/MM/AAAA',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: const OutlineInputBorder(),
                        fillColor: _isPatientFound ? Colors.grey.shade100 : Colors.white,
                        filled: _isPatientFound,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: _selectedGender,
                      hint: const Text('Selecione o gênero'),
                      decoration: InputDecoration(
                        labelText: 'Gênero',
                        prefixIcon: const Icon(Icons.wc),
                        border: const OutlineInputBorder(),
                        fillColor: _isPatientFound ? Colors.grey.shade100 : Colors.white,
                        filled: _isPatientFound,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'M', child: Text('Masculino')),
                        DropdownMenuItem(value: 'F', child: Text('Feminino')),
                        DropdownMenuItem(value: 'O', child: Text('Outro')),
                      ],
                      onChanged: _isPatientFound
                          ? null
                          : (val) {
                              setState(() {
                                _selectedGender = val;
                              });
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- BLOCO 2: PRONTUARIO ---
              _buildSectionTitle('2. Observações do Prontuário Médico'),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade300, width: 0.8),
                ),
                child: TextFormField(
                  controller: _observationsController,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText: 'Digite aqui as observações clínicas do paciente, histórico ou queixas...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- BLOCO 3: DADOS CLINICOS E SINAIS VITAIS ---
              _buildSectionTitle('3. Dados Clínicos e Sinais Vitais'),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade300, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String?>(
                      isExpanded: true,
                      initialValue: _selectedTriage,
                      hint: const Text('Selecione a classificação'),
                      decoration: const InputDecoration(
                        labelText: 'Classificação de Triagem',
                        prefixIcon: Icon(Icons.local_hospital),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Por favor, selecione a classificação de triagem.';
                        }
                        return null;
                      },
                      items: const [
                        DropdownMenuItem(
                          value: 'VERMELHO',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: Colors.red, size: 10),
                              SizedBox(width: 6),
                              Text('Emergência'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'LARANJA',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: Colors.orange, size: 10),
                              SizedBox(width: 6),
                              Text('Muito Urgente'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'AMARELO',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: Colors.amber, size: 10),
                              SizedBox(width: 6),
                              Text('Urgente'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'VERDE',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: Colors.green, size: 10),
                              SizedBox(width: 6),
                              Text('Pouco Urgente'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'AZUL',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: Colors.blue, size: 10),
                              SizedBox(width: 6),
                              Text('Não Urgente'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedTriage = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _glasgowController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Escala de Glasgow',
                        prefixIcon: Icon(Icons.psychology),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        final numVal = int.tryParse(val ?? '');
                        if (numVal == null || numVal < 3 || numVal > 15) {
                          return 'Informe um valor de 3 a 15.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bpController,
                      decoration: const InputDecoration(
                        labelText: 'Pressão Arterial (ex: 120/80 mmHg)',
                        prefixIcon: Icon(Icons.favorite),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _hrController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Frequência Cardíaca (ex: 80 bpm)',
                        prefixIcon: Icon(Icons.monitor_heart),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _o2Controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Saturação de O2 (ex: 98 %)',
                        prefixIcon: Icon(Icons.air),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- BLOCO 4: MEDICAMENTOS ADMINISTRADOS ---
              _buildSectionTitle('4. Medicamentos Administrados'),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade300, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_availableMedications.isNotEmpty)
                      DropdownButton<Medication>(
                        isExpanded: true,
                        hint: const Text('Selecione um medicamento'),
                        value: _selectedMedicationItem,
                        items: _availableMedications.map((med) {
                          return DropdownMenuItem<Medication>(
                            value: med,
                            child: Text('${med.name} (${med.concentration ?? '-'})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedMedicationItem = val;
                          });
                        },
                      )
                    else
                      const Text(
                        'Nenhum medicamento no catálogo local. (Sincronize para carregar).',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _doseController,
                      decoration: const InputDecoration(
                        labelText: 'Observação(ex: 2mL, 1 ampola)',
                        prefixIcon: Icon(Icons.local_pharmacy),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar Medicamento'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _addMedication,
                      ),
                    ),
                    if (_selectedMedications.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const Text(
                        'Medicamentos Ministrados neste Socorro:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Column(
                        children: _selectedMedications.map((m) {
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.medication, color: Colors.redAccent, size: 20),
                            title: Text(m['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Dose: ${m['dose']}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () {
                                setState(() {
                                  _selectedMedications.remove(m);
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Botao Principal de Salvar Atendimento
              CustomButton(
                text: 'SALVAR ATENDIMENTO',
                isLoading: _isSaving,
                onPressed: _saveAttendance,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Auxiliar para titulos dos blocos
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }
}
