Extension { #name : 'SharedQueue' }

{ #category : '*Memcached-GS64' }
SharedQueue >> findFirst: matchBlock [

	^ self isEmpty
		  ifTrue: [ nil ]
		  ifFalse: [
			  | value |

			  value := contents detect: matchBlock ifNone: [ nil ].
			  value ifNotNil: [
				  valueAvailable wait.
				  contents remove: value
				  ].
			  value
			  ]
]
