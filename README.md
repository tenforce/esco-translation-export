# ESCO EXPORT SERVICE

This service provides an endpoint from which you can get a CSV that contains an entry for every concept with it's uri, isco group code, pref label and alt labels

## API

We only have a single route: /export. When a GET call is performed to this endpoint it returns a comma separated string with an entry for every concept. You can add a language parameter:
```
export?language=nl
```
and then you will get only labels in that language. By default that language will be 'en' if the parameter was not set. If a certain concept does not have pref label in that language then the value will be "" (so effectively there will be nothing between the second and the third comman). After this a |-separtared list will follow with all alt labels in that language.
