// https://www.oanda.jp/lab-education/fx_on/%e4%b8%8a%e7%b4%9a%e8%80%85/3792/
input int MAGIC = 884;
input int TakeProfit = 100;
input double Lot = 0.1;
int d; //Dummy for Return Value
int i; //for For Roop
string Sym; //Symbol()
double TP; //TakeProfit x Point
double PriceTotal;
double cPrice;
datetime OldTime;

//**** Initialize ****
// 内部初期設定）
// Symbol() 関数の呼び出し時間軽減の為、Sym変数に代入します。
// 色々な通貨ペアで使用できるように TakeProfit をPoint を掛け変数TPに代入します。
// TakeProfit はint 型ですので(double)を付けています。
void OnInit(void)
{
    // Symbol: 現在チャートの通貨ペア名を返します 
    Sym = Symbol();
    // Point: 現在チャートの通貨ペアの価格の小数点値を返します 
    TP = (double)TakeProfit * Point;
} 

//**** OnTick ****
// ティック動作）
// 1.ティック単位で動作しますが、足ごとに動作するようにします。
// 2.Average()関数を呼び出し価格の合計、ポジション数の計算をしています。
// 3.ポジションがある時には価格幅を変動させつつOrderLong() 関数を呼び出します。
// 4.ポジションが無い時はOrderLong()関数を呼び出します。
void OnTick()
{
    // Time: チャートの各バーのオープン時間が含まれている時系列配列。
    // 時系列配列の要素は、逆の順序でインデックスが付けられています。
    // つまり、チャート上の現在(最新)バーのインデックスは[0]が付けられ、
    // チャート上の最も古いバーのインデックスは[Bars - 1]のインデックスが付けられます。
    if(Time[0] != OldTime)
    {
        // 足が更新された
        OldTime = Time[0];
        chkAverage();
        if(cPrice)
        {
            // ポジションあり
            // Bid: 現在の通貨ペアの最新の売値(買い手の価格)です。 
            if((PriceTotal+Bid)/(cPrice+1))
            {
                OrderLong();
                Modify();
            }
        }
        else{
            // ポジションなし
            OrderLong();
        }
    }
} 

//**** Order Long ****
// 発注関数）
// RSIが30以下の場合発注します。
void OrderLong()
{
    // iRSI: RSIインジケータを計算し、その値を返します
    // 通貨ペア、時間軸、計算をする平均期間、適用価格、インジケータバッファから取得する値のインデックス。(現在バーを基準にして、指定した時間軸のバー数分を過去方向へシフト)
    if(iRSI(Sym, PERIOD_CURRENT, 14, PRICE_CLOSE, 0) < 30)
    {
        // OrderSend: 新規成行注文や新規指値注文を行います 
        d = OrderSend(
            Sym,// 通貨ペア名
            OP_BUY,// 注文タイプ（OP_BUY: 成行買い)
            Lot,// ロット数
            Ask,// 注文価格（ダミー？）
            5,// 許容するスリップページ（単位は「ポイント」です。）
            0,// ストップロス価格（損切り価格を指定します。損切り価格を指定しない場合は、「０」と記述します。）
            Bid + TP,// リミット価格（利益確定価格を指定します。利益確定価格を指定しない場合は、「０」と記述します。）
            "AV-SYS",// 注文コメント。
            MAGIC);// マジックナンバー。ユーザーがEAを識別する為に使用します。 
        Print(Bid, " ", TP);
    }
}

//**** Check Average ****
// 平均価格計算）
// 全てのポジションからマジックナンバーの合うポジションの合計価格と数を算出します。
void chkAverage()
{
    PriceTotal = 0;
    cPrice = 0;
    // OrdersTotal: エントリー中の注文と保留中注文の総数を返します。
    for(i=OrdersTotal()-1; i>=0; i–)
    {
        // OrderSelect: 注文データを選択します（SELECT_BY_POS: 注文プールのインデックスをindexに指定します。）
        // 第2引数に SELECT_BY_POS、第3引数に MODE_TRADES (既定値) を入力することで保有中のポジションを取得できる。
        d = OrderSelect(i, SELECT_BY_POS);
        // OrderMagicNumber: 現在選択中の注文のマジック(識別)ナンバーを返します
        if(OrderMagicNumber() == MAGIC)
        {
            // OrderOpenPrice: 現在選択中の注文の注文価格を返します
            PriceTotal += OrderOpenPrice();
            cPrice++;
        }
    }
}

//**** Modify() ****
// 利益確定額変更）
// マジックナンバーの合うポジション全ての利益確定額を変更します。
void Modify()
{
    for(i=OrdersTotal()-1; i>=0; i–)
    {
        d = OrderSelect(i, SELECT_BY_POS);
        if(OrderMagicNumber() == MAGIC)
        {
            // OrderModify: エントリー中の注文や保留中の注文の変更
            // OrderTicket: 現在選択中の注文のチケット番号を返します
            // OrderOpenPrice: 現在選択中の注文の注文価格を返します
            d = OrderModify(
                OrderTicket(),// 変更する注文のチケット番号
                OrderOpenPrice(),// 新しい注文価格(保留中の注文のみ) 
                0,// 新しいストップロス価格
                PriceTotal/cPrice + TP,// 新しいリミット価格（利益確定価格を指定します。利益確定価格を指定しない場合は、「０」と記述します。）
                0);// 新しい有効期限(保留中の注文のみ)
        }
    }
}