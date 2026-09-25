# Changelog

## 1.0.1+2

- Fixed Android app-time inflation caused by treating `firstTimeStamp` and `lastTimeStamp` as one continuous foreground session.
- Usage totals now use Android's `totalTimeInForeground` daily aggregate.
- Version 1 usage cache is deleted on upgrade and rebuilt from corrected Android data.
- Successful syncs atomically replace the seven-day cache; platform errors preserve existing history.
- Dashboard and Insights no longer treat an empty app selection as permission to total every system app.
- App usage minutes are aggregated from milliseconds before rounding.
