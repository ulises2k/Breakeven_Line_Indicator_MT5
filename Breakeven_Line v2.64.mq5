//+------------------------------------------------------------------+
//|                                       me_Breakeven_Line v2.4.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022"
#property link      "https://www.forexfactory.com/thread/594407-break-even-line-for-multiple-order-indicator/"
#property version   "1.03"
#property indicator_chart_window

input color Buy_BE_Level_Color = Green;
input color Sell_BE_Level_Color = Red;
input color BuySell_BE_Level_Color = Gray;
input int Line_Width = 1;

input bool alert_buy = false; // Buy - Alert
input bool notification_buy = true; // Buy - Push notifications

input bool alert_sell = false; // Sell - Alert
input bool notification_sell = true; // Sell - Push notifications

input bool alert_buy_sell = false; // Buy + Sell - Alert
input bool notification_buy_sell = true; // Buy + Sell - Push notifications

input ENUM_BASE_CORNER Text_Location = CORNER_RIGHT_UPPER;
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
   double Pekali = 0;
   long Gigits = SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
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

   double Buy_BE_Price = 0;
   double Cons_Buy_Price = 0;
   double Total_Buy_Size = 0;

   double Sell_BE_Price = 0;
   double Cons_Sell_Price = 0;
   double Total_Sell_Size = 0;

   double Buy_Sell_BE_Price = 0; //BE Buy+Sell

   int i = 0;
   double Total_Buy_Profit = 0;
   double Total_Sell_Profit = 0;

//Comment(PositionsTotal());

   for(i = 0; i < PositionsTotal(); i++) {
      string symbol=PositionGetSymbol(i);
      long magic=PositionGetInteger(POSITION_MAGIC);
      if(symbol==_Symbol && (!Calculate_EA_trades || IsInArray(magic_numbers_array,magic))) {
         if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            Buy_BE_Price += PositionGetDouble(POSITION_PRICE_OPEN)*PositionGetDouble(POSITION_VOLUME);
            Total_Buy_Size += PositionGetDouble(POSITION_VOLUME);
            Total_Buy_Profit += PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
            orders_buy++;
         } else if ((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
            Sell_BE_Price += PositionGetDouble(POSITION_PRICE_OPEN)*PositionGetDouble(POSITION_VOLUME);
            Total_Sell_Size += PositionGetDouble(POSITION_VOLUME);
            Total_Sell_Profit += PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP);
            orders_sell++;
         }
      }
   }

   //Print("Buy_BE_Price:" + (string)Buy_BE_Price);
   //Print("Total_Buy_Size:" + (string)Total_Buy_Size);
   //Print("Total_Buy_Profit:" + (string)Total_Buy_Profit);

   //Print("Sell_BE_Price:" + (string)Sell_BE_Price);
   //Print("Total_Sell_Size:" + (string)Total_Sell_Size);
   //Print("Total_Sell_Profit:" + (string)Total_Sell_Profit);

   int orders = orders_buy + orders_sell;
   ObjectDelete(0,"BreakEven_Buy_Level");
   ObjectDelete(0,"BreakEven_Sell_Level");
   ObjectDelete(0,"BreakEven_BuySell_Level");

   if(Buy_BE_Price > 0) {
      Buy_BE_Price /= Total_Buy_Size;
      ObjectCreate(0,"BreakEven_Buy_Level", OBJ_HLINE, 0, 0, Buy_BE_Price);
      ObjectSetInteger(0,"BreakEven_Buy_Level", OBJPROP_COLOR, Buy_BE_Level_Color);
      ObjectSetInteger(0,"BreakEven_Buy_Level", OBJPROP_WIDTH, Line_Width);
      ObjectSetInteger(0,"BreakEven_Buy_Level", OBJPROP_BACK, false);
   }

   if(Sell_BE_Price > 0) {
      Sell_BE_Price /= Total_Sell_Size;
      ObjectCreate(0,"BreakEven_Sell_Level", OBJ_HLINE, 0, 0, Sell_BE_Price);
      ObjectSetInteger(0,"BreakEven_Sell_Level", OBJPROP_COLOR, Sell_BE_Level_Color);
      ObjectSetInteger(0,"BreakEven_Sell_Level", OBJPROP_WIDTH, Line_Width);
      ObjectSetInteger(0,"BreakEven_Sell_Level", OBJPROP_BACK, false);
   }

//BE Buy + SELL
   if(Buy_BE_Price > 0 && Sell_BE_Price > 0) {
      if (Sell_BE_Price > Buy_BE_Price  ) {
         Buy_Sell_BE_Price = ((Sell_BE_Price-Buy_BE_Price)/2)+Buy_BE_Price;
         ObjectCreate(0,"BreakEven_BuySell_Level", OBJ_HLINE, 0, 0, Buy_Sell_BE_Price);
         ObjectSetInteger(0,"BreakEven_BuySell_Level", OBJPROP_COLOR, BuySell_BE_Level_Color);
         ObjectSetInteger(0,"BreakEven_BuySell_Level", OBJPROP_WIDTH, Line_Width);
         ObjectSetInteger(0,"BreakEven_BuySell_Level", OBJPROP_BACK, false);
      }
   }



   MqlTick last_tick;
   double Bid = 0;
   double Ask = 0;
   if(SymbolInfoTick(_Symbol,last_tick)) {
      Bid=last_tick.bid;
      Ask=last_tick.ask;
   } else {
      Print("SymbolInfoTick() failed, error = ",GetLastError());
   }


   ENUM_ANCHOR_POINT align;
   if(Text_Location==CORNER_LEFT_UPPER)
      align=ANCHOR_LEFT_UPPER;
   else if(Text_Location==CORNER_RIGHT_UPPER)
      align=ANCHOR_RIGHT_UPPER;
   else if(Text_Location==CORNER_LEFT_LOWER)
      align=ANCHOR_LEFT_LOWER;
   else
      align=ANCHOR_RIGHT_LOWER;

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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   ObjectSetInteger(0,"Pips_To_Buy_BE", OBJPROP_CORNER, Text_Location);
   ObjectSetInteger(0,"Pips_To_Buy_BE", OBJPROP_ANCHOR, align);
   ObjectSetInteger(0,"Pips_To_Buy_BE", OBJPROP_XDISTANCE, Text_X_Distance);
   ObjectSetInteger(0,"Pips_To_Buy_BE", OBJPROP_YDISTANCE, Long_Text_Y_Distance);
   ObjectSetInteger(0,"Pips_To_Buy_BE", OBJPROP_COLOR, Buy_Color);
   ObjectSetInteger(0,"Pips_To_Buy_BE", OBJPROP_BACK, false);
   ObjectSetText("Pips_To_Buy_BE", Buy_Sign+DoubleToString(Buy_Pips_To_BE, 2)+ "p BE", 14, "Arial Bold");

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   ObjectSetInteger(0,"Count_Buy", OBJPROP_CORNER, Text_Location);
   ObjectSetInteger(0,"Count_Buy", OBJPROP_ANCHOR, align);
   ObjectSetInteger(0,"Count_Buy", OBJPROP_XDISTANCE, Text_X_Distance*30);
   ObjectSetInteger(0,"Count_Buy", OBJPROP_YDISTANCE, Long_Text_Y_Distance);
   ObjectSetInteger(0,"Count_Buy", OBJPROP_COLOR, Buy_Color);
   ObjectSetInteger(0,"Count_Buy", OBJPROP_BACK, false);
   ObjectSetText("Count_Buy", (string)orders_buy+" BUY = "+DoubleToString(Total_Buy_Size,2)+" lots = "+DoubleToString(Total_Buy_Profit,2), 14, "Arial Bold");

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
   ObjectSetInteger(0,"Pips_To_Sell_BE", OBJPROP_CORNER, Text_Location);
   ObjectSetInteger(0,"Pips_To_Sell_BE", OBJPROP_ANCHOR, align);
   ObjectSetInteger(0,"Pips_To_Sell_BE", OBJPROP_XDISTANCE, Text_X_Distance);
   ObjectSetInteger(0,"Pips_To_Sell_BE", OBJPROP_YDISTANCE, Short_Text_Y_Distance);
   ObjectSetInteger(0,"Pips_To_Sell_BE", OBJPROP_COLOR, Sell_Color);
   ObjectSetInteger(0,"Pips_To_Sell_BE", OBJPROP_BACK, false);
   ObjectSetText("Pips_To_Sell_BE", Sell_Sign+DoubleToString(Sell_Pips_To_BE, 2)+ "p BE", 14, "Arial Bold");

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   ObjectSetInteger(0,"Count_Sell", OBJPROP_CORNER, Text_Location);
   ObjectSetInteger(0,"Count_Sell", OBJPROP_ANCHOR, align);
   ObjectSetInteger(0,"Count_Sell", OBJPROP_XDISTANCE, Text_X_Distance*30);
   ObjectSetInteger(0,"Count_Sell", OBJPROP_YDISTANCE, Short_Text_Y_Distance);
   ObjectSetInteger(0,"Count_Sell", OBJPROP_COLOR, Sell_Color);
   ObjectSetInteger(0,"Count_Sell", OBJPROP_BACK, false);
   ObjectSetText("Count_Sell", (string)orders_sell+" SELL = "+DoubleToString(Total_Sell_Size,2)+" lots = "+DoubleToString(Total_Sell_Profit,2), 14, "Arial Bold");

   if (Bid == Buy_BE_Price) {
      if (alert_buy)
         Alert("Breakeven BUY: ", (string)NormalizeDouble(Buy_BE_Price, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)));
      if (notification_buy)
         SendNotification("Breakeven BUY: " + (string)NormalizeDouble(Buy_BE_Price, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)));
   }

   if (Ask == Sell_BE_Price) {
      if (alert_sell)
         Alert("Breakeven SELL: ", (string)NormalizeDouble(Sell_BE_Price, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)));
      if (notification_sell)
         SendNotification("Breakeven SELL: " + (string)NormalizeDouble(Sell_BE_Price, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)));
   }

   if ((Bid == Buy_Sell_BE_Price) || (Ask == Buy_Sell_BE_Price)) {
      if (alert_buy_sell)
         Alert("Breakeven BUY+SELL: ", (string)NormalizeDouble(Buy_Sell_BE_Price, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)));
      if (notification_buy_sell)
         SendNotification("Breakeven BUY+SELL: " + (string)NormalizeDouble(Buy_Sell_BE_Price, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)));
   }

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
