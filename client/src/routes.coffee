define ->
    # The routes for the application. This module returns a function.
    # `match` is match method of the Router
    (match) ->
        match 'admin/',          'documents#index'
        match 'admin/edit/:_id', 'documents#edit'
        match 'admin/new',       'documents#new'
        match 'admin/export',    'documents#export'