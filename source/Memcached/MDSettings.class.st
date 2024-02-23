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

{ #category : 'testing' }
MDSettings >> noStringEncoding [
	^false
]

{ #category : 'testing' }
MDSettings >> use32BitFlags [
	^false
]
