import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// عنوان API الذي تم تعريضه
const String apiUrl = 'https://5000-io7me4b1a0mdlga88ef9f-06499cd0.manusvm.computer/predict';

void main() {
  runApp(const CervicalCancerApp());
}

class CervicalCancerApp extends StatelessWidget {
  const CervicalCancerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تنبؤ سرطان عنق الرحم',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const PredictionScreen(),
    );
  }
}

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _featureDescriptions = {
    'Age': 'العمر (سنة)',
    'Number of sexual partners': 'عدد الشركاء الجنسيين',
    'First sexual intercourse': 'سن أول علاقة جنسية (سنة)',
    'Num of pregnancies': 'عدد الحمل',
    'Smokes': 'هل تدخن؟ (0=لا، 1=نعم)',
    'Smokes (years)': 'سنوات التدخين',
    'Smokes (packs/year)': 'عدد علب السجائر في السنة',
    'Hormonal Contraceptives': 'استخدام موانع الحمل الهرمونية (0=لا، 1=نعم)',
    'Hormonal Contraceptives (years)': 'سنوات استخدام موانع الحمل الهرمونية',
    'IUD': 'استخدام اللولب (0=لا، 1=نعم)',
    'IUD (years)': 'سنوات استخدام اللولب',
    'STDs': 'وجود أمراض معدية جنسياً (0=لا، 1=نعم)',
    'STDs (number)': 'عدد الأمراض المعدية الجنسية',
    'STDs:condylomatosis': 'الثآليل التناسلية (0=لا، 1=نعم)',
    'STDs:cervical condylomatosis': 'الثآليل على عنق الرحم (0=لا، 1=نعم)',
    'STDs:vaginal condylomatosis': 'الثآليل المهبلية (0=لا، 1=نعم)',
    'STDs:vulvo-perineal condylomatosis': 'الثآليل الخارجية (0=لا، 1=نعم)',
    'STDs:syphilis': 'الزهري (0=لا، 1=نعم)',
    'STDs:pelvic inflammatory disease': 'مرض التهاب الحوض (0=لا، 1=نعم)',
    'STDs:genital herpes': 'الهربس التناسلي (0=لا، 1=نعم)',
    'STDs:molluscum contagiosum': 'الجدري الرخوي (0=لا، 1=نعم)',
    'STDs:AIDS': 'الإيدز (0=لا، 1=نعم)',
    'STDs:HIV': 'فيروس نقص المناعة البشرية (0=لا، 1=نعم)',
    'STDs:Hepatitis B': 'التهاب الكبد B (0=لا، 1=نعم)',
    'STDs:HPV': 'فيروس الورم الحليمي البشري (0=لا، 1=نعم)',
    'STDs: Number of diagnosis': 'عدد التشخيصات',
    'STDs: Time since first diagnosis': 'الوقت منذ أول تشخيص (سنة)',
    'STDs: Time since last diagnosis': 'الوقت منذ آخر تشخيص (سنة)',
    'Dx:Cancer': 'تشخيص السرطان (0=لا، 1=نعم)',
    'Dx:CIN': 'الأورام الظهارية داخل عنق الرحم (0=لا، 1=نعم)',
    'Dx:HPV': 'تشخيص فيروس الورم الحليمي البشري (0=لا، 1=نعم)',
    'Dx': 'التشخيص العام (0=لا، 1=نعم)',
    'Hinselmann': 'اختبار Hinselmann (0=لا، 1=نعم)',
    'Schiller': 'اختبار Schiller (0=لا، 1=نعم)',
    'Cytology': 'فحص الخلايا (0=لا، 1=نعم)',
    'Biopsy': 'الخزعة (0=لا، 1=نعم)',
  };

  final List<String> _featureNames = [
    'Age',
    'Number of sexual partners',
    'First sexual intercourse',
    'Num of pregnancies',
    'Smokes',
    'Smokes (years)',
    'Smokes (packs/year)',
    'Hormonal Contraceptives',
    'Hormonal Contraceptives (years)',
    'IUD',
    'IUD (years)',
    'STDs',
    'STDs (number)',
    'STDs:condylomatosis',
    'STDs:cervical condylomatosis',
    'STDs:vaginal condylomatosis',
    'STDs:vulvo-perineal condylomatosis',
    'STDs:syphilis',
    'STDs:pelvic inflammatory disease',
    'STDs:genital herpes',
    'STDs:molluscum contagiosum',
    'STDs:AIDS',
    'STDs:HIV',
    'STDs:Hepatitis B',
    'STDs:HPV',
    'STDs: Number of diagnosis',
    'STDs: Time since first diagnosis',
    'STDs: Time since last diagnosis',
    'Dx:Cancer',
    'Dx:CIN',
    'Dx:HPV',
    'Dx',
    'Hinselmann',
    'Schiller',
    'Cytology',
    'Biopsy',
  ];

  String _predictionResult = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (var feature in _featureNames) {
      _controllers[feature] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _predictionResult = '';
    });

    try {
      final Map<String, dynamic> data = {};
      for (var feature in _featureNames) {
        data[feature] = _controllers[feature]!.text;
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success']) {
          setState(() {
            _predictionResult =
                'النتيجة: ${result['result']}\nالثقة: ${result['confidence'].toStringAsFixed(2)}%';
          });
        } else {
          setState(() {
            _predictionResult = 'خطأ في التنبؤ: ${result['error']}';
          });
        }
      } else {
        setState(() {
          _predictionResult =
              'خطأ في الاتصال بالخادم: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _predictionResult = 'حدث خطأ غير متوقع: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تنبؤ سرطان عنق الرحم'),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'يرجى إدخال البيانات التالية للتنبؤ:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ..._featureNames.map((feature) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: TextFormField(
                      controller: _controllers[feature],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _featureDescriptions[feature] ?? feature,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'هذا الحقل مطلوب';
                        }
                        if (double.tryParse(value) == null) {
                          return 'الرجاء إدخال رقم صحيح';
                        }
                        return null;
                      },
                    ),
                  );
                }).toList(),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _predict,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'تنبؤ',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
                const SizedBox(height: 30),
                if (_predictionResult.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      _predictionResult,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
