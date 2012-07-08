define ->
    
    # The routes for the application. This module returns a function.
    # `match` is match method of the Router
    (match) ->

        match '', 				'documents#index'
        match 'edit/:document', 'documents#edit'
        match 'new',            'documents#new'