import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart' as intl;
import 'package:noor/exports/components.dart'
    show CardTemplate, CardText, NotificationItem, SubtitleWithIcon;
import 'package:noor/exports/constants.dart' show Images, Links, NoorIcons;
import 'package:noor/exports/controllers.dart' show ThemeModel, SettingsModel;
import 'package:noor/exports/services.dart' show SharedPrefsService;
import 'package:noor/models/data.dart';
import 'package:noor/services/fcm.dart';
import 'package:provider/provider.dart';
import 'package:share/share.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

class Settings extends StatefulWidget {
  Settings({
    Key? key,
  }) : super(key: key);

  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  var morningNotiEnabled;
  var nightNotiEnabled;
  var morningNotiTime;
  var nightNotiTime;

  @override
  get wantKeepAlive => true;

  @override
  void initState() {
    tz.initializeTimeZones();

    morningNotiEnabled = SharedPrefsService.getBool('morningNotiEnabled');
    morningNotiTime = SharedPrefsService.getString('morningNotiTime').isNotEmpty
        ? DateTime.parse(SharedPrefsService.getString('morningNotiTime'))
        : null;
    nightNotiEnabled = SharedPrefsService.getBool('nightNotiEnabled') &&
        SharedPrefsService.getString('nightNotiTime').isNotEmpty;
    nightNotiTime = SharedPrefsService.getString('nightNotiTime').isNotEmpty
        ? DateTime.parse(SharedPrefsService.getString('nightNotiTime'))
        : null;

    super.initState();
  }

  var morningTemp;
  var nightTemp;
  List<String> fonts = <String>['١٦', '١٨', '٢٠', '٢٢'];
  TextStyle activeLabelStyle = const TextStyle(
    color: Color(0xff6db7e5),
    fontSize: 18,
    height: 1,
  );
  TextStyle inactiveLabelStyle = TextStyle(
    color: Colors.grey[400],
  );

  Widget title(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        right: 20.0,
      ),
      child: Text(
        text,
        textAlign: TextAlign.start,
        style: Theme.of(context).textTheme.subtitle1,
        textScaleFactor: 1,
      ),
    );
  }

  Widget subtitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        right: 20.0,
      ),
      child: Text(
        text,
        textAlign: TextAlign.start,
        style: Theme.of(context).textTheme.bodyText1?.copyWith(
              height: 1,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
        textScaleFactor: 1,
      ),
    );
  }

  Widget switcherOption({
    required String icon,
    required String title,
    option1,
    option2,
    required Function(bool) onChanged,
    required bool value,
    String? image,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        SubtitleWithIcon(text: title, icon: icon),
        Container(
          margin: EdgeInsets.only(left: 20.0),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Switch(
              value: value,
              activeColor: Theme.of(context).primaryColor,
              onChanged: onChanged,
            ),
          ),
        )
      ],
    );
  }

  segmentedControlOption({
    required String icon,
    required String title,
    required void Function(String?) onChanged,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        SubtitleWithIcon(text: title, icon: icon),
        Flexible(
          fit: FlexFit.loose,
          child: Container(
            width: 130,
            margin: EdgeInsets.symmetric(horizontal: 30.0),
            child: CupertinoSlidingSegmentedControl<String>(
              padding: EdgeInsets.all(3),
              thumbColor: Theme.of(context).primaryColor,
              children: <String, Widget>{
                'strong': Text(
                  'قوي',
                  style: TextStyle(
                    color: value == 'strong' ? Colors.white : Colors.grey,
                    fontSize: 11,
                  ),
                ),
                'light': Text(
                  'خفيف',
                  style: TextStyle(
                    color: value == 'light' ? Colors.white : Colors.grey,
                    fontSize: 11,
                  ),
                ),
                'none': Text(
                  'إيقاف',
                  style: TextStyle(
                    color: value == 'none' ? Colors.white : Colors.grey,
                    fontSize: 11,
                  ),
                )
              },
              groupValue: value,
              onValueChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  formatTime(DateTime? dateTime) {
    return dateTime == null
        ? 'اختر وقت'
        : intl.DateFormat('h:mm a', 'ar').format(dateTime);
  }

  changeTheme(value) async {
    context.read<SettingsModel>().theme = value;
    context.read<ThemeModel>().userTheme = value;
  }

  Widget radioBtn(icon, title, value) {
    return ListTileTheme(
      contentPadding: EdgeInsets.only(right: 0, left: 20),
      dense: false,
      child: RadioListTile(
        controlAffinity: ListTileControlAffinity.trailing,
        title: SubtitleWithIcon(text: title, icon: icon),
        activeColor: Theme.of(context).primaryColor,
        groupValue: context.watch<SettingsModel>().theme,
        value: value,
        onChanged: changeTheme,
      ),
    );
  }

  void share() {
    Share.share(
        'يضمُّ تطبيق نُور العديد من الأذكار والأدعية الواردة في كتاب حصن المسلم. كما يحتوي التطبيق على أدعية من القرآن الكريم والسنة النبوية. والعديد من المميزات. \n https://play.google.com/store/apps/details?id=com.noor.sa',
        subject: 'تطبيق نُور');
  }

  void setDailyNotification(DateTime dateTime, period, id) async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        new FlutterLocalNotificationsPlugin();

    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
      '$id',
      '$period',
      'repeatDailyAtTime $dateTime',
      showWhen: true,
    );
    var platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'أذكار $period',
      '',
      tz.TZDateTime.from(dateTime, tz.local).add(Duration(days: 10000)),
      platformChannelSpecifics,
      payload: period,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
    );
  }

  void cancelNotification(id) async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        new FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  launchURL(url) async {
    await launch(url);
  }

  ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final SettingsModel settings = context.watch<SettingsModel>();
    final Images images = Provider.of<ThemeModel>(context).images;

    return Scaffold(
      body: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  title('الخط'),
                  const Divider(),
                  Card(),
                  const Divider(),
                  SubtitleWithIcon(text: 'حجم الخط', icon: NoorIcons.fontSize),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 10.0),
                      child: Stack(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List<Widget>.from(
                                <Widget>[
                                  animatedSizeText(0, 16),
                                  animatedSizeText(1, 18),
                                  animatedSizeText(2, 20),
                                  animatedSizeText(3, 22)
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor:
                                    Theme.of(context).primaryColor,
                                thumbColor: Theme.of(context).primaryColor,
                                inactiveTrackColor: Colors.grey[400],
                                trackHeight: 2,
                                inactiveTickMarkColor:
                                    Theme.of(context).primaryColor,
                                activeTickMarkColor: Colors.grey[400],
                              ),
                              child: Slider(
                                divisions: 3,
                                onChanged: (double value) =>
                                    settings.fontSize = value,
                                value: settings.fontSize,
                                min: 1,
                                max: 1.375,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  SubtitleWithIcon(text: 'نوع الخط', icon: NoorIcons.fontType),
                  Padding(
                    padding: const EdgeInsets.only(
                        right: 40.0, left: 40.0, top: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        fontTypeButton('SST Arabic'),
                        fontTypeButton('Dubai'),
                        fontTypeButton('Geeza')
                      ],
                    ),
                  ),
                  const Divider(),
                  switcherOption(
                    icon: NoorIcons.tashkeel,
                    title: 'التشكيل',
                    value: settings.tashkeel,
                    onChanged: (bool value) => settings.tashkeel = value,
                  ),
                  const Divider(),
                  VerticalSpace(),
                  title('العداد'),
                  const Divider(),
                  switcherOption(
                    icon: NoorIcons.jump,
                    title: 'الانتقال التلقائي إلى الذكر التالي',
                    value: settings.autoJump,
                    onChanged: (value) => settings.autoJump = value,
                  ),
                  const Divider(),
                  VerticalSpace(),
                  title('إظهار العداد'),
                  const Divider(),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 30.0),
                    alignment: Alignment.center,
                    child: CupertinoSlidingSegmentedControl<int>(
                      padding: EdgeInsets.all(3),
                      thumbColor: Theme.of(context).primaryColor,
                      children: <int, Widget>{
                        0: Text(
                          'للأذكار ذات تكرار أكثر من مرة',
                          style: TextStyle(
                            color: !settings.showCounter
                                ? Colors.white
                                : Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                        1: Text(
                          'لكل الأذكار',
                          style: TextStyle(
                            color: settings.showCounter
                                ? Colors.white
                                : Colors.grey,
                            fontSize: 11,
                          ),
                        )
                      },
                      groupValue: settings.showCounter ? 1 : 0,
                      onValueChanged: (dynamic value) =>
                          settings.showCounter = value == 1,
                    ),
                  ),
                  const Divider(),
                  VerticalSpace(),
                  title('الهزاز'),
                  const Divider(),
                  switcherOption(
                    icon: NoorIcons.vibrate,
                    title: 'الهزاز لعداد صفحة الأذكار',
                    value: settings.vibrate,
                    onChanged: (bool value) => settings.vibrate = value,
                  ),
                  const Divider(),
                  AnimatedCrossFade(
                    firstChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: subtitle(
                            'نوع الهزاز لصفحة الأذكار',
                          ),
                        ),
                        VerticalSpace(),
                        segmentedControlOption(
                          icon: NoorIcons.click,
                          title: 'لكل ضغطة',
                          value: settings.vibrationClick,
                          onChanged: (String? value) {
                            settings.vibrationClick = value!;
                            if (value == 'strong') {
                              HapticFeedback.lightImpact();
                            }
                            if (value == 'light') {
                              HapticFeedback.heavyImpact();
                            }
                          },
                        ),
                        VerticalSpace(),
                        segmentedControlOption(
                          icon: NoorIcons.done,
                          title: 'عند اكتمال العد',
                          value: settings.vibrationDone,
                          onChanged: (String? value) {
                            settings.vibrationDone = value!;
                            if (value == 'strong') {
                              HapticFeedback.lightImpact();
                            }
                            if (value == 'light') {
                              HapticFeedback.heavyImpact();
                            }
                          },
                        ),
                        VerticalSpace(),
                        Divider(),
                      ],
                    ),
                    secondChild: Container(),
                    crossFadeState: settings.vibrate
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    duration: Duration(milliseconds: 300),
                  ),
                  switcherOption(
                    icon: NoorIcons.vibrate,
                    title: 'الهزاز لصفحة السبحة',
                    value: settings.vibrateCounter,
                    onChanged: (bool value) => settings.vibrateCounter = value,
                  ),
                  Divider(),
                  AnimatedCrossFade(
                    firstChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: subtitle(
                            'نوع الهزاز لصفحة السبحة',
                          ),
                        ),
                        VerticalSpace(),
                        segmentedControlOption(
                            icon: NoorIcons.click,
                            title: 'لكل ضغطة',
                            value: settings.vibrationClickCounter,
                            onChanged: (String? value) {
                              settings.vibrationClickCounter = value!;
                              if (value == 'strong') {
                                HapticFeedback.lightImpact();
                              }
                              if (value == 'light') {
                                HapticFeedback.heavyImpact();
                              }
                            }),
                        VerticalSpace(),
                        segmentedControlOption(
                          icon: NoorIcons.done,
                          title: 'عند مضاعفات المئة',
                          value: settings.vibrationHunderds,
                          onChanged: (String? value) {
                            settings.vibrationHunderds = value!;
                            if (value == 'strong') {
                              HapticFeedback.lightImpact();
                            }
                            if (value == 'light') {
                              HapticFeedback.heavyImpact();
                            }
                          },
                        ),
                        VerticalSpace(),
                        Divider(),
                      ],
                    ),
                    secondChild: Container(),
                    crossFadeState: settings.vibrateCounter
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    duration: Duration(milliseconds: 300),
                  ),
                  VerticalSpace(),
                  title('التنبيهات'),
                  Divider(),
                  NotificationItem(
                    text: 'التنبيه لأذكار الصباح',
                    icon: NoorIcons.morning,
                    time: formatTime(morningNotiTime),
                    enabled: morningNotiEnabled,
                    onTap: () {
                      showModalBottomSheet(
                        isDismissible: false,
                        context: context,
                        builder: (BuildContext context) => SizedBox(
                          height: 250,
                          child: Column(
                            children: <Widget>[
                              Container(
                                height: 35,
                                color: Theme.of(context)
                                    .dialogTheme
                                    .backgroundColor,
                                child: Row(
                                  children: <Widget>[
                                    SizedBox(
                                      width: 60,
                                      child: TextButton(
                                        child: Text(
                                          'حفظ',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText1!
                                              .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .accentColor,
                                                  fontSize: 12),
                                        ),
                                        onPressed: () async {
                                          Navigator.of(context).pop();
                                          if (morningTemp != null) {
                                            setState(() {
                                              morningNotiTime = morningTemp;
                                            });

                                            SharedPrefsService.putString(
                                                'morningNotiTime',
                                                morningNotiTime.toString());

                                            setDailyNotification(
                                                morningNotiTime, 'الصباح', 0);
                                          }
                                          if (morningNotiTime == null) {
                                            setState(() {
                                              morningNotiTime = DateTime.now();
                                            });
                                            SharedPrefsService.putString(
                                                'morningNotiTime',
                                                morningNotiTime.toString());
                                            setDailyNotification(
                                                morningNotiTime, 'الصباح', 0);
                                          }
                                        },
                                      ),
                                    ),
                                    SizedBox(
                                      width: 60,
                                      child: TextButton(
                                        child: Text(
                                          'إلغاء',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText1!
                                              .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .accentColor,
                                                  fontSize: 12),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ),
                                  ],
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                ),
                              ),
                              Expanded(
                                child: Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: CupertinoTheme(
                                    data: CupertinoThemeData(
                                      textTheme: CupertinoTextThemeData(
                                        dateTimePickerTextStyle:
                                            Theme.of(context)
                                                .textTheme
                                                .bodyText1,
                                      ),
                                    ),
                                    child: CupertinoDatePicker(
                                      backgroundColor:
                                          Theme.of(context).cardColor,
                                      mode: CupertinoDatePickerMode.time,
                                      initialDateTime:
                                          morningNotiTime ?? DateTime.now(),
                                      onDateTimeChanged:
                                          (DateTime newDateTime) {
                                        setState(() {
                                          morningTemp = newDateTime;
                                        });
                                      },
                                      minuteInterval: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    onChanged: (bool value) async {
                      morningNotiEnabled = !morningNotiEnabled;
                      SharedPrefsService.putBool('morningNotiEnabled', value);
                      if (morningNotiEnabled == false) {
                        cancelNotification(0);
                      }
                      if (morningNotiEnabled == true &&
                          morningNotiTime != null) {
                        setDailyNotification(morningNotiTime, 'الصباح', 0);
                      }
                      setState(() {});
                    },
                  ),
                  Divider(),
                  NotificationItem(
                    enabled: nightNotiEnabled,
                    text: 'التنبيه لأذكار المساء',
                    icon: NoorIcons.night,
                    time: formatTime(nightNotiTime),
                    onTap: () {
                      showModalBottomSheet(
                        isDismissible: false,
                        context: context,
                        builder: (BuildContext context) => SizedBox(
                          height: 250,
                          child: Column(
                            children: <Widget>[
                              Container(
                                height: 35,
                                color: Theme.of(context)
                                    .dialogTheme
                                    .backgroundColor,
                                child: Row(
                                  children: <Widget>[
                                    SizedBox(
                                      width: 60,
                                      child: TextButton(
                                        child: Text(
                                          'حفظ',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText1!
                                              .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .accentColor,
                                                  fontSize: 12),
                                        ),
                                        onPressed: () async {
                                          Navigator.of(context).pop();
                                          if (nightTemp != null) {
                                            setState(() {
                                              nightNotiTime = nightTemp;
                                            });
                                            SharedPrefsService.putString(
                                                'nightNotiTime',
                                                nightNotiTime.toString());

                                            setDailyNotification(
                                                nightNotiTime, 'المساء', 1);
                                          }
                                          if (nightNotiTime == null) {
                                            setState(() {
                                              nightNotiTime = DateTime.now();
                                            });
                                            SharedPrefsService.putString(
                                                'nightNotiTime',
                                                nightNotiTime.toString());
                                            setDailyNotification(
                                                nightNotiTime, 'المساء', 1);
                                          }
                                        },
                                      ),
                                    ),
                                    SizedBox(
                                      width: 60,
                                      child: TextButton(
                                        child: Text(
                                          'إلغاء',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText1!
                                              .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .accentColor,
                                                  fontSize: 12),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ),
                                  ],
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                ),
                              ),
                              Expanded(
                                child: Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: CupertinoTheme(
                                    data: CupertinoThemeData(
                                      textTheme: CupertinoTextThemeData(
                                        dateTimePickerTextStyle: TextStyle(
                                          locale: Locale('ar'),
                                          fontFamily: 'SST Arabic',
                                          fontSize: 16,
                                          color: Theme.of(context)
                                              .textTheme
                                              .body1!
                                              .color,
                                        ),
                                      ),
                                    ),
                                    child: CupertinoDatePicker(
                                      backgroundColor:
                                          Theme.of(context).cardColor,
                                      mode: CupertinoDatePickerMode.time,
                                      initialDateTime:
                                          nightNotiTime ?? DateTime.now(),
                                      onDateTimeChanged:
                                          (DateTime newDateTime) {
                                        setState(() {
                                          nightTemp = newDateTime;
                                        });
                                      },
                                      minuteInterval: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    onChanged: (bool value) async {
                      nightNotiEnabled = !nightNotiEnabled;

                      SharedPrefsService.putBool('nightNotiEnabled', value);
                      if (nightNotiEnabled == false) {
                        cancelNotification(1);
                      }
                      if (nightNotiEnabled == true && nightNotiTime != null) {
                        setDailyNotification(nightNotiTime, 'المساء', 1);
                      }
                      setState(() {});
                    },
                  ),
                  Divider(),
                  NotificationItem(
                    text: 'إشعارات عامة',
                    icon: NoorIcons.notifications,
                    enabled: settings.generalNotification,
                    onChanged: (bool value) {
                      if (value) {
                        FCMService.instance.subscribe();
                      } else {
                        FCMService.instance.unsubscribe();
                      }
                    },
                  ),
                  Divider(),
                  VerticalSpace(),
                  title('المظهر'),
                  Divider(),
                  radioBtn(
                    NoorIcons.lightMode,
                    'الوضع النهاري',
                    'light_theme',
                  ),
                  Divider(),
                  radioBtn(
                    NoorIcons.darkMode,
                    'الوضع الليلي',
                    'dark_theme',
                  ),
                  Divider(),
                  radioBtn(
                    NoorIcons.systemMode,
                    'وضع النظام',
                    'system_theme',
                  ),
                  const Divider(),
                  VerticalSpace(),
                  title('المصادر'),
                  const Divider(),
                  InkWell(
                    onTap: () => launchURL(Links.allahNamesResource),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      width: MediaQuery.of(context).size.width,
                      child: SubtitleWithIcon(
                        text: 'قسم أسماء الله الحُسنى',
                        icon: NoorIcons.allahNames,
                      ),
                    ),
                  ),
                  const Divider(),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    width: MediaQuery.of(context).size.width,
                    child: SubtitleWithIcon(
                      text: 'قسم الرقية الشرعية، كُتيب أَوراد',
                      icon: NoorIcons.ruqiya,
                    ),
                  ),
                  const Divider(),
                  SizedBox(height: 10.0),
                  title('عن التطبيق'),
                  const Divider(),
                  InkWell(
                    onTap: () => launchURL(Links.appURL),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      width: MediaQuery.of(context).size.width,
                      child: SubtitleWithIcon(
                        text: 'قيِّم التطبيق',
                        icon: NoorIcons.star,
                      ),
                    ),
                  ),
                  const Divider(),
                  InkWell(
                    onTap: share,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      width: MediaQuery.of(context).size.width,
                      child: SubtitleWithIcon(
                        text: 'نشر التطبيق',
                        icon: NoorIcons.share,
                      ),
                    ),
                  ),
                  const Divider(),
                  InkWell(
                    onTap: () => launchURL(Links.contactEmailURL),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      width: MediaQuery.of(context).size.width,
                      child: SubtitleWithIcon(
                        text: 'تواصل معنا',
                        icon: NoorIcons.mail,
                      ),
                    ),
                  ),
                  const Divider(),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SubtitleWithIcon(
                          text: 'شبكات التواصل',
                          icon: NoorIcons.follow,
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => launchURL(Links.twitter),
                              child:
                                  Image.asset(images.twitterButton, width: 65),
                            ),
                            SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => launchURL(Links.ig),
                              child: Image.asset(images.igButton, width: 65),
                            ),
                            SizedBox(width: 20)
                          ],
                        )
                      ],
                    ),
                  ),
                  const Divider(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget animatedSizeText(int i, int size) {
    return AnimatedSize(
      child: Text(
        fonts[i],
        style: SharedPrefsService.getDouble('fontSize') * 16 == size
            ? activeLabelStyle
            : inactiveLabelStyle,
      ),
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
  }

  Widget fontTypeButton(String font) {
    return FlatButton(
      onPressed: () => context.read<SettingsModel>().fontType = font,
      child: AnimatedDefaultTextStyle(
        style: TextStyle(
            fontFamily: font,
            color: context.read<SettingsModel>().fontType == font
                ? Theme.of(context).primaryColor
                : Colors.grey[400],
            height: 1,
            fontSize: context.read<SettingsModel>().fontType == font ? 20 : 16),
        duration: Duration(milliseconds: 200),
        child: Text('الحمدلله'),
      ),
    );
  }
}

class VerticalSpace extends StatelessWidget {
  const VerticalSpace({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 10.0);
  }
}

class Card extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CardTemplate(
      ribbon: context.read<DataModel>().athkar[1].ribbon,
      actions: <Widget>[
        Image.asset(Images.outlineHeartIcon),
        Image.asset(Images.copyIcon),
      ],
      child: CardText(text: context.read<DataModel>().athkar[1].text),
    );
  }
}
