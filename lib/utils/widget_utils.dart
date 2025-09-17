import 'package:home_widget/home_widget.dart';

Future<void> updateWidget() async {
  await HomeWidget.updateWidget(
    name: 'DeviceActionWidget',
    iOSName: 'DeviceActionWidget'
  );
}
