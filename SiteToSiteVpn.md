# Site-To-Site VPNの構築

[AWSのSite-to-Site VPN機能だけでAWS VPC同士をIPsecVPN接続する](https://qiita.com/h_nide/items/50902f0e441a8f7f4ddb)

# 仮想プライベートゲートウェイの作成

ここまでCloudFormationで設定済み。

接続元（VPC1）と接続先（VPC2）用に２つ作成する

![Site-To-Site-VPN1.png](images/Site-To-Site-VPN1.png)
![Site-To-Site-VPN2.png](images/Site-To-Site-VPN2.png)

VPC1、VPC2にそれぞれアタッチする

![Site-To-Site-VPN3.png](images/Site-To-Site-VPN3.png)
![Site-To-Site-VPN4.png](images/Site-To-Site-VPN4.png)

VPC1からVPC2へのルーティングテーブルを作成し作成した仮想プライベートゲートウェイを指定する

![Site-To-Site-VPN5.png](images/Site-To-Site-VPN5.png)
![Site-To-Site-VPN6.png](images/Site-To-Site-VPN6.png)

![Site-To-Site-VPN7.png](images/Site-To-Site-VPN7.png)
![Site-To-Site-VPN8.png](images/Site-To-Site-VPN8.png)

# VPC1からのカスタマーゲートウェイの作成

本来はオンプレミスの情報を登録するが、VPC間の接続なので一旦、仮の値を設定する

![Site-To-Site-VPN9.png](images/Site-To-Site-VPN9.png)

# Site-To-Site-VPNを作成する

![Site-To-Site-VPN10.png](images/Site-To-Site-VPN10.png)

アクティブになるのを待つ

![Site-To-Site-VPN11.png](images/Site-To-Site-VPN11.png)

設定をダウンロードする(値はなんでもよい)

![Site-To-Site-VPN12.png](images/Site-To-Site-VPN12.png)

ダウロードした設定をテキストで開き、「PreShared」もしくは「Shared」というキーワードで検索、32桁ぐらいのランダム文字列があるのでその文字列を記録する

tsWwn873iZAVDpa0AiwBZb7c1w_YZOU.

![Site-To-Site-VPN13.png](images%2FSite-To-Site-VPN13.png)

VPN接続の中の「トンネル詳細」タブを選択し、トンネル番号1の「外部IPアドレス」を記録する　・・・　VPC1の接続先IP (3.114.162.183)

![Site-To-Site-VPN14.png](images/Site-To-Site-VPN14.png)

# VPC2からのカスタマーゲートウェイの作成

IPアドレスにはVPC1の接続先IPを指定する

![Site-To-Site-VPN15.png](images/Site-To-Site-VPN15.png)

# Site-To-Site-VPNを作成する

トンネル詳細にダウンロードした文字列を指定する

![Site-To-Site-VPN16.png](images/Site-To-Site-VPN16.png)

アクティブになったら

![Site-To-Site-VPN17.png](images/Site-To-Site-VPN17.png)

設定をダウンロードしてSharedのキーが一致するか確認する

![Site-To-Site-VPN18.png](images/Site-To-Site-VPN18.png)

# VPC1からのカスタマーゲートウェイを再作成する

VCP2からのSite-To-Site-VPNのIPアドレスを取得して指定する

![Site-To-Site-VPN19.png](images/Site-To-Site-VPN19.png)

![Site-To-Site-VPN20.png](images/Site-To-Site-VPN20.png)

# VPC1からのSite-To-Site-VPNのカスタマーゲートウェイを更新する

VPC 接続オプションを変更する からカスタマーゲートウェイを新しく作成したものに変更する

![Site-To-Site-VPN21.png](images/Site-To-Site-VPN21.png)

# VPC1からのSite-To-Site-VPNのトンネルオプションを更新する

アクティブになるのを待って、VPC トンネルオプションの変更 から 「スタートアップアクション」で開始を選択して保存

![Site-To-Site-VPN22.png](images/Site-To-Site-VPN22.png)

![Site-To-Site-VPN23.png](images/Site-To-Site-VPN23.png)
![Site-To-Site-VPN24.png](images/Site-To-Site-VPN24.png)