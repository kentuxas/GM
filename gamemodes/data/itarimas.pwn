#if !defined tMaxWanted
        #define tMaxWanted 6
#endif

/////////////////////////////////////////////////////////////////////////////////////////////////////////

new
        Text:btLicht[MAX_PLAYERS],
        Text:btLicht2[MAX_PLAYERS],
        Text:tSterne[MAX_PLAYERS];


/////////////////////////////////////////////////////////////////////////////////////////////////////////

enum Player{
        wanteds
}

new
        tp[MAX_PLAYERS][Player],
        bool:tdshow[MAX_PLAYERS],
        lichttimer[MAX_PLAYERS],
        bool:licht[MAX_PLAYERS];

/////////////////////////////////////////////////////////////////////////////////////////////////////////


stock GetPlayerTWanted(playerid)
{
        return tp[playerid][wanteds];
}

stock GivePlayerTWanted(playerid, level)
{
        new string[15];
        tp[playerid][wanteds] += level;
        format(string,15,"~y~]]]]]]~w~+%d",tp[playerid][wanteds]-6);
        if(tdshow[playerid]){
                switch(tp[playerid][wanteds])
                {
                        case 0:{
                        }
                        case 1:{TextDrawSetString(tSterne[playerid],"~y~]");}
                        case 2:{TextDrawSetString(tSterne[playerid],"~y~]]");}
                        case 3:{TextDrawSetString(tSterne[playerid],"~y~]]]");}
                        case 4:{TextDrawSetString(tSterne[playerid],"~y~]]]]");}
                        case 5:{TextDrawSetString(tSterne[playerid],"~y~]]]]]");}
                        case 6:{TextDrawSetString(tSterne[playerid],"~y~]]]]]]");}
                        default:{TextDrawSetString(tSterne[playerid],string);}
                }
        }else{
                TextDrawHideForPlayer(playerid, tSterne[playerid]);
                TextDrawHideForPlayer(playerid, btLicht[playerid]);
                TextDrawHideForPlayer(playerid, btLicht2[playerid]);
                lichttimer[playerid] = SetTimerEx("BlauLicht",500,true,"d",playerid);
                tdshow[playerid] = true;
                licht[playerid] = true;
                switch(tp[playerid][wanteds])
                {
                        case 0:{
                        }
                        case 1:{TextDrawSetString(tSterne[playerid],"~y~]");}
                        case 2:{TextDrawSetString(tSterne[playerid],"~y~]]");}
                        case 3:{TextDrawSetString(tSterne[playerid],"~y~]]]");}
                        case 4:{TextDrawSetString(tSterne[playerid],"~y~]]]]");}
                        case 5:{TextDrawSetString(tSterne[playerid],"~y~]]]]]");}
                        case 6:{TextDrawSetString(tSterne[playerid],"~y~]]]]]]");}
                        default:{TextDrawSetString(tSterne[playerid],string);}
                }
        }
        return 1;
}

stock SetPlayerTWanted(playerid, level)
{
        new string[15];
        tp[playerid][wanteds] = level;
        format(string,15,"~y~]]]]]]~w~+%d",tp[playerid][wanteds]-6);
        if(tdshow[playerid]){
                switch(tp[playerid][wanteds])
                {
                        case 0:{
                                TextDrawHideForPlayer(playerid, tSterne[playerid]);
                                TextDrawHideForPlayer(playerid, btLicht[playerid]);
                                TextDrawHideForPlayer(playerid, btLicht2[playerid]);
                                KillTimer(lichttimer[playerid]);
                                tdshow[playerid] = false;
                        }
                        case 1:{TextDrawSetString(tSterne[playerid],"~y~]");}
                        case 2:{TextDrawSetString(tSterne[playerid],"~y~]]");}
                        case 3:{TextDrawSetString(tSterne[playerid],"~y~]]]");}
                        case 4:{TextDrawSetString(tSterne[playerid],"~y~]]]]");}
                        case 5:{TextDrawSetString(tSterne[playerid],"~y~]]]]]");}
                        case 6:{TextDrawSetString(tSterne[playerid],"~y~]]]]]]");}
                        default:{TextDrawSetString(tSterne[playerid],string);}
                }
        }else{
                TextDrawHideForPlayer(playerid, tSterne[playerid]);
                TextDrawHideForPlayer(playerid, btLicht[playerid]);
                TextDrawHideForPlayer(playerid, btLicht2[playerid]);
                lichttimer[playerid] = SetTimerEx("BlauLicht",500,true,"d",playerid);
                tdshow[playerid] = true;
                licht[playerid] = true;
                switch(tp[playerid][wanteds])
                {
                        case 0:{
                                TextDrawHideForPlayer(playerid, tSterne[playerid]);
                                TextDrawHideForPlayer(playerid, btLicht[playerid]);
                                TextDrawHideForPlayer(playerid, btLicht2[playerid]);
                                KillTimer(lichttimer[playerid]);
                                tdshow[playerid] = false;
                        }
                        case 1:{TextDrawSetString(tSterne[playerid],"~y~]");}
                        case 2:{TextDrawSetString(tSterne[playerid],"~y~]]");}
                        case 3:{TextDrawSetString(tSterne[playerid],"~y~]]]");}
                        case 4:{TextDrawSetString(tSterne[playerid],"~y~]]]]");}
                        case 5:{TextDrawSetString(tSterne[playerid],"~y~]]]]]");}
                        case 6:{TextDrawSetString(tSterne[playerid],"~y~]]]]]]");}
                        default:{TextDrawSetString(tSterne[playerid],string);}
                }
        }
        return 1;
}


forward BlauLicht(playerid);

public BlauLicht(playerid)
{
        return 1;
}
