import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/offer.dart';
import '../models/city.dart';
import '../data/repository.dart';
import '../widgets/category_tile.dart';
import '../widgets/offer_tile.dart';
import '../widgets/city_picker_dialog.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Repository2 _repo = Repository2();
  static final String _baseUrl = dotenv.env['API_URL']!;
  Timer? _eventsPollTimer;
  DateTime? _lastEventTime;

  List<Category> _allCategories = [];
  List<Offer> _allOffers = [];
  List<City> _allCities = [];
  City? _selectedCity;
  String _searchText = '';
  int? _selectedCategoryId;

  static const int _pageSize = 5;
  bool _showCategories = true;
  bool _isLoadingMore = false;

  bool _isLoadingCities = true;

  bool _hasMore = true;

  Future<void> _pollEvents() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/kafka/events'));
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;

      // Преобразуем в объекты c полем EventTime
      // Исходные данные: events — это List<Map<String, dynamic>>,
      // где каждое e['EventTime'] пока строка, например "2025-06-06T16:06:12.162Z".
      final List events = data['events'] as List;

      final List<Map<String, dynamic>> newEvents = [];

      for (var e in events) {
        // 2.1. Берём строковое значение времени
        final String timeString = e['commitTime'] as String;

        // 2.2. Парсим его в Dart-объект DateTime
        final DateTime parsedTime = DateTime.parse(timeString);

        // 2.3. Заменяем в копии события строку на DateTime
        // Чтобы не портить оригинал, можно сначала скопировать сам Map:
        final Map<String, dynamic> eventCopy = Map.from(e);
        eventCopy['commitTime'] = parsedTime;

        // 2.4. Добавляем в новый список
        newEvents.add(eventCopy);
      }

      // строго позже, чем lastEventTime
      final unseen = _lastEventTime == null
          ? newEvents
          : newEvents.where((e) => e['commitTime'].isAfter(_lastEventTime!)).toList();

      if (unseen.isNotEmpty) {
        // Ищем самое позднее время среди событий
        DateTime latest = unseen[0]['commitTime'] as DateTime;
        for (int i = 1; i < unseen.length; i++) {
          DateTime thisTime = unseen[i]['commitTime'] as DateTime;
          if (thisTime.isAfter(latest)) {
            latest = thisTime;
          }
        }

        _lastEventTime = latest;

        // вызываем перезагрузку один раз
        _resetAndLoad();
      }
    } catch (e) {
      debugPrint('Error polling events: $e');
    }
  }


  @override
  void initState() {
    super.initState();
    _loadCities();
    _eventsPollTimer = Timer.periodic(Duration(seconds: 5), (_) => _pollEvents());
  }


  @override
  void dispose() {
    _eventsPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCities() async {
    /*final data = await _repo.fetchOffers(offset: 0, city: city);
    _allCategories = data['categories'];
    _allOffers = data['offers'];
    for (int i = 0; i < _allOffers.length - 1; i++){
      Category? tmp;
      tmp = _allCategories.where((o) => o.id == _allOffers[i].categoryId).firstOrNull;
      try{
        _allOffers[i].categoryName = tmp!.name;
      }catch (e, stack){
        if (e.toString().contains('Null check operator used on a null value')) {
          debugPrint("stupid"); // поменять логер или типо того
        } else {
          rethrow;
        }
      }
    }*/
    try {
      final cities = await _repo.fetchCities();
      setState(() {
        _allCities = cities;
        _isLoadingCities = false;
      });
    } catch (e) {
      debugPrint('Ошибка при загрузке городов: $e'); // поменять логер или типо того
      setState(() {
        _allCities = [City(id: 1, name: "govno")];
        _isLoadingCities = false;
      });
    }
  }

  List<Offer> get _filteredOffers {
    if (_searchText.isEmpty) return _allOffers;
    return _allOffers.where((o) {
      final txt = _searchText.toLowerCase();
      return o.title.toLowerCase().contains(txt) ||
          o.description.toLowerCase().contains(txt) ||
          o.companyName.toLowerCase().contains(txt);
    }).toList();
  }

  List<Category> get _filteredCategories {
    Iterable<Category> tmp = _allCategories;
    if (_searchText.isNotEmpty) {
      tmp = tmp.where((c) =>
          c.name.toLowerCase().contains(_searchText.toLowerCase()));
    }
    return tmp.toList();
  }


  /// При изменении фильтра (поиск или смена категории) мы сбрасываем state,
  /// но не трогаем сервер.
  void _onFilterChanged() {
    if (_selectedCategoryId == null) {
      setState(() {
        _showCategories = true;
      });
    } else {
      setState(() {
        _showCategories = false;
      });
    }
  }

  /// Сбрасывает внутренние списки и загружает первую страницу (offset(_allOffers)=0)
  void _resetAndLoad() {
    _allCategories.clear();
    _allOffers.clear();
    _hasMore = true;
    _isLoadingMore = false;
    _showCategories = true;
    _loadCategories();
    //_loadMoreFromServer();
  }

  Future<void> _loadCategories() async {
    if (_isLoadingMore || !_hasMore) return;
    if (_selectedCity == null) return;
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final data = await _repo.fetchCategories();
      final List<Category> newCats = data;

      for (var cat in newCats) {
        if (!_allCategories.any((c) => c.id == cat.id)) {
          _allCategories.add(cat);
        }
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке данных категорий: $e');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreFromServer() async {
    if (_isLoadingMore || !_hasMore) return;
    if (_selectedCity == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    final offset = _allOffers.length;
    try {
      if (_selectedCategoryId != null) {
        final data = await _repo.fetchOffers(
          offset: offset,
          city: _selectedCity!.id,
          categoryId: _selectedCategoryId!,
        );
        final List<Offer> newOffers = data;

        // Добавляем новые предложения без дублирования
        for (var off in newOffers) {
          if (!_allOffers.any((o) => o.id == off.id)) {
            _allOffers.add(off);
          }
        }

        // Если сервер вернул меньше pageSize, значит дальше ничего нет
        if (newOffers.length < _pageSize) {
          _hasMore = false;
        }
      }
    } catch (e) {
      debugPrint('Ошибка при загрузке данных: $e');
      _hasMore = false;
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _onCategoryTap(int categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _showCategories = false;
    });
    //_resetAndLoad();
  }

  Future<void> _showCityPickerDialog() async {
    if (_isLoadingCities) return;
    final chosen = await showDialog<City>(
      context: context,
      builder: (ctx) {
        return CityPickerDialog(
          allCities: _allCities,
          selectedCity: _selectedCity?.id,
        );
      },
    );
    if (chosen != null && chosen != _selectedCity) {
      _selectedCity = chosen;
      _selectedCategoryId = null;
      _searchText = '';
      _resetAndLoad();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [Color(0xcc00C9FF), Color(0xFF92FE9D)],
        ),
      ),
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          tooltip: 'Назад',
          child: Icon(Icons.arrow_back),
          onPressed: () {
            if (!_showCategories) {
              setState(() {
                _allOffers.clear();
                _hasMore = true;
                _isLoadingMore = false;
                _showCategories = true;
              });
            }
          },
        ),
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Шапка: название + кнопка города
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Партнёрские скидки',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: _showCityPickerDialog,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black87,
                        backgroundColor: Colors.transparent,
                        splashFactory: NoSplash.splashFactory,
                        minimumSize: Size.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _selectedCity?.name ?? 'Выбрать город',
                            style: TextStyle(
                                fontSize: 18,
                                color: _selectedCity == null
                                    ? Colors.orangeAccent.shade700
                                    : Colors.blue.shade700),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),

              // Поле поиска
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Поиск категорий или предложений',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    _searchText = val;
                    _onFilterChanged();
                  },
                ),
              ),

              const SizedBox(height: 8),

              // Если город не выбран
              if (_selectedCity == null)
                Expanded(
                  child: Center(
                    child: Text(
                      'Пожалуйста, выберите город, чтобы увидеть предложения.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[900]),
                    ),
                  ),
                )
              else
                Expanded(
                  child: _showCategories
                      ? _buildCategoriesGrid(context)
                      : _buildOffersList(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(BuildContext context) {
    final filteredCats = _filteredCategories;

    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = (width ~/ 150).clamp(2, 4);

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredCats.length,
      itemBuilder: (ctx, idx) {
        final cat = filteredCats[idx];
        return CategoryTile(
          category: cat,
          onTap: () => _onCategoryTap(cat.id),
        );
      },
    );
  }

  Widget _buildOffersList(BuildContext context) {
    if (_allOffers.isEmpty && _hasMore && !_isLoadingMore) {
      _loadMoreFromServer();
    }

    if (_filteredOffers.isEmpty && !_isLoadingMore) {
      return Center(
        child: Text(
          'Нет предложений${_selectedCategoryId != null ? ' в этой категории' : ''}.',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (!_isLoadingMore &&
            _hasMore &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
          _loadMoreFromServer();
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: _filteredOffers.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
        itemBuilder: (ctx, idx) {
          if (idx < _filteredOffers.length) {
            final offer = _filteredOffers[idx];
            final cat = _allCategories.where( (e) => e.id == offer.categoryId).first;
            return OfferTile(offer: offer, category: cat,);
          } else {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );
  }
}
