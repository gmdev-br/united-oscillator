//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "© GM, 2020, 2021, 2022, 2023"
#property description "United Oscillator"

#property indicator_separate_window
//#property indicator_minimum 0
//#property indicator_maximum 100

#property indicator_buffers 2
#property indicator_plots   2
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrRed, clrLime, clrDimGray //Specify 3 colors for a graphic plot

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//--- input parameters
input string   inputAtivo                                 = "";
input int      InpPeriodRSI                        = 14;             // Períodos de cálculo
input ENUM_TIMEFRAMES Timeframe                   = PERIOD_M5;             // Fonte dos dados
input color    regColor                            = clrBlack;     // Cor da linha
input color    regColorOverbought                  = clrRed;         // Cor de sobrecompra
input color    regColorOversold                    = clrLime;        // Cor de sobrevenda
input int      espessura_linha                     = 2;              // Espessura da linha
input double   levelUp                             = 80;             // Nível da linha de sobrecompra
//input double   levelMid                            = 50;             // Nível da linha intermediária
input double   levelDown                           = 20;             // Nível da linha de sobrevenda
input int      limitCandles                        = 500;           // O cálculo será feito somente a partir do número de candles definido
input int      WaitMilliseconds                    = 1000;           // Timer (milliseconds) for recalculation
input bool                       debug = false;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//--- indicator buffers
double    ExtRSIBuffer[], buffer_color_line[], expMedia[];
int       numPeriodos;
bool _lastOK = false;
int totalRates;
string ativo;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit() {

//--- check for input
   if(InpPeriodRSI < 1)
      numPeriodos = 14;
   else
      numPeriodos = InpPeriodRSI;

   if(ativo == "")
      ativo = _Symbol;
   else
      ativo = inputAtivo;

//--- indicator buffers mapping
   SetIndexBuffer(0, ExtRSIBuffer, INDICATOR_DATA);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetInteger(0, PLOT_LINE_WIDTH, espessura_linha);
   ArraySetAsSeries(ExtRSIBuffer, true);

   SetIndexBuffer(1, buffer_color_line, INDICATOR_COLOR_INDEX);
//Specify the number of color indexes, used in the graphic plot
   PlotIndexSetInteger(0, PLOT_COLOR_INDEXES, 3);
   ArraySetAsSeries(buffer_color_line, true);

//SetIndexBuffer(2, expMedia, INDICATOR_DATA);
//PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0.0);
//PlotIndexSetInteger(2, PLOT_LINE_WIDTH, espessura_linha);
//PlotIndexSetInteger(2, PLOT_LINE_COLOR, clrYellow);
//PlotIndexSetInteger(2, PLOT_DRAW_TYPE, DRAW_LINE);
//PlotIndexSetString(2, PLOT_LABEL, "Média");
//ArraySetAsSeries(expMedia, true);

//Specify colors for each index
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 0, regColor); //Zeroth index -> regColor
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 1, regColorOversold); //First index  -> regColorOversold
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 2, regColorOverbought); //Second index  -> regColorOverbought

//--- set levels
//IndicatorSetInteger(INDICATOR_LEVELS, 4);
//IndicatorSetDouble(INDICATOR_LEVELVALUE, 0, levelDown / 100);
//IndicatorSetDouble(INDICATOR_LEVELVALUE, 1, levelUp / 100);
//IndicatorSetDouble(INDICATOR_LEVELVALUE, 2, C'65,65,65' / 100);
//IndicatorSetDouble(INDICATOR_LEVELVALUE, 3, levelMid / 100);

//--- set maximum and minimum for subwindow
//IndicatorSetDouble(INDICATOR_MINIMUM, 0);
//IndicatorSetDouble(INDICATOR_MAXIMUM, 100);

//   IndicatorSetInteger(INDICATOR_LEVELCOLOR, 0, clrDarkGreen);
//   IndicatorSetInteger(INDICATOR_LEVELCOLOR, 1, C'148,29,29');
//   IndicatorSetInteger(INDICATOR_LEVELCOLOR, 2, clrDarkGray);
//   IndicatorSetInteger(INDICATOR_LEVELCOLOR, 3, clrDarkGray);
//
//   IndicatorSetInteger(INDICATOR_LEVELSTYLE, 0, STYLE_SOLID);
//   IndicatorSetInteger(INDICATOR_LEVELSTYLE, 1, STYLE_SOLID);
//   IndicatorSetInteger(INDICATOR_LEVELSTYLE, 2, STYLE_SOLID);
//   IndicatorSetInteger(INDICATOR_LEVELSTYLE, 3, STYLE_SOLID);
//
//   IndicatorSetInteger(INDICATOR_LEVELWIDTH, 0, 1);
//   IndicatorSetInteger(INDICATOR_LEVELWIDTH, 1, 1);
//   IndicatorSetInteger(INDICATOR_LEVELWIDTH, 2, 1);
//   IndicatorSetInteger(INDICATOR_LEVELWIDTH, 3, 1);

   IndicatorSetInteger(INDICATOR_DIGITS, 2);
   IndicatorSetString(INDICATOR_SHORTNAME, "United : " + ativo + " : " + string(numPeriodos) + " : " + GetTimeFrame(Period()));

   _updateTimer = new MillisecondTimer(WaitMilliseconds, false);
   _lastOK = false;
   EventSetMillisecondTimer(WaitMilliseconds);

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[]) {
   return (1);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Update() {

   totalRates = SeriesInfoInteger(ativo, Timeframe, SERIES_BARS_COUNT);

   if (totalRates <= numPeriodos)
      return(0);

   if (totalRates >= limitCandles)
      totalRates = limitCandles;

   if(totalRates <= 0)
      return(0);

   int lastIndex = totalRates - 1;
//ArrayResize(expMedia, totalRates);
   ArrayInitialize(expMedia, 0);

   double high[], low[];

   int highCount = CopyHigh(ativo, Timeframe, 0, totalRates, high);
   int lowCount = CopyLow(ativo, Timeframe, 0, totalRates, low);

   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);

   for(int i = 0; i <= lastIndex; i++) {
      ExtRSIBuffer[i] = 0;
      buffer_color_line[i] = 0;
   }

   for(int i = lastIndex - numPeriodos; i >= 0; i--) {
      double soma = 0;
      double dh = 0;
      double dl = 0;

      for(int x = i; x < i + numPeriodos; x++) {
         int u = 0;
         double atual = high[x];
         double anterior = high[x + 1];

         if (atual > anterior) {
            dh = dh + atual - anterior;
         }

         // calculo low
         atual = low[x];
         anterior = low[x + 1];

         if (atual < anterior) {
            dl = dl + anterior - atual;
         }
      }

      dh = dh / numPeriodos;
      dl = dl / numPeriodos;
      if (dh > 0)
         soma = (dh / (dh + dl));

      if (soma >= levelUp / 100)
         buffer_color_line[i] = 2;
      else if (soma <= levelDown / 100)
         buffer_color_line[i] = 1;

      ExtRSIBuffer[i] = soma;

   }

//   for(int i = numPeriodos; i <= lastIndex; i++) {
//      double soma = 0;
//      for(int x = i; x >= i - numPeriodos; x--) {
//         soma = soma + ExtRSIBuffer[x];
//      }
//
//      expMedia[i] = soma / numPeriodos;
//      if (ExtRSIBuffer[i] >= levelUp)
//         buffer_color_line[i] = 2;
//      else if (ExtRSIBuffer[i] <= levelDown)
//         buffer_color_line[i] = 1;
//
//     if (soma >= levelUp)
//         buffer_color_line[i] = 2;
//      else if (soma <= levelDown)
//         buffer_color_line[i] = 1;
//   }
//ArrayReverse(expMedia);

   return(true);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   CheckTimer();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   delete(_updateTimer);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckTimer() {

   EventKillTimer();

   if(_updateTimer.Check() || !_lastOK) {
      _lastOK = Update();

      EventSetMillisecondTimer(WaitMilliseconds);

      ChartRedraw();
      if (debug) Print("United Oscillator " + " " + ativo + ":" + GetTimeFrame(Period()) + " ok");

      _updateTimer.Reset();
   } else {
      EventSetTimer(1);
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MillisecondTimer {

 private:
   int               _milliseconds;
 private:
   uint              _lastTick;

 public:
   void              MillisecondTimer(const int milliseconds, const bool reset = true) {
      _milliseconds = milliseconds;

      if(reset)
         Reset();
      else
         _lastTick = 0;
   }

 public:
   bool              Check() {
      uint now = getCurrentTick();
      bool stop = now >= _lastTick + _milliseconds;

      if(stop)
         _lastTick = now;

      return(stop);
   }

 public:
   void              Reset() {
      _lastTick = getCurrentTick();
   }

 private:
   uint              getCurrentTick() const {
      return(GetTickCount());
   }

};

MillisecondTimer *_updateTimer;

//+---------------------------------------------------------------------+
//| GetTimeFrame function - returns the textual timeframe               |
//+---------------------------------------------------------------------+
string GetTimeFrame(int lPeriod) {
   switch(lPeriod) {
   case PERIOD_M1:
      return("M1");
   case PERIOD_M2:
      return("M2");
   case PERIOD_M3:
      return("M3");
   case PERIOD_M4:
      return("M4");
   case PERIOD_M5:
      return("M5");
   case PERIOD_M6:
      return("M6");
   case PERIOD_M10:
      return("M10");
   case PERIOD_M12:
      return("M12");
   case PERIOD_M15:
      return("M15");
   case PERIOD_M20:
      return("M20");
   case PERIOD_M30:
      return("M30");
   case PERIOD_H1:
      return("H1");
   case PERIOD_H2:
      return("H2");
   case PERIOD_H3:
      return("H3");
   case PERIOD_H4:
      return("H4");
   case PERIOD_H6:
      return("H6");
   case PERIOD_H8:
      return("H8");
   case PERIOD_H12:
      return("H12");
   case PERIOD_D1:
      return("D1");
   case PERIOD_W1:
      return("W1");
   case PERIOD_MN1:
      return("MN1");
   }
   return IntegerToString(lPeriod);
}
//+------------------------------------------------------------------+
