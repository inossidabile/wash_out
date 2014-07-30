xml.instruct!
xml.tag!("wsdl:definitions",
         {'xmlns:soap' => 'http://schemas.xmlsoap.org/wsdl/soap/',
          #          'xmlns:tm' => 'http://microsoft.com/wsdl/mime/textMatching/',
          'xmlns:soapenc' => 'http://schemas.xmlsoap.org/soap/encoding/',
          'xmlns:mime' => 'http://schemas.xmlsoap.org/wsdl/mime/',
          'xmlns:tns' => @namespace,
          'xmlns:s' => 'http://www.w3.org/2001/XMLSchema',
          'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
          'xmlns:soap12' => 'http://schemas.xmlsoap.org/wsdl/soap12/',
          'xmlns' => 'http://schemas.xmlsoap.org/wsdl/',
          'xmlns:http' => 'http://schemas.xmlsoap.org/wsdl/http/',
          'xmlns:wsdl' => 'http://schemas.xmlsoap.org/wsdl/',
          'name' => @name,
          'targetNamespace' => @namespace}) do

            #xml.types do
            xml.tag! "wsdl:types" do
              xml.tag! "s:schema", :elementFormDefault => "qualified", :targetNamespace => @namespace do
                defined = []
                @map.each do |operation, formats|
                  xml.tag! "s:element", :name => "#{operation}" do
                    (formats[:in]).each do |p|
                      wsdl_type xml, p, defined
                    end
                  end
                end

                @map.each do |operation, formats|
                  xml.tag!("s:element", :name => "#{operation}#{controller.soap_config.camelize_wsdl ? 'Response' : '_response'}") do
                    (formats[:out]).each do |p|
                      wsdl_type xml, p, defined
                    end
                  end
                end

              end
            end

            @map.each do |operation, formats|
              #xml.message :name => "#{operation}" do
              xml.tag!("wsdl:message", {:name => "#{operation}#{controller.soap_config.camelize_wsdl ? 'SoapIn' : '_soap_in'}"}) do
                formats[:in].each do |p|
                  #xml.part wsdl_occurence(p, false, :name => p.name, :type => p.namespaced_type)
                  #xml.tag!("wsdl:part", wsdl_occurence(p, false, :name => p.name, :type => "s:#{p.type}") )
                  xml.tag!("wsdl:part", wsdl_occurence(p, false, :name => "parameters", :element => "tns:#{operation}") )
                end
              end
              #xml.message :name => "#{operation}#{controller.soap_config.camelize_wsdl ? 'Response' : '_response'}" do
              xml.tag!("wsdl:message",{:name => "#{operation}#{controller.soap_config.camelize_wsdl ? 'SoapOut' : '_soap_out'}"}) do
                formats[:out].each do |p|
                  #xml.part wsdl_occurence(p, false, :name => p.name, :type => p.namespaced_type)
                  #xml.tag!("wsdl:part", wsdl_occurence(p, false, :name => p.name, :element => "tns:#{p.type}") )
                  xml.tag!("wsdl:part", wsdl_occurence(p, false, :name => "parameters", :element => "tns:#{operation}#{controller.soap_config.camelize_wsdl ? 'Response' : '_response'}") )
                end
              end
            end

#            @map.each do |operation, formats|
#              #xml.message :name => "#{operation}" do
#              xml.tag!("wsdl:message", {:name => "#{operation}#{controller.soap_config.camelize_wsdl ? 'HttpGetIn' : '_http_get_in'}"}) do
#                formats[:in].each do |p|
#                  #xml.part wsdl_occurence(p, false, :name => p.name, :type => p.namespaced_type)
#                  #xml.tag!("wsdl:part", wsdl_occurence(p, false, :name => p.name, :type => "s:#{p.type}") )
#                  xml.tag!("wsdl:part", wsdl_occurence(p, false, :name => p.name, :type => "s:#{p.type}") )
#                end
#              end
#              #xml.message :name => "#{operation}#{controller.soap_config.camelize_wsdl ? 'Response' : '_response'}" do
#              xml.tag!("wsdl:message",{:name => "#{operation}#{controller.soap_config.camelize_wsdl ? 'HttpGetOut' : '_http_get_out'}"}) do
#                formats[:out].each do |p|
#                  #xml.part wsdl_occurence(p, false, :name => p.name, :type => p.namespaced_type)
#                  #xml.tag!("wsdl:part", wsdl_occurence(p, false, :name => p.name, :element => "tns:#{p.type}") )
#                  xml.tag!("wsdl:part", wsdl_occurence(p, false, :name => "Body", :element => "tns:#{p.type}"))
#                end
#              end
#            end
#
#            @map.each do |operation, formats|
#              #xml.message :name => "#{operation}" do
#              xml.tag!("wsdl:message", {:name => "#{operation}#{controller.soap_config.camelize_wsdl ? 'HttpPostIn' : '_http_post_in'}"}) do
#                formats[:in].each do |p|
#                  #xml.part wsdl_occurence(p, false, :name => p.name, :type => p.namespaced_type)
#                  #xml.tag!("wsdl:part", wsdl_occurence(p, false, :name => p.name, :type => "s:#{p.type}") )
#                  xml.tag!("wsdl:part", wsdl_occurence(p, false, :name => p.name, :type => "s:#{p.type}") )
#                end
#              end
#              #xml.message :name => "#{operation}#{controller.soap_config.camelize_wsdl ? 'Response' : '_response'}" do
#              xml.tag!("wsdl:message",{:name => "#{operation}#{controller.soap_config.camelize_wsdl ? 'HttpPostOut' : '_http_post_out'}"}) do
#                formats[:out].each do |p|
#                  #xml.part wsdl_occurence(p, false, :name => p.name, :type => p.namespaced_type)
#                  #xml.tag!("wsdl:part", wsdl_occurence(p, false, :name => p.name, :element => "tns:#{p.type}") )
#                  xml.tag!("wsdl:part", wsdl_occurence(p, false, :name => "Body", :element => "tns:#{p.type}"))
#                end
#              end
#            end

            #xml.portType :name => "#{@name}_port_soap" do
            xml.tag!("wsdl:portType",{:name => "#{@name}_port_soap"}) do
              @map.keys.each do |operation|
                #xml.operation :name => operation do
                xml.tag!("wsdl:operation",{:name => operation}) do
                  #xml.input :message => "tns:#{operation}"
                  xml.tag!("wsdl:input",{:message => "tns:#{operation}#{controller.soap_config.camelize_wsdl ? 'SoapIn' : '_soap_in'}"})
                  #xml.output :message => "tns:#{operation}#{controller.soap_config.camelize_wsdl ? 'Response' : '_response'}"
                  xml.tag!("wsdl:output",{:message => "tns:#{operation}#{controller.soap_config.camelize_wsdl ? 'SoapOut' : '_soap_out'}"})
                end
              end
            end

#            xml.tag!("wsdl:portType",{:name => "#{@name}_port_soap12"}) do
#              @map.keys.each do |operation|
#                #xml.operation :name => operation do
#                xml.tag!("wsdl:operation",{:name => operation}) do
#                  #xml.input :message => "tns:#{operation}"
#                  xml.tag!("wsdl:input",{:message => "tns:#{operation}#{controller.soap_config.camelize_wsdl ? 'SoapIn' : '_soap_in'}"})
#                  #xml.output :message => "tns:#{operation}#{controller.soap_config.camelize_wsdl ? 'Response' : '_response'}"
#                  xml.tag!("wsdl:output",{:message => "tns:#{operation}#{controller.soap_config.camelize_wsdl ? 'SoapOut' : '_soap_out'}"})
#                end
#              end
#            end

            #xml.portType :name => "#{@name}_port_http_get" do
#            xml.tag!("wsdl:portType",{:name => "#{@name}_port_http_get"}) do
#              @map.keys.each do |operation|
#                #xml.operation :name => operation do
#                xml.tag!("wsdl:operation",{:name => operation}) do
#                  #xml.input :message => "tns:#{operation}"
#                  xml.tag!("wsdl:input",{:message => "tns:#{operation}#{controller.soap_config.camelize_wsdl ? 'HttpGetIn' : '_http_get_in'}"})
#                  #xml.output :message => "tns:#{operation}#{controller.soap_config.camelize_wsdl ? 'Response' : '_response'}"
#                  xml.tag!("wsdl:output",{:message => "tns:#{operation}#{controller.soap_config.camelize_wsdl ? 'HttpGetOut' : '_http_get_out'}"})
#                end
#              end
#            end

#            #xml.portType :name => "#{@name}_port_http_post" do
#            xml.tag!("wsdl:portType",{:name => "#{@name}_port_http_post"}) do
#              @map.keys.each do |operation|
#                #xml.operation :name => operation do
#                xml.tag!("wsdl:operation",{:name => operation}) do
#                  #xml.input :message => "tns:#{operation}"
#                  xml.tag!("wsdl:input",{:message => "tns:#{operation}#{controller.soap_config.camelize_wsdl ? 'HttpPostIn' : '_http_post_in'}"})
#                  #xml.output :message => "tns:#{operation}#{controller.soap_config.camelize_wsdl ? 'Response' : '_response'}"
#                  xml.tag!("wsdl:output",{:message => "tns:#{operation}#{controller.soap_config.camelize_wsdl ? 'HttpPostOut' : '_http_post_out'}"})
#                end
#              end
#            end

            #xml.binding :name => "#{@name}_binding_soap", :type => "tns:#{@name}_port_soap" do
            xml.tag!("wsdl:binding",{:name => "#{@name}_binding_soap", :type => "tns:#{@name}_port_soap"}) do
              xml.tag! "soap:binding", :transport => 'http://schemas.xmlsoap.org/soap/http'
              @map.keys.each do |operation|
                #xml.operation :name => operation do
                xml.tag!("wsdl:operation",{:name => operation}) do
                  xml.tag! "soap:operation", :soapAction => "#{@namespace}/#{operation}", :style => 'document'
                  #xml.input do
                  xml.tag!("wsdl:input",{}) do
                    xml.tag! "soap:body",
                      :use => "literal"
                    #:namespace => @namespace
                  end
                  #xml.output do
                  xml.tag!("wsdl:output",{}) do
                    xml.tag! "soap:body",
                      :use => "literal"
                    #:namespace => @namespace
                  end
                end
              end
            end

#            #xml.binding :name => "#{@name}_binding_soap12", :type => "tns:#{@name}_port_soap12" do
#            xml.tag!("wsdl:binding",{:name => "#{@name}_binding_soap12", :type => "tns:#{@name}_port_soap"}) do
#              xml.tag! "soap12:binding", :transport => 'http://schemas.xmlsoap.org/soap/http'
#              @map.keys.each do |operation|
#                #xml.operation :name => operation do
#                xml.tag!("wsdl:operation",{:name => operation}) do
#                  xml.tag! "soap12:operation", :soapAction => "#{@namespace}/#{operation}", :style => 'document'
#                  #xml.input do
#                  xml.tag!("wsdl:input",{}) do
#                    xml.tag! "soap12:body",
#                      :use => "literal"
#                    #:namespace => @namespace
#                  end
#                  #xml.output do
#                  xml.tag!("wsdl:output", {}) do
#                    xml.tag! "soap12:body",
#                      :use => "literal"
#                    #:namespace => @namespace
#                  end
#                end
#              end
#            end

#            #xml.binding :name => "#{@name}_binding_http_get", :type => "tns:#{@name}_port_http_get" do
#            xml.tag!("wsdl:binding",{:name => "#{@name}_binding_http_get", :type => "tns:#{@name}_port_http_get"}) do
#              xml.tag! "http:binding", :verb => 'GET'
#              @map.keys.each do |operation|
#                #xml.operation :name => operation do
#                xml.tag!("wsdl:operation",{:name => operation}) do
#                  xml.tag!("http:operation", {:location => "/#{operation}"})
#                  #xml.input do
#                  xml.tag!("wsdl:input",{}) do
#                    xml.tag! "http:urlEncoded"
#                  end
#                  #xml.output do
#                  xml.tag!("wsdl:output",{}) do
#                    xml.tag! "mime:mimeXml",
#                      :part => "Body"
#                  end
#                end
#              end
#            end

#            #xml.binding :name => "#{@name}_binding_http_post", :type => "tns:#{@name}_port_http_post" do
#            xml.tag!("wsdl:binding",{:name => "#{@name}_binding_http_post", :type => "tns:#{@name}_port_http_post"}) do
#              xml.tag! "http:binding", :verb => 'POST'
#              @map.keys.each do |operation|
#                #xml.operation :name => operation do
#                xml.tag!("wsdl:operation", {:name => operation}) do
#                  xml.tag!("http:operation", {:location => "/#{operation}"})
#                  #xml.input do
#                  xml.tag!("wsdl:input",{}) do
#                    xml.tag! "mime:content",
#                      :type => "application/x-www-form-urlencoded"
#                  end
#                  #xml.output do
#                  xml.tag!("wsdl:output",{}) do
#                    xml.tag! "mime:mimeXml",
#                      :part => "Body"
#                  end
#                end
#              end
#            end

            #xml.service :name => "CoachOnRubyWebService" do
            xml.tag!("wsdl:service", {:name => "CoachOnRubyWebService"}) do
              #xml.port :name => "#{@name}_port_soap", :binding => "tns:#{@name}_binding_soap" do
              xml.tag!("wsdl:port",{:name => "#{@name}_port_soap", :binding => "tns:#{@name}_binding_soap"}) do
                xml.tag! "soap:address", :location => send("#{@name}_action_url")
              end
              #xml.port :name => "#{@name}_port_soap12", :binding => "tns:#{@name}_binding_soap12" do
#              xml.tag!("wsdl:port",{:name => "#{@name}_port_soap12", :binding => "tns:#{@name}_binding_soap12"}) do
#                xml.tag! "soap12:address", :location => send("#{@name}_action_url")
#              end
#              #xml.port :name => "#{@name}_port_http_get", :binding => "tns:#{@name}_binding_http_get" do
#              xml.tag!("wsdl:port",{:name => "#{@name}_port_http_get", :binding => "tns:#{@name}_binding_http_get"}) do
#                xml.tag! "http:address", :location => send("#{@name}_action_url")
#              end
#              #xml.port :name => "#{@name}_port_http_post", :binding => "tns:#{@name}_binding_http_post" do
#              xml.tag!("wsdl:port",{:name => "#{@name}_port_http_post", :binding => "tns:#{@name}_binding_http_post"}) do
#                xml.tag! "http:address", :location => send("#{@name}_action_url")
#              end
            end

          end
