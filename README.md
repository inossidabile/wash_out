Wash Out
========

Wash Out is a gem that greatly simplifies creation of SOAP service providers.

Installation
------------

    $ gem install wash_out

Usage
-----

A SOAP endpoint in WashOut is simply a Rails controller which includes the module WashOut::Dispatcher. Each SOAP
action corresponds to a certain controller method; this mapping, as well as the argument definition, is defined
by [wsdl_method][] method. Check the method documentation for complete info; here,
only a few examples will be demonstrated.

  [wsdl_method]: #

```ruby
# app/controllers/api_controller.rb
class ApiController < ApplicationController
  include WashOut::Dispatcher

  wsdl_method :integer_to_string,
              :args   => :integer,
              :return => :string
  def integer_to_string(value)
    value.to_s
  end

  wsdl_method :concat,
              :args   => { :a => :string, :b => :string }
              :return => :string
  def concat(a, b)
    a + b
  end

  wsdl_method :add_circle,
              :args   => { :circle => { :center => { :x => :integer,
                                                     :y => :integer },
                                        :radius => :float } },
              :return => []
  def add_circle(circle)
    raise SOAPError, "radius is too small" if circle[:radius] < 3.0

    Circle.new(circle[:center][:x], circle[:center][:y], circle[:radius])
  end
end
```

```ruby
# config/routes.rb
HelloWorld::Application.routes.draw do
  wash_with_soap :api
end
```

License
-------

    Copyright (C) 2011 by Boris Staal <boris@roundlake.ru>,
                          Peter Zotov <whitequark@whitequark.org>.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
