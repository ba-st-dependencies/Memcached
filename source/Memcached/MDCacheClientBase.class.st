"
Common abstract memcached client
"
Class {
	#name : 'MDCacheClientBase',
	#superclass : 'Object',
	#instVars : [
		'servers',
		'serverList',
		'lock'
	],
	#classVars : [
		'materializationAction',
		'serializationAction'
	],
	#classInstVars : [
		'serverPool'
	],
	#category : 'Memcached-Client',
	#package : 'Memcached',
	#tag : 'Client'
}

{ #category : 'defaults' }
MDCacheClientBase class >> defaultConnectionLifetime [
	^ 10 minutes
]

{ #category : 'defaults' }
MDCacheClientBase class >> defaultConnectionRetries [
	^ 5
]

{ #category : 'class initialization' }
MDCacheClientBase class >> initialize [

	self
		materializationAction: [ :bytes | self error: 'No materializer found' ]
		serializationAction: [ :object | self error: 'No serializer found' ]
]

{ #category : 'class initialization' }
MDCacheClientBase class >> materializationAction: aMaterializationBlock serializationAction: aSerializationBlock [

	materializationAction := aMaterializationBlock.
	serializationAction := aSerializationBlock
]

{ #category : 'accessing' }
MDCacheClientBase class >> materialize: bytes [

	^ materializationAction value: bytes
]

{ #category : 'instance creation' }
MDCacheClientBase class >> onServers: aList [
	^ (self new)
		serverList: aList;
		yourself
]

{ #category : 'socket-pool' }
MDCacheClientBase class >> returnServer: aServer [
	^ self serverPool nextPut: aServer
]

{ #category : 'accessing' }
MDCacheClientBase class >> serialize: object [

	^ serializationAction value: object
]

{ #category : 'socket-pool' }
MDCacheClientBase class >> serverAt: aKey ifAbsent: aBlock [

	| found |

	found := self serverPool findFirst: [ :e | e first = aKey ].
	found
		ifNil: [ ^ Array with: aKey with: DateAndTime now with: aBlock value ].
	DateAndTime now - found second > self defaultConnectionLifetime
		ifFalse: [ ^ found ].
	found third quit execute.
	^ self serverAt: aKey ifAbsent: aBlock
]

{ #category : 'socket-pool' }
MDCacheClientBase class >> serverPool [
	^ serverPool ifNil: [ serverPool := SharedQueue new ]
]

{ #category : 'private' }
MDCacheClientBase >> assertServers [

	serverList
		ifNil: [ Error signal: 'Memcache servers not configured!' ]
]

{ #category : 'private' }
MDCacheClientBase >> close [
	servers ifNil: [ ^ self ].
	(servers reject: [ :e | e isNil ]) do: [ :e | self class returnServer: e ].
	servers := nil
]

{ #category : 'protocol' }
MDCacheClientBase >> decrement: aString [
	self assertServers.
	^ self
		whileConnected: [ 
			((self serverForKey: aString) decr)
				key: aString asByteArray;
				execute ]
]

{ #category : 'protocol' }
MDCacheClientBase >> get: aString [

	self assertServers.

	^ [ | item |
	item := self
		whileConnected: [ (self serverForKey: aString) get
				key: aString asByteArray;
				execute ].
	item data ifNotNil: [ :value | self class materialize: item data ] ]
		on: MDKeyNotFoundError , Error
		do: [ :signal | signal return: nil ]
]

{ #category : 'protocol' }
MDCacheClientBase >> get: aString ifAbsentPut: aBlock [
	self assertServers.
	^ (self get: aString) ifNil: [ self set: aString value: aBlock value ]
]

{ #category : 'protocol' }
MDCacheClientBase >> get: aString ifAbsentPut: aBlock expires: aDuration [
	self assertServers.
	^ (self get: aString) ifNil: [ self set: aString value: aBlock value expires: aDuration ]
]

{ #category : 'protocol' }
MDCacheClientBase >> increment: aString [
	self assertServers.
	^ [ 
	self
		whileConnected: [ 
			((self serverForKey: aString) incr)
				key: aString asByteArray;
				execute ] ]
		on: MDKeyNotFoundError
		do: [ :signal | 
			self setCounter: aString value: 0.
			signal retry ]
]

{ #category : 'private' }
MDCacheClientBase >> lock [
	^ lock ifNil: [ lock := Monitor new ]
]

{ #category : 'private' }
MDCacheClientBase >> open [

	self assertServers.
	servers := (serverList
		collect: [ :e | self startServer: e key onPort: e value asNumber ])
		select: [ :signal | signal notNil ]
]

{ #category : 'protocol' }
MDCacheClientBase >> remove: aString [
	
	self assertServers.
	
	[ 
	self
		whileConnected: [ 
			((self serverForKey: aString) delete)
				key: aString asByteArray;
				execute ] ]
		on: Error
		do: [ :signal | signal return: nil ]
]

{ #category : 'private' }
MDCacheClientBase >> removeDeadServerIp: anIp port: aPort [
	"if you don't kill dead servers, then when one dies your site will fall over continually
	trying to reconnect to it"
	serverList := serverList reject: [ :each | each key = anIp and: [ each value = aPort asString ] ]
]

{ #category : 'private' }
MDCacheClientBase >> serverForKey: aKey [
	"hash the key to one of the servers in the pool"
	^ (servers at: aKey hash \\ servers size + 1) third
]

{ #category : 'accessing' }
MDCacheClientBase >> serverList: aList [

	serverList := aList
		collect: [ :e | 
			| server |
			server := ':' split: e.
			(( '.' split: server first) collect: [ :n | n asNumber ]) -> server second ]
]

{ #category : 'protocol' }
MDCacheClientBase >> set: aString value: aValue [

	^ self set: aString value: aValue expires: nil
]

{ #category : 'protocol' }
MDCacheClientBase >> set: aString value: aValue expires: aDuration [

	| serialized |

	self assertServers.
	^ [ serialized := self class serialize: aValue.
	self
		whileConnected: [ 
			(self serverForKey: aString) set
				key: aString asByteArray;
				data: serialized;
				expiration: (aDuration ifNil: [ 0 seconds ]) asSeconds truncated asString asByteArray;
				execute ].
	aValue ]
		on: Error
		do: [:signal | signal return: aValue ]
]

{ #category : 'protocol' }
MDCacheClientBase >> setCounter: aString value: anInteger [

	self assertServers.
	^ [ self
		whileConnected: [ (self serverForKey: aString) set
				key: aString asByteArray;
				data: anInteger asString asByteArray;
				execute ].
	anInteger ]
		on: Error
		do: [ :signal | signal return: anInteger ]
]

{ #category : 'private' }
MDCacheClientBase >> startServer: anIp onPort: aPort [

	| retries ipString |
	retries := 0.

	ipString := '.' join: anIp.
	^ self class serverAt: ipString , ':' , aPort asString ifAbsent: [
		  [
		  retries := retries + 1.
		  MDProtocolBuilder new
			  host: ipString;
			  port: aPort;
			  build ]
			  on: ConnectionTimedOut
			  do: [ :signal |
				  retries > self class defaultConnectionRetries ifTrue: [
					  self removeDeadServerIp: anIp port: aPort.
					  ^ nil ].
				  (Delay forMilliseconds: 100) wait.
				  signal retry ] ]
]

{ #category : 'private' }
MDCacheClientBase >> whileConnected: aBlock [
	| retried |
	^ self lock
		critical: [ 
			retried := false.
			self open.
			[ 
			aBlock
				on: MDConnectionClosedError , ConnectionClosed
				do: [ :signal | 
					retried
						ifTrue: [ signal pass ].
					servers := nil.
					retried := true.
					self open.
					signal retry ] ] ensure: [ self close ] ]
]
