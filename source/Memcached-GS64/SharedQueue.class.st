Class {
	#name : 'SharedQueue',
	#superclass : 'Object',
	#instVars : [
		'queue'
	],
	#category : 'Memcached-GS64',
	#package : 'Memcached-GS64'
}

{ #category : 'instance creation' }
SharedQueue class >> new [

	^ super new initialize
]

{ #category : 'accessing' }
SharedQueue >> findFirst: matchBlock [

	^ queue detect: matchBlock ifNone: [ nil ]
]

{ #category : 'initialization' }
SharedQueue >> initialize [

	super initialize.
	queue := RcQueue new
]

{ #category : 'accessing' }
SharedQueue >> nextPut: anObject [

	queue add: anObject.
	^ anObject
]
