## 0.0.12 (2012-03-29)

* BUG: not honor http_proxy env when put file. https://github.com/everbox/everbox-client-ruby/issues/3

## 0.0.11 (2012-02-16)

* honor http_proxy env.

## 0.0.10 (2012-02-13)

* use oauth login by default.

## 0.0.9 (2011-04-22)

* now works under ruby 1.9.
* now works under Windows.
* everbox cat use stream download (0.0.8 will print it to stdout after all data
  downloaded).

## 0.0.8 (2011-04-22)

* everbox help and everbox cat works.

## 0.0.7 (2011-01-21)

* everbox prepare_put works

## 0.0.6 (2011-01-06)

* everbox ls support argument as path
* everbox config (print config or set config)

## 0.0.5 (2010-12-02)

* OAuth login: "everbox login --oauth"
* show user info and space info: "everbox info"
* only get download url (do not download it): "everbox get -u FILENAME"
* gemspec no longer depends on git

