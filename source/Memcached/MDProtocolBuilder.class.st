"
I represent the information of a memcached server, its host address and port
"
Class {
	#name : 'MDProtocolBuilder',
	#superclass : 'Object',
	#instVars : [
		'host',
		'port'
	],
	#category : 'Memcached-Core',
	#package : 'Memcached',
	#tag : 'Core'
}

{ #category : 'instance creation' }
MDProtocolBuilder class >> buildDefault [

	^ self new
		host: self defaultHost;
		port: self defaultPort;
		build
]

{ #category : 'accessing defaults' }
MDProtocolBuilder class >> defaultHost [

	^ '127.0.0.1'
]

{ #category : 'accessing defaults' }
MDProtocolBuilder class >> defaultPort [

	^ 11211
]

{ #category : 'building' }
MDProtocolBuilder >> build [

	| stream |
	stream := host isString
		          ifTrue: [
			          ZnNetworkingUtils default socketStreamClass
				          openConnectionToHostNamed: host
				          port: port ]
		          ifFalse: [
			          ZnNetworkingUtils default socketStreamClass
				          openConnectionToHost: host
				          port: port ].
	^ MDProtocol on: stream
]

{ #category : 'accessing' }
MDProtocolBuilder >> host: aStringOrByteArray [
	
	"aStringOrByteArray can either be a String with the hostname or a ByteArray with the host address"
	host := aStringOrByteArray
]

{ #category : 'accessing' }
MDProtocolBuilder >> port: aPortNumber [

	port := aPortNumber
]
