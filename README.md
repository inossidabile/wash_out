Wash Out
========

Wash Out is a gem that greatly simplifies creation of SOAP service providers.

Installation
------------

In your Gemfile, add this line:

    gem 'wash_out'

Usage
-----

A SOAP endpoint in WashOut is simply a Rails controller which includes the module WashOut::SOAP. Each SOAP
action corresponds to a certain controller method; this mapping, as well as the argument definition, is defined
by [soap_action][] method. Check the method documentation for complete info; here,
only a few examples will be demonstrated.

  [soap_action]: http://rubydoc.info/gems/wash_out/0.2.0/WashOut/SOAP/ClassMethods#soap_action-instance_method

```ruby
# app/controllers/api_controller.rb
class ApiController < ApplicationController
  include WashOut::SOAP

  soap_action "integer_to_string",
              :args   => :integer,
              :return => :string
  def integer_to_string
    render :soap => params[:value].to_s
  end

  soap_action "concat",
              :args   => { :a => :string, :b => :string },
              :return => :string
  def concat
    render :soap => (params[:a] + params[:b])
  end

  soap_action "AddCircle",
              :args   => { :circle => { :center => { :x => :integer,
                                                     :y => :integer },
                                        :radius => :float } },
              :return => [],
              :to     => :add_circle
  def add_circle
    circle = params[:circle]

    raise SOAPError, "radius is too small" if circle[:radius] < 3.0

    Circle.new(circle[:center][:x], circle[:center][:y], circle[:radius])

    render :soap => nil
  end
end
```

```ruby
# config/routes.rb
HelloWorld::Application.routes.draw do
  wash_out :api
end
```

In such a setup, the generated WSDL may be queried at path `/api/wsdl`. So, with a
gem like Savon, a request can be done using this path:

```ruby
require 'savon'

client = Savon::Client.new("http://localhost:3000/api/wsdl")
client.wsdl.soap_actions # => [:integer_to_string, :concat]
client.request(:concat) do
  soap.body = { :a => "123", :b => "abc" }
end[:value] # => "123abc"
```

License
-------

    Copyright (C) 2011 by Boris Staal <boris@roundlake.ru>,
                          Peter Zotov <p.zotov@roundlake.ru>.

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
