library scrollable_list_tabview;

import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'model/scrollable_list_tab.dart';

export 'model/list_tab.dart';
export 'model/scrollable_list_tab.dart';

const Duration _kScrollDuration = const Duration(milliseconds: 150);
const EdgeInsetsGeometry _kTabMargin =
    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0);

const SizedBox _kSizedBoxW8 = const SizedBox(width: 8.0);

class ScrollableListTabView extends StatefulWidget {
  /// Create a new [ScrollableListTabView]
  const ScrollableListTabView(
      {Key? key,
      required this.tabs,
      this.tabHeight = kToolbarHeight,
      this.tabAnimationDuration = _kScrollDuration,
      this.bodyAnimationDuration = _kScrollDuration,
      this.tabAnimationCurve = Curves.decelerate,
      this.bodyAnimationCurve = Curves.decelerate})
      : super(key: key);

  /// List of tabs to be rendered.
  final List<ScrollableListTab> tabs;

  /// Height of the tab at the top of the view.
  final double tabHeight;

  /// Duration of tab change animation.
  final Duration tabAnimationDuration;

  /// Duration of inner scroll view animation.
  final Duration bodyAnimationDuration;

  /// Animation curve used when animating tab change.
  final Curve tabAnimationCurve;

  /// Animation curve used when changing index of inner [ScrollView]s.
  final Curve bodyAnimationCurve;

  @override
  _ScrollableListTabViewState createState() => _ScrollableListTabViewState();
}

class _ScrollableListTabViewState extends State<ScrollableListTabView> {
  final ValueNotifier<int> _index = ValueNotifier<int>(0);

  final ItemScrollController _bodyScrollController = ItemScrollController();
  final ItemPositionsListener _bodyPositionsListener =
      ItemPositionsListener.create();
  final ItemScrollController _tabScrollController = ItemScrollController();

  @override
  void initState() {
    super.initState();
    _bodyPositionsListener.itemPositions.addListener(_onInnerViewScrolled);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: widget.tabHeight,
          color: Theme.of(context).cardColor,
          child: ScrollablePositionedList.builder(
            itemCount: widget.tabs.length,
            scrollDirection: Axis.horizontal,
            itemScrollController: _tabScrollController,
            padding: EdgeInsets.symmetric(vertical: 2.5),
            itemBuilder: (context, index) {
              var tab = widget.tabs[index].tab;
              return ValueListenableBuilder<int>(
                valueListenable: _index,
                builder: (_, i, __) {
                  var selected = index == i;
                  return Container(
                    height: 32,
                    margin: _kTabMargin,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 2,
                          color: selected
                              ? tab.activeBackgroundColor
                              : tab.inactiveBackgroundColor,
                        ),
                      ),
                    ),
                    child: OutlinedButton(
                      style: ButtonStyle(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: MaterialStateProperty.all(BorderSide(
                          color: Colors.transparent,
                        )),
                        elevation: MaterialStateProperty.all(0),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: tab.borderRadius,
                          ),
                        ),
                      ),
                      child: _buildTab(index),
                      onPressed: () => _onTabPressed(index),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Expanded(
          child: ScrollablePositionedList.builder(
            itemScrollController: _bodyScrollController,
            itemPositionsListener: _bodyPositionsListener,
            itemCount: widget.tabs.length,
            itemBuilder: (_, index) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: _kTabMargin.add(const EdgeInsets.all(5.0)),
                  child: _buildInnerTab(index),
                ),
                widget.tabs[index].body
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInnerTab(int index) {
    var tab = widget.tabs[index].tab;
    var textStyle = Theme.of(context).textTheme.bodyText1!.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 24,
          color: Color(0xFF0B0A0A),
        );
    return Builder(
      builder: (_) {
        if (!tab.showIconOnList)
          return DefaultTextStyle(
            style: textStyle,
            child: tab.label ?? SizedBox.shrink(),
          );
        return DefaultTextStyle(
          style: Theme.of(context).textTheme.bodyText1!.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 24,
              ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              tab.icon ?? SizedBox.shrink(),
              _kSizedBoxW8,
              tab.label ?? SizedBox.shrink(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab(int index) {
    var tab = widget.tabs[index].tab;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        tab.icon ?? SizedBox.shrink(),
        _kSizedBoxW8,
        DefaultTextStyle(
          style: TextStyle(
            fontSize: 16,
            // fontFamily: sourceSansPro,
            color: Colors.black,
          ),
          child: tab.label ?? SizedBox.shrink(),
        ),
      ],
    );
  }

  void _onInnerViewScrolled() async {
    var positions = _bodyPositionsListener.itemPositions.value;

    /// Target [ScrollView] is not attached to any views and/or has no listeners.
    if (positions.isEmpty) return;

    /// Capture the index of the first [ItemPosition]. If the saved index is same
    /// with the current one do nothing and return.
    var firstIndex =
        _bodyPositionsListener.itemPositions.value.elementAt(0).index;
    if (_index.value == firstIndex) return;

    /// A new index has been detected.
    await _handleTabScroll(firstIndex);
  }

  Future<void> _handleTabScroll(int index) async {
    _index.value = index;
    await _tabScrollController.scrollTo(
        index: _index.value,
        duration: widget.tabAnimationDuration,
        curve: widget.tabAnimationCurve);
  }

  /// When a new tab has been pressed both [_tabScrollController] and
  /// [_bodyScrollController] should notify their views.
  void _onTabPressed(int index) async {
    await _tabScrollController.scrollTo(
        index: index,
        duration: widget.tabAnimationDuration,
        curve: widget.tabAnimationCurve);
    await _bodyScrollController.scrollTo(
        index: index,
        duration: widget.bodyAnimationDuration,
        curve: widget.bodyAnimationCurve);
    _index.value = index;
  }

  @override
  void dispose() {
    _bodyPositionsListener.itemPositions.removeListener(_onInnerViewScrolled);
    return super.dispose();
  }
}
