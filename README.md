# TopPriorityAction
WoW addon to propose combat actions (spells, items). Implements combat action priority list (APL).\
Uses retail WoW UI Lua.

## Current state
- Game version: 10.0.7 (Dragonflight)
- Specs:
  - Active: outlaw (10.0.7), protw (10.0.7), fury (10.0.7)
  - Inactive: assa (10.0.2), feral (9.2.7), guardian (9.2.7)

## Description

### Limitations:
Made for personal use to learn more about WoW and Lua.\
External requests and issues are not accepted.\
My APL is different from SimCraft and AskMrRobot to fit my playstyle and gear. Supports only talents I use.

Has no UI, no ingame description. To visualise a proposed action requires other addons (e.g. WeakAuras, TellMeWhen).\
Sample WeakAura import string:
```
!WA:2!fAvZUTTrq4Q6aeaHM0e3uJ2BecnP2ajco)2MaKcikl1Ogfjvk6O0dfYRihkUXulz3DPSvkqbQouKZ6rqN7jb0xa)eqiu0hG8i4d9CNDjPCSRRlpiS7SZFFZoZ3Qc1xF06UR7(2Vyo1jK1nmM7aRXpSTNNaKfM7elKHJSHdLrFPxmZrsdzBUvrd8JdYyoZGeZj9b24YTiJGIaZLpj14p6Jxqyo(H8oHuMCq1ATSRzT0jmmWn8aw3dOrWEhLVTM7qW3uLc7nvYPdhcCXvVfpB5FBkNebdstM5UWGyppBuc)z1A2P(UnxKEsFTwcjrglmJzu5GOaYeGBXWutu0cgdm5rv9jsJxacbzi8or8aT0oCWJEOv3o1A2CQicccA4kkMbFfYsUuQIIOB0RsF7ov6xPQDJ2T6VBNDQyxltZgiaIEWQcL2IBBq07o)QMYcvvZYXhC2pzJvzuxeJ0dx0VALU297AxXYo5Qhw4pUiFt9msfB80NAuQDhv(1T0wgsFGPvq9DQiB8uJ7E)hD3V(X)7JvGgpUu97wA1HzjVKhdAzyEFMa)lOfyYAVB3sgeMRXjs))shNyoh1TIgpyGtb2Pcdz1zNRrRsLSAYfJ7uLsR))xGptNNdtovEKFhMMokyM7m3ZS7Bm2wD5M3F6tDbljDe4olML1BVrYv)WORRmzmyNk6fHUWV)bhJtnaNrcEjolG(7NpEFaIQGnNoslcgb)zciWtpDLCzCQqG99CIe8NJ9qwWq0gXt2i5klXTdio7pKhgZCF7grRlX55(cFco59QSj9Opxlu)JxiFebviBHjlKbZwDCPBYIU275HQHbH8VRqHcR9UuP5jLzLDTBh9jAHKye)ys70J6k9nRGBponw0dbxTWFDzkDXpKLrhPp)1yLJ6nbbipehSbfvKzR2TQLCfoIlLoZ1k6OtJ1WVzzGGjJUwDo9ngFFmXflmedB7tH98iTul7GqUBpojAAVSfPjWyQGoia2ldZVhLwYLxUksk2OJSFwJQpV9U2nB0Q25upDYwKS9j21L(g4Mza)cUkyRm9Vwomi8G6C4NIbMZKoxA7Y37HP1c1blu)K7OPQnQmB5GyPmK1EmWrcX5kXnb2qP)NQ1pVomtTP6Q64rXc4BZL4BQo0xhDBFQZ(mKbDnTfDDibq6YMuu811bWeRIa3FGpqh6ljMbHe3xodDzFgskGhirRyYnSgfhiPfTCcicXgj)yrtvhE6cS4OwmNRBMvijPy0nYFZq1kSdvqWBhx)zegv1GfYEKf(caxw)iGiGUsUgOxo5kyz3vnFGQOFOGlaC23vmvPN23BBoIqz1taT2jEjdt8t2EGhLrf(Nv8ckl9orX8eTocSQz5fo(IZNWEMVjmCubEkBG4rjUftEDrt0zYBnZnSFkNWEkw9hheI1qd0wGJSgiBzVk3bFJ5oz8B3j1hLkMQx(BagynjI0fKskBOy3ixmQBM5K8xgUTr5YLtFEOhq2VcwbeLXBmwn9RzBw68EnR0zSwr8P1xXQiK8jpjDbWRsccuClBwQYo7G2FEU6CYYBNJ1TkAfZAHxK15iL7MN8xmUySXObBPOJ3AUm0zCk)4Nv43MxI6oftbd1FK4EXu3fE(pU3Mn2QsJT)klsqKpzTJth20XtDRpOBvRA1AzDc)Xa0yp6WICkt5AWFHNszSvc5qwZ6afzfzUQ3HQVzlonVJCVLiph682rPhSUW6HLVF5hS(4)8v)Zp
```

### Purpose:
Shared code might be usefull for other addon developers to find general hints and ideas.\
Combined with third-party visualization and a visual spell tracker (e.g. TrufiGCD, Details module) can be used to compare suggested actions with your actual actions on a recorded gameplay.\
Also may be used as a real time combat adviser.

This addon cannot execute any player action.
