# Changelog

## 0.3.4

* WSDL generation fixed to support complex structures for return values
* Configuration moved to OrderedOptions with proper Engine binding
* `snakecase` configuration directive added: if set to false, wash_out won't modify params keys

## 0.3.3

* Tiny fixes in wash_out behavior with inline arrays (#11, #12)
* Ability to change namespace

## 0.3.2

* WashOut doesn't check existance of parameters anymore you should do it yourself from now
* Proper handling of blank parameters (#10)
* Proper handling of complex structures inside arrays (#9)
* Response performance improved

## 0.3.1

* Support of complex structures inside array
* Better Nori handling (no more dependency on Savon hijacking)

## 0.3.0

* The syntax for empty set (no input params or output params) changed from [] to nil.
* SOAP response format improved. All results are now wrapped into tns:messages instead of soap:Body.
* Arrays (minOccurs/maxOccurs) are now supported with `:foo => [:integer]` syntax.
