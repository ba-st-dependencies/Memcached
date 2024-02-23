Class {
	#name : 'MDTest',
	#superclass : 'TestCase',
	#category : 'Memcached-Tests',
	#package : 'Memcached-Tests'
}

{ #category : 'testing' }
MDTest class >> isAbstract [

	^ self name = #MDTest
]

{ #category : 'enumerating' }
MDTest >> withCIHostNameDo: aBlock else: anotherBlock [

	^ LanguagePlatform current os
		  environmentAt: 'CI_MEMCACHED_HOSTNAME'
		  ifPresent: aBlock
		  ifAbsent: anotherBlock
]
