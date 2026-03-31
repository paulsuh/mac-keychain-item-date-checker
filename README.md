# Mac Keychain Item Date Checker
Checks a Mac keychain for items that are close to their expiry dates. 

Checks for password items that are within a certain interval of expiring, and notifies user. 

- Phase I: generic items, user keychain, only 30 days
- Phase II: generic items, user keychain, specified interval (30 days default)
- Phase III: generic|internet|certificates (generic default), user keychain, specified interval (30 days default)
- Phase IV: generic|internet|certificates (generic default), specified keychain (user default), specified interval (30 days default)
- Phase V: configurable automatic remediation scripts
