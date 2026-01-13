/**
    @name: Greater
    @title: Greater objeserver
    @author: Zai Dium
    @version: 1
    @revision: 70
    @localfile: ?defaultpath\Greater\?@name.lsl
    @updated: "2026-01-13 18:23:03"
    @license: by-nc-sa [https://creativecommons.org/licenses/by-nc-sa/4.0/]

    @resources:

        https://pixabay.com/sound-effects/search/ding%20dong/
*/
string version = "1.0";
integer show_text=TRUE;
integer short_name = FALSE;
//* use config
//string welcomeMessage = "Hi `user` welcome to our `region`";
string welcomeMessage = "";
string sayMessage = "";
string shoutMessage = "";
string sound = "doorbell";
string give = "";

updateText()
{
    if (show_text)
        llSetText("Greater "+version, <1,1,1>, 1);
    else
        llSetText("", ZERO_VECTOR, 1);
}

string configName = "config";
key nc_ConfigQueryID = NULL_KEY;
integer nc_configLine;

readConfig()
{
    if (llGetInventoryKey(configName) != NULL_KEY)
    {
        reset();
        llSetTimerEvent(0);
        nc_configLine = 0;
        nc_ConfigQueryID = llGetNotecardLine(configName, nc_configLine);
    }
}

integer toBool(string s)
{
    if ((llToLower(s) == "true") ||  (llToLower(s) == "on"))
        return TRUE;
    else
        return (integer)s;
}

string getDisplayName(key id)
{
    string name = llGetDisplayName(id);
    integer p = llSubStringIndex(name, "@");
    if (p > 0)
        return llStringTrim(llGetSubString(name, 0, p-1), STRING_TRIM);
    else
        return name;
}

string nameURI(key id)
{
    if (id==NULL_KEY)
        return "NONE";
    if (short_name)
        return getDisplayName(id);
    else
        return "secondlife:///app/agent/" + (string)id + "/inspect";
}

string parcelName = "";
string regionName = "";
string gridName = "";

string replace(string s, key id)
{
    string result = osReplaceString(s, "`user`", nameURI(id), -1, 0);
    result = osReplaceString(result, "`owner`", nameURI(llGetOwner()), -1, 0);
    result = osReplaceString(result, "`region`", regionName, -1, 0);
    result = osReplaceString(result, "`sim`", regionName, -1, 0);
    result = osReplaceString(result, "`parcel`", parcelName, -1, 0);
    result = osReplaceString(result, "`grid`", gridName, -1, 0);
    return result;
}

reset()
{
    parcelName = llList2String(llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_NAME]),0);
    regionName = llGetRegionName();
    gridName = osGetGridName();
}

default
{
    state_entry()
    {
        readConfig();
    }

    on_rez(integer number)
    {
        llResetScript();
    }

    link_message( integer sender_link, integer number, string message, key id )
    {
        if (id == NULL_KEY)
            return;

        if (message == "income")
        {
            if (welcomeMessage != "")
                llRegionSayTo(id, 0, replace(welcomeMessage, id));
            if (sayMessage != "")
                llSay(0, replace(sayMessage, id));
            if (shoutMessage != "")
                llShout(0, replace(shoutMessage, id));
            if (sound != "")
                llPlaySound(sound, 1);
            if (give != "")
                llGiveInventory(id, give);
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            readConfig();
        }
    }

    dataserver( key queryid, string data)
    {
        if (queryid == nc_ConfigQueryID)
        {
            if (data == EOF) //Reached end of notecard (End Of File).
            {
                nc_ConfigQueryID = NULL_KEY;
                updateText();
            }
            else
            {
                if ((llToLower(llGetSubString(data, 0, 0)) != "#") && (llToLower(llGetSubString(data, 0, 0)) != ";"))
                {
                    integer p = llSubStringIndex(data, "=");
                    string name;

                    if (p>=0)
                    {
                        name = llToLower(llStringTrim(llGetSubString(data, 0, p - 1), STRING_TRIM));
                        if (p<(llStringLength(data)-1))
                            data = llStringTrim(llGetSubString(data, p + 1, -1), STRING_TRIM);
                        else
                            data = "";
                    }
                    else
                        name = llStringTrim(data, STRING_TRIM);

                    if (data != "")
                    {
                        if (name=="message")
                            welcomeMessage = data;
                        else if (name=="say")
                            sayMessage = data;
                        else if (name=="shout")
                            shoutMessage = data;
                        else if (name=="sound")
                            sound = data;
                        else if (name=="give")
                            give = data;
                        else if (name=="short_name")
                            short_name = toBool(data);
                        else if ((name=="parcel") || (name=="every"))
                            llMessageLinked(LINK_SET, toBool(data), name, NULL_KEY);
                    }
                }

                ++nc_configLine;
                nc_ConfigQueryID = llGetNotecardLine(configName, nc_configLine);
            }
        }
    }
 }
