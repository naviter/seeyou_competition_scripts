Program eGlide_Total_results;
var i, j, minIdx : integer;
    min, PilotTotal, WinnersTotal : double;
begin
//  // Remove positive daily score
//  WinnersTotal := 0;
//  for i := 0 to GetArrayLength(Pilots)-1 do
//  begin
//    PilotTotal := 0;
//    for j := 0 to GetArrayLength(Pilots[i].DayPts)-1 do
//    begin
//      if Pilots[i].DayPts[j] < 0 Then
//	  begin
//	    PilotTotal := PilotTotal + Pilots[i].DayPts[j];
//	  end
//	  else
//	  begin
//	    WinnersTotal := WinnersTotal + Pilots[i].DayPts[j];
//	  end;
//    end;
//	Pilots[i].Total := PilotTotal;
//  end;
  
  // Find the lowest score
  min := -1000000;
  minIdx := -1;
  for i := 0 to GetArrayLength(Pilots)-1 do
  begin
    if Pilots[i].Total > min Then
	begin
	  min := Pilots[i].Total;
	  minIdx := i;
	end;
  end;
  
  for i := 0 to GetArrayLength(Pilots)-1 do
  begin
    Pilots[i].Total := Pilots[i].Total - min;
//    ShowMessage(Pilots[i].CompID + ' ' + IntToStr(Round(Pilots[i].Total)));
  end;
  
//  Pilots[minIdx].Total := WinnersTotal;
end.
