import 'package:flutter/material.dart';
import 'package:promo/config/app_configuration.dart';
import 'package:promo/services/peer_service.dart';
import 'package:promo/widgets/async_helper.dart';
import 'package:promo/widgets/loading.dart';

typedef OnPeerFound = void Function(Peer);

class PeerCard extends StatelessWidget {
  final Peer peer;

  const PeerCard({Key key, this.peer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print(peer);
    return Card(
      elevation: 4.0,
      margin: new EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
      child: Container(
        decoration: BoxDecoration(
          color: Color(peer.color),
        ),
        child: makeListTile(context),
      ),
    );
  }

  String get peerId => peer.id;

  String get proxyId => peer.peerProxyId.id;

  String get distance => '${peer.distance.toStringAsFixed(2)}m';

  Widget makeListTile(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      title: Text(
        peerId,
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 8.0),
        child: Text(
          proxyId,
        ),
      ),
      trailing: Text(
        distance,
        style: themeData.textTheme.title,
      ),
    );
  }
}

class PeerFinder extends StatefulWidget {
  final String data;
  final OnPeerFound onPeerFound;
  final AppConfiguration appConfiguration;

  PeerFinder({
    Key key,
    this.data,
    @required this.onPeerFound,
    @required this.appConfiguration,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return PeerFinderState(data);
  }
}

class PeerFinderState extends State<PeerFinder> {
  final String data;
  PeerService _peerService;
  Stream<List<Peer>> _peers;

  PeerFinderState(this.data);

  @override
  void initState() {
    super.initState();
    _peerService = PeerService(widget.appConfiguration);
    _peers = _peerService.peers(data: data);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return streamBuilder(
      name: 'Find Peers',
      stream: _peers,
      builder: _body,
      loadingWidget: _noPeersFound(context, "Looking for peers"),
      errorWidget: _noPeersFound(context, "Error finding peers"),
    );
  }

  Widget _noPeersFound(BuildContext context, String message) {
    return Center(
      child: Column(
        children: <Widget>[
          LoadingWidget(),
          const SizedBox(height: 32.0),
          Text(message),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, List<Peer> peers) {
    if (peers.isEmpty) {
      return _noPeersFound(context, "Looking for peers");
    }
    return ListView(
      children: peers.expand((p) {
        return [
          const SizedBox(height: 4.0),
          GestureDetector(
            child: PeerCard(peer: p),
            onTap: () => widget.onPeerFound(p),
          ),
        ];
      }).toList(),
    );
  }
}
