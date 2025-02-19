"
I am a memcache client for persistent databases like toyko tyrant or memcached db which implmentes the memcache protocol but doesn't support expiration.  This client adds client based expiration; keep in mind these db's don't supprt LRU cache expiration and won't shrink when something expires.
"
Class {
	#name : 'MDCacheDbClient',
	#superclass : 'MDCacheClientBase',
	#category : 'Memcached-Client',
	#package : 'Memcached',
	#tag : 'Client'
}

{ #category : 'protocol' }
MDCacheDbClient >> get: aSymbol [
	"memcachedb doesn't support expiration, so we implement expiration in the client so it can still be used as 
	an expiring cache.  The set:value: messages wrap all values with a valid expiration time which is read here"

	| result |
	result := super get: aSymbol.
	(result isNil or: [ result first < DateAndTime now ])
		ifTrue: [ ^ nil ].
	^ result second
]

{ #category : 'protocol' }
MDCacheDbClient >> set: aSymbol value: aValue expires: aDuration [
	"Wrap value in association with an expiration time, still passing up duration in case server changes in future"

	super
		set: aSymbol
		value:
			(Array
				with:
					(aDuration
						ifNil: [ DateAndTime now + 10 days ]
						ifNotNil: [ DateAndTime now + aDuration ])
				with: aValue)
		expires: aDuration.
	^ aValue
]
