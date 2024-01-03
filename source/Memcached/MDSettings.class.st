"
I hold setting related to the memcached client (unused for now)
"
Class {
	#name : 'MDSettings',
	#superclass : 'Object',
	#category : 'Memcached-Core',
	#package : 'Memcached',
	#tag : 'Core'
}

{ #category : 'as yet unclassified' }
MDSettings >> noStringEncoding [
	^false
]

{ #category : 'as yet unclassified' }
MDSettings >> use32BitFlags [
	^false
]
