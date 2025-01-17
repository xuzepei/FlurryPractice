import 'package:dio/dio.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:panda_union/common/button.dart';
import 'package:panda_union/common/dialog.dart';
import 'package:panda_union/main.dart';
import 'package:panda_union/util/color.dart';
import 'package:panda_union/util/route.dart';
import 'package:panda_union/util/tool.dart';
import 'package:panda_union/util/url_config.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final Dio _dio = Dio();
  var _isLoading = false;

  final _regionList = [
    ("cn", "China Mainland (CN)"),
    ("eu", "Europe (EU)"),
    ("in", "India (IN)"),
    ("en", "Other (EN)"),
  ];

  String _currentRegion = "";
  String _regionDisplayName = "";

  String getDisplayName(String region) {
    for (var item in _regionList) {
      if (item.$1 == region) {
        return item.$2;
      }
    }

    return "Select Region";
  }

  Future<void> _getRegion() async {
    String region = await Tool.getRegion();
    String displayName = getDisplayName(region);

    setState(() {
      _currentRegion = region;
      _regionDisplayName = displayName;
    });
  }

  Future<void> _saveRegion(String region) async {
    bool b = await Tool.setRegion(region);
    if (b) {
      String displayName = getDisplayName(region);
      setState(() {
        _currentRegion = region;
        _regionDisplayName = displayName;
      });
    }
  }

  Future<void> _getAPIHost() async {
    void onAPIHostSuccess() {
      debugPrint("#### getAPIHost success.");

      setState(() {
        _isLoading = false; // 关闭加载动画
      });
    }

    void onAPIHostError(String? msg) {
      debugPrint("#### getAPIHost error: $msg");

      setState(() {
        _isLoading = false; // 关闭加载动画
      });
    }

    setState(() {
      _isLoading = true; // 显示加载动画
    });

    String region = await Tool.getRegion();
    if (region.isEmpty) {
      setState(() {
        _isLoading = false; // 关闭加载动画
      });
      return;
    }

    String errorMsg = "Sorry, an unexpected error has occurred.";

    try {
      UrlConfig.instance.region = region;
      _dio.options.baseUrl = UrlConfig.instance.getBaseUrl(region);
      String urlString = "/common/services";

      Response response = await _dio.get(urlString);
      if (response.statusCode == 200) {
        debugPrint("#### getAPIHost success");
        debugPrint("#### getAPIHost: ${response.data?.runtimeType}");
        debugPrint("#### getAPIHost: ${response.data}");

        if (response.data is Map) {
          Map<String, dynamic> data = response.data;
          if (data.containsKey("success")) {
            dynamic success = data["success"];
            if (success is bool && success) {
              if (data.containsKey("data")) {
                dynamic dataDict = data["data"];
                if (dataDict is Map) {
                  Tool.setValue("${region}_$api_host_key", dataDict);
                  onAPIHostSuccess();
                  return;
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("#### getAPIHost error: $e");
    } finally {}

    onAPIHostError(errorMsg);
  }

  Future<bool> _checkAPIHost() async {
    String region = await Tool.getRegion();
    if (region.isEmpty) {
      return false;
    }

    Map<String, dynamic>? apiHost =
        await Tool.getMap("${region}_$api_host_key");
    if (apiHost == null) {
      return false;
    }

    return true;
  }

  @override
  void initState() {
    super.initState();
    _getRegion();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: null,
          ),
          body: Container(
            padding:
                const EdgeInsets.only(top: 0, left: 20, right: 20, bottom: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text("Welcome to", style: TextStyle(fontSize: 24)),
                const SizedBox(height: 8),
                const Text(appName,
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: MyColors.primaryColor)),
                const SizedBox(height: 8),
                const Text(
                    "A communication tool app designed specifically for Labs, clinics, and dentists.",
                    style: TextStyle(fontSize: 17)),
                const SizedBox(height: 26),
                const Text("Please select a business operation region first.",
                    style: TextStyle(fontSize: 16, color: MyColors.systemGray)),
                const SizedBox(height: 16),

                //下拉菜单
                DropdownSearch<(String, String)>(
                    clickProps: ClickProps(
                      borderRadius: BorderRadius.circular(10),
                      onTapUp: (TapUpDetails details) {
                        debugPrint("#### onTapUp");
                      },
                      onFocusChange: (value) {
                        debugPrint("#### onFocusChange: $value");
                      },
                    ),
                    mode: Mode.custom,
                    items: (f, cs) => _regionList,
                    compareFn: (item1, item2) {
                      // debugPrint("#### ${item1.$1}");
                      // debugPrint("#### ${item2.$1}");
                      return item1.$1 == item2.$1;
                    },
                    popupProps: PopupProps.menu(
                      showSelectedItems: true,
                      onDismissed: () {
                        debugPrint("#### onDismissed");
                      },
                      onItemsLoaded: (value) {
                        debugPrint("#### onItemsLoaded");
                      },
                      menuProps: MenuProps(
                          align: MenuAlign.bottomCenter,
                          margin: EdgeInsets.only(top: 10)),
                      fit: FlexFit.loose,
                      itemBuilder: (context, item, isDisabled, isSelected) =>
                          Padding(
                        padding: const EdgeInsets.only(
                            left: 30, right: 10, top: 15, bottom: 15),
                        child: Text(item.$2,
                            style:
                                TextStyle(color: Colors.black, fontSize: 17)),
                      ),
                    ),
                    onChanged: (selectedItem) {
                      Future.delayed(Duration(milliseconds: 300), () {
                        _saveRegion(selectedItem?.$1 ?? "").then((_) {
                          _getAPIHost();
                        });
                      });
                    },
                    enabled: !_isLoading,
                    dropdownBuilder: (ctx, selectedItem) {
                      return Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: OutlinedButton(
                                onPressed: null,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      width: 1.0,
                                      color: Colors.black), // 设置边框宽度和颜色
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10.0), // 设置圆角
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Image.asset(
                                      "images/globe.png",
                                      width: 24,
                                    ),
                                    Text(_regionDisplayName,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 18,
                                        )),
                                    Image.asset("images/arrow_down.png",
                                        width: 30),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                const SizedBox(height: 120),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: MyButton.show(() {
                          _checkAPIHost().then((value) {
                            if (!mounted) return;
                            if (value) {
                              Navigator.pushNamed(context, loginPageRouteName);
                            } else {
                              MyDialog.show(
                                  context,
                                  "Tip",
                                  "Please select a business operation region first.",
                                  "OK");
                            }
                          });
                        }, "Login"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
        if (_isLoading)
          GestureDetector(
            onTap: () {
              debugPrint("#### block tap");
            },
            child: Container(
              color: Colors.black.withOpacity(0), // 半透明背景
              child: Center(
                //child: SpinKitCircle(color: Colors.blue, size: 50.0),
                child: CircularProgressIndicator(
                  // You can set color, stroke width, etc.
                  // valueColor: AlwaysStoppedAnimation<Color>(
                  //     Colors.blue),
                  strokeWidth: 3.0, // Thickness of the line
                ),
              ),
            ),
          ),
      ],
    );
  }
}
