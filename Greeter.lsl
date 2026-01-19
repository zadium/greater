/**
    @name: Greeter
    @title: Greeter objeserver
    @author: Zai Dium
    @version: 1.5
    @revision: 145
    @localfile: ?defaultpath\Greeter\?@name.lsl
    @updated: "2026-01-19 16:59:04"
    @license: by-nc-sa [https://creativecommons.org/licenses/by-nc-sa/4.0/]

    @resources:

        https://pixabay.com/sound-effects/search/ding%20dong/
*/
string version = "1.5";
//** Stamp Change it to erease data
integer stamp = 0;
integer show_text=TRUE;
integer short_name = FALSE;
//* use config
//string welcomeMessage = "Hi `user` welcome to our `region`";
string welcomeMessage = "";
string sayMessage = "";
string shoutMessage = "";
string sound = "doorbell";
string give = "";
string rules = "";
integer accept_timeout = 120; //* 2 minutes
integer interval = 30;

updateText()
{
    if (show_text)
        llSetText("Greeter "+version, <1,1,1>, 1);
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
    if (id=="")
        return "UNKOWN";
    if (short_name)
        return getDisplayName(id);
    else
        return "secondlife:///app/agent/" + (string)id + "/inspect";
}

string parcelName = "";
key parcelOwner = NULL_KEY;
string regionName = "";
string gridName = "";

string replace(string s, key id)
{
    string result = osReplaceString(s, "`user`", nameURI(id), -1, 0);
    result = osReplaceString(result, "`owner`", nameURI(llGetOwner()), -1, 0);
    result = osReplaceString(result, "`parcel_owner`", nameURI(parcelOwner), -1, 0);
    result = osReplaceString(result, "`region`", regionName, -1, 0);
    result = osReplaceString(result, "`sim`", regionName, -1, 0);
    result = osReplaceString(result, "`parcel`", parcelName, -1, 0);
    result = osReplaceString(result, "`grid`", gridName, -1, 0);
    return result;
}

reset()
{
    list details = llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_NAME, PARCEL_COUNT_OWNER]);
    parcelName = llList2String(details,0);
    parcelOwner = llList2Key(details,1);
    regionName = llGetRegionName();
    gridName = osGetGridName();
}

list waiting_users = []; //* for TOS accept
list waiting_users_times = []; //* user time start waiting

addWaitingUser(key id)
{
    integer i = llListFindList(waiting_users, [id]);
    if (i < 0)
    {
        waiting_users += id;
        waiting_users_times += llGetUnixTime();
    }
}

removeWaitingUser(key id)
{
    integer i = llListFindList(waiting_users, [id]);
    if (i >= 0)
    {
        waiting_users = llDeleteSubList(waiting_users, i, i);
        waiting_users_times = llDeleteSubList(waiting_users_times, i, i);
    }
}

eject_user(key id)
{
    removeWaitingUser(id);
    llInstantMessage(llGetOwner(), "User " + nameURI(id) + " ignored to accept rules");
    if (llGetOwner() == parcelOwner)
    {
        llInstantMessage(id, "You ejected because you ignored to accept rules");
        llEjectFromLand(id);
    }
    else
        llInstantMessage(id, "Please leave because you ignored to accept rules");
}

integer rules_dialog_listen_id = -1;
integer rules_dialog_channel = -1;

ask(key id)
{
    //llListenRemove(dialog_listen_id); //* Nope we need to show it to multi users
    if (llGetOwner() == id)
        return;

    string already = llLinksetDataRead("accepted."+(string)id); //* not accepted before
    if (already=="")
    {
        addWaitingUser(id);
        llDialog(id, "\n"+rules, ["Accept", "Reject"], rules_dialog_channel);
        rules_dialog_listen_id = llListen(rules_dialog_channel, "", id, "");
    }
}

default
{
    state_entry()
    {
        if ((integer)llLinksetDataRead("stamp")!=stamp)
            llLinksetDataReset();
        llLinksetDataWrite("stamp", (string)stamp);
        rules_dialog_channel = -1 - (integer)("0x" + llGetSubString( (string) llGetKey(), -7, -1) ) + 1;
        readConfig();
        llSetTimerEvent(interval);
    }

    on_rez(integer number)
    {
        llResetScript();
    }

    link_message( integer sender_link, integer number, string message, key id )
    {
        if (id == NULL_KEY)
            return;

        if (message == "entered")
        {
            if (rules!="")
                ask(id);
        }
        else if (message == "income")
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

    listen(integer channel, string name, key id, string message)
    {
        if (channel==rules_dialog_channel)
        {
            message = llToLower(message);
            if (message=="accept")
            {
                llLinksetDataWrite("accepted."+(string)id, "true");
                removeWaitingUser(id);
            }
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
                        else if (name=="rules")
                            rules = osStringReplace(data, "\\n", "\n");
                        else if (name=="accept_timeout")
                            accept_timeout = (integer)data;
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

    timer()
    {
        //* Checking waiting users for accept
        list eject_users = [];
        integer c = llGetListLength(waiting_users);
        integer i = 0;
        while (i<c)
        {
            key user = llList2Key(waiting_users, i);
            //llOwnerSay("to:"+(string)user);
            integer time=llList2Integer(waiting_users_times, i);
            if ((llGetUnixTime() - time) > accept_timeout)
                eject_users += user;
            i++;
        }

        c = llGetListLength(eject_users);
        i = 0;
        while (i<c)
        {
            key user = llList2Key(eject_users, i);
            llOwnerSay("eject:" + (string)user);
            eject_user(user);
            i++;
        }
    }

 }
