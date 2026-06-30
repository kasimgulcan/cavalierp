import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
      responseDataCallback: (data) {
        if (data != null && data.isNotEmpty) {
          // ignore: avoid_print
          print('integration_test status: $data');
        }
      },
    );
