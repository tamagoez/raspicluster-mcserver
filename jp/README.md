どうもどうも、たばすこ。です。  
最近話題の[ラズベリーパイ(ラズパイ)](https://raspberrypi.org)を、クラスター化すると最強のマイクラサーバーを作れるのではないかと思い、興味本位で実験しようと思います。  
初心者でも簡単に入れられるように、長いコマンドを省いたりしてますのでよろしくお願いします。

## 概要
[ラズベリーパイ](https://raspberrypi.org)を**クラスター化**([スパコン](https://ja.wikipedia.org/wiki/%E3%82%B9%E3%83%BC%E3%83%91%E3%83%BC%E3%82%B3%E3%83%B3%E3%83%94%E3%83%A5%E3%83%BC%E3%82%BF)みたいにPC重ねまくって)させて、低スぺパソコンを合体させまくって高スぺクラスターをつくりたい! ってことー    
まず、クラスター化させるために、[Kubernetes](https://kubernetes.io/ja/)クラスターというのを使用します。  
本当の話、[Turing Pi](https://turingpi.com/)という、基盤を(7個)どんどん元になる基盤にぶっさすことで作れる夢のようなﾔﾂがあるんですが、もし100個(100個?!?!)ぐらい作るときは、Turing Piでは**カバーできない**ので、ラズパイ単品でベイクしていきます。

## 引用させていただく記事
 - *1 [@reireiasという方の記事 (裸のラズパイにKubernetesの環境を構築する方法)](https://qiita.com/reireias/items/0d87de18f43f27a8ed9b)
 - *2 [Jeef Geerling という方の記事 (サーバーの導入方法)](https://www.jeffgeerling.com/blog/2020/raspberry-pi-cluster-episode-4-minecraft-pi-hole-grafana-and-more)
 - *3 [とある方の記事](https://gist.github.com/gabrielsson/2d110bb3f43b46597831f4a0e4065265)

## 最初の工程
### 購入
[ラズパイ](https://raspberrypi.org)を購入する。  
*1 ですが、Kubernetes環境を構築するためには、最低で3つのラズパイを使用する必要があります。  
なので、**3つ以上**のラズパイを購入します。  
ちなみに、現在の一番高スぺであるラズパイは以下のようになっています。

| 性能 | 値 |
| ---- | ---- |
| CPU | Broadcom BCM2711, Quad core Cortex-A72 (ARM v8) 64-bit SoC @ 1.5GHz |
| CPUコア数 | 4コア |
| メモリ | 8GB LPDDR4-3200 SDRAM |
| インターネット | Gigabit Ethernet |
| その他 | [こちらから](https://www.raspberrypi.org/products/raspberry-pi-4-model-b/specifications/) |

一つ10,230円くらいです。  
なんと、適当に見てみたところOkdoというオンラインショップでは現在在庫切れのようです...

### OSベーキング
#### 概要
せっかく買ったラズパイ、でも電源入れてみても立ち上がらない。  
当たり前です。  
[OS](https://e-words.jp/w/OS.html)という、基盤の次に**大切なﾔﾂがない**のです!  
ところで、ラズパイの標準ディスクは、MicroSD Cardとなっています。  
ですが、実際僕が使用した時にもよく起きましたが、[`Kernel panic`](https://www.otsuka-shokai.co.jp/words/kernelpanic.html)という**SDカードの耐久性の弱さ**のために、**OSの中核部分**であるカーネル（kernel）の**実行に致命的な支障が発生**し、エラーが吐き出されてしまうことがしばしばあり、最悪の場合起動すら許可してくれません。    
[`Kernel panic`](https://www.otsuka-shokai.co.jp/words/kernelpanic.html)は、Windowsでいう**ブルースクリーン**らしいです。  
なので、後に少々面倒なことをしなくてはいけません。

### MicroSDにインストール
#### フォーマット
まずはMicroSDカードを用意します。  
理由は後にお伝えします。  
ラズパイは**fat32**というフォーマットをする必要があります。  
~~そこでWindowsでは、**32GB**までちゃんとフォーマットできますが、**64GB**以降は専用のフォーマットソフトをインストールして使用する必要があります。  
まぁ、32GBのMicroSDカードで大丈夫でしょう。~~

今回は*1との手順とは違い、最初は[RaspberryPi Imager](https://www.raspberrypi.org/software/)という公式のソフトウェアを使用させていただきます。  
早速[RaspberryPi Imager](https://www.raspberrypi.org/software/)をインストールします。  
`Download for (OS)`となっているボタンを押すとダウンロードが開始するので、ダウンロードされた`imager_(version).(拡張子)`をクリックしてください。  
インストールが完了したら、まずPCに**MicroSD Card**をぶっさしてやってください。  

そし鱈、ついさっきインストールしたソフトを起動させます。  
そして、`CHOOSE OS`のボタンを押し、`Erase`を選択します。  
次に、`CHOOSE SD CARD`のボタンを押します。  
そうすると、つい先ほどぶっ刺したMicroSD Cardがリストに出てくると思います。ので、それを押してやってください。  
そしたら、`WRITE`しちゃってください!!!  
あっという間にフォーマット完了!

#### OSイメージのダウンロード
まだまだ[RaspberryPi Imager](https://www.raspberrypi.org/software/)の活躍は続きます!  
ですが、先に64bit用のイメージをダウンロードしましょう。  
残念ながら[RaspberryPi Imager](https://www.raspberrypi.org/software/)では、64bitはリストされず、32bitだけとなっております。  
なぜ、32bitだとダメなのって方は、フレッツ光さんの[こちらの記事](https://flets-w.com/chienetta/list/2021/02/cb_pc-equipment11.html)を見るとわかるかもしれません。  
では早速ダウンロードしましょう!  
まず、[このページにアクセスします](https://downloads.raspberrypi.org/raspios_lite_arm64/images/?C=M;O=D)。  
そうするとバージョン毎にリストされるので、最終更新(**Last Modified**)が一番新しいバージョンをクリックしましょう。  
そうしたら、またリストが出てくるので、拡張子が`.zip`となっているリンクを押すとダウンロードされます。  
この時にもう、ZIPファイルを**解凍**しちゃいましょう。  
解凍方法がわからない方はググれば見つかると思います。

#### OSイメージを焼く
またまたimagerを起動し、またまた`CHOOSE OS`をクリックします。  
そうしたら今回は`Use custom`をクリックします。  
ファイル参照画面が出てくると思いますので、先ほどダウンロードして解凍したファイルを選択してください。  
そして今回も`CHOOSE SD CARD`は、**MicroSD Card**を選択。  
そしたら、ちょっと待ったぁ!  
裏設定を設定してちょっと楽しちゃいましょう。  
裏設定は`Ctrl+Shift+X`で発動できます。  
では設定していきましょう。

 - まず最初に目に留まる`Image customization options`ですが、これはこの設定を このセッションでのみ適応する/永続的に適当する かなので、そこら辺は自分の勝手にしてください!  
 - `Dissable Overscan`ですが、特に設定はそのままでかまいません。  
 - `Set hostname`は、**masterpi**など、マスターPCと認知できるホスト名をつけてあげましょう。  
ニックネームみたいなものです。  
 - `Enable SSH`で、早速リモート接続の準備をしていきましょう。  
 - `Use password authentication`を選択してあげて、解読されないようなパスワードを与えてあげてください。  
このパスワードは一時的なものです。
 - `Configure wifi`を使用すれば、Wifiを設定することができます。  
**LAN**を使用する方は設定しなくてもよいかもしれません。  
個人の好みでどうぞ。  
 - 最後に`Set locale settings`を設定してあげましょう。  
これは、ロケールに関しての設定です。  
日本のタイムゾーンにしたい場合は、`Time zone`を`Asisa/Tokyo`にしてあげましょう。  
`Keyboard layout`は、自身のキーボード環境に合わせて変えましょう。  
日本国のキーボードを使用している場合は、`JP`で大丈夫です。  

そこまで来たら右上の**x**を押して閉じましょう!

ｿｼﾀﾗやっと、`WRITE`です!  
この間が一番の休み場!  
コーヒーでも飲んじゃってください!(こぼしてPCを破損させないように!)

### ラズパイの設定
まずは、ラズパイを起動させてあげましょう。  
```
ssh pi@(ラズパイのip)
```
を、遠隔操作するPCで実行します。  

では早速設定していきましょう。  
<b>#</b>はコメントです。

```
# rootユーザーになりましょう
sudo su

# 作者が作った自動初期セットアップコマンドを実行しましょう
# 安全面の為piユーザーは削除され、masterpiが追加されます
curl -sSL https://git.io/Jz6SF | sh

# 再起動して更新を反映させましょう
reboot
```

再起動したら、パッケージをインストールしましょう。
```
# またrootになりましょう
sudo su

# 作者が作成したコマンドを実行しましょう
curl -sSL https://git.io/Jz69J | sh

# シャットダウンしましょう
shutdown now
```

### コマンドを実行していく！
~~ここからはめんどくさい作業となっています。~~  
自動化しましたが、各ラズパイにて実行するため時間を要する場合があります。 
`ラズパイの子分の台数*2分`ぐらいの時間がかかると思います。  
ipアドレスは、子分の台数が99以下であることを想定しています  
では一台目のコマンドを実行しましょう！  
二台目からは、違うコマンドを実行します。

#### 1台目DAKE
```
# rootユーザーになりましょう
sudo su

# 自動化コマンドを実行します
# ここは弄らないでください
$num=01

# オプションを設定します

# 連番にする前のipアドレスを指定します
# =の後の192.168.0.1を変更します
# 192.168.0.1に設定し、連番01の時192.168.0.101が固定されるipアドレスになります
# ipアドレスが重ならないように確認して設定してください
$ipbase=192.168.0.1

# 接続モードを指定します
# Wi-Fiで接続する場合は"wifi"、LANで接続する場合は"lan"にかえてください
$mode="wifi"

# ルーターアドレスを指定します
$router=192.168.0.1

# DNSアドレスを指定します
# ルーターアドレスと同じ場合があります
$dns = 192.168.0.1

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ここは変更しないでください
$option = "$ipbase $num $mode $router $dns"

curl -sSL https://git.io/JziqO | sh $option

# 実行した際に
# $option=192.168.XXX.XXX 02 XXXX 192.168.XXX.XXX XXX.XXX.XXX.XXX
# の様な文字列が出力されます。
# これをメモしてください！
```

$optionは、毎回連番しか変動しないので、全文字をメモしたら、最初の2字を変えるだけでダイジョブです。
#### 2台目以降
```
# 出力された
# curl -sSL https://git.io/JziqO | sh XX XXX XXX.XXX.XXX.XXX XXX.XXX.XXX.XXX XXX.XXX.XXX
curl -sSL https://git.io/JziqO | sh $option

# そして出力された$optionをまた他のラズパイで実行してください
# 全ての機器で実行したら完了です
```

お疲れ様です。  
ケアレスミスを減らすために、休憩をまたまたとりましょう。
