(function() {
  /**
   * Require the given path.
   *
   * @param {String} path
   * @return {Object} exports
   * @api public
   */
  function require(path, parent, orig) {
    var resolved = require.resolve(path);

    // lookup failed
    if (null == resolved) {
      orig = orig || path;
      parent = parent || 'root';
      var err = new Error('Failed to require "' + orig + '" from "' + parent + '"');
      err.path = orig;
      err.parent = parent;
      err.require = true;
      throw err;
    }

    var module = require.modules[resolved];

    // perform real require()
    // by invoking the module's
    // registered function
    if (!module._resolving && !module.exports) {
      var mod = {};
      mod.exports = {};
      mod.client = mod.component = true;
      module._resolving = true;
      module.call(this, mod.exports, require.relative(resolved), mod);
      delete module._resolving;
      module.exports = mod.exports;
    }

    return module.exports;
  }

  /**
   * Registered modules.
   */

  require.modules = {};

  /**
   * Registered aliases.
   */

  require.aliases = {};

  /**
   * Resolve `path`.
   *
   * Lookup:
   *
   *   - PATH/index.js
   *   - PATH.js
   *   - PATH
   *
   * @param {String} path
   * @return {String} path or null
   * @api private
   */

  require.resolve = function(path) {
    if (path.charAt(0) === '/') path = path.slice(1);

    var paths = [
      path,
      path + '.js',
      path + '.json',
      path + '/index.js',
      path + '/index.json'
    ];

    for (var i = 0; i < paths.length; i++) {
      var path = paths[i];
      if (require.modules.hasOwnProperty(path)) return path;
      if (require.aliases.hasOwnProperty(path)) return require.aliases[path];
    }
  };

  /**
   * Normalize `path` relative to the current path.
   *
   * @param {String} curr
   * @param {String} path
   * @return {String}
   * @api private
   */

  require.normalize = function(curr, path) {
    var segs = [];

    if ('.' != path.charAt(0)) return path;

    curr = curr.split('/');
    path = path.split('/');

    for (var i = 0; i < path.length; ++i) {
      if ('..' == path[i]) {
        curr.pop();
      } else if ('.' != path[i] && '' != path[i]) {
        segs.push(path[i]);
      }
    }

    return curr.concat(segs).join('/');
  };

  /**
   * Register module at `path` with callback `definition`.
   *
   * @param {String} path
   * @param {Function} definition
   * @api private
   */

  require.register = function(path, definition) {
    require.modules[path] = definition;
  };

  /**
   * Alias a module definition.
   *
   * @param {String} from
   * @param {String} to
   * @api private
   */

  require.alias = function(from, to) {
    if (!require.modules.hasOwnProperty(from)) {
      throw new Error('Failed to alias "' + from + '", it does not exist');
    }
    require.aliases[to] = from;
  };

  /**
   * Return a require function relative to the `parent` path.
   *
   * @param {String} parent
   * @return {Function}
   * @api private
   */

  require.relative = function(parent) {
    var p = require.normalize(parent, '..');

    /**
     * lastIndexOf helper.
     */

    function lastIndexOf(arr, obj) {
      var i = arr.length;
      while (i--) {
        if (arr[i] === obj) return i;
      }
      return -1;
    }

    /**
     * The relative require() itself.
     */

    function localRequire(path) {
      var resolved = localRequire.resolve(path);
      return require(resolved, parent, path);
    }

    /**
     * Resolve relative to the parent.
     */

    localRequire.resolve = function(path) {
      var c = path.charAt(0);
      if ('/' == c) return path.slice(1);
      if ('.' == c) return require.normalize(p, path);

      // resolve deps by returning
      // the dep in the nearest "deps"
      // directory
      var segs = parent.split('/');
      var i = lastIndexOf(segs, 'deps') + 1;
      if (!i) i = 0;
      path = segs.slice(0, i + 1).join('/') + '/deps/' + path;
      return path;
    };

    /**
     * Check if module is defined at `path`.
     */
    localRequire.exists = function(path) {
      return require.modules.hasOwnProperty(localRequire.resolve(path));
    };

    return localRequire;
  };

  // All our modules will see our own require.
  (function() {
    
    
    // app.coffee
    require.register('blad/client/src/app.js', function(exports, require, module) {
    
      var App, Layout, routes, _ref,
        __hasProp = {}.hasOwnProperty,
        __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };
      
      Layout = require('../views/layout');
      
      routes = require('routes');
      
      App = (function(_super) {
        __extends(App, _super);
      
        function App() {
          _ref = App.__super__.constructor.apply(this, arguments);
          return _ref;
        }
      
        App.prototype.title = 'blað CMS';
      
        App.prototype.apiKey = void 0;
      
        App.prototype.auth = function(signedIn) {
          var cookie, k, v, _i, _len, _ref1, _ref2;
          _ref1 = document.cookie.split(';');
          for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
            cookie = _ref1[_i];
            _ref2 = cookie.split('='), k = _ref2[0], v = _ref2[1];
            if (k === 'X-Blad-ApiKey') {
              return signedIn(true, v);
            }
          }
          $('#app').append($('<div/>', {
            'class': 'alert-box',
            'text': 'Signing-in to Persona.org (Mozilla), make sure pop-ups are allowed'
          }));
          return navigator.id.get(function(assertion) {
            if (assertion) {
              return $.ajax({
                url: '/auth',
                type: 'POST',
                dataType: 'json',
                data: {
                  'assertion': assertion
                },
                success: function(data) {
                  var d;
                  d = new Date();
                  d.setDate(d.getDate() + 1);
                  d = d.toUTCString();
                  document.cookie = "X-Blad-ApiKey=" + data.key + ";expires=" + d;
                  return signedIn(true, data.key);
                },
                error: function(data) {
                  return signedIn(false, data);
                }
              });
            } else {
              return signedIn(false, {
                'message': 'Cancelled sign-in'
              });
            }
          });
        };
      
        App.prototype.initialize = function() {
          var _this = this;
          App.__super__.initialize.apply(this, arguments);
          this.initDispatcher();
          this.initLayout();
          this.initTemplates();
          this.initMediator();
          return this.auth(function(isSignedIn, res) {
            if (isSignedIn) {
              _this.apiKey = res;
              _this.initRouter(routes);
              return typeof Object.freeze === "function" ? Object.freeze(_this) : void 0;
            } else {
              return $('#app').append($('<div/>', {
                'class': 'alert-box alert',
                'text': JSON.parse(res.responseText).message
              }));
            }
          });
        };
      
        App.prototype.initLayout = function() {
          return this.layout = new Layout({
            title: this.title
          });
        };
      
        App.prototype.initTemplates = function() {
          return window.JST = {};
        };
      
        App.prototype.initMediator = function() {
          Chaplin.mediator.user = null;
          return Chaplin.mediator.seal();
        };
      
        return App;
      
      })(Chaplin.Application);
      
      module.exports = App;
      
    });

    
    // documents_controller.coffee
    require.register('blad/client/src/controllers/documents_controller.js', function(exports, require, module) {
    
      var Document, DocumentEditView, DocumentExportView, Documents, DocumentsController, DocumentsListView, _ref,
        __hasProp = {}.hasOwnProperty,
        __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };
      
      Document = require('../models/document');
      
      Documents = require('../models/documents');
      
      DocumentsListView = require('../views/documents_list_view');
      
      DocumentEditView = require('../views/document_edit_view');
      
      DocumentExportView = require('../views/document_export_view');
      
      DocumentsController = (function(_super) {
        __extends(DocumentsController, _super);
      
        function DocumentsController() {
          _ref = DocumentsController.__super__.constructor.apply(this, arguments);
          return _ref;
        }
      
        DocumentsController.prototype.historyURL = function(params) {
          return '';
        };
      
        DocumentsController.prototype.index = function(params) {
          if (params == null) {
            params = {};
          }
          this.collection = new Documents();
          return this.collection.fetch({
            'error': function(collection, response) {
              throw response;
            },
            'success': function(collection, response) {
              return this.view = new DocumentsListView({
                'collection': collection,
                'message': params != null ? params.message : void 0
              });
            }
          });
        };
      
        DocumentsController.prototype.edit = function(params) {
          if (params == null) {
            params = {};
          }
          this.model = new Document({
            '_id': params._id
          });
          return this.model.fetch({
            'success': function(model) {
              return this.view = new DocumentEditView({
                'model': model,
                'message': params != null ? params.message : void 0
              });
            }
          });
        };
      
        DocumentsController.prototype["new"] = function() {
          return this.view = new DocumentEditView();
        };
      
        DocumentsController.prototype["export"] = function() {
          this.collection = new Documents();
          return this.collection.fetch({
            'error': function(collection, response) {
              return this.view = new DocumentExportView({
                'message': {
                  'type': 'alert',
                  'text': 'There was a problem getting your documents. Server offline?'
                }
              });
            },
            'success': function(collection, response) {
              var count, message;
              if ((count = collection.length) > 0) {
                message = {
                  'type': 'success',
                  'text': "" + count + " document" + (count !== 1 ? 's' : '') + " exported."
                };
              } else {
                message = {
                  'type': 'notify',
                  'text': 'Nothing to export.'
                };
              }
              return this.view = new DocumentExportView({
                'collection': collection,
                'message': message
              });
            }
          });
        };
      
        return DocumentsController;
      
      })(Chaplin.Controller);
      
      module.exports = DocumentsController;
      
    });

    
    // document.coffee
    require.register('blad/client/src/models/document.js', function(exports, require, module) {
    
      var Document, _ref,
        __hasProp = {}.hasOwnProperty,
        __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };
      
      Document = (function(_super) {
        __extends(Document, _super);
      
        function Document() {
          _ref = Document.__super__.constructor.apply(this, arguments);
          return _ref;
        }
      
        Document.prototype.idAttribute = "_id";
      
        Document.prototype.defaults = {
          'type': 'BasicDocument',
          'public': true
        };
      
        Document.prototype.url = function() {
          if (this.get('_id') != null) {
            return '/api/document?_id=' + this.get('_id');
          } else {
            return '/api/document';
          }
        };
      
        Document.prototype.sync = function(method, model, options) {
          options = options || {};
          options.headers = {
            'X-Blad-ApiKey': window.app.apiKey
          };
          return Backbone.sync(method, this, options);
        };
      
        Document.prototype.getAttributes = function() {
          return _.extend({
            '_description': this.attrDescription(),
            '_types': this.attrTypes()
          }, this.attributes);
        };
      
        Document.prototype.attrDescription = function() {
          if (this.get('description') == null) {
            return {};
          }
          return this.get('description').replace(/label:(\S*)/g, '<span class="radius label">$1</span>');
        };
      
        Document.prototype.attrTypes = function() {
          var key, value;
          return ((function() {
            var _ref1, _results;
            _ref1 = window.JST;
            _results = [];
            for (key in _ref1) {
              value = _ref1[key];
              if (key.indexOf('form_') === 0) {
                _results.push(key.slice(5, key.length - 4));
              }
            }
            return _results;
          })()).sort();
        };
      
        return Document;
      
      })(Chaplin.Model);
      
      module.exports = Document;
      
    });

    
    // documents.coffee
    require.register('blad/client/src/models/documents.js', function(exports, require, module) {
    
      var Document, Documents, _ref,
        __hasProp = {}.hasOwnProperty,
        __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };
      
      Document = require('./document');
      
      Documents = (function(_super) {
        __extends(Documents, _super);
      
        function Documents() {
          _ref = Documents.__super__.constructor.apply(this, arguments);
          return _ref;
        }
      
        Documents.prototype.url = '/api/documents';
      
        Documents.prototype.sync = function(method, model, options) {
          options = options || {};
          options.headers = {
            'X-Blad-ApiKey': window.app.apiKey
          };
          return Backbone.sync(method, this, options);
        };
      
        Documents.prototype.model = Document;
      
        return Documents;
      
      })(Chaplin.Collection);
      
      module.exports = Documents;
      
    });

    
    // routes.coffee
    require.register('blad/client/src/routes.js', function(exports, require, module) {
    
      module.exports = function(match) {
        match('admin/', 'documents#index');
        match('admin/edit/:_id', 'documents#edit');
        match('admin/new', 'documents#new');
        return match('admin/export', 'documents#export');
      };
      
    });

    
    // document_edit.eco
    require.register('blad/client/src/templates/document_edit.js', function(exports, require, module) {
    
      module.exports = function(__obj) {
        if (!__obj) __obj = {};
        var __out = [], __capture = function(callback) {
          var out = __out, result;
          __out = [];
          callback.call(this);
          result = __out.join('');
          __out = out;
          return __safe(result);
        }, __sanitize = function(value) {
          if (value && value.ecoSafe) {
            return value;
          } else if (typeof value !== 'undefined' && value != null) {
            return __escape(value);
          } else {
            return '';
          }
        }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
        __safe = __obj.safe = function(value) {
          if (value && value.ecoSafe) {
            return value;
          } else {
            if (!(typeof value !== 'undefined' && value != null)) value = '';
            var result = new String(value);
            result.ecoSafe = true;
            return result;
          }
        };
        if (!__escape) {
          __escape = __obj.escape = function(value) {
            return ('' + value)
              .replace(/&/g, '&amp;')
              .replace(/</g, '&lt;')
              .replace(/>/g, '&gt;')
              .replace(/"/g, '&quot;');
          };
        }
        (function() {
          (function() {
            var type, _i, _len, _ref;
          
            __out.push('<!-- head -->\n<h2>\n    ');
          
            __out.push(__sanitize(this.type));
          
            __out.push('\n    ');
          
            if (this.url) {
              __out.push('\n        ');
              if (this["public"]) {
                __out.push('\n            <a href="');
                __out.push(__sanitize(this.url));
                __out.push('" target="_new">\n                ');
                __out.push(__sanitize(this.url));
                __out.push(' <span class="external icon-external-link"></span>\n            </a>\n        ');
              } else {
                __out.push('\n            ');
                __out.push(__sanitize(this.url));
                __out.push('\n        ');
              }
              __out.push('\n    ');
            }
          
            __out.push('\n</h2>\n\n');
          
            if (this._id) {
              __out.push('\n    <input type="hidden" name="_id" value="');
              __out.push(__sanitize(this._id));
              __out.push('">\n');
            }
          
            __out.push('\n\n<div class="row">\n    <!-- the type -->\n    <div class="three columns">\n        <label>Document type</label>\n        <select class="changeType" name="type">\n            ');
          
            _ref = this._types;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              type = _ref[_i];
              __out.push('\n                <option value="');
              __out.push(__sanitize(type));
              __out.push('" ');
              if (this.type === type) {
                __out.push('selected="selected"');
              }
              __out.push('>');
              __out.push(__sanitize(type));
              __out.push('</option>\n            ');
            }
          
            __out.push('\n        </select>\n    </div>\n    <!-- the url -->\n    <div class="four columns">\n        <label>URL</label>\n        <input type="text" placeholder="/" name="url" value="');
          
            __out.push(__sanitize(this.url));
          
            __out.push('">\n    </div>\n    <!-- published status -->\n    <div class="one columns">\n        <label>Public</label>\n        <select name="public">\n            <option value="true" ');
          
            if (this["public"]) {
              __out.push('selected="selected"');
            }
          
            __out.push('>Yes</option>\n            <option value="false" ');
          
            if (!this["public"]) {
              __out.push('selected="selected"');
            }
          
            __out.push('>No</option>\n        </select>\n    </div>\n    <!-- the description -->\n    <div class="four columns">\n        <label>Description</label>\n        <input type="text" name="description" value="');
          
            __out.push(__sanitize(this.description));
          
            __out.push('">\n    </div>\n</div>\n\n<!-- custom type fields -->\n<div class="row" id="custom"></div>\n\n<!-- save -->\n<div class="row">    \n    <!-- save -->\n    <a class="save success button right">Save</a>\n\n    <!-- delete -->\n    ');
          
            if (this._id) {
              __out.push('\n        <a class="delete alert button ĺeft">Delete</a>\n    ');
            }
          
            __out.push('\n</div>');
          
          }).call(this);
          
        }).call(__obj);
        __obj.safe = __objSafe, __obj.escape = __escape;
        return __out.join('');
      }
    });

    
    // document_row.eco
    require.register('blad/client/src/templates/document_row.js', function(exports, require, module) {
    
      module.exports = function(__obj) {
        if (!__obj) __obj = {};
        var __out = [], __capture = function(callback) {
          var out = __out, result;
          __out = [];
          callback.call(this);
          result = __out.join('');
          __out = out;
          return __safe(result);
        }, __sanitize = function(value) {
          if (value && value.ecoSafe) {
            return value;
          } else if (typeof value !== 'undefined' && value != null) {
            return __escape(value);
          } else {
            return '';
          }
        }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
        __safe = __obj.safe = function(value) {
          if (value && value.ecoSafe) {
            return value;
          } else {
            if (!(typeof value !== 'undefined' && value != null)) value = '';
            var result = new String(value);
            result.ecoSafe = true;
            return result;
          }
        };
        if (!__escape) {
          __escape = __obj.escape = function(value) {
            return ('' + value)
              .replace(/&/g, '&amp;')
              .replace(/</g, '&lt;')
              .replace(/>/g, '&gt;')
              .replace(/"/g, '&quot;');
          };
        }
        (function() {
          (function() {
            __out.push('<!-- description with optional labels -->\n<span class="right">');
          
            __out.push(this._description);
          
            __out.push('</span>\n\n<!-- url and link to edit document -->\n');
          
            if (this["public"]) {
              __out.push('\n    <strong><a href="edit/');
              __out.push(__sanitize(this._id));
              __out.push('">');
              __out.push(__sanitize(this.url));
              __out.push('</a></strong>\n    <a href="');
              __out.push(__sanitize(this.url));
              __out.push('" target="_new" class="external icon-external-link"></a>\n');
            } else {
              __out.push('\n    <strong><a class="private" href="edit/');
              __out.push(__sanitize(this._id));
              __out.push('">');
              __out.push(__sanitize(this.url));
              __out.push('</a></strong>\n');
            }
          
            __out.push('\n\n<!-- the type of the document -->\n<span class="radius label secondary type">');
          
            __out.push(__sanitize(this.type));
          
            __out.push('</span>');
          
          }).call(this);
          
        }).call(__obj);
        __obj.safe = __objSafe, __obj.escape = __escape;
        return __out.join('');
      }
    });

    
    // message.eco
    require.register('blad/client/src/templates/message.js', function(exports, require, module) {
    
      module.exports = function(__obj) {
        if (!__obj) __obj = {};
        var __out = [], __capture = function(callback) {
          var out = __out, result;
          __out = [];
          callback.call(this);
          result = __out.join('');
          __out = out;
          return __safe(result);
        }, __sanitize = function(value) {
          if (value && value.ecoSafe) {
            return value;
          } else if (typeof value !== 'undefined' && value != null) {
            return __escape(value);
          } else {
            return '';
          }
        }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
        __safe = __obj.safe = function(value) {
          if (value && value.ecoSafe) {
            return value;
          } else {
            if (!(typeof value !== 'undefined' && value != null)) value = '';
            var result = new String(value);
            result.ecoSafe = true;
            return result;
          }
        };
        if (!__escape) {
          __escape = __obj.escape = function(value) {
            return ('' + value)
              .replace(/&/g, '&amp;')
              .replace(/</g, '&lt;')
              .replace(/>/g, '&gt;')
              .replace(/"/g, '&quot;');
          };
        }
        (function() {
          (function() {
            __out.push('<div class="alert-box ');
          
            __out.push(__sanitize(this.type));
          
            __out.push('">\n  ');
          
            __out.push(__sanitize(this.text));
          
            __out.push('\n  <a class="close">&times;</a>\n</div>');
          
          }).call(this);
          
        }).call(__obj);
        __obj.safe = __objSafe, __obj.escape = __escape;
        return __out.join('');
      }
    });

    
    // document_custom_view.coffee
    require.register('blad/client/src/views/document_custom_view.js', function(exports, require, module) {
    
      var DocumentCustomView, _ref,
        __hasProp = {}.hasOwnProperty,
        __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };
      
      DocumentCustomView = (function(_super) {
        __extends(DocumentCustomView, _super);
      
        function DocumentCustomView() {
          _ref = DocumentCustomView.__super__.constructor.apply(this, arguments);
          return _ref;
        }
      
        DocumentCustomView.prototype.container = '#custom';
      
        DocumentCustomView.prototype.containerMethod = 'html';
      
        DocumentCustomView.prototype.autoRender = true;
      
        DocumentCustomView.prototype.getTemplateFunction = function() {
          return require('../templates/form_' + this.model.get('type'));
        };
      
        DocumentCustomView.prototype.initialize = function(params) {
          this.model = params.model;
          return this.subviews != null ? this.subviews : this.subviews = [];
        };
      
        DocumentCustomView.prototype.afterRender = function() {
          DocumentCustomView.__super__.afterRender.apply(this, arguments);
          this.delegate('change', '[data-custom="file"]', this.loadFileHandler);
          return this.delegate('change', '[data-custom="date"]', this.niceDateHandler);
        };
      
        DocumentCustomView.prototype.loadFileHandler = function(e) {
          var file,
            _this = this;
          file = new FileReader();
          file.readAsDataURL($(e.target)[0].files[0]);
          return file.onload = function(event) {
            var target;
            target = $(e.target).attr('data-target');
            return $(_this.el).find("[name=" + target + "]").val(event.target.result);
          };
        };
      
        DocumentCustomView.prototype.niceDateHandler = function(e) {
          var d, div, j, t, target, _ref1;
          target = $(e.target);
          target.closest('div').removeClass('error');
          if ((_ref1 = this.error) != null) {
            _ref1.remove();
          }
          d = Kronic.parse(target.val());
          if (d == null) {
            div = target.closest('div');
            div.addClass('error');
            return div.append(this.error = $('<small/>', {
              'text': 'Do not understand this date'
            }));
          } else {
            j = new Date(d).toJSON();
            t = target.attr('data-target');
            return $(this.el).find("[name=" + t + "]").val(j);
          }
        };
      
        return DocumentCustomView;
      
      })(Chaplin.View);
      
      module.exports = DocumentCustomView;
      
    });

    
    // document_edit_view.coffee
    require.register('blad/client/src/views/document_edit_view.js', function(exports, require, module) {
    
      var Document, DocumentCustomView, DocumentEditView, MessageView, _ref,
        __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
        __hasProp = {}.hasOwnProperty,
        __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };
      
      Document = require('../models/document');
      
      DocumentCustomView = require('./document_custom_view');
      
      MessageView = require('./message_view');
      
      DocumentEditView = (function(_super) {
        __extends(DocumentEditView, _super);
      
        function DocumentEditView() {
          this.deleteHandler = __bind(this.deleteHandler, this);
          this.saveHandler = __bind(this.saveHandler, this);
          _ref = DocumentEditView.__super__.constructor.apply(this, arguments);
          return _ref;
        }
      
        DocumentEditView.prototype.clearThese = [];
      
        DocumentEditView.prototype.tagName = 'form';
      
        DocumentEditView.prototype.container = '#app';
      
        DocumentEditView.prototype.containerMethod = 'html';
      
        DocumentEditView.prototype.autoRender = true;
      
        DocumentEditView.prototype.getTemplateFunction = function() {
          return require('../templates/document_edit');
        };
      
        DocumentEditView.prototype.initialize = function(params) {
          if (this.subviews == null) {
            this.subviews = [];
          }
          this.model = (params != null ? params.model : void 0) || new Document();
          if ((params != null ? params.message : void 0) != null) {
            return this.message = params.message;
          }
        };
      
        DocumentEditView.prototype.afterRender = function() {
          DocumentEditView.__super__.afterRender.apply(this, arguments);
          this.undelegate();
          this.delegate('click', '.save', this.saveHandler);
          this.delegate('click', '.delete', this.deleteHandler);
          this.delegate('change', '.changeType', this.changeTypeHandler);
          this.subviews.push(new DocumentCustomView({
            'model': this.model
          }));
          if (this.message != null) {
            return this.subviews.push(new MessageView(this.message));
          }
        };
      
        DocumentEditView.prototype.saveHandler = function() {
          var attr, element, object, _i, _j, _len, _len1, _ref1, _ref2,
            _this = this;
          attr = {};
          _ref1 = $("" + this.container + " " + this.tagName).serializeArray();
          for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
            object = _ref1[_i];
            switch (object.value) {
              case 'true':
                attr[object.name] = true;
                break;
              case 'false':
                attr[object.name] = false;
                break;
              default:
                attr[object.name] = object.value;
            }
          }
          $(this.container).find("" + this.tagName + " .error").removeClass('error');
          _ref2 = this.clearThese;
          for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
            element = _ref2[_j];
            element.remove();
          }
          return this.model.save(attr, {
            'wait': true,
            'success': function(model, response) {
              Chaplin.mediator.publish('!startupController', 'documents', 'edit', {
                '_id': response._id,
                'message': {
                  'type': 'success',
                  'text': "Document " + (model.get('url')) + " saved."
                }
              });
              return Chaplin.mediator.publish('!router:changeURL', "admin/edit/" + response._id);
            },
            'error': function(model, response) {
              var div, field, message, small, _ref3;
              _ref3 = JSON.parse(response.responseText);
              for (field in _ref3) {
                message = _ref3[field];
                div = $(_this.container).find("" + _this.tagName + " [name=" + field + "]").closest('div');
                div.addClass('error');
                div.append(small = $('<small/>', {
                  'text': message
                }));
                _this.clearThese.push(small);
              }
              return _this.subviews.push(new MessageView({
                'type': 'alert',
                'text': "You no want dis."
              }));
            }
          });
        };
      
        DocumentEditView.prototype.deleteHandler = function() {
          if (confirm('Are you sure you want to delete this document?')) {
            return this.model.destroy({
              'success': function(model, response) {
                Chaplin.mediator.publish('!startupController', 'documents', 'index', {
                  'message': {
                    'type': 'success',
                    'text': "Document " + (model.get('url')) + " deleted."
                  }
                });
                return Chaplin.mediator.publish('!router:changeURL', "admin/");
              },
              'error': function(model, response) {
                return this.subviews.push(new MessageView({
                  'type': 'alert',
                  'text': "You no want dis."
                }));
              }
            });
          }
        };
      
        DocumentEditView.prototype.changeTypeHandler = function(e) {
          this.model.set('type', $(e.target).find('option:selected').text());
          return this.render();
        };
      
        return DocumentEditView;
      
      })(Chaplin.View);
      
      module.exports = DocumentEditView;
      
    });

    
    // document_export_view.coffee
    require.register('blad/client/src/views/document_export_view.js', function(exports, require, module) {
    
      var DocumentExportView, MessageView, _ref,
        __hasProp = {}.hasOwnProperty,
        __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };
      
      MessageView = require('./message_view');
      
      DocumentExportView = (function(_super) {
        __extends(DocumentExportView, _super);
      
        function DocumentExportView() {
          _ref = DocumentExportView.__super__.constructor.apply(this, arguments);
          return _ref;
        }
      
        DocumentExportView.prototype.container = '#app';
      
        DocumentExportView.prototype.containerMethod = 'html';
      
        DocumentExportView.prototype.autoRender = true;
      
        DocumentExportView.prototype.getTemplateFunction = function() {};
      
        DocumentExportView.prototype.initialize = function(params) {
          DocumentExportView.__super__.initialize.apply(this, arguments);
          if ((params != null ? params.message : void 0) != null) {
            return this.message = params.message;
          }
        };
      
        DocumentExportView.prototype.afterRender = function() {
          var blob;
          DocumentExportView.__super__.afterRender.apply(this, arguments);
          if (this.message != null) {
            new MessageView(this.message);
          }
          if (this.collection && this.collection.length !== 0) {
            blob = new Blob([JSON.stringify(this.collection.toJSON())], {
              'type': "application/json;charset=utf-8"
            });
            return saveAs(blob, "blad-cms-dump-" + ((new Date).toISOString()) + ".json");
          }
        };
      
        return DocumentExportView;
      
      })(Chaplin.View);
      
      module.exports = DocumentExportView;
      
    });

    
    // document_list_view.coffee
    require.register('blad/client/src/views/document_list_view.js', function(exports, require, module) {
    
      var DocumentListView, _ref,
        __hasProp = {}.hasOwnProperty,
        __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };
      
      DocumentListView = (function(_super) {
        __extends(DocumentListView, _super);
      
        function DocumentListView() {
          _ref = DocumentListView.__super__.constructor.apply(this, arguments);
          return _ref;
        }
      
        DocumentListView.prototype.tagName = 'li';
      
        DocumentListView.prototype.getTemplateFunction = function() {
          return require('../templates/document_row');
        };
      
        return DocumentListView;
      
      })(Chaplin.View);
      
      module.exports = DocumentListView;
      
    });

    
    // documents_list_view.coffee
    require.register('blad/client/src/views/documents_list_view.js', function(exports, require, module) {
    
      var DocumentListView, DocumentsListView, MessageView, _ref,
        __hasProp = {}.hasOwnProperty,
        __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };
      
      DocumentListView = require('./document_list_view');
      
      MessageView = require('./message_view');
      
      DocumentsListView = (function(_super) {
        __extends(DocumentsListView, _super);
      
        function DocumentsListView() {
          _ref = DocumentsListView.__super__.constructor.apply(this, arguments);
          return _ref;
        }
      
        DocumentsListView.prototype.tagName = 'ul';
      
        DocumentsListView.prototype.className = 'list';
      
        DocumentsListView.prototype.container = '#app';
      
        DocumentsListView.prototype.containerMethod = 'html';
      
        DocumentsListView.prototype.autoRender = true;
      
        DocumentsListView.prototype.getView = function(item) {
          return new DocumentListView({
            'model': item
          });
        };
      
        DocumentsListView.prototype.initialize = function(params) {
          DocumentsListView.__super__.initialize.apply(this, arguments);
          if ((params != null ? params.message : void 0) != null) {
            return this.message = params.message;
          }
        };
      
        DocumentsListView.prototype.afterRender = function() {
          DocumentsListView.__super__.afterRender.apply(this, arguments);
          if (this.message != null) {
            return new MessageView(this.message);
          }
        };
      
        return DocumentsListView;
      
      })(Chaplin.CollectionView);
      
      module.exports = DocumentsListView;
      
    });

    
    // layout.coffee
    require.register('blad/client/src/views/layout.js', function(exports, require, module) {
    
      var Layout, _ref,
        __hasProp = {}.hasOwnProperty,
        __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };
      
      Layout = (function(_super) {
        __extends(Layout, _super);
      
        function Layout() {
          _ref = Layout.__super__.constructor.apply(this, arguments);
          return _ref;
        }
      
        return Layout;
      
      })(Chaplin.Layout);
      
      module.exports = Layout;
      
    });

    
    // message_view.coffee
    require.register('blad/client/src/views/message_view.js', function(exports, require, module) {
    
      var MessageView, _ref,
        __hasProp = {}.hasOwnProperty,
        __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };
      
      MessageView = (function(_super) {
        __extends(MessageView, _super);
      
        function MessageView() {
          _ref = MessageView.__super__.constructor.apply(this, arguments);
          return _ref;
        }
      
        MessageView.prototype.container = '#app';
      
        MessageView.prototype.containerMethod = 'prepend';
      
        MessageView.prototype.autoRender = true;
      
        MessageView.prototype.getTemplateFunction = function() {
          return require('../templates/message');
        };
      
        MessageView.prototype.getTemplateData = function() {
          return this.params;
        };
      
        MessageView.prototype.initialize = function(params) {
          this.params = params;
          return MessageView.__super__.initialize.apply(this, arguments);
        };
      
        MessageView.prototype.afterRender = function() {
          MessageView.__super__.afterRender.apply(this, arguments);
          return this.delegate('click', this.dispose);
        };
      
        return MessageView;
      
      })(Chaplin.View);
      
      module.exports = MessageView;
      
    });
  })();

  // Return the main app.
  var main = require("blad/client/src/app.js");

  // Global on server, window in browser.
  var root = this;

  // AMD/RequireJS.
  if (typeof define !== 'undefined' && define.amd) {
  
    define("blad", [ /* load deps ahead of time */ ], function () {
      return main;
    });
  
  }

  // CommonJS.
  else if (typeof module !== 'undefined' && module.exports) {
    module.exports = main;
  }

  // Globally exported.
  else {
  
    root["blad"] = main;
  
  }

  // Alias our app.
  
  require.alias("blad/client/src/app.js", "blad/index.js");
  

  // Export internal loader?
  root.require = (typeof root.require !== 'undefined') ? root.require : require;
})();