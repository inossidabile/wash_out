xml.instruct!
xml.tag! "soap:Envelope", "xmlns:soap" => 'http://schemas.xmlsoap.org/soap/envelope/',
                          "xmlns:xsd" => 'http://www.w3.org/2001/XMLSchema',
                          "xmlns:xsi" => 'http://www.w3.org/2001/XMLSchema-instance',
                          "xmlns:#{@response_tag.nil? ? 'tns:' : @response_tag}" => @namespace do
  if !header.nil?
    xml.tag! "soap:Header" do
      if @response_attribute_tags.nil?
        xml.tag! "#{@response_tag.nil? ? 'tns:' : @response_tag}#{@action_spec[:response_tag]}" do
          wsdl_data xml, header
        end
      else
        xml.tag! "#{@response_tag.nil? ? 'tns:' : @response_tag}#{@action_spec[:response_tag]}", @response_attribute_tags do
          wsdl_data xml, header
        end
      end
    end
  end
  xml.tag! "soap:Body" do
    if @response_attribute_tags.nil?
      xml.tag! "#{@response_tag.nil? ? 'tns:' : @response_tag}#{@action_spec[:response_tag]}" do
        wsdl_data xml, result
      end
    else
      xml.tag! "#{@response_tag.nil? ? 'tns:' : @response_tag}#{@action_spec[:response_tag]}", @response_attribute_tags do
        wsdl_data xml, result
      end
    end
  end
end
