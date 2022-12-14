//+------------------------------------------------------------------+
//|                                       me_Breakeven_Line v2.4.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

#define OP_BUY 0           //Покупка 
#define OP_SELL 1          //Продажа 
#define OP_BUYLIMIT 2      //Отложенный ордер BUY LIMIT 
#define OP_SELLLIMIT 3     //Отложенный ордер SELL LIMIT 
#define OP_BUYSTOP 4       //Отложенный ордер BUY STOP 
#define OP_SELLSTOP 5      //Отложенный ордер SELL STOP 
//---
#define MODE_OPEN 0
#define MODE_CLOSE 3
#define MODE_VOLUME 4 
#define MODE_REAL_VOLUME 5
#define MODE_TRADES 0
#define MODE_HISTORY 1
#define SELECT_BY_POS 0
#define SELECT_BY_TICKET 1
//---
#define DOUBLE_VALUE 0
#define FLOAT_VALUE 1
#define LONG_VALUE INT_VALUE
//---
#define CHART_BAR 0
#define CHART_CANDLE 1
//---
#define MODE_ASCEND 0
#define MODE_DESCEND 1
//---
#define MODE_LOW 1
#define MODE_HIGH 2
#define MODE_TIME 5
#define MODE_BID 9
#define MODE_ASK 10
#define MODE_POINT 11
#define MODE_DIGITS 12
#define MODE_SPREAD 13
#define MODE_STOPLEVEL 14
#define MODE_LOTSIZE 15
#define MODE_TICKVALUE 16
#define MODE_TICKSIZE 17
#define MODE_SWAPLONG 18
#define MODE_SWAPSHORT 19
#define MODE_STARTING 20
#define MODE_EXPIRATION 21
#define MODE_TRADEALLOWED 22
#define MODE_MINLOT 23
#define MODE_LOTSTEP 24
#define MODE_MAXLOT 25
#define MODE_SWAPTYPE 26
#define MODE_PROFITCALCMODE 27
#define MODE_MARGINCALCMODE 28
#define MODE_MARGININIT 29
#define MODE_MARGINMAINTENANCE 30
#define MODE_MARGINHEDGED 31
#define MODE_MARGINREQUIRED 32
#define MODE_FREEZELEVEL 33
//---
#define EMPTY -1

input color Buy_BE_Level_Color = Blue;
input color Sell_BE_Level_Color = Green;
input int Line_Width = 3;

input ENUM_BASE_CORNER Text_Corner_0_to_3 = CORNER_LEFT_LOWER;
input int Text_X_Distance = 4;
input int Long_Text_Y_Distance = 10;
input int Short_Text_Y_Distance = 35;
input bool Calculate_EA_trades = false;
input string magic_numbers = "12345,123456,327,67";

int magic_numbers_array[];


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   string support[];
   StringSplit(magic_numbers,StringGetCharacter(",",0),support);
   ArrayResize(magic_numbers_array,ArrayRange(support,0));
   for (int i = 0;i < ArrayRange(support,0);i++){
      magic_numbers_array[i] = (int)support[i];
   }
   
   
  ObjectDelete (0,"BreakEven_Sell_Level");
  ObjectDelete (0,"BreakEven_Buy_Level");
  ObjectDelete (0,"Pips_To_Sell_BE");
  ObjectDelete (0,"Pips_To_Buy_BE");
  ObjectDelete (0,"Count_Buy");
  ObjectDelete (0,"Count_Sell");
  
  
  ObjectCreate (0,"Count_Buy",  OBJ_LABEL, 0, 0, 0);
  ObjectCreate (0,"Count_Sell", OBJ_LABEL, 0, 0, 0);
  ObjectCreate (0,"Pips_To_Buy_BE",  OBJ_LABEL, 0, 0, 0);
  ObjectCreate (0,"Pips_To_Sell_BE", OBJ_LABEL, 0, 0, 0);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   double Pekali;
   double Gigits = MarketInfo (Symbol(), MODE_DIGITS);
   if (Gigits == 2) Pekali = 100;
   if (Gigits == 3) Pekali = 100;
   if (Gigits == 4) Pekali = 10000;
   if (Gigits == 5) Pekali = 10000;

   int orders_buy = 0;
   int orders_sell = 0;
   double Overall_BE_Price = 0;
   double Sel_BE_Price = 0;
   double Cons_Sell_Price = 0;
   double Total_Sell_Size = 0;
   double Buy_BE_Price = 0;
   double Cons_Buy_Price = 0;
   double Total_Buy_Size = 0;
   double Overall_Size = 0;
   int buy_count=0,sell_count=0;
   int i;
   double total_buy_profit=0;
   double total_sell_profit=0;
   //Comment(PositionsTotal());
   for (i = 0; i < PositionsTotal(); i++)
      {
         string symbol=PositionGetSymbol(i);
         long magic=PositionGetInteger(POSITION_MAGIC);
       if (symbol==_Symbol && (!Calculate_EA_trades || IsInArray(magic_numbers_array,magic)))
         {
          if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            {
             Buy_BE_Price += PositionGetDouble(POSITION_PRICE_OPEN)*PositionGetDouble(POSITION_VOLUME);
             Total_Buy_Size += PositionGetDouble(POSITION_VOLUME);
             buy_count++;
             total_buy_profit += PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
             Overall_BE_Price +=  PositionGetDouble(POSITION_PRICE_OPEN)*PositionGetDouble(POSITION_VOLUME);
             Overall_Size += PositionGetDouble(POSITION_VOLUME);
             orders_buy++;
            }
            else
            {
             Sel_BE_Price += PositionGetDouble(POSITION_PRICE_OPEN)*PositionGetDouble(POSITION_VOLUME);
             Total_Sell_Size += PositionGetDouble(POSITION_VOLUME);
             sell_count++;
             total_sell_profit += PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
             Overall_BE_Price += PositionGetDouble(POSITION_PRICE_OPEN)*PositionGetDouble(POSITION_VOLUME);
             Overall_Size += PositionGetDouble(POSITION_VOLUME);
             orders_sell++;
            }
        }
   }
   int orders = orders_buy + orders_sell;
   ObjectDelete(0,"BreakEven_Buy_Level");
   ObjectDelete(0,"BreakEven_Sell_Level");
   
   
   if (Buy_BE_Price > 0)
     {
      Buy_BE_Price /= Total_Buy_Size;
      ObjectCreate(0,"BreakEven_Buy_Level", OBJ_HLINE, 0, 0, Buy_BE_Price);
      ObjectSetInteger(0,"BreakEven_Buy_Level", OBJPROP_COLOR, Buy_BE_Level_Color);
      ObjectSetInteger(0,"BreakEven_Buy_Level", OBJPROP_WIDTH, Line_Width);
      ObjectSetInteger(0,"BreakEven_Buy_Level", OBJPROP_BACK, false);
     }
     
   if (Sel_BE_Price > 0)
     {
      Sel_BE_Price /= Total_Sell_Size;
      ObjectCreate(0,"BreakEven_Sell_Level", OBJ_HLINE, 0, 0, Sel_BE_Price);
      ObjectSetInteger(0,"BreakEven_Sell_Level", OBJPROP_COLOR, Sell_BE_Level_Color);
      ObjectSetInteger(0,"BreakEven_Sell_Level", OBJPROP_WIDTH, Line_Width);
      ObjectSetInteger(0,"BreakEven_Sell_Level", OBJPROP_BACK, false);
     }
  
   string Buy_Sign;
   color Buy_Color;
   MqlTick last_tick;
   SymbolInfoTick(_Symbol,last_tick);
   double Bid=last_tick.bid;
   double Ask=last_tick.ask;
   double Buy_Pips_To_BE  = (Bid - Buy_BE_Price)*Pekali;
   if (orders_buy > 0 && Buy_Pips_To_BE >= 0) {Buy_Sign = "+";Buy_Color = Lime;}
   if (orders_buy > 0 && Buy_Pips_To_BE < 0)  {Buy_Sign = ""; Buy_Color = Red;}
   if (orders_buy <= 0) {Buy_Sign = ""; Buy_Color = Silver; Buy_Pips_To_BE  = 0;}
   ObjectSetInteger(0,"Pips_To_Buy_BE", OBJPROP_CORNER, Text_Corner_0_to_3);
   ENUM_ANCHOR_POINT align;
   if(Text_Corner_0_to_3==CORNER_LEFT_UPPER)
      align=ANCHOR_LEFT_UPPER;
   else if(Text_Corner_0_to_3==CORNER_RIGHT_UPPER)
      align=ANCHOR_RIGHT_UPPER;
   else if(Text_Corner_0_to_3==CORNER_LEFT_LOWER)
      align=ANCHOR_LEFT_LOWER;
   else
      align=ANCHOR_RIGHT_LOWER;
   ObjectSetInteger(0,"Pips_To_Buy_BE", OBJPROP_ANCHOR, align);
   ObjectSetInteger(0,"Pips_To_Buy_BE", OBJPROP_XDISTANCE, Text_X_Distance);
   ObjectSetInteger(0,"Pips_To_Buy_BE", OBJPROP_YDISTANCE, Long_Text_Y_Distance);
   ObjectSetInteger(0,"Pips_To_Buy_BE", OBJPROP_COLOR, Buy_Color);
   ObjectSetInteger(0,"Pips_To_Buy_BE", OBJPROP_BACK, false);
   ObjectSetText ("Pips_To_Buy_BE", Buy_Sign+DoubleToString (Buy_Pips_To_BE, 1)+ "p BE", 14, "Arial Bold");
   
   ObjectSetInteger(0,"Count_Buy", OBJPROP_CORNER, Text_Corner_0_to_3);
   ObjectSetInteger(0,"Count_Buy", OBJPROP_ANCHOR, align);
   ObjectSetInteger(0,"Count_Buy", OBJPROP_XDISTANCE, Text_X_Distance*30);
   ObjectSetInteger(0,"Count_Buy", OBJPROP_YDISTANCE, Long_Text_Y_Distance);
   ObjectSetInteger(0,"Count_Buy", OBJPROP_COLOR, Buy_Color);
   ObjectSetInteger(0,"Count_Buy", OBJPROP_BACK, false);
   ObjectSetText ("Count_Buy", buy_count+" BUY = "+DoubleToString(Total_Buy_Size,2)+" lots = "+DoubleToString(total_buy_profit,2), 14, "Arial Bold");
   
   string Sell_Sign;
   color Sell_Color;
   double Sell_Pips_To_BE = (Sel_BE_Price - Ask)*Pekali;
   if (orders_sell > 0 && Sell_Pips_To_BE >= 0) {Sell_Sign = "+";Sell_Color = Lime;}
   if (orders_sell > 0 && Sell_Pips_To_BE < 0)  {Sell_Sign = ""; Sell_Color = Red;}
   if (orders_sell <= 0) {Sell_Sign = ""; Sell_Color = Silver; Sell_Pips_To_BE = 0;}
   ObjectSetInteger(0,"Pips_To_Sell_BE", OBJPROP_CORNER, Text_Corner_0_to_3);
   ObjectSetInteger(0,"Pips_To_Sell_BE", OBJPROP_ANCHOR, align);
   ObjectSetInteger(0,"Pips_To_Sell_BE", OBJPROP_XDISTANCE, Text_X_Distance);
   ObjectSetInteger(0,"Pips_To_Sell_BE", OBJPROP_YDISTANCE, Short_Text_Y_Distance);
   ObjectSetInteger(0,"Pips_To_Sell_BE", OBJPROP_COLOR, Sell_Color);
   ObjectSetInteger(0,"Pips_To_Sell_BE", OBJPROP_BACK, false);
   ObjectSetText ("Pips_To_Sell_BE", Sell_Sign+DoubleToString (Sell_Pips_To_BE, 1)+ "p BE", 14, "Arial Bold");
   
   ObjectSetInteger(0,"Count_Sell", OBJPROP_CORNER, Text_Corner_0_to_3);
   ObjectSetInteger(0,"Count_Sell", OBJPROP_ANCHOR, align);
   ObjectSetInteger(0,"Count_Sell", OBJPROP_XDISTANCE, Text_X_Distance*30);
   ObjectSetInteger(0,"Count_Sell", OBJPROP_YDISTANCE, Short_Text_Y_Distance);
   ObjectSetInteger(0,"Count_Sell", OBJPROP_COLOR, Sell_Color);
   ObjectSetInteger(0,"Count_Sell", OBJPROP_BACK, false);
   ObjectSetText ("Count_Sell", sell_count+" SELL = "+DoubleToString(Total_Sell_Size,2)+" lots = "+DoubleToString(total_sell_profit,2)+"     -->  "+Symbol(), 14, "Arial Bold");
//--- return value of prev_calculated for next call
   return(rates_total);
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectDelete (0,"BreakEven_Sell_Level");
   ObjectDelete (0,"BreakEven_Buy_Level");
   ObjectDelete (0,"Pips_To_Sell_BE");
   ObjectDelete (0,"Pips_To_Buy_BE");
   ObjectDelete (0,"Count_Buy");
   ObjectDelete (0,"Count_Sell");
}

bool IsInArray(int &array[],int val){
   for (int i = 0;i < ArrayRange(array,0);i++){
      if (val == array[i])
         return true;
   }
   return false;
}

double MarketInfo(string symbol,
                      int type)
  {
   switch(type)
     {
      case MODE_LOW:
         return(SymbolInfoDouble(symbol,SYMBOL_LASTLOW));
      case MODE_HIGH:
         return(SymbolInfoDouble(symbol,SYMBOL_LASTHIGH));
      case MODE_TIME:
         return(SymbolInfoInteger(symbol,SYMBOL_TIME));
      case MODE_BID:
        {
         MqlTick last_tick;
         SymbolInfoTick(symbol,last_tick);
         double Bid=last_tick.bid;
         return(Bid);
        }
      case MODE_ASK:
        {
         MqlTick last_tick;
         SymbolInfoTick(symbol,last_tick);
         double Ask=last_tick.ask;
         return(Ask);
        }
      case MODE_POINT:
         return(SymbolInfoDouble(symbol,SYMBOL_POINT));
      case MODE_DIGITS:
         return(SymbolInfoInteger(symbol,SYMBOL_DIGITS));
      case MODE_SPREAD:
         return(SymbolInfoInteger(symbol,SYMBOL_SPREAD));
      case MODE_STOPLEVEL:
         return(SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL));
      case MODE_LOTSIZE:
         return(SymbolInfoDouble(symbol,SYMBOL_TRADE_CONTRACT_SIZE));
      case MODE_TICKVALUE:
         return(SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_VALUE));
      case MODE_TICKSIZE:
         return(SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE));
      case MODE_SWAPLONG:
         return(SymbolInfoDouble(symbol,SYMBOL_SWAP_LONG));
      case MODE_SWAPSHORT:
         return(SymbolInfoDouble(symbol,SYMBOL_SWAP_SHORT));
      case MODE_STARTING:
         return(0);
      case MODE_EXPIRATION:
         return(0);
      case MODE_TRADEALLOWED:
         return(0);
      case MODE_MINLOT:
         return(SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN));
      case MODE_LOTSTEP:
         return(SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP));
      case MODE_MAXLOT:
         return(SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX));
      case MODE_SWAPTYPE:
         return(SymbolInfoInteger(symbol,SYMBOL_SWAP_MODE));
      case MODE_PROFITCALCMODE:
         return(SymbolInfoInteger(symbol,SYMBOL_TRADE_CALC_MODE));
      case MODE_MARGINCALCMODE:
         return(0);
      case MODE_MARGININIT:
         return(0);
      case MODE_MARGINMAINTENANCE:
         return(0);
      case MODE_MARGINHEDGED:
         return(0);
      case MODE_MARGINREQUIRED:
         return(0);
      case MODE_FREEZELEVEL:
         return(SymbolInfoInteger(symbol,SYMBOL_TRADE_FREEZE_LEVEL));

      default: return(0);
     }
   return(0);
  }  
  
  bool ObjectSetText(string name2,
                       string text2,
                       int font_size,
                       string font,
                       color text_color=CLR_NONE)
  {
      if(ObjectSetString(0,name2,OBJPROP_TEXT,text2)==true
         && ObjectSetInteger(0,name2,OBJPROP_FONTSIZE,font_size)==true)
        {
         if(ObjectSetString(0,name2,OBJPROP_FONT,font)==false)
            return(false);
         if(text_color!=CLR_NONE && ObjectSetInteger(0,name2,OBJPROP_COLOR,text_color)==false)
            return(false);
         return(true);
        }
      return(false);
     
   return(false);
  }