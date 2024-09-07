import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_cupertino_fields/form_builder_cupertino_fields.dart';
import 'package:tflite_web/tflite_web.dart';

class HomeWeb extends StatefulWidget {
  const HomeWeb({super.key});

  @override
  State<HomeWeb> createState() => _HomeWebState();
}

class _HomeWebState extends State<HomeWeb> {
  TFLiteModel? _tfLieModel;
  String? _housePrice;
  bool isModelLoaded = false;
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      TFLiteWeb.initialize().then((value) async {
        // Load the TFLite model from the /web/models directory
        _tfLieModel = await TFLiteModel.fromUrl(
          '/models/house_price_model.tflite',
        );
        setState(() {
          // Set the model output to the model's name
          isModelLoaded = true;
        });
      }).catchError((e) {
        throw Exception('Failed to initialize TFLite: $e');
      });
    });
  }

  Future<void> _predictHousePrice() async {
    print(_formKey.currentState!.value);
    final houseData = _formKey.currentState!.value;

    var inputs = [
      houseData['bedrooms'] as double,
      houseData['bathrooms'] as double,
      houseData['sqft_living'] as double,
      houseData['floors'] as double,
      houseData['condition'] as double,
    ];
    var minMaxScale = _minMaxScale(inputs);
    var inputTensor =
        createTensor(minMaxScale, shape: [1, 5], type: TFLiteDataType.float32);

    // Make a prediction
    final prediction =
        await _tfLieModel!.predict<NamedTensorMap>([inputTensor]);
    // regex to extract the prediction value
    final parts = prediction
        .toString()
        .split(RegExp(r'\[\[|\],\]')); // Split by `[[` or `],]`
    if (parts.length > 1) {
      final result = parts[1].trim(); // Extract the second part
      setState(() {
        _housePrice =
            inverseLogTransform(double.parse(result)).toStringAsFixed(2);
      });
    } else {
      print('Prediction failed');
    }
    // Set the model output to the prediction
  }

  List<double> _minMaxScale(List<double> data) {
    // Min-max scaling of the features
    List<double> maxValues = [33.0, 8.0, 12050.0, 3.5, 13.0];
    List<double> minValues = [0.0, 0.0, 290.0, 1.0, 1.0];
    return List.generate(data.length, (i) {
      return (data[i] - minValues[i]) / (maxValues[i] - minValues[i]);
    });
  }

  double inverseLogTransform(double value) {
    // Inverse log transformation of the predicted value
    return exp(value) - 1;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: Center(
        child: SizedBox(
          width: 1200,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Welcome to the House Price Prediction App',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isModelLoaded)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Neural Network Model Loaded Successfully!',
                      style: TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.systemGreen,
                      ),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CupertinoActivityIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Loading Model...',
                          style: TextStyle(
                            fontSize: 16,
                            color: CupertinoColors.systemPink,
                          ),
                        ),
                      ],
                    ),
                  ),
                PredictionsForm(
                  formKey: _formKey,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoButton.filled(
                      onPressed: () {
                        if (isModelLoaded) {
                          _formKey.currentState!.save();
                          _predictHousePrice();
                        }
                      },
                      child: const Text('Predict House Price'),
                    ),
                    const SizedBox(width: 16),
                    CupertinoButton(
                      color: CupertinoColors.systemRed,
                      child: const Text("Clear"),
                      onPressed: () {
                        setState(
                          () {
                            _housePrice = null;
                          },
                        );
                      },
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AnimatedCrossFade(
                    duration: const Duration(milliseconds: 100),
                    firstChild: const Text(
                      'Click the button to predict the house price',
                    ),
                    secondChild: Column(
                      children: [
                        const Text(
                          'The predicted house price is',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "\$$_housePrice",
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.systemGreen,
                          ),
                        ),
                      ],
                    ),
                    crossFadeState: _housePrice == null
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
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

class PredictionsForm extends StatelessWidget {
  const PredictionsForm({
    Key? key,
    required this.formKey,
  }) : super(key: key);

  final GlobalKey<FormBuilderState> formKey;

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: formKey,
      child: Column(
        children: [
          //   sliders for features: 'bedrooms', 'bathrooms', 'sqft_living', 'floors', 'condition'
          FormBuilderCupertinoSlider(
            name: 'bedrooms',
            min: 0,
            max: 30,
            initialValue: 4,
            divisions: 30,
            valueWidget: (value) => Text("${value} bedrooms"),
          ),
          FormBuilderCupertinoSlider(
            name: 'bathrooms',
            min: 0,
            max: 8,
            initialValue: 3,
            divisions: 8,
            valueWidget: (value) => Text("${value} bathrooms"),
          ),
          FormBuilderCupertinoSlider(
            name: 'sqft_living',
            min: 290,
            max: 12050,
            initialValue: 5420,
            valueWidget: (value) => Text("${value} sqft"),
          ),
          FormBuilderCupertinoSlider(
            name: 'floors',
            min: 1,
            max: 5,
            initialValue: 1,
            divisions: 4,
            valueWidget: (value) => Text("${value} floors"),
          ),
          FormBuilderCupertinoSlider(
            name: 'condition',
            min: 1,
            max: 13,
            initialValue: 11,
            divisions: 12,
            valueWidget: (value) => Text("Condition: ${value}"),
          ),
        ],
      ),
    );
  }
}
