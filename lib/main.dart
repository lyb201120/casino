import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '178CASINO',
      theme: ThemeData.dark(),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ========== 全局数据 ==========
class GameData {
  static final Map<String, int> _players = {};
  static String? currentId;
  
  static void init() {
    _players['88888888'] = 10000;
  }
  
  static bool exists(String id) => _players.containsKey(id);
  static int getCoins(String id) => _players[id] ?? 0;
  static void setCoins(String id, int coins) { _players[id] = coins; }
  
  static String register() {
    final random = Random();
    String newId;
    do {
      newId = (100000000 + random.nextInt(900000000)).toString();
    } while (_players.containsKey(newId));
    _players[newId] = 0;
    return newId;
  }
  
  static void adminSetCoins(String id, int coins) { _players[id] = coins; }
  static List<String> getAllPlayerIds() => _players.keys.toList();
  static Map<String, int> getAllPlayers() => Map.from(_players);
}

class RoomConfig {
  final String name; final int minBet; final int minCoins;
  const RoomConfig(this.name, this.minBet, this.minCoins);
  static const List<RoomConfig> rooms = [
    RoomConfig('翡翠厅', 100, 1000),
    RoomConfig('黄金厅', 500, 5000),
    RoomConfig('铂金厅', 1000, 10000),
    RoomConfig('帝王厅', 5000, 50000),
  ];
}

// ========== 登录页 ==========
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _idCtrl = TextEditingController();
  final TextEditingController _pwdCtrl = TextEditingController();
  String _error = '';
  bool _isAdminLogin = false;
  
  @override
  void initState() {
    super.initState();
    GameData.init();
  }
  
  void _login() {
    if (_isAdminLogin) {
      if (_idCtrl.text == 'Zjcu201120withu' && _pwdCtrl.text == '201120') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminPanelPage()));
      } else {
        setState(() => _error = '账号或密码错误');
      }
    } else {
      final id = _idCtrl.text.trim();
      if (id.isEmpty) {
        setState(() => _error = '请输入ID');
        return;
      }
      if (GameData.exists(id)) {
        GameData.currentId = id;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LobbyPage()));
      } else {
        setState(() => _error = 'ID不存在，请先注册');
      }
    }
  }
  
  void _register() {
    final newId = GameData.register();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('注册成功'),
        content: Text('您的ID：$newId\n初始金币：0\n请联系管理员领取'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _idCtrl.text = newId;
            },
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF1A1A2E),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('178 CASINO', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amber)),
              const SizedBox(height: 40),
              TextField(
                controller: _idCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: _isAdminLogin ? '管理员账号' : '玩家ID',
                  labelStyle: const TextStyle(color: Colors.amber),
                  border: const OutlineInputBorder(),
                ),
              ),
              if (_isAdminLogin) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _pwdCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: '密码',
                    labelStyle: TextStyle(color: Colors.amber),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (_error.isNotEmpty) Text(_error, style: const TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                child: Text(_isAdminLogin ? '管理员登录' : '玩家登录'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => setState(() => _isAdminLogin = !_isAdminLogin),
                child: Text(_isAdminLogin ? '返回玩家登录' : '管理员登录', style: const TextStyle(color: Colors.amber)),
              ),
              if (!_isAdminLogin)
                TextButton(onPressed: _register, child: const Text('注册新玩家', style: TextStyle(color: Colors.amber))),
            ]),
          ),
        ),
      ),
    );
  }
}

// ========== 管理员面板 ==========
class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});
  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  Map<String, int> _players = {};
  
  @override
  void initState() {
    super.initState();
    _refresh();
  }
  
  void _refresh() {
    setState(() {
      _players = GameData.getAllPlayers();
    });
  }
  
  void _awardCoins(String playerId, int currentCoins) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('发放金币'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '数量'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              final amount = int.tryParse(controller.text);
              if (amount != null && amount > 0) {
                GameData.adminSetCoins(playerId, currentCoins + amount);
                _refresh();
                Navigator.pop(ctx);
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('管理员面板'), backgroundColor: Colors.amber, foregroundColor: Colors.black),
      body: _players.isEmpty
          ? const Center(child: Text('暂无玩家'))
          : ListView.builder(
              itemCount: _players.length,
              itemBuilder: (context, index) {
                final id = _players.keys.elementAt(index);
                final coins = _players[id]!;
                return ListTile(
                  title: Text(id),
                  subtitle: Text('金币: $coins'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    ElevatedButton(
                      onPressed: () => _awardCoins(id, coins),
                      child: const Text('发币'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        GameData.adminSetCoins(id, 0);
                        _refresh();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('清零'),
                    ),
                  ]),
                );
              },
            ),
    );
  }
}

// ========== 大厅 ==========
class LobbyPage extends StatefulWidget {
  const LobbyPage({super.key});
  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  int _coins = 0;
  String _playerId = '';
  
  final List<Map<String, dynamic>> _games = [
    {'name': '百家乐', 'icon': '🎲', 'color': Colors.red},
    {'name': '牛牛', 'icon': '🐮', 'color': Colors.orange},
    {'name': '龙虎斗', 'icon': '🐉', 'color': Colors.purple},
  ];
  
  @override
  void initState() {
    super.initState();
    _playerId = GameData.currentId!;
    _refresh();
  }
  
  void _refresh() {
    setState(() {
      _coins = GameData.getCoins(_playerId);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('欢迎, $_playerId'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
            child: Text('$_coins', style: const TextStyle(color: Colors.amber)),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.2),
        itemCount: _games.length,
        itemBuilder: (context, index) {
          final game = _games[index];
          return Card(
            color: (game['color'] as Color).withOpacity(0.2),
            child: InkWell(
              onTap: () => _showRoomSelection(game['name']),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(game['icon'], style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                Text(game['name'], style: const TextStyle(fontSize: 18, color: Colors.white)),
              ]),
            ),
          );
        },
      ),
    );
  }
  
  void _showRoomSelection(String gameName) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('选择场次', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...RoomConfig.rooms.map((room) => ListTile(
            title: Text(room.name),
            subtitle: Text('底注 ${room.minBet} 币 | 需 ${room.minCoins} 币'),
            trailing: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => GamePage(gameName: gameName, room: room)));
              },
              child: const Text('进入'),
            ),
          )),
        ]),
      ),
    );
  }
}

// ========== 游戏页面 ==========
class GamePage extends StatefulWidget {
  final String gameName;
  final RoomConfig room;
  const GamePage({super.key, required this.gameName, required this.room});
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  int _coins = 0;
  int _bet = 0;
  String _result = '';
  bool _isDealing = false;
  int _timerSeconds = 20;
  Timer? _countdownTimer;
  final Random _random = Random();
  
  String _betOn = '';
  String _playerCards = '??', _bankerCards = '??';
  int _playerPoints = 0, _bankerPoints = 0;
  String _dragonCard = '?', _tigerCard = '?';
  String _playerNiuCards = '', _bankerNiuCards = '';
  String _playerNiuType = '', _bankerNiuType = '';
  
  String get _playerId => GameData.currentId!;
  
  @override
  void initState() {
    super.initState();
    _refreshCoins();
    _startTimer();
  }
  
  void _refreshCoins() { setState(() { _coins = GameData.getCoins(_playerId); }); }
  void _saveCoins(int newCoins) { GameData.setCoins(_playerId, newCoins); _refreshCoins(); }
  
  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds <= 1) {
        timer.cancel();
        if (!_isDealing && _bet > 0) _deal();
      } else {
        setState(() { _timerSeconds--; });
      }
    });
  }
  
  void _placeBet(int amount, {String? betType}) {
    if (_isDealing) return;
    if (amount > _coins) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('余额不足')));
      return;
    }
    setState(() {
      _bet = amount;
      if (betType != null) _betOn = betType;
      _saveCoins(_coins - amount);
    });
  }
  
  Future<void> _deal() async {
    setState(() { _isDealing = true; _result = ''; });
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (widget.gameName == '百家乐') {
      await _playBaccarat();
    } else if (widget.gameName == '牛牛') {
      await _playNiuniu();
    } else if (widget.gameName == '龙虎斗') {
      await _playDragonTiger();
    }
    
    setState(() { _isDealing = false; });
    
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() { _bet = 0; _betOn = ''; _result = ''; _timerSeconds = 20; });
        _startTimer();
      }
    });
  }
  
  Future<void> _playBaccarat() async {
    if (_betOn.isEmpty) {
      setState(() { _result = '请先选择下注区域'; _isDealing = false; });
      return;
    }
    
    List<String> ranks = ['A','2','3','4','5','6','7','8','9','10','J','Q','K'];
    String p1 = ranks[_random.nextInt(13)];
    String p2 = ranks[_random.nextInt(13)];
    String b1 = ranks[_random.nextInt(13)];
    String b2 = ranks[_random.nextInt(13)];
    
    _playerCards = '$p1 $p2';
    _bankerCards = '$b1 $b2';
    _playerPoints = (_getCardValue(p1) + _getCardValue(p2)) % 10;
    _bankerPoints = (_getCardValue(b1) + _getCardValue(b2)) % 10;
    
    setState(() {});
    
    bool playerWin = _playerPoints > _bankerPoints;
    bool bankerWin = _bankerPoints > _playerPoints;
    bool tie = _playerPoints == _bankerPoints;
    
    int winAmount = 0;
    if (_betOn == 'player' && playerWin) winAmount = _bet;
    else if (_betOn == 'banker' && bankerWin) winAmount = (_bet * 95) ~/ 100;
    else if (_betOn == 'tie' && tie) winAmount = _bet * 8;
    
    if (winAmount > 0) {
      _saveCoins(_coins + winAmount);
      _result = '赢了 $winAmount 币！\n闲: $_playerCards = $_playerPoints 点\n庄: $_bankerCards = $_bankerPoints 点';
    } else {
      _result = '输了 $_bet 币！\n闲: $_playerCards = $_playerPoints 点\n庄: $_bankerCards = $_bankerPoints 点';
    }
  }
  
  int _getCardValue(String rank) {
    if (rank == 'A') return 1;
    if (rank == 'J' || rank == 'Q' || rank == 'K') return 0;
    return int.parse(rank);
  }
  
  Future<void> _playNiuniu() async {
    List<String> ranks = ['A','2','3','4','5','6','7','8','9','10','J','Q','K'];
    List<String> pCards = [];
    List<String> bCards = [];
    for (int i = 0; i < 5; i++) {
      pCards.add(ranks[_random.nextInt(13)]);
      bCards.add(ranks[_random.nextInt(13)]);
    }
    _playerNiuCards = pCards.join(' ');
    _bankerNiuCards = bCards.join(' ');
    
    int pSum = 0;
    for (var c in pCards) {
      int v = _getNiuValue(c);
      pSum += v > 10 ? 10 : v;
    }
    int bSum = 0;
    for (var c in bCards) {
      int v = _getNiuValue(c);
      bSum += v > 10 ? 10 : v;
    }
    _playerNiuType = (pSum % 10 == 0) ? '牛牛' : '${pSum % 10}点';
    _bankerNiuType = (bSum % 10 == 0) ? '牛牛' : '${bSum % 10}点';
    
    setState(() {});
    
    int pNum = _playerNiuType == '牛牛' ? 10 : int.parse(_playerNiuType.replaceAll('点', ''));
    int bNum = _bankerNiuType == '牛牛' ? 10 : int.parse(_bankerNiuType.replaceAll('点', ''));
    bool playerWin = pNum > bNum;
    
    if (playerWin) {
      int winAmount = _bet * 2;
      _saveCoins(_coins + winAmount);
      _result = '赢了 $winAmount 币！\n您: $_playerNiuCards = $_playerNiuType\n庄: $_bankerNiuCards = $_bankerNiuType';
    } else {
      _result = '输了 $_bet 币！\n您: $_playerNiuCards = $_playerNiuType\n庄: $_bankerNiuCards = $_bankerNiuType';
    }
  }
  
  int _getNiuValue(String rank) {
    if (rank == 'A') return 1;
    if (rank == 'J' || rank == 'Q' || rank == 'K') return 10;
    return int.parse(rank);
  }
  
  Future<void> _playDragonTiger() async {
    if (_betOn.isEmpty) {
      setState(() { _result = '请先选择龙或虎'; _isDealing = false; });
      return;
    }
    
    List<String> ranks = ['A','2','3','4','5','6','7','8','9','10','J','Q','K'];
    _dragonCard = ranks[_random.nextInt(13)];
    _tigerCard = ranks[_random.nextInt(13)];
    setState(() {});
    
    int dragonValue = _getDragonValue(_dragonCard);
    int tigerValue = _getDragonValue(_tigerCard);
    
    bool dragonWin = dragonValue > tigerValue;
    bool tigerWin = tigerValue > dragonValue;
    bool tie = dragonValue == tigerValue;
    
    int winAmount = 0;
    if (_betOn == 'dragon' && dragonWin) winAmount = _bet;
    else if (_betOn == 'tiger' && tigerWin) winAmount = _bet;
    else if (_betOn == 'tie' && tie) winAmount = _bet * 8;
    
    if (winAmount > 0) {
      _saveCoins(_coins + winAmount);
      _result = '赢了 $winAmount 币！\n龙: $_dragonCard  VS 虎: $_tigerCard';
    } else {
      _result = '输了 $_bet 币！\n龙: $_dragonCard  VS 虎: $_tigerCard';
    }
  }
  
  int _getDragonValue(String rank) {
    if (rank == 'A') return 14;
    if (rank == 'K') return 13;
    if (rank == 'Q') return 12;
    if (rank == 'J') return 11;
    return int.parse(rank);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.room.name} - ${widget.gameName}'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
            child: Text('$_coins', style: const TextStyle(color: Colors.amber)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _timerSeconds <= 5 ? Colors.red : Colors.amber,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text('$_timerSeconds 秒后开牌', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.gameName == '百家乐') ...[
                      Text('庄家: $_bankerCards', style: const TextStyle(fontSize: 20)),
                      Text('$_bankerPoints 点', style: const TextStyle(color: Colors.amber, fontSize: 18)),
                      const SizedBox(height: 20),
                      Text('闲家: $_playerCards', style: const TextStyle(fontSize: 20)),
                      Text('$_playerPoints 点', style: const TextStyle(color: Colors.amber, fontSize: 18)),
                    ] else if (widget.gameName == '牛牛') ...[
                      Text('您的牌:', style: const TextStyle(fontSize: 16)),
                      Text(_playerNiuCards.isEmpty ? '等待发牌' : _playerNiuCards, style: const TextStyle(fontSize: 16)),
                      Text(_playerNiuType, style: const TextStyle(color: Colors.amber)),
                      const SizedBox(height: 20),
                      Text('庄家牌:', style: const TextStyle(fontSize: 16)),
                      Text(_bankerNiuCards.isEmpty ? '等待发牌' : _bankerNiuCards, style: const TextStyle(fontSize: 16)),
                      Text(_bankerNiuType, style: const TextStyle(color: Colors.amber)),
                    ] else if (widget.gameName == '龙虎斗') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(children: [const Text('🐉', style: TextStyle(fontSize: 40)), Text(_dragonCard, style: const TextStyle(fontSize: 32))]),
                          const SizedBox(width: 40),
                          Column(children: [const Text('🐯', style: TextStyle(fontSize: 40)), Text(_tigerCard, style: const TextStyle(fontSize: 32))]),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (_result.isNotEmpty)
                      Text(_result, style: TextStyle(fontSize: 16, color: _result.contains('赢') ? Colors.green : Colors.red)),
                    if (_isDealing) const CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                if (widget.gameName == '百家乐')
                  Wrap(
                    spacing: 10,
                    children: [
                      ElevatedButton(onPressed: () => _placeBet(widget.room.minBet, betType: 'player'), child: const Text('押闲')),
                      ElevatedButton(onPressed: () => _placeBet(widget.room.minBet, betType: 'banker'), child: const Text('押庄')),
                      ElevatedButton(onPressed: () => _placeBet(widget.room.minBet, betType: 'tie'), child: const Text('押和')),
                    ],
                  )
                else if (widget.gameName == '龙虎斗')
                  Wrap(
                    spacing: 10,
                    children: [
                      ElevatedButton(onPressed: () => _placeBet(widget.room.minBet, betType: 'dragon'), child: const Text('押龙')),
                      ElevatedButton(onPressed: () => _placeBet(widget.room.minBet, betType: 'tiger'), child: const Text('押虎')),
                      ElevatedButton(onPressed: () => _placeBet(widget.room.minBet, betType: 'tie'), child: const Text('押和')),
                    ],
                  )
                else
                  Wrap(
                    spacing: 10,
                    children: [
                      ElevatedButton(onPressed: () => _placeBet(widget.room.minBet), child: Text('${widget.room.minBet}')),
                      ElevatedButton(onPressed: () => _placeBet(widget.room.minBet * 2), child: Text('${widget.room.minBet * 2}')),
                      ElevatedButton(onPressed: () => _placeBet(widget.room.minBet * 5), child: Text('${widget.room.minBet * 5}')),
                    ],
                  ),
                const SizedBox(height: 8),
                if (_bet > 0) Text('已下注: $_bet', style: const TextStyle(color: Colors.amber)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
