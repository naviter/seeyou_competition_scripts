Program Solve_ties_by_daily_ranks;

// + Version 1.20 by Wojciech Scigala, 14.10.2014
//	Script solves tied scores according to number of daily ranks
//	(no. of 1st places, no. of 2nd places and so on)
//	Designed to operate with IGC 1000-point scoring system

// known bug: HC is not checked when determining Daily or Total ranks
// (variable Pilots[i].isHC not available in SeeYou)


// Parameter ONLYTOPRANKS limits solving ties only to given number
// of top ranked pilots. If set to 0, all ties are solved.


const
  ONLYTOPRANKS = 3;
  SMALLINC = 0.01;

var
  i,j,x : Integer;
  Days : Integer;
  Ties : array of Integer;
  PilotsDone : array of boolean;
  DayRankCache : array of array of SmallInt;


function DayRank (Pilot, Day : integer) : integer;
var j, r : integer;

begin
  r := DayRankCache[Pilot][Day];
  if r = -1 then
  begin
    r := 1;
    for j := low(Pilots) to high(Pilots) do
    begin
      if Pilots[Pilot].DayPts[Day] < Pilots[j].DayPts[Day] then
        r := r + 1;
    end;
    DayRankCache[Pilot][Day] := r;
  end
  
  result := r;
end;


Function PilotTotalRank(Pilot : integer) : integer;
var i, r : integer;

begin
  r := 1;
  for i:=low(Pilots) to high(Pilots) do
  begin
    if (Pilots[i].Total > Pilots[Pilot].Total) then
       r := r + 1;
  end;

  result := r;
end;


function CountDayRanks (Pilot, Rank : integer) : integer;

var d,r : integer;

begin
  r := 0;
  for d := 0 to Days-1 do
  begin
    if Rank = DayRank(Pilot,d) then
      r := r + 1;
  end;

  result := r;
end;


function CompareTwoPilots (p1,p2 : integer) : integer;

var
  dr : integer;
  p1_dr, p2_dr : integer;

begin
  result := 0;				// unsolvable

  for dr := 1 to high(Pilots)+1 do
  begin
    // Count Day Ranks
    p1_dr := CountDayRanks(p1,dr);
    p2_dr := CountDayRanks(p2,dr);

    if p1_dr > p2_dr then
    begin
      result := 1;
      break;
    end;

    if p1_dr < p2_dr then
    begin
      result := 2;
      break;
    end;
  
  end;
end;


procedure SolveTies (TiedPilots : array of integer);
var
  i,j : integer;
  p1,p2 : integer;
  CompResult : integer;

begin
  for i:=low(TiedPilots) to high(TiedPilots)-1 do
  begin
    PilotsDone[i] := true;
    p1 := TiedPilots[i];
    for j:=i+1 to high(TiedPilots) do
    begin
      p2 := TiedPilots[j];
      CompResult := CompareTwoPilots(p1,p2);
      if CompResult = 1 then
        Pilots[p1].Total := Pilots[p1].Total + SMALLINC;

      if CompResult = 2 then
        Pilots[p2].Total := Pilots[p2].Total + SMALLINC;

    end;
  end;
end;



begin

  // initial checks
  if GetArrayLength(Pilots) <= 1 then
    exit;

  Days := GetArrayLength(Pilots[0].DayPts);
  if Days <= 1 then
    exit;

  // set up PilotsDone array
  setarraylength(PilotsDone, GetArrayLength(Pilots));
  for i:= low(PilotsDone) to high(PilotsDone) do
    PilotsDone[i] := false;

  //set up DayRankCache
  setarraylength(DayRankCache, GetArrayLength(Pilots));
  for i:=low(DayRankCache) to high(DayRankCache) do
  begin
    setarraylength(DayRankCache[i], Days);
    for j:=0 to Days-1 do
      DayRankCache[i][j] := -1;
  end;

  // Store actual points as strings for presentation
  for i := low(Pilots) to high(Pilots) do
  begin
    Pilots[i].TotalString := FloatToStr(Pilots[i].Total);
  end;

  // set PilotsDone := true for pilots with rank > ONLYTOPRANKS
  if (ONLYTOPRANKS > 0) then
    for i := low(Pilots) to high(Pilots) do
      begin
        if (PilotTotalRank(i) > ONLYTOPRANKS) then
          PilotsDone[i] := true;
      end;
  
  // Find and solve tied scores
  for i := low(Pilots) to high(Pilots)-1 do
  begin
    if (Pilots[i].Total <> 0) and (PilotsDone[i] = false) then
    begin
      x := 0;
      setarraylength(Ties, 0);
      for j := low(Pilots) to high(Pilots) do
      if (Pilots[i].Total = Pilots[j].Total) then
      begin
        x := x + 1;
        setarraylength(Ties, x);
        Ties[x-1] := j;
      end;

      if GetArrayLength(Ties) >= 2 then
        SolveTies(Ties);

    end;
  end;
end.
