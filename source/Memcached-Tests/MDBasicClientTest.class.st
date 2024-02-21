"
Unit tests for MDBasicClient
"
Class {
	#name : 'MDBasicClientTest',
	#superclass : 'TestCase',
	#category : 'Memcached-Tests',
	#package : 'Memcached-Tests'
}

{ #category : 'support' }
MDBasicClientTest >> newClient [

	^ LanguagePlatform current os
		  environmentAt: 'CI_MEMCACHED_HOSTNAME'
		  ifPresent: [ :hostname |
			  MDBasicClient on: ( MDProtocolBuilder new
					    host: hostname;
					    port: MDProtocolBuilder defaultPort;
					    build )
			  ]
		  ifAbsent: [ MDBasicClient new ]
]

{ #category : 'tests' }
MDBasicClientTest >> testAddValue [

	self useClientDuring: [ :client |
		client add: 'foo1' value: #[ 1 2 3 ].
		self assert: ( client get: 'foo1' ) equals: #[ 1 2 3 ]
		].

	self useClientDuring: [ :client |
		client add: 'foo1' value: 'other value'.
		self assert: ( client get: 'foo1' ) equals: #[ 1 2 3 ]
		]
]

{ #category : 'tests' }
MDBasicClientTest >> testConvenience [

	self useClientDuring: [ :client |
		client at: 'foo' ifAbsentPut: [ #[ 1 2 3 ] ].
		self assert: ( client at: 'foo' ) equals: #[ 1 2 3 ].
		self assert: ( client includesKey: 'foo' ).
		client removeKey: 'foo'.
		self deny: ( client includesKey: 'foo' ).
		self should: [ client at: 'foo' ] raise: MDKeyNotFoundError
		]
]

{ #category : 'tests' }
MDBasicClientTest >> testDecrement [

	self useClientDuring: [ :client |
		client
			encoder: [ :object | object printString asByteArray ];
			decoder: [ :byteArray | Object readFrom: byteArray asString ].

		client set: #counter value: 10.
		self assert: 9 equals: ( client decrement: #counter ).
		self assert: 8 equals: ( client decrement: #counter ).
		self assert: 7 equals: ( client decrement: #counter ).
		self assert: 6 equals: ( client decrement: #counter ).
		self assert: 5 equals: ( client decrement: #counter ).

		client delete: #counter
		]
]

{ #category : 'tests' }
MDBasicClientTest >> testEncoderDecoder [

	self useClientDuring: [ :client |
		client
			encoder: [ :object | ( STON toString: object ) utf8Encoded ];
			decoder: [ :bytes | STON fromString: bytes utf8Decoded ].

		client set: 'string' value: 'aStringValue'.
		self assert: ( client get: 'string' ) equals: 'aStringValue'.
		client set: 'integer' value: 123456.
		self assert: ( client get: 'integer' ) equals: 123456.
		client set: 'boolean' value: true.
		self assert: ( client get: 'boolean' ) equals: true
		]
]

{ #category : 'tests' }
MDBasicClientTest >> testIncrement [

	self useClientDuring: [ :client |
		client
			encoder: [ :object | object printString asByteArray ];
			decoder: [ :byteArray | Object readFrom: byteArray asString ].

		client set: #counter value: 5.
		self assert: 6 equals: ( client increment: #counter ).
		self assert: 7 equals: ( client increment: #counter ).
		self assert: 8 equals: ( client increment: #counter ).
		self assert: 9 equals: ( client increment: #counter ).
		self assert: 10 equals: ( client increment: #counter ).

		client delete: #counter
		]
]

{ #category : 'tests' }
MDBasicClientTest >> testReplaceValue [

	| client |

	client := self newClient.
	[ self deny: (client replace: 'foo2' value: #[1 2 3]).
	self should: [ client get: 'foo2' ] raise: MDKeyNotFoundError ]
		ensure: [ 
			client flushAll.
			client close ]
]

{ #category : 'tests' }
MDBasicClientTest >> testSetGet [

	self useClientDuring: [ :client |
		client set: 'foo' value: #[ 1 2 3 ].
		self assert: ( client get: 'foo' ) equals: #[ 1 2 3 ]
		]
]

{ #category : 'tests' }
MDBasicClientTest >> testStats [

	self useClientDuring: [ :client |
		self
			assert: ( $. split: client stats version ) first >= '1'
			description: 'This test requires at least version 1.5.0 released in 2017-7-21'.
		self.
		self
			assert: ( $. split: client stats version ) second >= '5'
			description: 'This test requires at least version 1.5.0 released in 2017-7-21'
		]
]

{ #category : 'support' }
MDBasicClientTest >> useClientDuring: aBlock [

	| client |

	client := self newClient.
	[ aBlock value: client ] ensure: [ client close ]
]
