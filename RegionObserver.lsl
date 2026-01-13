/**
    @name: RegionObserver
    @title: Greater objeserver
    @author: Zai Dium
    @version: 1
    @revision: 82
    @localfile: ?defaultpath\Greater\?@name.lsl
    @updated: "2026-01-13 18:55:05"
    @license: by-nc-sa [https://creativecommons.org/licenses/by-nc-sa/4.0/]
*/
integer parcel = FALSE;
integer interval = 5;
integer every=86400; //* a Day

//* Exists users
list exists = [];

check()
{
    list agents;
    integer t = llGetUnixTime();
    if (parcel)
        agents = llGetAgentList(AGENT_LIST_PARCEL, []);
    else
        agents = llGetAgentList(AGENT_LIST_REGION, []);
    integer c;
    integer i;

    list new_exists = [];
    c = llGetListLength(exists);
    i = 0;
    while (i < c)
    {
        key user = llList2Key(exists, i);
        if (llListFindList(agents, [user])>=0)
            new_exists += user;
        i++;
    }
    exists = new_exists;

    c = llGetListLength(agents);
    i = 0;

    while (i < c)
    {
        key user = llList2Key(agents, i);
        integer last_visit = (integer)llLinksetDataRead("users."+(string)user);
        integer delta = t-(integer)last_visit;

        if (llListFindList(exists, [user]) < 0) //* exists in the region
        {
            if ((last_visit == 0) || (delta > every)) //* a Day
            {
                exists += [user];
                llMessageLinked(LINK_SET, 0, "income", user);
                llLinksetDataWrite("users."+(string)user, (string)t);
            }
        }
        i++;
    }
}

default
{
    state_entry()
    {
        llSetTimerEvent(interval);
        //llLinksetDataReset();
    }

    on_rez(integer number)
    {
        llLinksetDataReset();
        llResetScript();
    }

/*    touch_start(integer num_detected)
    {
        check();
    }
    */

    link_message( integer sender_link, integer number, string message, key id )
    {
        if (message == "check")
            check();
        else if (message == "parcel")
            parcel = number;
        else if (message == "every")
            every = number;
        else if (message == "interval")
            interval = number;
    }

    timer()
    {
        check();
    }
}
