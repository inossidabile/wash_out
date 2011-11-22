xml.instruct!
xml.Envelope "xmlns:xsi" => 'http://www.w3.org/2001/XMLSchema-instance',
             :xmlns => 'http://schemas.xmlsoap.org/soap/envelope/' do
  xml.Body do
    wsdl_data xml, result
  end
end
