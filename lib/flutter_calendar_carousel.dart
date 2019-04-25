library flutter_calendar_dooboo;

import 'package:date_util/date_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' show DateFormat;

typedef DateTileBuilder = Widget Function(
    DateTime date, bool isThisMonthDay, bool isSelected, bool isMainPage);
typedef MarkedDateIconBuilder<T> = Widget Function(T event);

class CalendarCarousel<T> extends StatefulWidget {
  static final TextStyle defaultHeaderTextStyle = TextStyle(
    fontSize: 16.0,
    color: Colors.black,
  );
  static final TextStyle defaultOutedDaysTextStyle = TextStyle(
    color: Colors.grey,
    fontSize: 12.0,
  );
  static final TextStyle defaultDaysTextStyle = TextStyle(
    color: Colors.black,
    fontSize: 12.0,
  );
  static final TextStyle defaultTodayTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 12.0,
  );
  static final TextStyle defaultWeekDayTextStyle = TextStyle(
    color: Colors.black38,
    fontSize: 10.0,
  );
  static final TextStyle defaultSelectedDayTextStyle = TextStyle(
    color: Colors.black,
    fontSize: 12.0,
  );
  static final TextStyle defaultWeekendTextStyle = TextStyle(
    color: Colors.pinkAccent,
    fontSize: 12.0,
  );
  static final Color defaultSelectedDayBgColor = Color(0xFFEF5E5E);

  // text style
  final TextStyle daysTextStyle;
  final TextStyle todayTextStyle;
  final TextStyle selectedDayTextStyle;
  final TextStyle outedDaysTextStyle;
  final TextStyle weekendTextStyle;
  final TextStyle inactiveDaysTextStyle;
  final TextStyle headerTextStyle;
  final TextStyle weekDayTextStyle;

  // specific settings
  final String locale;
  final DateTime minSelectedDate;
  final DateTime maxSelectedDate;
  final bool showWeekDays;
  final bool showHeader;
  final bool showHeaderButton;
  final bool headerTitleTouchable;
  final ScrollPhysics customGridViewPhysics;
  final bool scrollable;
  final bool canSelectOutOfMonthDay;
  final bool canSelectMultiple;

  // color
  final Color selectedDayBorderColor;
  final Color selectedDayBgColor;
  final Color headerArrowIconColor;
  final Color todayCircleColor;
  final Color dateCircularBorderColor;
  final Color selectedDayWholeBgColor;

  // size
  final double dayPadding;
  final double height;
  final double width;
  final EdgeInsets headerMargin;
  final double childAspectRatio;
  final EdgeInsets weekDayMargin;

  // callback
  final void Function(DateTime, List<DateTime>) onDayPressed;
  final Function(DateTime) onCalendarChanged;
  final Function onHeaderTitlePressed;

  // builder
  final DateTileBuilder dateTileBuilder;

  final WeekdayFormat weekDayFormat;
  final bool staticSixWeekFormat;
  final List<DateTime> multiSelectedDate;

  CalendarCarousel({
    this.customGridViewPhysics,
    TextStyle todayTextStyle,
    TextStyle daysTextStyle,
    TextStyle outedDaysTextStyle,
    TextStyle selectedDayTextStyle,
    TextStyle headerTextStyle,
    TextStyle weekendTextStyle,
    TextStyle weekDayTextStyle,
    this.dateCircularBorderColor = Colors.transparent,
    this.todayCircleColor = Colors.blueAccent,
    this.selectedDayWholeBgColor,
    this.selectedDayBgColor = const Color(0xFFF7B5B5),
    this.dayPadding = 2.0,
    this.height = double.infinity,
    this.width = double.infinity,
    this.selectedDayBorderColor = const Color(0xFFEF5E5E),
    this.onDayPressed,
    this.headerMargin = const EdgeInsets.symmetric(vertical: 0.0),
    this.childAspectRatio = 1.0,
    this.weekDayMargin = const EdgeInsets.symmetric(vertical: 4.0),
    this.showWeekDays = true,
    this.showHeader = true,
    this.showHeaderButton = true,
    this.onCalendarChanged,
    this.locale = "en",
    this.minSelectedDate,
    this.maxSelectedDate,
    this.inactiveDaysTextStyle,
    this.headerTitleTouchable = false,
    this.onHeaderTitlePressed,
    this.weekDayFormat = WeekdayFormat.short,
    this.staticSixWeekFormat = false,
    this.dateTileBuilder,
    this.scrollable = true,
    this.canSelectOutOfMonthDay = true,
    multiSelectedDate,
    this.canSelectMultiple = true,
    this.headerArrowIconColor = Colors.black45,
  })  : this.multiSelectedDate = multiSelectedDate ?? [],
        this.daysTextStyle = daysTextStyle ?? defaultDaysTextStyle,
        this.todayTextStyle = todayTextStyle ?? defaultTodayTextStyle,
        this.outedDaysTextStyle =
            outedDaysTextStyle ?? defaultOutedDaysTextStyle,
        this.selectedDayTextStyle =
            selectedDayTextStyle ?? defaultSelectedDayTextStyle,
        this.headerTextStyle = headerTextStyle ?? defaultHeaderTextStyle,
        this.weekendTextStyle = weekendTextStyle ?? defaultWeekendTextStyle,
        this.weekDayTextStyle = weekDayTextStyle ?? defaultWeekDayTextStyle;

  @override
  _CalendarState<T> createState() => _CalendarState<T>();
}

enum WeekdayFormat {
  weekdays,
  standalone,
  short,
  standaloneShort,
  narrow,
  standaloneNarrow,
}

class _CalendarState<T> extends State<CalendarCarousel<T>> {
  PageController _controller;
  List<DateTime> _dates = List(3);

  DateFormat _localeDate;
  List<DateTime> _multiSelectedDate = [];

  int _currentPage = 1;
  bool _shouldChange = true;

  int firstDayOfWeek = 0;

  @override
  initState() {
    super.initState();
    initializeDateFormatting();

    _controller = PageController(
      initialPage: 1,
      keepPage: true,
    );

    _controller.addListener(() {
      if (_shouldChange) {
        final viewPort = _controller.position.viewportDimension.toInt();
        final offset = _controller.offset.toInt();
        if (offset % viewPort == 0) {
          _shouldChange = false;
          final next = offset ~/ viewPort;
          _currentPage = next;
          _setPage(next, null);
        }
      }
    });

    _localeDate = DateFormat.yMMM(widget.locale);
    firstDayOfWeek = (_localeDate.dateSymbols.FIRSTDAYOFWEEK + 1) % 7;

    if (widget.multiSelectedDate != null) {
      _multiSelectedDate = widget.multiSelectedDate;
    }
    _setPage(
        -1,
        _multiSelectedDate != null && _multiSelectedDate.isNotEmpty
            ? _multiSelectedDate.first
            : DateTime.now());
  }

  @override
  didUpdateWidget(Widget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.multiSelectedDate != null) {
      setState(() {
        _multiSelectedDate = widget.multiSelectedDate;
      });
    }
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget headerText = Text(
      '${_localeDate.format(_dates[1])}',
      style: widget.headerTextStyle,
    );
    return Container(
      color: Colors.white,
      width: widget.width,
      height: widget.height,
      child: Column(
        children: <Widget>[
          widget.showHeader
              ? Container(
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: Color(0xFFEEEEEE)),
                          top: BorderSide(color: Color(0xFFEEEEEE)))),
                  margin: EdgeInsets.only(
                    top: widget.headerMargin.top,
                    bottom: widget.headerMargin.bottom,
                  ),
                  child: Container(
                    child: DefaultTextStyle(
                        style: widget.headerTextStyle,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              FlatButton(
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding: EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 10),
                                onPressed: () => _setPage(0, null),
                                child: Container(
                                  child: widget.showHeaderButton
                                      ? Icon(
                                          CupertinoIcons.left_chevron,
                                          color: widget.headerArrowIconColor,
                                          size: 15,
                                        )
                                      : Container(),
                                  padding: EdgeInsets.symmetric(horizontal: 30),
                                ),
                              ),
                              headerText,
                              FlatButton(
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding: EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 10),
                                onPressed: () => _setPage(2, null),
                                child: Container(
                                  child: widget.showHeaderButton
                                      ? Icon(
                                          CupertinoIcons.right_chevron,
                                          color: widget.headerArrowIconColor,
                                          size: 15,
                                        )
                                      : Container(),
                                  padding: EdgeInsets.symmetric(horizontal: 30),
                                ),
                              ),
                            ])),
                  ),
                )
              : Container(),
          Container(
            decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
            child: !widget.showWeekDays
                ? Container()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: _renderWeekDays(),
                  ),
          ),
          Expanded(
              child: PageView.builder(
            itemCount: 3,
            physics: widget.scrollable
                ? ScrollPhysics()
                : NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              if (_currentPage != index) {
                _shouldChange = true;
              }
            },
            controller: _controller,
            itemBuilder: (context, index) {
              return builder(index);
            },
          )),
        ],
      ),
    );
  }

  Widget builder(int slideIndex) {
    final date = _dates[slideIndex];

    final dates = List<DateTime>(3);

    dates[0] = DateTime(date.year, date.month - 1, 1);
    dates[1] = DateTime(date.year, date.month, 1);
    dates[2] = DateTime(date.year, date.month + 1, 1);

    final _startWeekday = dates[1].weekday - firstDayOfWeek;
    final _endWeekday = dates[2].weekday - firstDayOfWeek;

    double screenWidth = MediaQuery.of(context).size.width;
    int totalItemCount = widget.staticSixWeekFormat
        ? 42
        : DateTime(
              _dates[slideIndex].year,
              _dates[slideIndex].month + 1,
              0,
            ).day +
            _startWeekday +
            (7 - _endWeekday);
    int year = _dates[slideIndex].year;
    int month = _dates[slideIndex].month;

    return Stack(
      children: <Widget>[
        Positioned(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: GridView.count(
              physics: widget.customGridViewPhysics,
              crossAxisCount: 7,
              childAspectRatio: widget.childAspectRatio,
              padding: EdgeInsets.all(2),
              children: List.generate(totalItemCount, (index) {
                bool isToday =
                    DateTime.now().day == index + 1 - _startWeekday &&
                        DateTime.now().month == month &&
                        DateTime.now().year == year;
                bool isSelectedDay = false;
                if (_multiSelectedDate != null) {
                  final days = _multiSelectedDate;
                  final day = index + 1 - _startWeekday;
                  final dayNum = DateUtil().daysInMonth(month, year);
                  if (day <= 0) {
                    final prevMonthDay = DateTime(year, month, 1)
                        .subtract(Duration(days: -1 * (day - 1)));
                    isSelectedDay = days
                        .where((_day) =>
                            _day.year == prevMonthDay.year &&
                            _day.month == prevMonthDay.month &&
                            _day.day == prevMonthDay.day)
                        .isNotEmpty;
                  } else if (day > dayNum) {
                    final prevMonthDay = DateTime(year, month, dayNum)
                        .subtract(Duration(days: -(day - dayNum)));
                    isSelectedDay = days
                        .where((_day) =>
                            _day.year == prevMonthDay.year &&
                            _day.month == prevMonthDay.month &&
                            _day.day == prevMonthDay.day)
                        .isNotEmpty;
                  } else {
                    isSelectedDay = days
                        .where((_day) =>
                            _day.year == year &&
                            _day.month == month &&
                            _day.day == day)
                        .isNotEmpty;
                  }
                }
                bool isPrevMonthDay = index < _startWeekday;
                bool isNextMonthDay =
                    index >= (DateTime(year, month + 1, 0).day) + _startWeekday;
                bool isWeekend = index % 7 == 0 || index % 7 == 6;

                DateTime now = DateTime(year, month, 1);

                var textStyle = widget.daysTextStyle;

                if (isToday) {
                  textStyle = widget.todayTextStyle;
                } else if (isSelectedDay) {
                  textStyle = widget.selectedDayTextStyle;
                } else if (isPrevMonthDay || isNextMonthDay) {
                  textStyle = widget.outedDaysTextStyle;
                } else if (isWeekend) {
                  textStyle = widget.weekendTextStyle;
                }

                if (isPrevMonthDay) {
                  now = now.subtract(Duration(days: _startWeekday - index));
                } else if (isNextMonthDay) {
                  now = DateTime(year, month, index + 1 - _startWeekday);
                } else {
                  now = DateTime(year, month, index + 1 - _startWeekday);
                }

                bool isSelectable = true;
                if (widget.minSelectedDate != null &&
                    now.millisecondsSinceEpoch <
                        widget.minSelectedDate.millisecondsSinceEpoch) {
                  isSelectable = false;
                } else if (widget.maxSelectedDate != null &&
                    now.millisecondsSinceEpoch >
                        widget.maxSelectedDate.millisecondsSinceEpoch) {
                  isSelectable = false;
                } else if (!widget.canSelectOutOfMonthDay &&
                    (isPrevMonthDay || isNextMonthDay)) {
                  isSelectable = false;
                }

                var header = now.day.toString().length == 1
                    ? ' ${now.day} '
                    : '${now.day}';

                return GestureDetector(
                  onTap: () => isSelectable ? _onDayPressed(now) : {},
                  child: Container(
                    padding: EdgeInsets.all(widget.dayPadding),
                    decoration: BoxDecoration(
                        color: isSelectedDay &&
                                widget.selectedDayWholeBgColor != null
                            ? widget.selectedDayWholeBgColor
                            : Colors.white,
                        border: Border(
                            bottom: BorderSide(color: Color(0xFFEEEEEE)))),
                    child: Container(
                      decoration: BoxDecoration(
                          color: isSelectedDay &&
                                  widget.selectedDayWholeBgColor == null
                              ? widget.selectedDayBgColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                              color: isSelectedDay &&
                                      widget.selectedDayWholeBgColor == null
                                  ? widget.selectedDayBorderColor
                                  : Colors.transparent)),
                      padding: EdgeInsets.all(widget.dayPadding),
                      child: Column(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: isSelectedDay
                                  ? null
                                  : Border.all(
                                      width: 0.3,
                                      color: widget.dateCircularBorderColor),
                              color: isToday
                                  ? widget.todayCircleColor
                                  : Colors.transparent,
                            ),
                            child: Text(
                              header,
                              style: textStyle,
                              maxLines: 1,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              alignment: Alignment.center,
                              child: SingleChildScrollView(
                                child: widget.dateTileBuilder == null
                                    ? Container()
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          widget.dateTileBuilder(
                                              now,
                                              !isPrevMonthDay &&
                                                  !isNextMonthDay,
                                              isSelectedDay,
                                              slideIndex == 1),
                                        ],
                                      ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  void _onDayPressed(DateTime picked) {
    final dates = _multiSelectedDate;
    final canSelectMultiple = widget.canSelectMultiple;

    if (widget.onDayPressed != null) {
      widget.onDayPressed(picked, dates);
    }

    if (canSelectMultiple) {
      setState(() {
        if (dates.indexOf(picked) > -1) {
          dates.remove(picked);
        } else {
          dates.add(picked);
        }
        _multiSelectedDate = dates;
      });
    } else {
      setState(() {
        dates
          ..clear()
          ..add(picked);
        _multiSelectedDate = dates;
      });
    }
  }

  void _setPage(int page, DateTime date) {
    if (page == -1) {
      DateTime date0 = DateTime(date.year, date.month - 1, 1);
      DateTime date1 = DateTime(date.year, date.month, 1);
      DateTime date2 = DateTime(date.year, date.month + 1, 1);

      setState(() {
        this._dates = [
          date0,
          date1,
          date2,
        ];
      });
    } else if (page == 1) {
      return;
    } else if (page == 0 || page == 2) {
      final dates = this._dates;
      final newDates = List<DateTime>(3);
      if (page == 0) {
        newDates[2] = DateTime(dates[0].year, dates[0].month + 1, 1);
        newDates[1] = DateTime(dates[0].year, dates[0].month + 1, 1);
        newDates[0] = DateTime(dates[0].year, dates[0].month - 1, 1);
      } else if (page == 2) {
        newDates[0] = DateTime(dates[2].year, dates[2].month - 1, 1);
        newDates[1] = DateTime(dates[2].year, dates[2].month - 1, 1);
        newDates[2] = DateTime(dates[2].year, dates[2].month + 1, 1);
      }

      setState(() {
        this._dates = newDates;
      });

      _controller.jumpToPage(1);

      //call callback
      if (widget.onCalendarChanged != null) {
        widget.onCalendarChanged(dates[page]);
      }

      if (page == 0) {
        newDates[2] = DateTime(dates[0].year, dates[0].month + 1, 1);
        newDates[1] = DateTime(dates[0].year, dates[0].month, 1);
        newDates[0] = DateTime(dates[0].year, dates[0].month - 1, 1);
      } else if (page == 2) {
        newDates[0] = DateTime(dates[2].year, dates[2].month - 1, 1);
        newDates[1] = DateTime(dates[2].year, dates[2].month, 1);
        newDates[2] = DateTime(dates[2].year, dates[2].month + 1, 1);
      }

      setState(() {
        this._dates = newDates;
      });
    }
    return;
  }

  List<Widget> _renderWeekDays() {
    List<Widget> list = [];

    for (var i = firstDayOfWeek, count = 0;
        count < 7;
        i = (i + 1) % 7, count++) {
      String weekDay;

      switch (widget.weekDayFormat) {
        case WeekdayFormat.weekdays:
          weekDay = _localeDate.dateSymbols.WEEKDAYS[i];
          break;
        case WeekdayFormat.standalone:
          weekDay = _localeDate.dateSymbols.STANDALONEWEEKDAYS[i];
          break;
        case WeekdayFormat.short:
          weekDay = _localeDate.dateSymbols.SHORTWEEKDAYS[i];
          break;
        case WeekdayFormat.standaloneShort:
          weekDay = _localeDate.dateSymbols.STANDALONESHORTWEEKDAYS[i];
          break;
        case WeekdayFormat.narrow:
          weekDay = _localeDate.dateSymbols.NARROWWEEKDAYS[i];
          break;
        case WeekdayFormat.standaloneNarrow:
          weekDay = _localeDate.dateSymbols.STANDALONENARROWWEEKDAYS[i];
          break;
        default:
          weekDay = _localeDate.dateSymbols.STANDALONEWEEKDAYS[i];
          break;
      }

      list.add(
        Expanded(
            child: Container(
          margin: widget.weekDayMargin,
          child: Center(
            child: Text(
              weekDay,
              style: widget.weekDayTextStyle,
            ),
          ),
        )),
      );
    }
    return list;
  }
}
