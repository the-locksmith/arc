## Getting Started

**Room Server**
ルームサーバはP2Pの中継通信を行うサーバです.
下記のコマンドをプロジェクトルート直下で行ってください
```
$ make local-db-up
$ go run pkg/room/main.go coordinator --redis_host=127.0.0.1:16379 --port 8080 --debug
```

**Room Client**

- Reader
```
$ go run pkg/room/main.go client --in '{ 
    "mode": "sender",
    "id": "aaaa",
    "credential": "",
    "host": "127.0.0.1:8080",
    "permission": [
        "bbbb"
    ],
    "span": 6
}'
```

- Writer
```
$ go run pkg/room/main.go client --in '{ 
    "mode": "bench_sender",
    "id": "bbbb",
    "credential": "",
    "host": "127.0.0.1:8081",
    "permission": [
        "aaaa"
    ],
    "span": 6,
    "frequency": 1,
    "chunk": 512
}'
```

## Room Server実装

### データ構造

**MySQL**
Brokerと共用のMySQLにroomテーブルを作る

|id|address|latitude|longitude|
|:-:|:-:|:-:|:-:|

**KVS**
Roomサーバ間で共有

`key=peer_id, value=room_server_addr`
データを中継する際に使用する

## Room Server 仕様

### 接続確立
ピアはBrokerから位置情報を元に最も地理的に近く，接続可能なRoom Serverのエンドポイントを取得し，
このためにRoomServerにはインクリメンタルな一意なIDが割り振られている
`ws://room.one.com:8001/bind?peer_id=xxxx&credential=yyyy` というふうなアドレスにwebsocketで接続する

peer_idは接続元のピアが一意なものと判定するためのもので，credentialは本当にそのpeer_idを持つpeer自身かの真正性を確認するためのパラメータである
roomサーバは接続ソケットを保存し，roomサーバ間で共有のKVSに `key=peer_id, value=room_server_addr` という形で書き込む
この情報は他のroomサーバ，ピアからデータを中継する際にそのコネクションを保持しているroomサーバに正しく転送するために利用する

### Permission
ピアがRoomサーバとコネクションを維持することでデータのやり取りが可能になるが，あらゆるピアからのデータ転送を許可し，
そのフィルタリングをピア側で行うのはネットワーク，ピアともに負担がかかる

なので，どのピアからのデータは転送を許可するというルールをPermissionの導入によって行う
ピアはroomサーバにCreatePermission Requestを送信することで指定したpeer_idからのデータ転送を許可する

### Room Serverのスケールアウト
代表的な中継サーバとしてTURNがあるが，こいつをスケールアウトさせるのにはいくつもの自前実装を行わなければならない．
1. リソースの監視機構
2. オートスケールアウトさせる際どうやって新しいサーバにTURNをデプロイするのか
3. どうやって今動いているTURNサーバが新しいサーバを認識するか
3. 新しいTURNにコネクションを割り当てるにはどうするのか
4. TURN間でコネクションが跨がらないように注意

等々たくさん考えることがある

Arcで提供するroomサーバは複数のサーバが協調動作し，サーバ間をまたぐピア同士のコネクションも中継することができる．また，新しいサーバを追加した際にも現状動いているroomサーバの一つを指定してプログラムを動作させるだけで自動的にスケールアウトする
 
