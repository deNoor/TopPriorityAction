# TopPriorityAction
WoW addon to propose combat actions (spells, items). Implements combat action priority list (APL).\
Uses retail WoW UI Lua.

## Current state
- Game version: 10.2.0 (Dragonflight)
- Specs:
  - Active: outlaw (10.2.0)
  - Inactive: protw (10.0.7), fury (10.0.7), assa (10.0.2), feral (9.2.7), guardian (9.2.7)

## Description

### Limitations:
Made for personal use to learn more about WoW and Lua.\
External requests and issues are not accepted.\
My APL is different from SimCraft and AskMrRobot to fit my playstyle and gear. Supports only talents I use.

Has no UI, no ingame description. To visualise a proposed action requires other addons (e.g. WeakAuras, TellMeWhen).\
Sample WeakAura import string:
```
!WA:2!DA1tVTXTs86Adya1MIe3yJ2lTQcTP2aogooXUV4hYbjz5g14yPUADC6jzQDhPL1Ri3sYv2of9qDp0CwFe012t(JG)eSqO49biFe8H353qYDvKsuCaEcqsKZmC(7VziNz3f6UG)c(V8Rhq94Sg8yHhm7qsSkGlQfPOCMm3aVyPI31fovf9TTJzEAYlVsU84hbOIfS8KybPjW6T2(KUqoG5loRw72sqnZfeMhQR6Ckt1QCL9DR4m0JZd95NWACcnco6YSTv87abcIr9YTCKkIqDN((8Mw7Ful7)rF5iRv0i7ouzui5STllaIcwELsugvDNKp(OKBC6C)7qUhjmpQEqu1p)JYx4WI31TEX76fleatDxR9kKZkhzCnIs)RMOSspus9zlUZo12VjE8Mfl7wfxEq9Dk6wPWQgXQIPquQ1T7EcOvqbK3VLlv7kbTthqCiXOWvZtzP5yuWdbYXfXatUwdpcZiGC1XOwvMkBTiGLQVSIrEoRSnCSzKdI81zI0GE10OYwXMic3UgBItmUGt6SlJ5TPe4ROl2zHNrqhOdvQe6yFI95YnYBjtTS96mD2r22UaeLjHHTiEhVSecBVwAYBQX8QzvAR60YJAbbIlN6PVdNq)pxoDV4aM4A9J)VmOlivpL7NzXrq6um09U)w37F9WjzP7T0iQDVxHRv1oqBbid0WM3H2nUVE9unGHlIEFpgXgJzbDMQx)1uYAagpXmUNDDQ)AWLJBnlD7oU4TnEkF9gKDH0820NFms8095Y1QnojrgyhLeL)Dm2ze0580og5NChr6Y)Bj1zrqYnUWo6Qza1hCu0UG)RKXTanaQrC720tVOz5InCB2WTOJBMW6J2cNcQILwrLr3EAnHogMxwoGOY)uqkjDGsX4iWwA3deOR)xJMABe1MhPTT7Y)iSivRUwHnkSsEvayHftankEDGxiucVVJ82GsDPySRquIyZnhP32OXIjZDUmccdR6p6siDLo6btgotoF7nVrYaZr964faEhN8fomuZYCJY)1faM)DAuVYE7nWhAHLdxmXlECL9QV7b71pMLwlxk5gFy0T0MQh4AjPZb)9hCfE1giyKWNH1E0p(JRogGOIOR7PCiONf0NWOD1RyBL8r7MSyjgNbxcej0qHtW6OcMFOp6WAjmLDHeq32xEUwgT7KSrPUekdpBYgj3F(KhKSzYw4YB9MuWqqIiguxqWamg1tXWln2EPKfhIB1tV6i4Xm)xUu0ck8k9MYacE77ZtVVo6Znen)0MlqVUPmDrYg9hXRW3WIU5yhVmpKl(HzMzMzFLLk2dAUZVuXdCRf9PgI4Zk460G3HuFvqPI42RSgIEk4Bi(7dTVx4NsDNln8)zS2tBFwY8deCSFa0pfP0(12VsYIcmO0YmWiONXnMf)0pncyQOBURG(I8)ymXhZkK8UUte4zwAOH2jCH)Hcs05hMUW6a9OsARq4O0yES30Km)uYySrzSPW0BeZHJ8Xg0xaFvAO)8jCinxna4s3hxT8tQDG7Ev3VY)zyNq(j7kGFjgyENvFU1xBJnT5cnJl0)KPMZ1B0AyyRyLIZQ1deyd5an59myVfnYNLh6R3uEuE8Yyj89zuckPzgyebFLsi(urJ2dOEhZWjpZA4ShfxFlJbkHzrqe0kaODcuLlfYj(pRpQYMmS5dzOqLWul50nourZ54fsKYLsO5kP7ESlWuJEXaHbjRJKs63Qw6fCE3zeNMfMzVI8Oe2rr3oBNgPGJGiyXZpiAb0YLt5G9UyZjC0af3RNTX9ZM5pNRa1)CCcBETjAHFBt7KZHegfqM15encTSZRbzBet9VODWdpC5QRuS66FNGY0QccUOTaNYGn3iGB2RS11D1K0UFRgLDQuz)b6oCQ9j2xqzwqbUlx)rnpjZVG0zZ12CTnwO3)88)3d
```

### Purpose:
Shared code might be usefull for other addon developers to find general hints and ideas.\
Combined with third-party visualization and a visual spell tracker (e.g. TrufiGCD, Details module) can be used to compare suggested actions with your actual actions on a recorded gameplay.\
Also may be used as a real time combat adviser.

This addon cannot execute any player action.
