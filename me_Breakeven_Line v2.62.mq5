//+------------------------------------------------------------------+
//|                                       me_Breakeven_Line v2.4.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.01"
#property indicator_chart_window

#define MODE_DIGITS 12

input color Buy_BE_Level_Color = Green;
input color Sell_BE_Level_Color = Red;
input color BuySell_BE_Level_Color = Aqua;
input int Line_Width = 2;

input ENUM_BASE_CORNER Text_Corner_0_to_3 = CORNER_RIGHT_UPPER;
input int Text_X_Distance = 4;
input int Long_Text_Y_Distance = 10;
input int Short_Text_Y_Distance = 35;
input bool Calculate_EA_trades = false;
input string magic_numbers = "248,249";

int magic_numbers_array[];


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   string support[];
   StringSplit(magic_numbers,StringGetCharacter(",",0),support);
   ArrayResize(magic_numbers_array,ArrayRange(support,0));
   for(int i = 0; i < ArrayRange(support,0); i++) {
      magic_numbers_array[i] = (int)support[i];
   }

   ObjectDelete(0,"BreakEven_Buy_Level");
   ObjectDelete(0,"BreakEven_Sell_Level");
   ObjectDelete(0,"BreakEven_BuySell_Level");
   ObjectDelete(0,"Pips_To_Buy_BE");
   ObjectDelete(0,"Pips_To_Sell_BE");
   ObjectDelete(0,"Count_Buy");
   ObjectDelete(0,"Count_Sell");


   ObjectCreate(0,"Count_Buy",  OBJ_LABEL, 0, 0, 0);
   ObjectCreate(0,"Count_Sell", OBJ_LABEL, 0, 0, 0);
   ObjectCreate(0,"Pips_To_Buy_BE",  OBJ_LABEL, 0, 0, 0);
   ObjectCreate(0,"Pips_To_Sell_BE", OBJ_LABEL, 0, 0, 0);
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
                const int &spread[]) {
//---
   double Pekali=0;
   double Gigits = MarketInfo(Symbol(), MODE_DIGITS);
   if(Gigits == 2)
      Pekali = 100;
   if(Gigits == 3)
      Pekali = 100;
   if(Gigits == 4)
      Pekali = 10000;
   if(Gigits == 5)
      Pekali = 10000;

   int orders_buy = 0;
   int orders_sell = 0;
   double Overall_BE_Price = 0;

   double Sell_BE_Price = 0;
   double Cons_Sell_Price = 0;
   double Total_Sell_Size = 0;

   double Buy_BE_Price = 0;
   double Cons_Buy_Price = 0;
   double Total_Buy_Size = 0;

   double Overall_Size = 0;

   double Buy_Sell_BE_Price = 0; //BE Buy+Sell

   int buy_count = 0;
   int sell_count = 0;
   int i = 0;
   double total_buy_profit = 0;
   double total_sell_profit = 0;

//Comment(PositionsTotal());

   for(i = 0; i < PositionsTotal(); i++) {
      string symbol=PositionGetSymbol(i);
      long magic=PositionGetInteger(POSITION_MAGIC);
      if(symbol==_Symbol && (!Calculate_EA_trades || IsInArray(magic_numbers_array,magic))) {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            Buy_BE_Price += PositionGetDouble(POSITION_PRICE_OPEN)*PositionGetDouble(POSITION_VOLUME);
            Total_Buy_Size += PositionGetDouble(POSITION_VOLUME);
            buy_count++;
            total_buy_profit += PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
            Overall_BE_Price +=  PositionGetDouble(POSITION_PRICE_OPEN)*PositionGetDouble(POSITION_VOLUME);
            Overall_Size += PositionGetDouble(POSITION_VOLUME);
            orders_buy++;
         } else {
            Sell_BE_Price += PositionGetDouble(POSITION_PRICE_OPEN)*PositionGetDouble(POSITION_VOLUME);
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
   ObjectDelete(0,"BreakEven_BuySell_Level");

   bool BuyBE = false;
   bool SellBE = false;
   if(Buy_BE_Price > 0) {
      BuyBE = true;
      Buy_BE_Price /= Total_Buy_Size;
      ObjectCreate(0,"BreakEven_Buy_Level", OBJ_HLINE, 0, 0, Buy_BE_Price);
      ObjectSetInteger(0,"BreakEven_Buy_Level", OBJPROP_COLOR, Buy_BE_Level_Color);
      ObjectSetInteger(0,"BreakEven_Buy_Level", OBJPROP_WIDTH, Line_Width);
      ObjectSetInteger(0,"BreakEven_Buy_Level", OBJPROP_BACK, false);
   }

   if(Sell_BE_Price > 0) {
      SellBE = true;
      Sell_BE_Price /= Total_Sell_Size;
      ObjectCreate(0,"BreakEven_Sell_Level", OBJ_HLINE, 0, 0, Sell_BE_Price);
      ObjectSetInteger(0,"BreakEven_Sell_Level", OBJPROP_COLOR, Sell_BE_Level_Color);
      ObjectSetInteger(0,"BreakEven_Sell_Level", OBJPROP_WIDTH, Line_Width);
      ObjectSetInteger(0,"BreakEven_Sell_Level", OBJPROP_BACK, false);
   }

//BE Buy + SELL
   if(BuyBE && SellBE) {

      if (Buy_BE_Price > Sell_BE_Price)
         Buy_Sell_BE_Price = ((Buy_BE_Price-Sell_BE_Price)/2)+Sell_BE_Price;

      if (Sell_BE_Price > Buy_BE_Price  )
         Buy_Sell_BE_Price = ((Sell_BE_Price-Buy_BE_Price)/2)+Buy_BE_Price;

      if (Buy_BE_Price == Sell_BE_Price )
         Buy_Sell_BE_Price = (Buy_BE_Price - Sell_BE_Price)/2;

      ObjectCreate(0,"BreakEven_BuySell_Level", OBJ_HLINE, 0, 0, Buy_Sell_BE_Price);
      ObjectSetInteger(0,"BreakEven_BuySell_Level", OBJPROP_COLOR, BuySell_BE_Level_Color);
      ObjectSetInteger(0,"BreakEven_BuySell_Level", OBJPROP_WIDTH, Line_Width);
      ObjectSetInteger(0,"BreakEven_BuySell_Level", OBJPROP_BACK, false);
   }


   MqlTick last_tick;
   SymbolInfoTick(_Symbol,last_tick);
   double Bid=last_tick.bid;
   double Ask=last_tick.ask;


   string Buy_Sign;
   color Buy_Color = Silver;
   double Buy_Pips_To_BE  = (Bid - Buy_BE_Price)*Pekali;
   if(orders_buy > 0 && Buy_Pips_To_BE >= 0) {
      Buy_Sign = "+";
      Buy_Color = Lime;
   }
   if(orders_buy > 0 && Buy_Pips_To_BE < 0) {
      Buy_Sign = "";
      Buy_Color = Red;
   }
   if(orders_buy <= 0) {
      Buy_Sign = "";
      Buy_Color = Silver;
      Buy_Pips_To_BE  = 0;
   }

   ENUM_ANCHOR_POINT align;
   if(Text_Corner_0_to_3==CORNER_LEFT_UPPER)
      align=ANCHOR_LEFT_UPPER;
   else if(Text_Corner_0_to_3==CORNER_RIGHT_UPPER)
      align=ANCHOR_RIGHT_UPPER;
   else if(Text_Corner_0_to_3==CORNER_LEFT_LOWER)
      align=ANCHOR_LEFT_LOWER;
   else
      align=ANCHOR_RIGHT_LOWER;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   ObjectSetInteger(0,"Pips_To_Buy_BE", OBJPROP_CORNER, Text_Corner_0_to_3);
   ObjectSetInteger(0,"Pips_To_Buy_BE", OBJPROP_ANCHOR, align);
   ObjectSetInteger(0,"Pips_To_Buy_BE", OBJPROP_XDISTANCE, Text_X_Distance);
   ObjectSetInteger(0,"Pips_To_Buy_BE", OBJPROP_YDISTANCE, Long_Text_Y_Distance);
   ObjectSetInteger(0,"Pips_To_Buy_BE", OBJPROP_COLOR, Buy_Color);
   ObjectSetInteger(0,"Pips_To_Buy_BE", OBJPROP_BACK, false);
   ObjectSetText("Pips_To_Buy_BE", Buy_Sign+DoubleToString(Buy_Pips_To_BE, 1)+ "p BE", 14, "Arial Bold");

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   ObjectSetInteger(0,"Count_Buy", OBJPROP_CORNER, Text_Corner_0_to_3);
   ObjectSetInteger(0,"Count_Buy", OBJPROP_ANCHOR, align);
   ObjectSetInteger(0,"Count_Buy", OBJPROP_XDISTANCE, Text_X_Distance*30);
   ObjectSetInteger(0,"Count_Buy", OBJPROP_YDISTANCE, Long_Text_Y_Distance);
   ObjectSetInteger(0,"Count_Buy", OBJPROP_COLOR, Buy_Color);
   ObjectSetInteger(0,"Count_Buy", OBJPROP_BACK, false);
   ObjectSetText("Count_Buy", (string)buy_count+" BUY = "+DoubleToString(Total_Buy_Size,2)+" lots = "+DoubleToString(total_buy_profit,2), 14, "Arial Bold");

   string Sell_Sign;
   color Sell_Color = Silver;
   double Sell_Pips_To_BE = (Sell_BE_Price - Ask)*Pekali;
   if(orders_sell > 0 && Sell_Pips_To_BE >= 0) {
      Sell_Sign = "+";
      Sell_Color = Lime;
   }
   if(orders_sell > 0 && Sell_Pips_To_BE < 0) {
      Sell_Sign = "";
      Sell_Color = Red;
   }
   if(orders_sell <= 0) {
      Sell_Sign = "";
      Sell_Color = Silver;
      Sell_Pips_To_BE = 0;
   }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   ObjectSetInteger(0,"Pips_To_Sell_BE", OBJPROP_CORNER, Text_Corner_0_to_3);
   ObjectSetInteger(0,"Pips_To_Sell_BE", OBJPROP_ANCHOR, align);
   ObjectSetInteger(0,"Pips_To_Sell_BE", OBJPROP_XDISTANCE, Text_X_Distance);
   ObjectSetInteger(0,"Pips_To_Sell_BE", OBJPROP_YDISTANCE, Short_Text_Y_Distance);
   ObjectSetInteger(0,"Pips_To_Sell_BE", OBJPROP_COLOR, Sell_Color);
   ObjectSetInteger(0,"Pips_To_Sell_BE", OBJPROP_BACK, false);
   ObjectSetText("Pips_To_Sell_BE", Sell_Sign+DoubleToString(Sell_Pips_To_BE, 1)+ "p BE", 14, "Arial Bold");

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   ObjectSetInteger(0,"Count_Sell", OBJPROP_CORNER, Text_Corner_0_to_3);
   ObjectSetInteger(0,"Count_Sell", OBJPROP_ANCHOR, align);
   ObjectSetInteger(0,"Count_Sell", OBJPROP_XDISTANCE, Text_X_Distance*30);
   ObjectSetInteger(0,"Count_Sell", OBJPROP_YDISTANCE, Short_Text_Y_Distance);
   ObjectSetInteger(0,"Count_Sell", OBJPROP_COLOR, Sell_Color);
   ObjectSetInteger(0,"Count_Sell", OBJPROP_BACK, false);
//ObjectSetText("Count_Sell", (string)sell_count+" SELL = "+DoubleToString(Total_Sell_Size,2)+" lots = "+DoubleToString(total_sell_profit,2)+"     -->  "+Symbol(), 14, "Arial Bold");
   ObjectSetText("Count_Sell", (string)sell_count+" SELL = "+DoubleToString(Total_Sell_Size,2)+" lots = "+DoubleToString(total_sell_profit,2), 14, "Arial Bold");

//--- return value of prev_calculated for next call
   return(rates_total);
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   ObjectDelete(0,"BreakEven_Buy_Level");
   ObjectDelete(0,"BreakEven_Sell_Level");
   ObjectDelete(0,"BreakEven_BuySell_Level");
   ObjectDelete(0,"Pips_To_Buy_BE");
   ObjectDelete(0,"Pips_To_Sell_BE");
   ObjectDelete(0,"Count_Buy");
   ObjectDelete(0,"Count_Sell");
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsInArray(int &array[],long val) {
   for(int i = 0; i < ArrayRange(array,0); i++) {
      if(val == array[i])
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MarketInfo(const string Symb, const ENUM_SYMBOL_INFO_DOUBLE Property)  {
   return(SymbolInfoDouble(Symb, Property));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ObjectSetText(string name, string text, int font_size, string font_name=NULL, color text_color=CLR_NONE) {
   int tmpObjType=(int)ObjectGetInteger(0,name,OBJPROP_TYPE);
   if(tmpObjType!=OBJ_LABEL && tmpObjType!=OBJ_TEXT) return(false);
   if(StringLen(text)>0 && font_size>0) {
      if(ObjectSetString(0,name,OBJPROP_TEXT,text)==true && ObjectSetInteger(0,name,OBJPROP_FONTSIZE,font_size)==true) {
         if((StringLen(font_name)>0) && ObjectSetString(0,name,OBJPROP_FONT,font_name)==false)
            return(false);
         if(text_color!=CLR_NONE && ObjectSetInteger(0,name,OBJPROP_COLOR,text_color)==false)
            return(false);
         return(true);
      }
      return(false);
   }
   return(false);
}
//+------------------------------------------------------------------+
