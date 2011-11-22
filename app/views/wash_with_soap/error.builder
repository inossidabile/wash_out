xml.instruct!
xml.Envelope "xmlns:xsi" => 'http://www.w3.org/2001/XMLSchema-instance',
             :xmlns => 'http://schemas.xmlsoap.org/soap/envelope/' do
  xml.Body do
    xml.Fault :encodingStyle => 'http://schemas.xmlsoap.org/soap/encoding/' do
      xml.faultcode "Server", 'xsi:type' => 'xsd:QName'
      xml.faultstring error_message, 'xsi:type' => 'xsd:string'
    end
  end
end
