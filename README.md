# Region Greater
Region Greater, send welcome message to comming user, once a day

## Options

Remove ; to enable the line or keep it for default value
You can use variables like `user`, `region`, `sim`, `parcel`, `grid`, `owner`

Private message to incoming user, keep it empty or disabled for no message

    message=Hi `user` welcome to our `region`, SY `owner`

Say in public, keep it empty or disabled no say

    say=Hi `user` welcome to our `region`, SY `owner`

Shout in public, keep it empty or disabled no shout

    shout=

Sound when incoming user, keep it empty or disabled for no sound

    sound=doorbell

An object you want to send it to new comming user, maybe a notecard

    give=welcome

Use short names in message

    short_name=Off

If you want it in parcel instead whole region, default is Off

    parcel=Off

In Seconds do not send message to same user in every, default is 86400 seconds (a Day)

    every=30

## Notices

It need OpenSim 0.9.3 or above
Rerez the object to reset all data, reset script not work